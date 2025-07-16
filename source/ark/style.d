module ark.style;

import ark.structures;

template ArkStyle()
{
    /** 
     * Whether to enable color or not.
     *
     * Params:
     *   enable = Color or no color
     */
    static void enableColor(bool enable = true)
    {
        colorEnabled = enable;
    }

    /** 
     * Colorize some text using corresponding ANSI escape code.
     *
     * Params:
     *   text = Text to colorize
     *   color = Color to use
     *
     * Returns: The colorized 
     */
    private static string colorize(string text, Color color) => colorEnabled ? (
        color ~ text ~ Color.RESET
    ) : text;

    private static string colorize(string text, Color fg, Color bg = Color.RESET)
    {
        if (!colorEnabled)
            return text;
        string fgCode = cast(string) fg;
        string bgCode = (bg != Color.RESET) ? toBgCode(bg) : "";
        return fgCode ~ bgCode ~ text ~ Color.RESET;
    }

    static void printColorized(T...)(Color fg, Color bg, T args, string separator = " ")
    {
        import std.conv;

        foreach (arg; args)
        {
            string text = arg.to!string;
            write(colorize(text, fg, bg) ~ separator);
        }
        writeln();
    }

    /** 
     * Stylize some text.
     *
     * Params:
     *   text = The text
     *   style = The style to use (e.g. underline, bold, etc...)
     * Returns: 
     */
    private static string stylize(string text, Style style) => colorEnabled ? (
        style ~ text ~ Style.RESET
    ) : text;
    private static string toBgCode(Color color) @safe
    {
        import std.regex : matchFirst;
        import std.conv : to;

        if (color == Color.RESET)
            return "";

        string colorStr = cast(string) color;
        auto m = colorStr.matchFirst(r"\x1b\[38;5;(\d+)m");
        if (m)
        {
            int code = m[1].to!int;
            return "\033[48;5;" ~ code.to!string ~ "m";
        }

        auto mStd = colorStr.matchFirst(r"\x1b\[(\d+)m");
        if (mStd)
        {
            int code = mStd[1].to!int;
            if (code >= 30 && code <= 37)
                return "\033[" ~ (code + 10).to!string ~ "m";
            if (code >= 90 && code <= 97)
                return "\033[" ~ (code + 10).to!string ~ "m";
        }

        return "";
    }
}

static string noConColorize(string text, Color color) => color ~ text ~ Color.RESET;
