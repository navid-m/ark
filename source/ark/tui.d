module ark.tui;

import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.string;
import std.datetime;
import std.format;

version (Windows)
{
	import core.sys.windows.windows;
	import core.sys.windows.wincon;
}
else
{
	import core.sys.posix.unistd;
	import core.sys.posix.termios;
}

enum Color : string
{
	RESET = "\033[0m",
	BLACK = "\033[30m",
	RED = "\033[31m",
	GREEN = "\033[32m",
	YELLOW = "\033[33m",
	BLUE = "\033[34m",
	MAGENTA = "\033[35m",
	CYAN = "\033[36m",
	WHITE = "\033[37m",
	BRIGHT_BLACK = "\033[90m",
	BRIGHT_RED = "\033[91m",
	BRIGHT_GREEN = "\033[92m",
	BRIGHT_YELLOW = "\033[93m",
	BRIGHT_BLUE = "\033[94m",
	BRIGHT_MAGENTA = "\033[95m",
	BRIGHT_CYAN = "\033[96m",
	BRIGHT_WHITE = "\033[97m"
}

enum Style : string
{
	RESET = "\033[0m",
	BOLD = "\033[1m",
	DIM = "\033[2m",
	ITALIC = "\033[3m",
	UNDERLINE = "\033[4m",
	BLINK = "\033[5m",
	REVERSE = "\033[7m",
	STRIKETHROUGH = "\033[9m"
}

enum LogLevel
{
	INFO,
	SUCCESS,
	WARNING,
	ERROR,
	DEBUG
}

final class TerminalOut
{
	private static immutable defaultLineLength = 50;
	private static bool colorEnabled = true;
	private static size_t spinnerIndex = 0;
	private static immutable string[] spinnerChars = [
		"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"
	];

	static this()
	{
		version (Windows)
			SetConsoleOutputCP(65_001);
	}

	static void enableColor(bool enable = true)
	{
		colorEnabled = enable;
	}

	private static string colorize(string text, Color color) => colorEnabled ? (
		color ~ text ~ Color.RESET
	) : text;

	private static string stylize(string text, Style style) => colorEnabled ? (
		style ~ text ~ Style.RESET
	) : text;

	static void printSeparator(string sep = "─", size_t length = defaultLineLength, Color color = Color
			.RESET)
	{
		writeln(colorize(sep.replicate(length), color));
	}

	static void writeBlock(string text, string sep = "─", size_t length = defaultLineLength, Color color = Color
			.RESET)
	{
		printSeparator(sep, length, color);
		write(text ~ "\n");
		printSeparator(sep, length, color);
		write("\n");
	}

	static void printProgress(double progress, size_t width = 40, string prefix = "", Color barColor = Color
			.GREEN)
	{
		progress = progress < 0 ? 0 : (progress > 1 ? 1 : progress);

		auto filled = cast(size_t)(progress * width);
		auto empty = width - filled;
		auto bar = "█".replicate(filled) ~ "░".replicate(empty);
		auto percentage = format("%.1f%%", progress * 100);

		write("\r" ~ prefix);
		write(colorize(bar, barColor));
		write(" " ~ percentage);
		stdout.flush();
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

	static void printSpinner(string message = "Loading...")
	{
		write("\r" ~ colorize(spinnerChars[spinnerIndex], Color.CYAN) ~ " " ~ message);
		stdout.flush();
		spinnerIndex = (spinnerIndex + 1) % spinnerChars.length;
	}

	static void clearSpinner()
	{
		write("\r" ~ " ".replicate(80) ~ "\r");
	}

	static void printStatus(string message, bool success, string details = "")
	{
		string symbol = success ? "✓" : "✗";
		Color color = success ? Color.GREEN : Color.RED;
		write(colorize(symbol, color) ~ " " ~ message);
		if (details.length > 0)
		{
			write(colorize(" (" ~ details ~ ")", Color.BRIGHT_BLACK));
		}
		writeln();
	}

	static void printIndented(string text, size_t level = 1, string indent = "  ")
	{
		writeln(indent.replicate(level) ~ text);
	}

	static void printTable(string[] headers, string[][] rows, size_t minColWidth = 10)
	{
		if (headers.length == 0)
			return;

		auto colWidths = new size_t[headers.length];
		foreach (i, header; headers)
		{
			colWidths[i] = max(header.length, minColWidth);
		}

		foreach (row; rows)
		{
			foreach (i, cell; row)
			{
				if (i < colWidths.length)
					colWidths[i] = max(colWidths[i], cell.length);
			}
		}

		write("┌");
		foreach (i, width; colWidths)
		{
			write("─".replicate(width + 2));
			write(i == cast(int) colWidths.length - 1 ? "┐" : "┬");
		}

		writeln();
		write("│");

		foreach (i, header; headers)
		{
			writef(" %-*s │", colWidths[i], header);
		}

		writeln();
		write("├");

		foreach (i, width; colWidths)
		{
			write("─".replicate(width + 2));
			write(i == cast(int) colWidths.length - 1 ? "┤" : "┼");
		}

		writeln();

		foreach (row; rows)
		{
			write("│");
			foreach (i; 0 .. colWidths.length)
			{
				string cell = i < row.length ? row[i] : "";
				writef(" %-*s │", colWidths[i], cell);
			}
			writeln();
		}

		write("└");

		foreach (i, width; colWidths)
		{
			write("─".replicate(width + 2));
			write(i == cast(int) colWidths.length - 1 ? "┘" : "┴");
		}

		writeln();
	}

	static void printAlert(string message, LogLevel level = LogLevel.INFO, size_t width = 60)
	{
		Color borderColor;
		string icon;

		final switch (level)
		{
		case LogLevel.INFO:
			borderColor = Color.BLUE;
			icon = "ⓘ";
			break;
		case LogLevel.SUCCESS:
			borderColor = Color.GREEN;
			icon = "✓";
			break;
		case LogLevel.WARNING:
			borderColor = Color.YELLOW;
			icon = "⚠";
			break;
		case LogLevel.ERROR:
			borderColor = Color.RED;
			icon = "✗";
			break;
		case LogLevel.DEBUG:
			borderColor = Color.MAGENTA;
			icon = "🐛";
			break;
		}

		auto lines = message.split('\n');
		auto maxLen = lines.map!(l => l.length).maxElement;
		auto boxWidth = max(width, maxLen + 6);

		writeln(colorize("┌" ~ "─".replicate(boxWidth - 2) ~ "┐", borderColor));
		writeln(colorize("│", borderColor) ~ " " ~ colorize(icon, borderColor) ~ " " ~
				format("%-*s", boxWidth - 6, lines[0]) ~ " " ~ colorize("│", borderColor)
		);

		foreach (line; lines[1 .. $])
		{
			writeln(colorize("│", borderColor) ~ "   " ~
					format("%-*s", boxWidth - 6, line) ~ " " ~ colorize("│", borderColor));
		}

		writeln(colorize("└" ~ "─".replicate(boxWidth - 2) ~ "┘", borderColor));
	}

	static void printKeyValue(string key, string value, size_t keyWidth = 20, Color keyColor = Color
			.CYAN)
	{
		writef(
			"%s: %s\n",
			colorize(format("%-*s", keyWidth, key), keyColor),
			value
		);
	}

	static void clear()
	{
		version (Windows)
		{
			for (int i = 0; i < 100; i++)
			{
				writeln("\n");
			}
			HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
			CONSOLE_SCREEN_BUFFER_INFO csbi;

			if (!GetConsoleScreenBufferInfo(hConsole, &csbi))
			{
				writeln("Failed to get console buffer info.");
				return;
			}

			SMALL_RECT scrollRect = csbi.srWindow;
			COORD destOrigin = COORD(0, cast(short)(csbi.srWindow.Top - 100));
			CHAR_INFO fill;
			fill.Char.AsciiChar = ' ';
			fill.Attributes = csbi.wAttributes;

			ScrollConsoleScreenBufferA(
				hConsole,
				&scrollRect,
				null,
				destOrigin,
				&fill
			);

			COORD topLeft = COORD(0, csbi.srWindow.Top);
			SetConsoleCursorPosition(hConsole, topLeft);
		}
		version (Posix)
		{
			write("\033[2J\033[H");
		}
	}
}

final class TUI
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
			SetConsoleOutputCP(65_001);

		enableRawMode();
		write("\033[?25l");
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
			raw.c_lflag &= ~(ICANON | ECHO);
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
			write(" " ~ title ~ " ");
		}
	}

	int showMenu(string[] options, string title = "Select an option:")
	{
		int selected = 0;

		while (true)
		{
			clear();
			writeln(title);
			TerminalOut.printSeparator("─", title.length);

			foreach (i, option; options)
			{
				if (i == selected)
					writeln(TerminalOut.colorize("> " ~ option, Color.CYAN));
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

class App
{
	void run()
	{
		TerminalOut.log(LogLevel.INFO, "Application starting...");
		TerminalOut.printAlert("Some message", LogLevel.SUCCESS);
		TerminalOut.printKeyValue("Version", "1.0.0");
		TerminalOut.printKeyValue("Author", "Your Name");
		TerminalOut.printKeyValue("Build", "Debug");

		writeln();
		write("Loading stuff: ");
		foreach (i; 0 .. 301)
		{
			TerminalOut.printProgress(i / 200.0, 100, "", Color.GREEN);
			import core.thread : Thread;
			import core.time : msecs;

			Thread.sleep(5.msecs);
		}

		writeln();

		TerminalOut.printStatus("Core module", true, "loaded in 245ms");
		TerminalOut.printStatus("Network module", true, "connected");
		TerminalOut.printStatus("Database module", false, "connection failed");

		writeln();

		string[] headers = ["Name", "Status", "CPU", "Memory"];
		string[][] data = [
			["WebServer", "Running", "12%", "256MB"],
			["Database", "Stopped", "0%", "0MB"],
			["Cache", "Running", "3%", "128MB"]
		];

		writeln("System Status:");

		TerminalOut.printTable(headers, data);
		TerminalOut.log(LogLevel.SUCCESS, "Demo completed successfully");

		readln();
	}
}

unittest
{
	auto app = new App();
	app.run();
}
