module ark.tui;

import std.array;
import std.conv;
import std.stdio;

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

final class TerminalOut
{
	private static immutable defaultLineLength = 50;

	static this()
	{
		version (Windows)
			SetConsoleOutputCP(65_001);
	}

	static void printSeparator(string sep = "─", size_t length = defaultLineLength)
	{
		writeln(sep.replicate(length));
	}

	static void writeBlock(string text, string sep = "─", size_t length = defaultLineLength)
	{
		printSeparator(sep, length);
		write(text ~ "\n");
		printSeparator();
		write("\n");
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
}

class App
{
	void run()
	{
		TerminalOut.writeBlock("ya did it");
		readln;
		TerminalOut.writeBlock("ya did it");
		readln;
	}
}

unittest
{
	auto app = new App();
	app.run();
}
