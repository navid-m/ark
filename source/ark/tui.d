module ark.tui;

import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.range;
import std.array;

version (Windows)
{
	import core.sys.windows.windows;
	import core.sys.windows.wincon;
}
else
{
	import core.sys.posix.termios;
	import core.sys.posix.unistd;
	import core.sys.posix.sys.ioctl;
}

// Color definitions
enum Color : ubyte
{
	Black = 0,
	Red = 1,
	Green = 2,
	Yellow = 3,
	Blue = 4,
	Magenta = 5,
	Cyan = 6,
	White = 7,
	BrightBlack = 8,
	BrightRed = 9,
	BrightGreen = 10,
	BrightYellow = 11,
	BrightBlue = 12,
	BrightMagenta = 13,
	BrightCyan = 14,
	BrightWhite = 15
}

// Key codes
enum Key : int
{
	Unknown = -1,
	Enter = 13,
	Escape = 27,
	Backspace = 8,
	Tab = 9,
	Space = 32,
	Delete = 127,
	Up = 1000,
	Down,
	Left,
	Right,
	Home,
	End,
	PageUp,
	PageDown,
	F1,
	F2,
	F3,
	F4,
	F5,
	F6,
	F7,
	F8,
	F9,
	F10,
	F11,
	F12
}

// Event types
enum EventType
{
	Key,
	Mouse,
	Resize
}

struct Event
{
	EventType type;
	union
	{
		struct
		{
			Key key;
			char ch;
			bool ctrl, alt, shift;
		}

		struct
		{
			int mouseX, mouseY;
			bool leftButton, rightButton;
		}

		struct
		{
			int newWidth, newHeight;
		}
	}
}

// Terminal interface
class Terminal
{
	private int width_, height_;
	private char[][] buffer;
	private Color[][] fgColors, bgColors;

	version (Windows)
	{
		private HANDLE hConsole;
		private CONSOLE_SCREEN_BUFFER_INFO csbi;
		private HANDLE hInput;
		private DWORD oldMode;
		private INPUT_RECORD[32] inputBuffer;
	}
	else
	{
		private termios oldTermios;
	}

	this()
	{
		initTerminal();
		updateSize();
		buffer = new char[][](height_, width_);
		fgColors = new Color[][](height_, width_);
		bgColors = new Color[][](height_, width_);
		clear();
	}

	~this()
	{
		restoreTerminal();
	}

	private void initTerminal()
	{
		version (Windows)
		{
			hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
			hInput = GetStdHandle(STD_INPUT_HANDLE);
			GetConsoleMode(hInput, &oldMode);
			SetConsoleMode(hInput, ENABLE_WINDOW_INPUT | ENABLE_MOUSE_INPUT | ENABLE_EXTENDED_FLAGS);
		}
		else
		{
			tcgetattr(STDIN_FILENO, &oldTermios);
			termios newTermios = oldTermios;
			newTermios.c_lflag &= ~(ICANON | ECHO);
			tcsetattr(STDIN_FILENO, TCSANOW, &newTermios);
			write("\033[?1049h"); // Alternative screen buffer
			write("\033[?25l"); // Hide cursor
		}
	}

	private void restoreTerminal()
	{
		version (Windows)
		{
			SetConsoleMode(hInput, oldMode);
		}
		else
		{
			write("\033[?25h"); // Show cursor
			write("\033[?1049l"); // Normal screen buffer
			tcsetattr(STDIN_FILENO, TCSANOW, &oldTermios);
		}
	}

	private void updateSize()
	{
		version (Windows)
		{
			GetConsoleScreenBufferInfo(hConsole, &csbi);
			width_ = csbi.srWindow.Right - csbi.srWindow.Left + 1;
			height_ = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
		}
		else
		{
			winsize ws;
			ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws);
			width_ = ws.ws_col;
			height_ = ws.ws_row;
		}
	}

	@property int width()
	{
		return width_;
	}

	@property int height()
	{
		return height_;
	}

	void clear(Color bg = Color.Black)
	{
		foreach (y; 0 .. height_)
		{
			foreach (x; 0 .. width_)
			{
				buffer[y][x] = ' ';
				fgColors[y][x] = Color.White;
				bgColors[y][x] = bg;
			}
		}
	}

	void setChar(int x, int y, char ch, Color fg = Color.White, Color bg = Color.Black)
	{
		if (x >= 0 && x < width_ && y >= 0 && y < height_)
		{
			buffer[y][x] = ch;
			fgColors[y][x] = fg;
			bgColors[y][x] = bg;
		}
	}

	void writeText(int x, int y, string text, Color fg = Color.White, Color bg = Color.Black)
	{
		foreach (i, ch; text)
		{
			setChar(x + cast(int) i, y, ch, fg, bg);
		}
	}

	void drawBox(int x, int y, int w, int h, Color fg = Color.White, Color bg = Color.Black)
	{
		// Draw corners
		setChar(x, y, '+', fg, bg);
		setChar(x + w - 1, y, '+', fg, bg);
		setChar(x, y + h - 1, '+', fg, bg);
		setChar(x + w - 1, y + h - 1, '+', fg, bg);

		// Draw horizontal lines
		foreach (i; x + 1 .. x + w - 1)
		{
			setChar(i, y, '-', fg, bg);
			setChar(i, y + h - 1, '-', fg, bg);
		}

		// Draw vertical lines
		foreach (i; y + 1 .. y + h - 1)
		{
			setChar(x, i, '|', fg, bg);
			setChar(x + w - 1, i, '|', fg, bg);
		}
	}

	void fillRect(int x, int y, int w, int h, char ch = ' ', Color fg = Color.White, Color bg = Color
			.Black)
	{
		foreach (py; y .. y + h)
		{
			foreach (px; x .. x + w)
			{
				setChar(px, py, ch, fg, bg);
			}
		}
	}

	void render()
	{
		version (Windows)
		{
			COORD coord = {0, 0};
			SetConsoleCursorPosition(hConsole, coord);

			foreach (y; 0 .. height_)
			{
				foreach (x; 0 .. width_)
				{
					WORD attr = cast(WORD)(fgColors[y][x] | (bgColors[y][x] << 4));
					SetConsoleTextAttribute(hConsole, attr);
					WriteConsoleA(hConsole, &buffer[y][x], 1, null, null);
				}
			}
		}
		else
		{
			write("\033[H"); // Move cursor to home

			Color lastFg = Color.White, lastBg = Color.Black;
			foreach (y; 0 .. height_)
			{
				foreach (x; 0 .. width_)
				{
					if (fgColors[y][x] != lastFg || bgColors[y][x] != lastBg)
					{
						writef("\033[%d;%dm", 30 + fgColors[y][x], 40 + bgColors[y][x]);
						lastFg = fgColors[y][x];
						lastBg = bgColors[y][x];
					}
					write(buffer[y][x]);
				}
			}
			stdout.flush();
		}
	}

	bool pollEvent(ref Event event)
	{
		version (Windows)
		{
			DWORD numRead;
			if (!GetNumberOfConsoleInputEvents(hInput, &numRead) || numRead == 0)
			{
				return false;
			}

			if (!ReadConsoleInput(hInput, inputBuffer.ptr, 1, &numRead) || numRead == 0)
			{
				return false;
			}

			auto record = inputBuffer[0];

			if (record.EventType == KEY_EVENT && record.Event.KeyEvent.bKeyDown)
			{
				event.type = EventType.Key;
				event.key = cast(Key) record.Event.KeyEvent.wVirtualKeyCode;
				event.ch = cast(char) record.Event.KeyEvent.uChar.AsciiChar;
				event.ctrl = (record.Event.KeyEvent.dwControlKeyState & LEFT_CTRL_PRESSED) != 0;
				event.alt = (record.Event.KeyEvent.dwControlKeyState & LEFT_ALT_PRESSED) != 0;
				event.shift = (record.Event.KeyEvent.dwControlKeyState & SHIFT_PRESSED) != 0;
				return true;
			}

			return false;
		}
		else
		{
			import core.sys.posix.sys.select;

			fd_set readfds;
			FD_ZERO(&readfds);
			FD_SET(STDIN_FILENO, &readfds);

			timeval tv = {0, 0}; // Non-blocking

			if (select(STDIN_FILENO + 1, &readfds, null, null, &tv) <= 0)
			{
				return false;
			}

			char[16] buf;
			auto n = read(STDIN_FILENO, buf.ptr, buf.length);
			if (n <= 0)
				return false;

			event.type = EventType.Key;
			event.ctrl = false;
			event.alt = false;
			event.shift = false;

			if (n == 1)
			{
				event.ch = buf[0];
				switch (buf[0])
				{
				case 13:
					event.key = Key.Enter;
					break;
				case 27:
					event.key = Key.Escape;
					break;
				case 8:
				case 127:
					event.key = Key.Backspace;
					break;
				case 9:
					event.key = Key.Tab;
					break;
				case 32:
					event.key = Key.Space;
					break;
				default:
					event.key = Key.Unknown;
					break;
				}
			}
			else if (n >= 3 && buf[0] == 27 && buf[1] == '[')
			{
				switch (buf[2])
				{
				case 'A':
					event.key = Key.Up;
					break;
				case 'B':
					event.key = Key.Down;
					break;
				case 'C':
					event.key = Key.Right;
					break;
				case 'D':
					event.key = Key.Left;
					break;
				default:
					event.key = Key.Unknown;
					break;
				}
				event.ch = 0;
			}
			else
			{
				event.key = Key.Unknown;
				event.ch = buf[0];
			}

			return true;
		}
	}
}

// Base widget class
abstract class Widget
{
	int x, y, width, height;
	bool visible = true;
	bool focused = false;
	Color fgColor = Color.White;
	Color bgColor = Color.Black;

	this(int x, int y, int w, int h)
	{
		this.x = x;
		this.y = y;
		this.width = w;
		this.height = h;
	}

	abstract void render(Terminal term);
	abstract bool handleEvent(Event event);

	bool contains(int px, int py)
	{
		return px >= x && px < x + width && py >= y && py < y + height;
	}
}

// Label widget
class Label : Widget
{
	string text;

	this(int x, int y, string text)
	{
		super(x, y, cast(int) text.length, 1);
		this.text = text;
	}

	override void render(Terminal term)
	{
		if (!visible)
			return;
		term.writeText(x, y, text, fgColor, bgColor);
	}

	override bool handleEvent(Event event)
	{
		return false;
	}
}

// Button widget
class Button : Widget
{
	string text;
	void delegate() onClick;
	bool pressed = false;

	this(int x, int y, string text, void delegate() onClick = null)
	{
		super(x, y, cast(int) text.length + 4, 3);
		this.text = text;
		this.onClick = onClick;
	}

	override void render(Terminal term)
	{
		if (!visible)
			return;

		Color fg = focused ? Color.BrightWhite : fgColor;
		Color bg = pressed ? Color.BrightBlue : (focused ? Color.Blue : bgColor);

		term.drawBox(x, y, width, height, fg, bg);
		term.writeText(x + 2, y + 1, text, fg, bg);
	}

	override bool handleEvent(Event event)
	{
		if (!visible)
			return false;

		if (event.type == EventType.Key)
		{
			if (focused && (event.key == Key.Enter || event.key == Key.Space))
			{
				pressed = !pressed;
				if (onClick)
					onClick();
				return true;
			}
		}

		return false;
	}
}

// Text input widget
class TextInput : Widget
{
	string text;
	int cursorPos = 0;
	int maxLength = 100;

	this(int x, int y, int w, int maxLen = 100)
	{
		super(x, y, w, 1);
		this.maxLength = maxLen;
	}

	override void render(Terminal term)
	{
		if (!visible)
			return;

		Color bg = focused ? Color.BrightBlue : Color.Blue;
		term.fillRect(x, y, width, height, ' ', fgColor, bg);

		string displayText = text;
		if (displayText.length > width)
		{
			displayText = displayText[$ - width .. $];
		}

		term.writeText(x, y, displayText, Color.White, bg);

		if (focused)
		{
			int cursorX = x + min(cursorPos, width - 1);
			term.setChar(cursorX, y, '_', Color.BrightWhite, bg);
		}
	}

	override bool handleEvent(Event event)
	{
		if (!visible || !focused)
			return false;

		if (event.type == EventType.Key)
		{
			switch (event.key)
			{
			case Key.Backspace:
				if (cursorPos > 0)
				{
					text = text[0 .. cursorPos - 1] ~ text[cursorPos .. $];
					cursorPos--;
				}
				return true;

			case Key.Delete:
				if (cursorPos < text.length)
				{
					text = text[0 .. cursorPos] ~ text[cursorPos + 1 .. $];
				}
				return true;

			case Key.Left:
				if (cursorPos > 0)
					cursorPos--;
				return true;

			case Key.Right:
				if (cursorPos < text.length)
					cursorPos++;
				return true;

			case Key.Home:
				cursorPos = 0;
				return true;

			case Key.End:
				cursorPos = cast(int) text.length;
				return true;

			default:
				if (event.ch >= 32 && event.ch < 127 && text.length < maxLength)
				{
					text = text[0 .. cursorPos] ~ event.ch ~ text[cursorPos .. $];
					cursorPos++;
					return true;
				}
				break;
			}
		}

		return false;
	}
}

// Window widget
class Window : Widget
{
	string title;
	Widget[] children;

	this(int x, int y, int w, int h, string title = "")
	{
		super(x, y, w, h);
		this.title = title;
		this.bgColor = Color.Blue;
	}

	void addChild(Widget widget)
	{
		children ~= widget;
	}

	override void render(Terminal term)
	{
		if (!visible)
			return;

		// Draw window background
		term.fillRect(x, y, width, height, ' ', fgColor, bgColor);

		// Draw border
		term.drawBox(x, y, width, height, Color.BrightWhite, bgColor);

		// Draw title
		if (title.length > 0)
		{
			string displayTitle = " " ~ title ~ " ";
			if (displayTitle.length > width - 4)
			{
				displayTitle = displayTitle[0 .. width - 4];
			}
			term.writeText(x + 2, y, displayTitle, Color.BrightWhite, bgColor);
		}

		// Render children
		foreach (child; children)
		{
			child.render(term);
		}
	}

	override bool handleEvent(Event event)
	{
		if (!visible)
			return false;

		// Forward events to focused child first
		foreach_reverse (child; children)
		{
			if (child.focused && child.handleEvent(event))
			{
				return true;
			}
		}

		// Then to other children
		foreach_reverse (child; children)
		{
			if (!child.focused && child.handleEvent(event))
			{
				return true;
			}
		}

		return false;
	}

	void focusNext()
	{
		if (children.length == 0)
			return;

		int currentFocus = -1;
		foreach (i, child; children)
		{
			if (child.focused)
			{
				child.focused = false;
				currentFocus = cast(int) i;
				break;
			}
		}

		int nextFocus = cast(int)((currentFocus + 1) % cast(int) children.length);
		children[nextFocus].focused = true;
	}

	void focusPrevious()
	{
		if (children.length == 0)
			return;

		int currentFocus = -1;
		foreach (i, child; children)
		{
			if (child.focused)
			{
				child.focused = false;
				currentFocus = cast(int) i;
				break;
			}
		}

		int prevFocus = currentFocus <= 0 ? cast(int) children.length - 1 : currentFocus - 1;
		children[prevFocus].focused = true;
	}
}

// Application class
class Application
{
	Terminal terminal;
	Widget[] widgets;
	bool running = true;

	this()
	{
		terminal = new Terminal();
	}

	~this()
	{
		destroy(terminal);
	}

	void addWidget(Widget widget)
	{
		widgets ~= widget;
		if (widgets.length == 1)
		{
			widget.focused = true;
		}
	}

	void run()
	{
		while (running)
		{
			// Handle events
			Event event;
			while (terminal.pollEvent(event))
			{
				if (event.type == EventType.Key && event.key == Key.Escape)
				{
					running = false;
					break;
				}

				if (event.type == EventType.Key && event.key == Key.Tab)
				{
					focusNext();
					continue;
				}

				// Forward to widgets
				bool handled = false;
				foreach_reverse (widget; widgets)
				{
					if (widget.handleEvent(event))
					{
						handled = true;
						break;
					}
				}
			}

			// Render
			terminal.clear();
			foreach (widget; widgets)
			{
				widget.render(terminal);
			}
			terminal.render();

			// Small delay to prevent excessive CPU usage
			import core.thread;

			Thread.sleep(16.msecs); // ~60 FPS
		}
	}

	void quit()
	{
		running = false;
	}

	private void focusNext()
	{
		if (widgets.length == 0)
			return;

		int currentFocus = -1;
		foreach (i, widget; widgets)
		{
			if (widget.focused)
			{
				widget.focused = false;
				currentFocus = cast(int) i;
				break;
			}
		}

		int nextFocus = cast(int)((currentFocus + 1) % cast(int) widgets.length);
		widgets[nextFocus].focused = true;
	}
}

unittest
{
	auto app = new Application();

	// Create a main window
	auto mainWindow = new Window(5, 2, 60, 20, "SimpleTUI Demo");

	// Add some widgets to the window
	auto label = new Label(7, 4, "Welcome to SimpleTUI!");
	label.fgColor = Color.BrightYellow;

	auto nameInput = new TextInput(7, 6, 30);
	auto nameLabel = new Label(7, 5, "Enter your name:");

	auto button1 = new Button(7, 8, "Say Hello", () {
		writeln("Hello from button 1!");
	});

	auto button2 = new Button(20, 8, "Quit", () { app.quit(); });

	// Add widgets to window
	mainWindow.addChild(label);
	mainWindow.addChild(nameLabel);
	mainWindow.addChild(nameInput);
	mainWindow.addChild(button1);
	mainWindow.addChild(button2);

	// Set initial focus
	nameInput.focused = true;

	// Add window to application
	app.addWidget(mainWindow);

	// Create a second window
	auto infoWindow = new Window(70, 2, 25, 10, "Info");
	infoWindow.bgColor = Color.Green;

	auto infoLabel = new Label(72, 4, "Use Tab to switch");
	infoLabel.fgColor = Color.White;
	auto infoLabel2 = new Label(72, 5, "between widgets.");
	infoLabel2.fgColor = Color.White;
	auto infoLabel3 = new Label(72, 7, "Press ESC to quit.");
	infoLabel3.fgColor = Color.BrightWhite;

	infoWindow.addChild(infoLabel);
	infoWindow.addChild(infoLabel2);
	infoWindow.addChild(infoLabel3);

	app.addWidget(infoWindow);

	// Run the application
	app.run();
}
