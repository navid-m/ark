module ark.tui;

import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.string;
import std.datetime;
import std.format;
import std.math;
import core.thread;

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

enum BorderStyle
{
	SINGLE,
	DOUBLE,
	ROUNDED,
	THICK,
	ASCII
}

struct BorderChars
{
	string topLeft, topRight, bottomLeft, bottomRight;
	string horizontal, vertical;
	string topJoin, bottomJoin, leftJoin, rightJoin, cross;
}

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

	static void printColumns(string[][] columns, size_t[] widths = [], string separator = " │ ")
	{
		if (columns.length == 0)
			return;

		auto maxRows = columns.map!(col => col.length).maxElement;

		if (widths.length == 0)
		{
			widths = new size_t[columns.length];
			foreach (i, col; columns)
			{
				widths[i] = col.length > 0 ? col.map!(s => s.length).maxElement : 0;
			}
		}

		foreach (row; 0 .. maxRows)
		{
			foreach (col; 0 .. columns.length)
			{
				string content = row < columns[col].length ? columns[col][row] : "";
				if (col >= widths.length)
					continue;
				writef("%-*s", widths[col], content);
				if (col < cast(int) columns.length - 1)
					write(separator);
			}
			writeln();
		}
	}

	static string printTree(
		string[string] tree,
		string root = "",
		size_t level = 0,
		bool[] isLast = [],
		bool onlyReturn = false
	)
	{
		string result = "";

		if (level == 0)
		{
			result ~= "root\n";
			if (!onlyReturn)
			{
				write("root\n");
			}
		}

		string[] paths;

		foreach (path, value; tree)
		{
			paths ~= path;
		}

		paths.sort();

		string[string] children;
		string[] immediateFiles;

		foreach (path; paths)
		{
			string relativePath = path;
			if (root.length > 0)
			{
				if (!path.startsWith(root ~ "/"))
					continue;
				relativePath = path[root.length + 1 .. $];
			}

			auto slashIndex = relativePath.indexOf('/');
			if (slashIndex == -1)
			{
				immediateFiles ~= relativePath;
			}
			else
			{
				string dirName = relativePath[0 .. slashIndex];
				if (dirName !in children)
				{
					children[dirName] = "";
				}
			}
		}

		foreach (i, fileName; immediateFiles)
		{
			string indent = "";
			foreach (j; 0 .. level)
			{
				if (j < isLast.length && isLast[j])
					indent ~= "    ";
				else
					indent ~= "│   ";
			}

			bool isLastItem = (i == cast(int) immediateFiles.length - 1) && (children.length == 0);
			string prefix = isLastItem ? "└── " : "├── ";
			string fullPath = root.length > 0 ? root ~ "/" ~ fileName : fileName;
			string line = indent ~ prefix ~ fileName ~ " = " ~ tree[fullPath] ~ "\n";
			result ~= line;

			if (!onlyReturn)
				write(line);
		}

		auto dirNames = children.keys.array.sort();
		int i = 0;

		foreach (dirName; dirNames)
		{
			string indent = "";
			foreach (j; 0 .. level)
			{
				if (j < isLast.length && isLast[j])
					indent ~= "    ";
				else
					indent ~= "│   ";
			}

			bool isLastDir = (i == cast(int) dirNames.length - 1);
			string prefix = isLastDir ? "└── " : "├── ";
			string line = indent ~ prefix ~ dirName ~ "/\n";
			result ~= line;

			if (!onlyReturn)
				write(line);

			string newRoot = root.length > 0 ? root ~ "/" ~ dirName : dirName;
			auto newIsLast = isLast ~ isLastDir;
			string subResult = printTree(tree, newRoot, level + 1, newIsLast, onlyReturn);
			result ~= subResult;
			i++;
		}

		return result;
	}

	static void printGauge(double value, double min = 0, double max = 100, size_t width = 30,
		string label = "", Color color = Color.GREEN)
	{
		value = value < min ? min : (value > max ? max : value);
		double percentage = (
			value - min) / (max - min);
		auto filled = cast(size_t)(percentage * width);
		auto empty = width - filled;
		string bar = "█".replicate(
			filled) ~ "░".replicate(empty);
		string display = format("%s [%s] %.1f/%.1f", label, colorize(
				bar, color), value, max);
		writeln(display);
	}

	static void printTextBox(string text, size_t width = 60, BorderStyle style = BorderStyle.SINGLE,
		Color borderColor = Color.RESET, string title = "")
	{
		auto borders = borderStyles[style];
		auto lines = text.split('\n');
		auto maxWidth = width - 3;
		string[] wrappedLines;
		foreach (line; lines)
		{
			if (line.length <= maxWidth)
			{
				wrappedLines ~= line;
			}
			else
			{
				auto words = line.split(' ');
				string currentLine = "";
				foreach (word; words)
				{
					if (currentLine.length + word.length + 1 <= maxWidth)
					{
						currentLine ~= (currentLine.length > 0 ? " " : "") ~ word;
					}
					else
					{
						if (currentLine.length > 0)
							wrappedLines ~= currentLine;
						currentLine = word;
					}
				}
				if (currentLine.length > 0)
					wrappedLines ~= currentLine;
			}
		}

		string topLine = borders.topLeft ~ borders.horizontal.replicate(
			width - 2) ~ borders.topRight;
		if (title.length > 0 && title.length < width - 4)
		{
			auto titlePos = (width - title.length - 2) / 2;
			topLine = borders.topLeft ~ borders.horizontal.replicate(
				titlePos) ~
				" " ~ title ~ " " ~
				borders.horizontal.replicate(
					width - titlePos - title.length - 3) ~ borders.topRight;
		}
		writeln(colorize(topLine, borderColor));
		foreach (line; wrappedLines)
		{
			writeln(colorize(borders.vertical, borderColor) ~
					format(" %-*s ", maxWidth, line) ~
					colorize(borders.vertical, borderColor));
		}

		writeln(colorize(borders.bottomLeft ~ borders.horizontal.replicate(
				width - 2) ~ borders.bottomRight, borderColor));
	}

	static void printBanner(string text, string font = "block")
	{
		string[char] blockChars = [
			'A': "██████\r\n██  ██\r\n██████\r\n██  ██\r\n██  ██",
			'B': "██████\r\n██  ██\r\n██████\r\n██  ██\r\n██████",
			'C': "██████\r\n██    \r\n██    \r\n██    \r\n██████",
		];
		foreach (c; text.toUpper())
		{
			if (c in blockChars)
			{
				writeln(blockChars[c]);
				writeln();
			}
			else if (c == ' ')
			{
				writeln("      ");
			}
		}
	}

	static void printDashboard(string[string] panels, size_t cols = 2)
	{
		auto keys = panels.keys.array;
		auto rows = (
			keys.length + cols - 1) / cols;
		foreach (row; 0 .. rows)
		{
			foreach (col; 0 .. cols)
			{
				auto idx = row * cols + col;
				if (idx < keys.length)
				{
					auto key = keys[idx];
					printTextBox(panels[key], 35, BorderStyle
							.SINGLE, Color.CYAN, key);
				}
			}
			writeln();
		}
	}

	static void printSparkline(double[] data, size_t width = 50, string label = "")
	{
		if (data.length == 0)
			return;
		auto minVal = data.minElement;
		auto maxVal = data.maxElement;
		auto range = maxVal - minVal;
		if (range == 0)
			range = 1;

		string[] chars = [
			"▁", "▂", "▃", "▄",
			"▅", "▆", "▇", "█"
		];
		string sparkline = "";
		foreach (val; data)
		{
			auto normalized = (val - minVal) / range;
			auto charIndex = cast(size_t)(
				normalized * (
					cast(int) chars.length - 1));
			sparkline ~= chars[charIndex];
		}

		if (label.length > 0)
			writef("%s: ", label);
		writef("%s (%.2f - %.2f)\n", colorize(sparkline, Color
				.GREEN), minVal, maxVal);
	}

	static void printCodeBlock(string code, string language = "", Color commentColor = Color
			.BRIGHT_BLACK)
	{
		printTextBox("", 80, BorderStyle.SINGLE, Color.BRIGHT_BLACK, language
				.length > 0 ? language.toUpper() : "CODE");

		foreach (line; code.split('\n'))
		{
			string processedLine = line;

			if (line.strip().startsWith("//") || line.strip()
				.startsWith("#"))
			{
				processedLine = colorize(line, commentColor);
			}

			writeln("  " ~ processedLine);
		}

		writeln(colorize("└" ~ "─".replicate(78) ~ "┘", Color
				.BRIGHT_BLACK));
	}

	static void printToast(string message, LogLevel level = LogLevel.INFO, size_t duration = 3)
	{
		Color bgColor = Color.BLUE;
		string icon = "ℹ";

		final switch (level)
		{
		case LogLevel.INFO:
			bgColor = Color.BLUE;
			icon = "ℹ";
			break;
		case LogLevel.SUCCESS:
			bgColor = Color.GREEN;
			icon = "✓";
			break;
		case LogLevel.WARNING:
			bgColor = Color.YELLOW;
			icon = "⚠";
			break;
		case LogLevel.ERROR:
			bgColor = Color.RED;
			icon = "✗";
			break;
		case LogLevel.DEBUG:
			bgColor = Color.MAGENTA;
			icon = "🐛";
			break;
		}

		auto timestamp = Clock.currTime.toString()[11 .. 19];
		string toast = format(" %s %s (%s) ", icon, message, timestamp);

		writeln(colorize("╭" ~ "─".replicate(toast.length) ~ "╮", bgColor));
		writeln(colorize("│" ~ toast ~ "  │", bgColor));
		writeln(colorize("╰" ~ "─".replicate(toast.length) ~ "╯", bgColor));
	}

	static void printLoadingDots(string message = "Loading", size_t dots = 3)
	{
		static size_t dotCount = 0;
		write("\r" ~ message ~ " " ~ ".".replicate(
				(dotCount % (dots + 1))) ~
				" ".replicate(
					dots - (dotCount % (dots + 1))) ~ "   ");
		stdout.flush();
		dotCount++;
	}

	static void printBreadcrumb(string[] path, string separator = " > ")
	{
		foreach (i, item; path)
		{
			if (i == cast(int) path.length - 1)
				write(colorize(item, Color.BRIGHT_WHITE));
			else
				write(colorize(item, Color
						.BRIGHT_BLACK));

			if (
				i < cast(int) path.length - 1)
				write(
					colorize(separator, Color
						.BRIGHT_BLACK));
		}
		writeln();
	}

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

	static void printProgress(
		double progress,
		size_t width = 40,
		string prefix = "",
		Color barColor = Color.GREEN
	)
	{
		progress = progress < 0 ? 0 : (progress > 1 ? 1 : progress);
		auto filled = cast(
			size_t)(progress * width);
		auto empty = width - filled;
		auto bar = "█".replicate(
			filled) ~ "░".replicate(
			empty);
		auto percentage = format("%.1f%%", progress * 100);

		write("\r" ~ prefix);
		write(colorize(bar, barColor));
		write(" " ~ percentage);
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

	static void printSpinner(
		string message = "Loading...")
	{
		write(
			"\r" ~ colorize(spinnerChars[spinnerIndex], Color
				.CYAN) ~ " " ~ message);
		stdout.flush();
		spinnerIndex = (
			spinnerIndex + 1) % spinnerChars
			.length;
	}

	static void clearSpinner()
	{
		write(
			"\r" ~ " ".replicate(
				80) ~ "\r");
	}

	static void printStatus(string message, bool success, string details = "")
	{
		string symbol = success ? "✓" : "✗";
		Color color = success ? Color.GREEN : Color.RED;
		write(colorize(symbol, color) ~ " " ~ message);
		if (details.length > 0)
		{
			write(colorize(" (" ~ details ~ ")", Color
					.BRIGHT_BLACK));
		}
		writeln();
	}

	static void printIndented(string text, size_t level = 1, string indent = "  ")
	{
		writeln(
			indent.replicate(
				level) ~ text);
	}

	static void printTable(string[] headers, string[][] rows, size_t minColWidth = 10)
	{
		if (headers.length == 0)
			return;

		auto colWidths = new size_t[headers
				.length];
		foreach (i, header; headers)
		{
			colWidths[i] = max(header.length, minColWidth);
		}

		foreach (row; rows)
		{
			foreach (i, cell; row)
			{
				if (
					i < colWidths
					.length)
					colWidths[i] = max(colWidths[i], cell
							.length);
			}
		}

		write("┌");
		foreach (i, width; colWidths)
		{
			write(
				"─".replicate(
					width + 2));
			write(i == cast(
					int) colWidths.length - 1 ? "┐" : "┬");
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
			write(
				"─".replicate(
					width + 2));
			write(i == cast(
					int) colWidths.length - 1 ? "┤" : "┼");
		}

		writeln();

		foreach (row; rows)
		{
			write("│");
			foreach (i; 0 .. colWidths
				.length)
			{
				string cell = i < row.length ? row[i] : "";
				writef(" %-*s │", colWidths[i], cell);
			}
			writeln();
		}

		write("└");

		foreach (i, width; colWidths)
		{
			write(
				"─".replicate(
					width + 2));
			write(i == cast(
					int) colWidths.length - 1 ? "┘" : "┴");
		}

		writeln();
	}

	static void printAlert(string message, LogLevel level = LogLevel
			.INFO, size_t width = 60)
	{
		Color borderColor;
		string icon;

		final switch (level)
		{
		case LogLevel.INFO:
			borderColor = Color
				.BLUE;
			icon = "ⓘ";
			break;
		case LogLevel.SUCCESS:
			borderColor = Color
				.GREEN;
			icon = "✓";
			break;
		case LogLevel.WARNING:
			borderColor = Color
				.YELLOW;
			icon = "⚠";
			break;
		case LogLevel.ERROR:
			borderColor = Color
				.RED;
			icon = "✗";
			break;
		case LogLevel.DEBUG:
			borderColor = Color
				.MAGENTA;
			icon = "🐛";
			break;
		}

		auto lines = message.split(
			'\n');
		auto maxLen = lines.map!(l => l.length)
			.maxElement;
		auto boxWidth = max(width, maxLen + 6);

		writeln(colorize("┌" ~ "─".replicate(
				boxWidth - 2) ~ "┐", borderColor));
		writeln(colorize("│", borderColor) ~ " " ~ colorize(icon, borderColor) ~ " " ~
				format("%-*s", boxWidth - 6, lines[0]) ~ " " ~ colorize(
					"│", borderColor)
		);
		foreach (line; lines[1 .. $])
		{
			writeln(colorize("│", borderColor) ~ "   " ~
					format("%-*s", boxWidth - 6, line) ~ " " ~ colorize("│", borderColor));
		}

		writeln(colorize("└" ~ "─".replicate(
				boxWidth - 2) ~ "┘", borderColor));
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
			HANDLE hConsole = GetStdHandle(
				STD_OUTPUT_HANDLE);
			CONSOLE_SCREEN_BUFFER_INFO csbi;

			if (!GetConsoleScreenBufferInfo(
					hConsole, &csbi))
			{
				writeln("Failed to get console buffer info.");
				return;
			}

			SMALL_RECT scrollRect = csbi
				.srWindow;
			COORD destOrigin = COORD(0, cast(
					short)(
					csbi.srWindow.Top - 100));
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
			write(
				"\033[2J\033[H");
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
		write(
			"\033[0m\033[2J\033[H");
	}

	void enableRawMode()
	{
		version (Windows)
		{
			hIn = GetStdHandle(
				STD_INPUT_HANDLE);
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
		write(
			"┌" ~ "─".replicate(
				w - 2) ~ "┐");
		foreach (i; 1 .. h - 1)
		{
			moveTo(y + i, x);
			write("│" ~ " ".replicate(
					w - 2) ~ "│");
		}
		moveTo(y + h - 1, x);
		write(
			"└" ~ "─".replicate(
				w - 2) ~ "┘");
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
			writeln(
				title);
			ArkTerm.printSeparator("─", title
					.length);

			foreach (i, option; options)
			{
				if (
					i == selected)
					writeln(
						ArkTerm.colorize(
							"> " ~ option, Color
							.CYAN));
				else
					writeln(
						"  " ~ option);
			}

			char key = readKey();
			switch (key)
			{
			case 'w', 'W':
				selected = selected > 0 ? selected - 1 : cast(
					int) options.length - 1;
				break;
			case 's', 'S':
				selected = (
					selected + 1) % cast(
					int) options
					.length;
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
		ArkTerm.log(LogLevel.INFO, "Application starting...");

		ArkTerm.printBreadcrumb([
			"Home",
			"Projects",
			"MyApp",
			"src"
		]);
		writeln();

		ArkTerm.printToast("Something", LogLevel
				.SUCCESS);
		writeln();

		ArkTerm.printAlert(
			"System Information:");
		string[][] sysInfo = [
			[
				"OS",
				"CPU",
				"Memory"
			],
			[
				"Linux",
				"Intel i7",
				"16GB"
			],
			[
				"Version",
				"Usage",
				"Available"
			],
			[
				"Ubuntu 22.04",
				"45%",
				"8.8GB"
			]
		];
		size_t[] colWidths = [
			15,
			12,
			10
		];
		ArkTerm.printColumns(sysInfo, colWidths);
		writeln();

		ArkTerm.printGauge(75, 0, 100, 25, "CPU Usage", Color
				.YELLOW);
		ArkTerm.printGauge(45, 0, 100, 25, "Memory", Color
				.GREEN);
		ArkTerm.printGauge(90, 0, 100, 25, "Disk", Color
				.RED);
		writeln();

		double[] cpuData = [
			23,
			45,
			67,
			43,
			89,
			76,
			54,
			32,
			67,
			78,
			45,
			23,
			56,
			78,
			90
		];
		ArkTerm.printSparkline(cpuData, 30, "CPU Trend");
		writeln();

		ArkTerm.printAlert("Some message", LogLevel
				.SUCCESS);
		ArkTerm.printKeyValue("Version", "1.0.0");
		ArkTerm.printKeyValue("Author", "Acme");
		ArkTerm.printKeyValue("Build", "Debug");

		writeln();
		write(
			"Loading stuff: ");
		foreach (i; 0 .. 301)
		{
			ArkTerm.printProgress(i / 200.0, 10, "", Color
					.GREEN);

			Thread.sleep(
				100
					.nsecs);
		}

		writeln();

		ArkTerm.printStatus("Core module", true, "loaded in 245ms");
		ArkTerm.printStatus("Network module", true, "connected");
		ArkTerm.printStatus("Database module", false, "connection failed");

		writeln();

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
		ArkTerm.printAlert(
			"System Status:");
		ArkTerm.printTable(headers, data);

		ArkTerm.printTextBox(
			"This is a multi-line text box with automatic word wrapping. " ~
				"It can contain multiple paragraphs and will probably properly format the content " ~
				"within the specified width constraints.\n\n", 50, BorderStyle
				.ROUNDED, Color.BLUE, "Information"
		);
		writeln();

		string sampleCode = `void main() {
    import std.stdio;
    writeln("Hello, World");
    
    foreach(i; 0..5) {
        writeln("Count: ", i);
    }
}`;
		ArkTerm.printCodeBlock(sampleCode, "D");
		writeln();
		string[string] dashboardPanels = [
			"Server Status": "Online\nUptime: 24h 15m\nLoad: 0.45",
			"Database": "Connected\nQueries/sec: 1,247\nConnections: 12/100",
			"Cache": "Redis Online\nHit Rate: 94.2%\nMemory: 2.1GB",
			"Network": "Bandwidth: 45 Mbps\nLatency: 12ms\nPacket Loss: 0%"
		];
		ArkTerm.printAlert(
			"System Dashboard:");
		ArkTerm.printDashboard(dashboardPanels, 2);
		ArkTerm.printAlert(
			"Project Structure:");

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

unittest
{
	auto app = new App();
	app.run();
}
