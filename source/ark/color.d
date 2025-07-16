module ark.color;

import std.conv;
import std.variant;

/** 
 * Surround text with ANSI escape codes as per ArkColor.
 *
 * Params:
 *   text = Text to colorize
 *   fg = Foreground
 *   bg = Background
 * Returns: Colorized text
 */
string colorize(string text, int fg, int bg = -1)
{
    string result = "\033[38;5;" ~ to!string(fg) ~ "m";
    if (bg >= 0)
        result ~= "\033[48;5;" ~ to!string(bg) ~ "m";
    result ~= text ~ "\033[0m";
    return result;
}

/** 
 * Print some colored output.
 *
 * Params:
 *   fg = Foreground color 
 *   bg = Background color
 *   things = Any input, object or text to print
 */
void colorPrint(int fg, int bg = -1, Variant things...)
{
    import std.stdio;

    foreach (string thing; things)
    {
        if (bg >= 0)
            writeln(colorize(to!string(thing), fg, bg));
    }
}

/** 
 * Further finegrained color selection.
 * Preferred use vs Color class which is primarily for Ark internals.
 */
public enum ArkColor : ubyte
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
    BrightWhite = 15,
    Nord0 = 236,
    Nord1 = 238,
    Nord2 = 240,
    Nord3 = 245,
    Nord4 = 250,
    NordBlue = 67,
    NordCyan = 73,
    NordGreen = 114,
    NordRed = 131,
    NordOrange = 166,
    GruvboxBg = 235,
    GruvboxFg = 223,
    GruvboxRed = 124,
    GruvboxGreen = 106,
    GruvboxYellow = 172,
    GruvboxBlue = 66,
    GruvboxPurple = 132,
    GruvboxAqua = 108,
    SolarizedBase03 = 234,
    SolarizedBase02 = 235,
    SolarizedBase01 = 240,
    SolarizedBase00 = 241,
    SolarizedBase0 = 244,
    SolarizedBase1 = 245,
    SolarizedBase2 = 254,
    SolarizedBase3 = 230,
    SolarizedYellow = 136,
    SolarizedOrange = 166,
    SolarizedRed = 160,
    SolarizedMagenta = 125,
    SolarizedViolet = 61,
    SolarizedBlue = 33,
    SolarizedCyan = 37,
    SolarizedGreen = 64
}
