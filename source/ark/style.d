module ark.style;

template ArkStyle()
{
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
}
