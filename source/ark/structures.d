module ark.structures;
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

template Structures()
{

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

    enum LegendStyle
    {
        TABLE,
        DOT
    }

    struct BorderChars
    {
        string topLeft, topRight, bottomLeft, bottomRight;
        string horizontal, vertical;
        string topJoin, bottomJoin, leftJoin, rightJoin, cross;
    }

    struct FlowNode
    {
        string id;
        string text;
        size_t x, y;
        size_t width = 0;
    }

    struct FlowConnection
    {
        string fromId;
        string toId;
        string direction = "down";
    }
}
