module ark.asialang;

/**
 * Modify the character counting method so
 * that the calculation of character length
 * is compatible with Asia-Pacific char.
 */
template AsiaLangFunc() {

    static bool isAsiaChar(wchar c) {
        return (c >= 0x1100 && c <= 0x115F)
            || (c >= 0x2E80 && c <= 0xA4CF && c != 0x303F)
            || (c >= 0xAC00 && c <= 0xD7A3)
            || (c >= 0xF900 && c <= 0xFAFF)
            || (c >= 0xFE10 && c <= 0xFE19)
            || (c >= 0xFE30 && c <= 0xFE6F)
            || (c >= 0xFF01 && c <= 0xFF60)
            || (c >= 0xFFE0 && c <= 0xFFE6)
            || (c >= 0x20000 && c <= 0x323AF);
    }

    static int getCharWidth(wchar c) {
        return isAsiaChar(c) ? 2 : 1;
    }

    static int getAsiaCount(string input) {
        int width = 0;
        foreach (wchar c; input) {
            width += isAsiaChar(c) ? 1 : 0;
        }
        return width;
    }

    static int getStringWidth(string input) {
        int width = 0;
        foreach (char c; input) {
            width += getCharWidth(c);
        }

        return width;
    }

    static int length(string str) {
        return getStringWidth(str);
    }

    static string[] wrapText(string text, size_t maxWidth) {
        import std.string;
        import std.math;

        string[] outputLines = new string[0];
        string[] lines = text.split("\n");
        string currentLine = "";

        foreach (string line; lines) {
            if (line == "") {
                if (currentLine != "") {
                    outputLines ~= currentLine;
                    currentLine = "";
                }
                outputLines ~= "";
                continue;
            }

            if (line.length < maxWidth) {
                outputLines ~= line;
                continue;
            }

            string[] words = line.split(" ");
            foreach (string word; words) {
                if (currentLine.length + word.length + 1 < maxWidth) {
                    currentLine ~= " " ~ word;
                    continue;
                }

                if (currentLine != "") {
                    outputLines ~= currentLine;
                    currentLine = "";
                }

                while (word.length >= maxWidth) {
                    string subText = word[0 .. maxWidth];
                    int asiaWordLen = getAsiaCount(subText);
                    if (asiaWordLen > 0) {
                        subText ~= word[maxWidth .. min(word.length, maxWidth + asiaWordLen - 1)];
                    }
                    outputLines ~= subText;
                    word = word[min(word.length, maxWidth + asiaWordLen - 1) .. $];
                }

                currentLine ~= word;
            }
        }

        if (currentLine != "") {
            outputLines ~= currentLine;
        }

        return outputLines;
    }

    private static size_t min(size_t x, size_t y) {
        return x < y ? x : y;
    }
}
