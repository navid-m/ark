module ark.foundations;

template ArkFoundationComponents()
{
    /** 
     * Write some text block surrounded by separators.
     *
     * Params:
     *   text = The text to write
     *   sep = The separating string, not character, string
     *   length = The length of the separators
     *   color = The color of the separators
     */
    static void writeBlock(
        string text,
        string sep = "─",
        size_t length = defaultLineLength,
        Color color = Color.RESET
    )
    {
        drawSeparator(sep, length, color);
        write(text ~ "\n");
        drawSeparator(sep, length, color);
        write("\n");
    }

    /** 
     * Print a table.
     *
     * Params:
     *   headers = Table headers
     *   rows = Rows of the table
     *   minColWidth = Minimum column width per column
     */
    static void drawTable(string[] headers, string[][] rows, size_t minColWidth = 10)
    {
        if (headers.length == 0)
            return;

        auto colWidths = new size_t[headers.length];
        foreach (i, header; headers)
        {
            colWidths[i] = max(header.length, minColWidth);
        }

        foreach (row; rows)
        {
            foreach (i, cell; row)
            {
                if (i < colWidths.length)
                    colWidths[i] = max(colWidths[i], cell.length);
            }
        }

        write("┌");
        foreach (i, width; colWidths)
        {
            write("─".replicate(width + 2));
            write(i == cast(int) colWidths.length - 1 ? "┐" : "┬");
        }

        writeln;
        write("│");

        foreach (i, header; headers)
        {
            writef(" %-*s │", colWidths[i], header);
        }

        writeln;
        write("├");

        foreach (i, width; colWidths)
        {
            write(
                "─".replicate(
                    width + 2));
            write(i == cast(
                    int) colWidths.length - 1 ? "┤" : "┼");
        }

        writeln;

        foreach (row; rows)
        {
            write("│");
            foreach (i; 0 .. colWidths
                .length)
            {
                string cell = i < row.length ? row[i] : "";
                writef(" %-*s │", colWidths[i], cell);
            }
            writeln;
        }

        write("└");

        foreach (i, width; colWidths)
        {
            write(
                "─".replicate(
                    width + 2));
            write(i == cast(
                    int) colWidths.length - 1 ? "┘" : "┴");
        }

        writeln;
    }

    /**
     * Print a table with rounded corners.
     *
     * Params:
     *   headers = Table headers
     *   rows = Rows of the table
     *   minColWidth = Minimum column width per column
     */
    static void drawRoundedTable(string[] headers, string[][] rows, size_t minColWidth = 10)
    {
        if (headers.length == 0)
            return;

        auto colWidths = new size_t[headers.length];
        foreach (i, header; headers)
        {
            colWidths[i] = max(header.length, minColWidth);
        }
        foreach (row; rows)
        {
            foreach (i, cell; row)
            {
                if (i < colWidths.length)
                    colWidths[i] = max(colWidths[i], cell.length);
            }
        }
        write("╭");
        foreach (i, width; colWidths)
        {
            write("─".replicate(width + 2));
            write(i == cast(int) colWidths.length - 1 ? "╮" : "┬");
        }
        writeln;
        write("│");
        foreach (i, header; headers)
        {
            writef(" %-*s │", colWidths[i], header);
        }
        writeln;
        write("├");
        foreach (i, width; colWidths)
        {
            write("─".replicate(width + 2));
            write(i == cast(int) colWidths.length - 1 ? "┤" : "┼");
        }
        writeln;
        foreach (row; rows)
        {
            write("│");
            foreach (i; 0 .. colWidths.length)
            {
                string cell = i < row.length ? row[i] : "";
                writef(" %-*s │", colWidths[i], cell);
            }
            writeln;
        }
        write("╰");
        foreach (i, width; colWidths)
        {
            write("─".replicate(width + 2));
            write(i == cast(int) colWidths.length - 1 ? "╯" : "┴");
        }
        writeln;
    }

    /** 
     * Print some alert.
     *
     * Params:
     *   message = The message of the alert
     *   level = Log level
     *   width = Width of containing box
     */
    static void drawAlert(string message, LogLevel level = LogLevel.INFO, size_t width = 60)
    {
        Color borderColor;
        string icon;

        final switch (level)
        {
        case LogLevel.INFO:
            borderColor = Color.BLUE;
            icon = "ℹ";
            break;
        case LogLevel.SUCCESS:
            borderColor = Color.GREEN;
            icon = "✓";
            break;
        case LogLevel.WARNING:
            borderColor = Color.YELLOW;
            icon = "⚠";
            break;
        case LogLevel.ERROR:
            borderColor = Color.RED;
            icon = "✗";
            break;
        case LogLevel.DEBUG:
            borderColor = Color.MAGENTA;
            icon = "🐛";
            break;
        }

        auto lines = message.split('\n');
        auto maxLen = lines.map!(l => l.length).maxElement;
        auto boxWidth = max(width, maxLen + 6);

        writeln(colorize("┌" ~ "─".replicate(boxWidth - 2) ~ "┐", borderColor));
        writeln(colorize("│", borderColor) ~ " " ~ colorize(icon, borderColor) ~ " "
                ~ format("%-*s", boxWidth - 6, lines[0]) ~ " " ~ colorize(
                    "│", borderColor));

        foreach (line; lines[1 .. $])
        {
            writeln(colorize("│", borderColor) ~ "   " ~
                    format("%-*s", boxWidth - 6, line) ~ " " ~ colorize("│", borderColor));
        }

        writeln(colorize("└" ~ "─".replicate(boxWidth - 2) ~ "┘", borderColor));
    }

    /** 
     * Print key value pairs in a formatted TSV way.
     *
     * Params:
     *   key = The key
     *   value = The value
     *   keyWidth = Width of key element
     *   keyColor = The color to use for the key element
     */
    static void drawKeyValue(
        string key,
        string value,
        size_t keyWidth = 20,
        Color keyColor = Color.CYAN
    )
    {
        writef(
            "%s: %s\n",
            colorize(format("%-*s", keyWidth, key), keyColor),
            value
        );
    }

    /** 
     * Print a spinner.
     *
     * Params:
     *   message = Annotation to show on left hand side of spinner
     */
    static void drawSpinner(string message = "Loading...")
    {
        write("\r" ~ colorize(spinnerChars[spinnerIndex], Color.CYAN) ~ " " ~ message);
        stdout.flush();
        spinnerIndex = (spinnerIndex + 1) % spinnerChars.length;
    }

    /**
     * Clears the spinner from the console by overwriting the current line with spaces.
     */
    static void clearSpinner()
    {
        write("\r" ~ " ".replicate(80) ~ "\r");
    }

    /** 
     * Print some status message.
     *
     * Params:
     *   message = The message
     *   success = Success or not, will change icon based on this
     *   details = Details of status message to appear as subtitle
     */
    static void drawStatus(string message, bool success, string details = "")
    {
        string symbol = success ? "✓" : "✗";
        Color color = success ? Color.GREEN : Color.RED;
        write(colorize(symbol, color) ~ " " ~ message);

        if (details.length > 0)
            write(colorize(" (" ~ details ~ ")", Color.BRIGHT_BLACK));

        writeln;
    }

    static void drawProgress(
        double progress,
        size_t width = 40,
        string prefix = "",
        Color barColor = Color.GREEN
    )
    {
        progress = progress < 0 ? 0 : (progress > 1 ? 1 : progress);
        auto filled = cast(size_t)(progress * width);
        auto empty = width - filled;
        auto bar = "█".replicate(filled) ~ "░".replicate(empty);
        auto percentage = format("%.1f%%", progress * 100);

        write("\r" ~ prefix);
        write(colorize(bar, barColor));
        write(" " ~ percentage);
    }

    static void drawColumns(string[][] columns, size_t[] widths = [], string separator = " │ ")
    {
        if (columns.length == 0)
            return;

        auto maxRows = columns.map!(col => col.length).maxElement;

        if (widths.length == 0)
        {
            widths = new size_t[columns.length];
            foreach (i, col; columns)
            {
                widths[i] = col.length > 0 ? col.map!(s => s.length).maxElement : 0;
            }
        }

        foreach (row; 0 .. maxRows)
        {
            foreach (col; 0 .. columns.length)
            {
                string content = row < columns[col].length ? columns[col][row] : "";
                if (col >= widths.length)
                    continue;
                writef("%-*s", widths[col], content);
                if (col < cast(int) columns.length - 1)
                    write(separator);
            }
            writeln;
        }
    }

    static void drawGauge(
        double value,
        double min = 0,
        double max = 100,
        size_t width = 30,
        string label = "",
        Color color = Color.GREEN
    )
    {
        value = value < min ? min : (value > max ? max : value);
        double percentage = (value - min) / (max - min);
        auto filled = cast(size_t)(percentage * width);
        auto empty = width - filled;
        string bar = "█".replicate(filled) ~ "░".replicate(empty);
        string display = format("%s [%s] %.1f/%.1f", label, colorize(bar, color), value, max);
        writeln(display);
    }

    static void drawTextBox(
        string text,
        size_t width = 60,
        BorderStyle style = BorderStyle.SINGLE,
        Color borderColor = Color.RESET,
        string title = ""
    )
    {
        auto borders = borderStyles[style];
        auto lines = text.split('\n');
        auto maxWidth = width - 3;
        string[] wrappedLines;

        foreach (line; lines)
        {
            if (line.length <= maxWidth)
            {
                wrappedLines ~= line;
            }
            else
            {
                auto words = line.split(' ');
                string currentLine = "";
                foreach (word; words)
                {
                    if (currentLine.length + word.length + 1 <= maxWidth)
                    {
                        currentLine ~= (currentLine.length > 0 ? " " : "") ~ word;
                    }
                    else
                    {
                        if (currentLine.length > 0)
                            wrappedLines ~= currentLine;
                        currentLine = word;
                    }
                }
                if (currentLine.length > 0)
                    wrappedLines ~= currentLine;
            }
        }

        string topLine = borders.topLeft ~ borders.horizontal.replicate(
            width - 2) ~ borders.topRight;
        if (title.length > 0 && title.length < width - 4)
        {
            auto titlePos = (width - title.length - 2) / 2;
            topLine = borders.topLeft ~ borders.horizontal.replicate(
                titlePos) ~
                " " ~ title ~ " " ~
                borders.horizontal.replicate(
                    width - titlePos - title.length - 3) ~ borders.topRight;
        }
        writeln(colorize(topLine, borderColor));
        foreach (line; wrappedLines)
        {
            writeln(colorize(borders.vertical, borderColor) ~
                    format(" %-*s ", maxWidth, line) ~
                    colorize(borders.vertical, borderColor));
        }

        writeln(colorize(borders.bottomLeft ~ borders.horizontal.replicate(
                width - 2) ~ borders.bottomRight, borderColor));
    }

    static void drawBanner(string text, string font = "block")
    {
        string[char] blockChars = [
            'A': "██████\r\n██  ██\r\n██████\r\n██  ██\r\n██  ██",
            'B': "██████\r\n██  ██\r\n██████\r\n██  ██\r\n██████",
            'C': "██████\r\n██    \r\n██    \r\n██    \r\n██████",
        ];
        foreach (c; text.toUpper())
        {
            if (c in blockChars)
            {
                writeln(blockChars[c]);
                writeln;
            }
            else if (c == ' ')
            {
                writeln("      ");
            }
        }
    }

    static void drawDashboard(string[string] panels, size_t cols = 2)
    {
        auto keys = panels.keys.array;
        auto rows = (
            keys.length + cols - 1) / cols;
        foreach (row; 0 .. rows)
        {
            foreach (col; 0 .. cols)
            {
                auto idx = row * cols + col;
                if (idx < keys.length)
                {
                    auto key = keys[idx];
                    drawTextBox(panels[key], 35, BorderStyle.SINGLE, Color.CYAN, key);
                }
            }
            writeln;
        }
    }

    static void drawCodeBlock(
        string code,
        string language = "",
        Color commentColor = Color.BRIGHT_BLACK)
    {
        drawTextBox(
            "", 80, BorderStyle.SINGLE, Color.BRIGHT_BLACK, language.length > 0 ? language.toUpper()
                : "CODE"
        );

        foreach (line; code.split('\n'))
        {
            string processedLine = line;

            if (line.strip().startsWith("//") || line.strip()
                .startsWith("#"))
            {
                processedLine = colorize(line, commentColor);
            }

            writeln("  " ~ processedLine);
        }

        writeln(colorize("└" ~ "─".replicate(78) ~ "┘", Color
                .BRIGHT_BLACK));
    }

    static void drawToast(string message, LogLevel level = LogLevel.INFO, size_t duration = 3)
    {
        Color bgColor = Color.BLUE;
        string icon = "ℹ";

        final switch (level)
        {
        case LogLevel.INFO:
            bgColor = Color.BLUE;
            icon = "ℹ";
            break;
        case LogLevel.SUCCESS:
            bgColor = Color.GREEN;
            icon = "✓";
            break;
        case LogLevel.WARNING:
            bgColor = Color.YELLOW;
            icon = "⚠";
            break;
        case LogLevel.ERROR:
            bgColor = Color.RED;
            icon = "✗";
            break;
        case LogLevel.DEBUG:
            bgColor = Color.MAGENTA;
            icon = "🐛";
            break;
        }

        auto timestamp = Clock.currTime.toString()[11 .. 19];
        string toast = format(" %s %s (%s) ", icon, message, strip(timestamp));

        writeln(colorize("╭" ~ "─".replicate(toast.length) ~ "╮", bgColor));
        writeln(colorize("│" ~ toast ~ "  │", bgColor));
        writeln(colorize("╰" ~ "─".replicate(toast.length) ~ "╯", bgColor));
    }

    static void drawLoadingDots(string message = "Loading", size_t dots = 3)
    {
        static size_t dotCount = 0;
        write("\r" ~ message ~ " " ~ ".".replicate(
                (dotCount % (dots + 1))) ~
                " ".replicate(
                    dots - (dotCount % (dots + 1))) ~ "   ");
        stdout.flush();
        dotCount++;
    }

    /** 
     * Draw a breadcrumb/path-display component.
     *
     * Params:
     *   path = The path to be represented
     *   separator = The separator 
     */
    static void drawBreadcrumb(string[] path, string separator = " > ")
    {
        foreach (i, item; path)
        {
            if (i == cast(int) path.length - 1)
                write(colorize(item, Color.BRIGHT_WHITE));
            else
                write(colorize(item, Color.BRIGHT_BLACK));
            if (i < cast(int) path.length - 1)
                write(colorize(separator, Color.BRIGHT_BLACK));
        }
        writeln;
    }

    static void drawSeparator(
        string sep = "─",
        size_t length = defaultLineLength,
        Color color = Color.RESET
    )
    {
        writeln(colorize(sep.replicate(length), color));
    }

    static void drawIndented(string text, size_t level = 1, string indent = "  ")
    {
        writeln(indent.replicate(level) ~ text);
    }
}
