module ark.components;

template ArkComponents()
{
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
            borderColor = Color
                .BLUE;
            icon = "ⓘ";
            break;
        case LogLevel.SUCCESS:
            borderColor = Color
                .GREEN;
            icon = "✓";
            break;
        case LogLevel.WARNING:
            borderColor = Color
                .YELLOW;
            icon = "⚠";
            break;
        case LogLevel.ERROR:
            borderColor = Color
                .RED;
            icon = "✗";
            break;
        case LogLevel.DEBUG:
            borderColor = Color
                .MAGENTA;
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

    static string drawTree(
        string[string] tree,
        string root = "",
        size_t level = 0,
        bool[] isLast = [],
        bool onlyReturn = false
    )
    {
        string result = "";

        if (level == 0)
        {
            result ~= "root\n";
            if (!onlyReturn)
            {
                write("root\n");
            }
        }

        string[] paths;

        foreach (path, value; tree)
        {
            paths ~= path;
        }

        paths.sort();

        string[string] children;
        string[] immediateFiles;

        foreach (path; paths)
        {
            string relativePath = path;
            if (root.length > 0)
            {
                if (!path.startsWith(root ~ "/"))
                    continue;
                relativePath = path[root.length + 1 .. $];
            }

            auto slashIndex = relativePath.indexOf('/');
            if (slashIndex == -1)
            {
                immediateFiles ~= relativePath;
            }
            else
            {
                string dirName = relativePath[0 .. slashIndex];
                if (dirName !in children)
                {
                    children[dirName] = "";
                }
            }
        }

        foreach (i, fileName; immediateFiles)
        {
            string indent = "";
            foreach (j; 0 .. level)
            {
                if (j < isLast.length && isLast[j])
                    indent ~= "    ";
                else
                    indent ~= "│   ";
            }

            bool isLastItem = (i == cast(int) immediateFiles.length - 1) && (children.length == 0);
            string prefix = isLastItem ? "└── " : "├── ";
            string fullPath = root.length > 0 ? root ~ "/" ~ fileName : fileName;
            string line = indent ~ prefix ~ fileName ~ " = " ~ tree[fullPath] ~ "\n";
            result ~= line;

            if (!onlyReturn)
                write(line);
        }

        auto dirNames = children.keys.array.sort();
        int i = 0;

        foreach (dirName; dirNames)
        {
            string indent = "";
            foreach (j; 0 .. level)
            {
                if (j < isLast.length && isLast[j])
                    indent ~= "    ";
                else
                    indent ~= "│   ";
            }

            bool isLastDir = (i == cast(int) dirNames.length - 1);
            string prefix = isLastDir ? "└── " : "├── ";
            string line = indent ~ prefix ~ dirName ~ "/\n";
            result ~= line;

            if (!onlyReturn)
                write(line);

            string newRoot = root.length > 0 ? root ~ "/" ~ dirName : dirName;
            auto newIsLast = isLast ~ isLastDir;
            string subResult = drawTree(tree, newRoot, level + 1, newIsLast, onlyReturn);
            result ~= subResult;
            i++;
        }

        return result;
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

    static void drawSparkline(double[] data, size_t width = 50, string label = "")
    {
        if (data.length == 0)
            return;

        auto minVal = data.minElement;
        auto maxVal = data.maxElement;
        auto range = maxVal - minVal;

        if (range == 0)
            range = 1;

        string[] chars = [
            "▁", "▂", "▃", "▄",
            "▅", "▆", "▇", "█"
        ];
        string sparkline = "";

        foreach (val; data)
        {
            auto normalized = (val - minVal) / range;
            auto charIndex = cast(size_t)(
                normalized * (
                    cast(int) chars.length - 1));
            sparkline ~= chars[charIndex];
        }

        if (label.length > 0)
            writef("%s: ", label);

        writef("%s (%.2f - %.2f)\n", colorize(sparkline, Color.GREEN), minVal, maxVal);
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
        string toast = format(" %s %s (%s) ", icon, message, timestamp);

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

    /** 
     * Print a horizontal bar chart.
     *
     * Params:
     *   labels = Labels for each bar
     *   values = Values for each bar
     *   maxBarWidth = Maximum width of the bars
     *   showValues = Whether to show values at the end of bars
     *   barColor = Color of the bars
     *   title = Optional title for the chart
     */
    static void drawBarChart(
        string[] labels,
        double[] values,
        size_t maxBarWidth = 40,
        bool showValues = true,
        Color barColor = Color.CYAN,
        string title = ""
    )
    {
        if (labels.length == 0 || values.length == 0 || labels.length != values.length)
            return;

        if (title.length > 0)
        {
            writeln(colorize(title, Color.BRIGHT_WHITE));
            drawSeparator("─", title.length, Color.BRIGHT_BLACK);
        }

        auto maxValue = values.maxElement;
        if (maxValue <= 0)
            maxValue = 1;

        auto maxLabelWidth = labels.map!(l => l.length).maxElement;

        foreach (i, label; labels)
        {
            auto value = values[i];
            auto barLength = cast(size_t)((value / maxValue) * maxBarWidth);

            writef("%-*s │", maxLabelWidth, label);
            write(colorize("█".replicate(barLength), barColor));

            if (showValues)
            {
                write(" ");
                writef("%.1f", value);
            }

            writeln;
        }
    }

    /** 
     * Draw a line graph using ASCII characters.
     *
     * Params:
     *   data       = Array of data points to plot
     *   width      = Width of the graph in characters
     *   height     = Height of the graph in characters
     *   title      = Optional title for the graph
     *   xLabels    = Optional labels for x-axis points
     *   showGrid   = Whether to show grid lines
     *   lineColor  = Color of the line
     *   gridColor  = Color of the grid
     *   showYAxis  = Whether to show Y-axis with values
     */
    static void drawLineGraph(
        double[] data,
        size_t width = 60,
        size_t height = 20,
        string title = "",
        string[] xLabels = [],
        bool showGrid = true,
        Color lineColor = Color.CYAN,
        Color gridColor = Color.BRIGHT_BLACK,
        bool showYAxis = true
    )
    {
        import std.math : abs;
        import std.conv;

        if (data.length == 0)
            return;

        if (title.length > 0)
        {
            writeln(colorize(title, Color.BRIGHT_WHITE));
            drawSeparator("─", title.length, Color.BRIGHT_BLACK);
        }

        auto minVal = data.minElement;
        auto maxVal = data.maxElement;
        auto range = maxVal - minVal;

        if (range == 0)
            range = 1;

        size_t yAxisWidth = 0;
        if (showYAxis)
        {
            yAxisWidth = max(format("%.1f", maxVal).length, format("%.1f", minVal).length) + 1;
        }

        auto graphWidth = width - yAxisWidth;
        wchar[][] grid = new wchar[][](height, graphWidth);
        foreach (ref row; grid)
        {
            row[] = ' ';
        }

        if (showGrid)
        {
            foreach (y; 0 .. height)
            {
                if (y % 4 == 0 || y == height - 1)
                {
                    foreach (x; 0 .. graphWidth)
                    {
                        grid[y][x] = '─';
                    }
                }
            }

            foreach (x; 0 .. graphWidth)
            {
                if (x % 10 == 0)
                {
                    foreach (y; 0 .. height)
                    {
                        if (grid[y][x] == '─')
                            grid[y][x] = '┼';
                        else
                            grid[y][x] = '│';
                    }
                }
            }
        }

        for (size_t i = 0; i < cast(int) data.length - 1; i++)
        {
            auto x1 = cast(size_t)((cast(double) i / (cast(int) data.length - 1)) * (graphWidth - 1));
            auto x2 = cast(size_t)((cast(double)(i + 1) / (cast(int) data.length - 1)) * (
                    graphWidth - 1));
            auto y1 = cast(size_t)((1.0 - (data[i] - minVal) / range) * (height - 1));
            auto y2 = cast(size_t)((1.0 - (data[i + 1] - minVal) / range) * (height - 1));
            auto dx = cast(int) x2 - cast(int) x1;
            auto dy = cast(int) y2 - cast(int) y1;
            auto steps = max(abs(dx), abs(dy));

            if (steps == 0)
                steps = 1;

            auto xIncrement = cast(double) dx / steps;
            auto yIncrement = cast(double) dy / steps;
            auto x = cast(double) x1;
            auto y = cast(double) y1;

            for (int step = 0; step <= steps; step++)
            {
                auto plotX = cast(size_t) x;
                auto plotY = cast(size_t) y;

                if (plotX < graphWidth && plotY < height)
                {
                    if (abs(xIncrement) > abs(yIncrement))
                        grid[plotY][plotX] = '─';
                    else if (abs(yIncrement) > abs(xIncrement))
                        grid[plotY][plotX] = '│';
                    else
                        grid[plotY][plotX] = '●';
                }

                x += xIncrement;
                y += yIncrement;
            }
        }

        foreach (i, value; data)
        {
            auto x = cast(size_t)((cast(double) i / (cast(int) data.length - 1)) * (graphWidth - 1));
            auto y = cast(size_t)((1.0 - (value - minVal) / range) * (height - 1));

            if (x < graphWidth && y < height)
            {
                grid[y][x] = '●';
            }
        }

        foreach (y; 0 .. height)
        {
            if (showYAxis)
            {
                if (y == 0)
                    writef("%*s ", yAxisWidth - 1, format("%.1f", maxVal));
                else if (y == height - 1)
                    writef("%*s ", yAxisWidth - 1, format("%.1f", minVal));
                else if (y == height / 2)
                    writef("%*s ", yAxisWidth - 1, format("%.1f", (maxVal + minVal) / 2));
                else
                    writef("%*s ", yAxisWidth - 1, "");
            }

            foreach (x; 0 .. graphWidth)
            {
                wchar ch = grid[y][x];
                if (ch == '●' || ch == '─' || ch == '│')
                    write(colorize(ch.to!string, lineColor));
                else if (showGrid && (ch == '┼' || ch == '─' || ch == '│'))
                    write(colorize(ch.to!string, gridColor));
                else
                    write(ch);
            }
            writeln;
        }

        if (xLabels.length > 0)
        {
            if (showYAxis)
                write(" ".replicate(yAxisWidth));

            auto labelStep = max(1, graphWidth / min(xLabels.length, 8));

            foreach (i; 0 .. min(xLabels.length, graphWidth / 8))
            {
                auto pos = i * labelStep;
                if (pos < graphWidth && i < xLabels.length)
                {
                    if (i > 0)
                        write(" ".replicate(labelStep - xLabels[i - 1].length));
                    write(colorize(xLabels[i], Color.BRIGHT_BLACK));
                }
            }

            writeln;
        }

        writeln;
    }

    /** 
     * Draw a pie chart using ASCII characters.
     *
     * Params:
     *   labels = Labels for each slice
     *   values = Values for each slice
     *   radius = Radius of the pie chart
     *   title = Optional title for the chart
     *   showLegend = Whether to show legend with percentages
     *   colors = Array of colors for each slice (cycles if fewer than slices)
     */
    /** 
 * Draw a pie chart using ASCII characters.
 *
 * Params:
 *   labels = Labels for each slice
 *   values = Values for each slice
 *   radius = Radius of the pie chart
 *   title = Optional title for the chart
 *   showLegend = Whether to show legend with percentages
 *   colors = Array of colors for each slice (cycles if fewer than slices)
 */
    static void drawPieChart(
        string[] labels,
        double[] values,
        size_t radius = 10,
        string title = "",
        bool showLegend = true,
        Color[] colors = []
    )
    {
        import std.math : PI, cos, sin, atan2, sqrt;
        import std.conv;

        if (labels.length == 0 || values.length == 0 || labels.length != values.length)
            return;

        if (colors.length == 0)
        {
            colors = [
                Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW,
                Color.MAGENTA, Color.CYAN, Color.BRIGHT_RED, Color.BRIGHT_GREEN
            ];
        }

        if (title.length > 0)
        {
            writeln(colorize(title, Color.BRIGHT_WHITE));
            drawSeparator("─", title.length, Color.BRIGHT_BLACK);
        }

        auto totalValue = values.sum;
        if (totalValue <= 0)
            return;

        double[] angles = new double[values.length + 1];
        angles[0] = 0;
        foreach (i, value; values)
        {
            angles[i + 1] = angles[i] + (value / totalValue) * 2 * PI;
        }

        auto size = radius * 2 + 1;
        wchar[][] grid = new wchar[][](size, size * 2);
        foreach (ref row; grid)
        {
            row[] = ' ';
        }

        auto centerX = radius;
        auto centerY = radius;

        foreach (y; 0 .. size)
        {
            foreach (x; 0 .. size * 2)
            {
                auto dx = (cast(double) x / 2.0) - centerX;
                auto dy = cast(double) y - centerY;
                auto distance = sqrt(dx * dx + dy * dy);

                if (distance <= radius)
                {
                    auto angle = atan2(dy, dx);
                    if (angle < 0)
                        angle += 2 * PI;

                    // Find which slice this point belongs to
                    foreach (i; 0 .. values.length)
                    {
                        if (angle >= angles[i] && angle < angles[i + 1])
                        {
                            auto colorIndex = i % colors.length;

                            // Use different characters for different slices
                            wchar[] chars = [
                                '█', '▓', '▒', '░', '▪', '▫', '■',
                                '□'
                            ];
                            auto charIndex = i % chars.length;
                            grid[y][x] = chars[charIndex];
                            break;
                        }
                    }
                }
            }
        }
        foreach (y; 0 .. size)
        {
            foreach (x; 0 .. size * 2)
            {
                wchar ch = grid[y][x];
                if (ch != ' ')
                {
                    int sliceIndex = -1;
                    auto dx = (cast(double) x / 2.0) - centerX;
                    auto dy = cast(double) y - centerY;
                    auto distance = sqrt(dx * dx + dy * dy);

                    if (distance <= radius)
                    {
                        auto angle = atan2(dy, dx);
                        if (angle < 0)
                            angle += 2 * PI;

                        foreach (i; 0 .. values.length)
                        {
                            if (angle >= angles[i] && angle < angles[i + 1])
                            {
                                sliceIndex = cast(int) i;
                                break;
                            }
                        }
                    }

                    if (sliceIndex >= 0)
                    {
                        auto colorIndex = sliceIndex % colors.length;
                        write(colorize(ch.to!string, colors[colorIndex]));
                    }
                    else
                    {
                        write(ch);
                    }
                }
                else
                {
                    write(' ');
                }
            }
            writeln;
        }

        writeln;

        if (showLegend)
        {
            drawSeparator("─", 40, Color.BRIGHT_BLACK);
            auto maxLabelWidth = labels.map!(l => l.length).maxElement;

            foreach (i, label; labels)
            {
                auto percentage = (values[i] / totalValue) * 100;
                auto colorIndex = i % colors.length;
                wchar[] chars = [
                    '█', '▓', '▒', '░', '▪', '▫', '■', '□'
                ];
                auto charIndex = i % chars.length;
                string indicator = colorize(chars[charIndex].to!string
                        ~ chars[charIndex].to!string, colors[colorIndex]);
                writef("%s %-*s │ %6.1f%% │ %8.2f\n",
                    indicator,
                    maxLabelWidth,
                    label,
                    percentage,
                    values[i]
                );
            }
            drawSeparator("─", 40, Color.BRIGHT_BLACK);
        }
    }
}
