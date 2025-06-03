module ark.style;

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
     * Colorize some text using corresponding ANSI escpae code.
     *
     * Params:
     *   text = Text to colorize
     *   color = Color to use
     * Returns: 
     */
    private static string colorize(string text, Color color) => colorEnabled ? (
        color ~ text ~ Color.RESET
    ) : text;

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
}
