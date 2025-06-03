module ark.tui;

import ark.style;
import ark.components;
import ark.structures;

import core.thread;
import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.string;
import std.datetime;
import std.format;
import std.math;

version (Windows)
{
	import core.sys.windows.windows;
	import core.sys.windows.wincon;
}
else
{
	import core.sys.posix.unistd;
	import core.sys.posix.termios;
	import ark.style;
}

mixin Structures!();

/** 
 * Terminal components.
 */
final class ArkTerm
{
	private static immutable defaultLineLength = 50;
	private static bool colorEnabled = true;
	private static size_t spinnerIndex = 0;
	private static immutable string[] spinnerChars = [
		"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"
	];

	private static BorderChars[BorderStyle] borderStyles;

	static this()
	{
		version (Windows)
			SetConsoleOutputCP(65_001);

		borderStyles = [
			BorderStyle.SINGLE: BorderChars("┌", "┐", "└", "─┘", "─", "│", "┬", "┴", "├", "┤", "┼"),
			BorderStyle.DOUBLE: BorderChars("╔", "╗", "╚", "╝", "═", "║", "╦", "╩", "╠", "╣", "╬"),
			BorderStyle.ROUNDED: BorderChars("╭", "╮", "╰", "─╯", "─", "│", "┬", "┴", "├", "┤", "┼"),
			BorderStyle.THICK: BorderChars("┏", "┓", "┗", "┛", "━", "┃", "┳", "┻", "┣", "┫", "╋"),
			BorderStyle.ASCII: BorderChars("+", "+", "+", "+", "-", "|", "+", "+", "+", "+", "+")
		];
	}

	mixin ArkStyle!();
	mixin ArkComponents!();

	static void writeBlock(string text, string sep = "─", size_t length = defaultLineLength, Color color = Color
			.RESET)
	{
		printSeparator(sep, length, color);
		write(text ~ "\n");
		printSeparator(sep, length, color);
		write("\n");
	}

	static void log(LogLevel level, string message)
	{
		auto timestamp = Clock.currTime.toISOExtString()[0 .. 19];
		string levelStr;
		Color levelColor;

		final switch (level)
		{
		case LogLevel.INFO:
			levelStr = "INFO ";
			levelColor = Color.BLUE;
			break;
		case LogLevel.SUCCESS:
			levelStr = "OK   ";
			levelColor = Color.GREEN;
			break;
		case LogLevel.WARNING:
			levelStr = "WARN ";
			levelColor = Color.YELLOW;
			break;
		case LogLevel.ERROR:
			levelStr = "ERROR";
			levelColor = Color.RED;
			break;
		case LogLevel.DEBUG:
			levelStr = "DEBUG";
			levelColor = Color.MAGENTA;
			break;
		}

		writef("[%s] %s %s\n",
			colorize(timestamp, Color.BRIGHT_BLACK),
			colorize(levelStr, levelColor),
			message
		);
	}

	static void printIndented(string text, size_t level = 1, string indent = "  ")
	{
		writeln(indent.replicate(level) ~ text);
	}

	static void clear()
	{
		version (Windows)
		{
			for (int i = 0; i < 100; i++)
			{
				writeln("\n");
			}
			HANDLE hConsole = GetStdHandle(
				STD_OUTPUT_HANDLE);
			CONSOLE_SCREEN_BUFFER_INFO csbi;

			if (!GetConsoleScreenBufferInfo(
					hConsole, &csbi))
			{
				writeln("Failed to get console buffer info.");
				return;
			}

			SMALL_RECT scrollRect = csbi.srWindow;
			COORD destOrigin = COORD(0, cast(short)(csbi.srWindow.Top - 100));
			CHAR_INFO fill;
			fill.Char.AsciiChar = ' ';
			fill.Attributes = csbi
				.wAttributes;

			ScrollConsoleScreenBufferA(
				hConsole,
				&scrollRect,
				null,
				destOrigin,
				&fill
			);

			COORD topLeft = COORD(0, csbi
					.srWindow
					.Top);
			SetConsoleCursorPosition(hConsole, topLeft);
		}
		version (Posix)
		{
			write("\033[2J\033[H");
		}
	}
}

/** 
 * Specifically for input-capturing TUIs.
 */
final class ArkTUI
{
	version (Windows)
	{
		HANDLE hIn;
		DWORD originalMode;
	}
	else
	{
		termios origTerm;
	}

	this()
	{
		version (Windows)
			SetConsoleOutputCP(
				65_001);

		enableRawMode();
		write(
			"\033[?25l");
	}

	~this()
	{
		disableRawMode();
		write("\033[?25h");
		write("\033[0m\033[2J\033[H");
	}

	void enableRawMode()
	{
		version (Windows)
		{
			hIn = GetStdHandle(STD_INPUT_HANDLE);
			DWORD mode;
			GetConsoleMode(hIn, &mode);
			originalMode = mode;
			mode &= ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT);
			SetConsoleMode(hIn, mode);
		}
		else
		{
			tcgetattr(0, &origTerm);
			termios raw = origTerm;
			raw.c_lflag &= ~(
				ICANON | ECHO);
			tcsetattr(0, TCSAFLUSH, &raw);
		}
	}

	void disableRawMode()
	{
		version (Windows)
			SetConsoleMode(hIn, originalMode);
		else
			tcsetattr(0, TCSAFLUSH, &origTerm);
	}

	char readKey()
	{
		char c;
		version (Windows)
		{
			DWORD read;
			ReadConsoleA(hIn, &c, 1, &read, null);
		}
		else
		{
			auto res = read(0, &c, 1);
		}
		return c;
	}

	void clear()
	{
		write("\033[2J\033[H");
	}

	void moveTo(int row, int col)
	{
		writef("\033[%d;%dH", row, col);
	}

	void drawBox(int x, int y, int w, int h, string title = "")
	{
		moveTo(y, x);
		write("┌" ~ "─".replicate(w - 2) ~ "┐");
		foreach (i; 1 .. h - 1)
		{
			moveTo(y + i, x);
			write("│" ~ " ".replicate(w - 2) ~ "│");
		}
		moveTo(y + h - 1, x);
		write("└" ~ "─".replicate(w - 2) ~ "┘");
		if (title.length > 0 && title.length < w - 4)
		{
			moveTo(y, x + 2);
			write(
				" " ~ title ~ " ");
		}
	}

	int showMenu(string[] options, string title = "Select an option:")
	{
		int selected = 0;

		while (true)
		{
			clear();
			writeln(title);
			ArkTerm.printSeparator("─", title.length);

			foreach (i, option; options)
			{
				if (i == selected)
					writeln(ArkTerm.colorize("> " ~ option, Color.CYAN));
				else
					writeln("  " ~ option);
			}

			char key = readKey();
			switch (key)
			{
			case 'w', 'W':
				selected = selected > 0 ? selected - 1 : cast(int) options.length - 1;
				break;
			case 's', 'S':
				selected = (selected + 1) % cast(int) options.length;
				break;
			case '\r', '\n':
				return selected;
			case 'q', 'Q', 27:
				return -1;
			default:
				break;
			}
		}
	}
}

unittest
{
	class App
	{
		void run()
		{
			ArkTerm.log(LogLevel.INFO, "Application starting...");

			ArkTerm.printBreadcrumb([
				"Home",
				"Projects",
				"MyApp",
				"src"
			]);

			writeln;

			ArkTerm.printToast("Something", LogLevel.SUCCESS);

			writeln;

			ArkTerm.printAlert("System Information:");
			string[][] sysInfo = [
				["OS", "CPU", "Memory"],
				["Linux", "Intel i7", "16GB"],
				["Version", "Usage", "Available"],
				[
					"Ubuntu 22.04", "45%", "8.8GB"
				]
			];

			size_t[] colWidths = [15, 12, 10];

			ArkTerm.printColumns(sysInfo, colWidths);

			writeln;

			ArkTerm.printGauge(75, 0, 100, 25, "CPU Usage", Color.YELLOW);
			ArkTerm.printGauge(45, 0, 100, 25, "Memory", Color.GREEN);
			ArkTerm.printGauge(90, 0, 100, 25, "Disk", Color.RED);

			writeln;

			double[] cpuData = [
				23, 45, 67, 43, 89, 76, 54, 32, 67, 78, 45, 23, 56, 78, 90
			];

			ArkTerm.printSparkline(cpuData, 30, "CPU Trend");

			writeln;

			ArkTerm.printAlert("Some message", LogLevel.SUCCESS);
			ArkTerm.printKeyValue("Version", "1.0.0");
			ArkTerm.printKeyValue("Author", "Acme");
			ArkTerm.printKeyValue("Build", "Debug");

			writeln;

			write("Loading stuff: ");

			foreach (i; 0 .. 301)
			{
				ArkTerm.printProgress(i / 200.0, 10, "", Color.GREEN);
				Thread.sleep(100.nsecs);
			}

			writeln;

			ArkTerm.printStatus("Core module", true, "loaded in 245ms");
			ArkTerm.printStatus("Network module", true, "connected");
			ArkTerm.printStatus("Database module", false, "connection failed");

			writeln;

			string[] headers = [
				"Name",
				"Status",
				"CPU",
				"Memory"
			];
			string[][] data = [
				[
					"WebServer",
					"Running",
					"12%",
					"256MB"
				],
				[
					"Database",
					"Stopped",
					"0%",
					"0MB"
				],
				[
					"Cache",
					"Running",
					"3%",
					"128MB"
				]
			];

			ArkTerm.printAlert("System Status:");
			ArkTerm.printTable(headers, data);
			ArkTerm.printTextBox(
				"This is a multi-line text box with automatic word wrapping. " ~
					"It can contain multiple paragraphs and will probably properly format the content " ~
					"within the specified width constraints.\n\n", 50, BorderStyle
					.ROUNDED, Color.BLUE, "Information"
			);

			writeln;

			string sampleCode = `void main() {
    import std.stdio;
    writeln("Hello, World");
    
    foreach(i; 0..5) {
        writeln("Count: ", i);
    }
}`;
			ArkTerm.printCodeBlock(sampleCode, "D");

			writeln;

			string[string] dashboardPanels = [
				"Server Status": "Online\nUptime: 24h 15m\nLoad: 0.45",
				"Database": "Connected\nQueries/sec: 1,247\nConnections: 12/100",
				"Cache": "Redis Online\nHit Rate: 94.2%\nMemory: 2.1GB",
				"Network": "Bandwidth: 45 Mbps\nLatency: 12ms\nPacket Loss: 0%"
			];

			ArkTerm.printAlert("System Dashboard:");
			ArkTerm.printDashboard(dashboardPanels, 2);
			ArkTerm.printAlert("Project Structure:");

			string[string] projectTree = [
				"src/main.d": "Main application file",
				"src/ui/terminal.d": "Terminal UI components",
				"src/core/app.d": "Core application logic",
				"tests/unit.d": "Unit tests",
				"docs/README.md": "Documentation"
			];

			string tree = ArkTerm.printTree(
				projectTree, onlyReturn:
				true
			);

			ArkTerm.printAlert(tree);
			writeln;
			ArkTerm.log(LogLevel.SUCCESS, "Demo completed successfully");
		}
	}

	new App().run;
}
