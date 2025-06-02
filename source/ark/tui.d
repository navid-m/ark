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

final class Terminal
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
		{
			SetConsoleMode(hIn, originalMode);
		}
		else
		{
			tcsetattr(0, TCSAFLUSH, &origTerm);
		}
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
	Terminal term;

	this()
	{
		term = new Terminal();
	}

	void run()
	{
		version (Windows)
			SetConsoleOutputCP(65_001);

		bool running = true;

		while (running)
		{
			render();
			auto key = term.readKey();
			if (key == 'q')
			{
				running = false;
			}
		}
	}

	void render()
	{
		term.clear();
		term.drawBox(5, 3, 30, 10, "Cross-Platform TUI");
		term.moveTo(6, 7);
		write("Press 'q' to quit.");
		stdout.flush();
	}
}

unittest
{
	auto app = new App();
	app.run();
}
