module ark.charts;

template ArkCharts()
{
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
     * Draw a horizontal breakdown chart.
     *
     * Params:
     *   labels      = Labels for each category
     *   values      = Values for each category
     *   width       = Total width of the breakdown bar
     *   title       = Optional title for the chart
     *   colors      = Colors for each category 
     *   legendStyle = DOT or TABLE format
     */
    static void drawBreakdownChart(
        string[] labels,
        double[] values,
        size_t width = 60,
        string title = "",
        Color[] colors = [],
        LegendStyle legendStyle = LegendStyle.DOT
    )
    {
        import std.algorithm : sum, maxElement, map;

        if (labels.length == 0 || values.length == 0 || labels.length != values.length)
            return;

        if (colors.length == 0)
        {
            colors = [
                Color.RED, Color.GREEN, Color.YELLOW, Color.BLUE, Color.MAGENTA,
                Color.CYAN, Color.BRIGHT_RED, Color.BRIGHT_GREEN,
                Color.BRIGHT_YELLOW
            ];
        }

        auto total = values.sum;
        if (total == 0)
            return;

        if (title.length > 0)
        {
            drawSeparator("─", title.length, Color.BRIGHT_BLACK);
            writeln(colorize(title, Color.BRIGHT_WHITE));
            drawSeparator("─", title.length, Color.BRIGHT_BLACK);
        }

        size_t[] segments;
        double[] proportions;

        foreach (val; values)
        {
            double pct = val / total;
            proportions ~= pct;
            segments ~= cast(size_t)(pct * width);
        }

        size_t used = segments.sum;
        if (used < width)
            segments[segments.maxIndex] += width - used;

        foreach (i, seg; segments)
        {
            string block = "█".replicate(seg);
            write(colorize(block, colors[i % colors.length]));
        }

        writeln;
        drawSeparator("─", width, Color.BRIGHT_BLACK);
        if (legendStyle == LegendStyle.TABLE)
        {
            auto labelWidth = labels.map!(l => l.length).maxElement;
            foreach (i, label; labels)
            {
                auto percentage = proportions[i] * 100;
                string sample = colorize("██", colors[i % colors.length]);
                writef("%s %-*s │ %5.1f%% │ %8.2f\n",
                    sample, labelWidth, label, percentage, values[i]
                );
            }
        }
        else if (legendStyle == LegendStyle.DOT)
        {
            foreach (i, label; labels)
            {
                auto pct = proportions[i] * 100;
                string dot = colorize("●", colors[i % colors.length]);
                writef("%s %s %.1f%% ", dot, label, pct);
            }
        }
        writeln;
        drawSeparator("─", width, Color.BRIGHT_BLACK);
    }

    /** 
     * Draw a pie chart.
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
        size_t radius = 12,
        string title = "",
        bool showLegend = true,
        Color[] colors = []
    )
    {
        import std.math : PI, cos, sin, atan2, sqrt;
        import std.algorithm : sum, maxElement;
        import std.conv : to;
        import std.stdio : writeln, write;
        import std.range : iota;

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
                auto dx = (cast(double) x / 2.2) - centerX;
                auto dy = cast(double) y - centerY;
                auto distance = sqrt(dx * dx + dy * dy);

                if (distance <= radius)
                {
                    auto angle = atan2(dy, dx);
                    if (angle < 0)
                        angle += 2 * PI;

                    foreach (i; 0 .. values.length)
                    {
                        if (angle >= angles[i] && (i == cast(int) values.length - 1 || angle < angles[i + 1]))
                        {
                            wchar ch;
                            if (distance > radius - 0.6)
                            {
                                double quadrant = angle / (PI / 2);
                                int q = cast(int) quadrant;
                                ch = ['◜', '◝', '◞', '◟'][q % 4];
                            }
                            else
                                ch = '●';
                            grid[y][x] = ch;
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
                    auto dx = (cast(double) x / 2.2) - centerX;
                    auto dy = cast(double) y - centerY;
                    auto distance = sqrt(dx * dx + dy * dy);
                    if (distance <= radius)
                    {
                        auto angle = atan2(dy, dx);
                        if (angle < 0)
                            angle += 2 * PI;

                        foreach (i; 0 .. values.length)
                        {
                            if (angle >= angles[i] && (i == cast(int) values.length - 1 || angle < angles[i + 1]))
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
                string indicator = colorize("●●", colors[colorIndex]);
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
}
