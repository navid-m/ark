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
    BRIGHT_WHITE = "\033[97m",
    NORD0 = "\033[38;5;236m",
    NORD1 = "\033[38;5;238m",
    NORD2 = "\033[38;5;240m",
    NORD3 = "\033[38;5;245m",
    NORD4 = "\033[38;5;250m",
    NORDBLUE = "\033[38;5;67m",
    NORDCYAN = "\033[38;5;73m",
    NORDGREEN = "\033[38;5;114m",
    NORDRED = "\033[38;5;131m",
    NORDORANGE = "\033[38;5;166m",
    GRUVBOXBG = "\033[38;5;235m",
    GRUVBOXFG = "\033[38;5;223m",
    GRUVBOXRED = "\033[38;5;124m",
    GRUVBOXGREEN = "\033[38;5;106m",
    GRUVBOXYELLOW = "\033[38;5;172m",
    GRUVBOXBLUE = "\033[38;5;66m",
    GRUVBOXPURPLE = "\033[38;5;132m",
    GRUVBOXAQUA = "\033[38;5;108m",
    SOLARIZEDBASE03 = "\033[38;5;234m",
    SOLARIZEDBASE02 = "\033[38;5;235m",
    SOLARIZEDBASE01 = "\033[38;5;240m",
    SOLARIZEDBASE00 = "\033[38;5;241m",
    SOLARIZEDBASE0 = "\033[38;5;244m",
    SOLARIZEDBASE1 = "\033[38;5;245m",
    SOLARIZEDBASE2 = "\033[38;5;254m",
    SOLARIZEDBASE3 = "\033[38;5;230m",
    SOLARIZEDYELLOW = "\033[38;5;136m",
    SOLARIZEDORANGE = "\033[38;5;166m",
    SOLARIZEDRED = "\033[38;5;160m",
    SOLARIZEDMAGENTA = "\033[38;5;125m",
    SOLARIZEDVIOLET = "\033[38;5;61m",
    SOLARIZEDBLUE = "\033[38;5;33m",
    SOLARIZEDCYAN = "\033[38;5;37m",
    SOLARIZEDGREEN = "\033[38;5;64m"
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
