module ark.graphs;

template ArkGraphs()
{
    static void drawLineGraph(
        double[] data,
        size_t width = 60,
        size_t height = 20,
        string title = "",
        string[] xLabels = [],
        bool showGrid = true,
        Color lineColor = Color.CYAN,
        Color gridColor = Color.BRIGHT_BLACK,
        bool showYAxis = true,
        bool scatter = false
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

        if (!scatter)
        {
            for (size_t i = 0; i < cast(int) data.length - 1; i++)
            {
                auto x1 = cast(size_t)((cast(double) i / (cast(int) data.length - 1)) * (
                        graphWidth - 1));
                auto x2 = cast(size_t)(
                    (cast(double)(i + 1) / (cast(int) data.length - 1)) * (graphWidth - 1));
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

    static void drawFlowDiagram(
        FlowNode[] nodes,
        FlowConnection[] connections,
        size_t width = 80,
        size_t height = 20,
        Color boxColor = Color.CYAN,
        Color arrowColor = Color.BRIGHT_BLACK
    )
    {
        if (nodes.length == 0)
            return;

        auto grid = new string[][](height, width);
        foreach (ref row; grid)
        {
            row[] = " ";
        }

        foreach (ref node; nodes)
        {
            if (node.width == 0)
                node.width = max(node.text.length + 4, 8);
        }

        foreach (conn; connections)
        {
            auto fromNode = nodes.find!(n => n.id == conn.fromId);
            auto toNode = nodes.find!(n => n.id == conn.toId);

            if (fromNode.empty || toNode.empty)
                continue;

            auto from = fromNode[0];
            auto to = toNode[0];

            drawFlowGraphConnection(grid, from, to, conn.direction, width, height);
        }

        foreach (node; nodes)
        {
            drawFlowGraphBox(grid, node, width, height);
        }

        foreach (y; 0 .. height)
        {
            string line = "";
            foreach (x; 0 .. width)
            {
                string cell = grid[y][x];

                if (cell == "┌" || cell == "┐" || cell == "└" || cell == "┘" ||
                    cell == "│" || cell == "─")
                {
                    line ~= colorize(cell, boxColor);
                }
                else if (cell == "→" || cell == "↓" || cell == "←" || cell == "↑" ||
                    cell == "┼" || cell == "┬" || cell == "┴" || cell == "├" || cell == "┤")
                {
                    line ~= colorize(cell, arrowColor);
                }
                else
                {
                    line ~= cell;
                }
            }
            writeln(line);
        }
    }

    private static void drawFlowGraphBox(string[][] grid, FlowNode node, size_t maxWidth, size_t maxHeight)
    {
        size_t boxHeight = 3;

        if (node.x >= maxWidth || node.y >= maxHeight ||
            node.x + node.width >= maxWidth || node.y + boxHeight >= maxHeight)
            return;

        grid[node.y][node.x] = "┌";

        foreach (i; 1 .. node.width - 1)
            grid[node.y][node.x + i] = "─";

        grid[node.y][node.x + node.width - 1] = "┐";
        grid[node.y + 1][node.x] = "│";

        size_t textStart = node.x + 1 + (node.width - 2 - node.text.length) / 2;

        foreach (i, c; node.text)
        {
            if (textStart + i < node.x + node.width - 1)
                grid[node.y + 1][textStart + i] = [c];
        }
        foreach (i; 1 .. node.width - 1)
        {
            if (grid[node.y + 1][node.x + i] == " ")
                grid[node.y + 1][node.x + i] = " ";
        }

        grid[node.y + 1][node.x + node.width - 1] = "│";
        grid[node.y + 2][node.x] = "└";

        foreach (i; 1 .. node.width - 1)
            grid[node.y + 2][node.x + i] = "─";

        grid[node.y + 2][node.x + node.width - 1] = "┘";
    }

    private static void drawFlowGraphConnection(
        string[][] grid,
        FlowNode from,
        FlowNode to,
        string direction,
        size_t maxWidth,
        size_t maxHeight
    )
    {
        size_t fromX, fromY, toX, toY;

        switch (direction)
        {
        case "down":
            fromX = from.x + from.width / 2;
            fromY = from.y + 3;
            toX = to.x + to.width / 2;
            toY = to.y;
            break;
        case "right":
            fromX = from.x + from.width;
            fromY = from.y + 1;
            toX = to.x;
            toY = to.y + 1;
            break;
        case "up":
            fromX = from.x + from.width / 2;
            fromY = from.y;
            toX = to.x + to.width / 2;
            toY = to.y + 3;
            break;
        case "left":
            fromX = from.x;
            fromY = from.y + 1;
            toX = to.x + to.width;
            toY = to.y + 1;
            break;
        default:
            return;
        }

        if (direction == "down" || direction == "up")
        {
            size_t startY = min(fromY, toY);
            size_t endY = max(fromY, toY);

            if (fromX < maxWidth)
            {
                foreach (y; startY .. endY)
                {
                    if (y < maxHeight && grid[y][fromX] == " ")
                        grid[y][fromX] = "│";
                }
                if (direction == "down" && toY < maxHeight && toX < maxWidth)
                    grid[toY][toX] = "↓";
                else if (direction == "up" && toY < maxHeight && toX < maxWidth)
                    grid[toY][toX] = "↑";
            }
        }
        else if (direction == "right" || direction == "left")
        {
            size_t startX = min(fromX, toX);
            size_t endX = max(fromX, toX);

            if (fromY < maxHeight)
            {
                foreach (x; startX .. endX)
                {
                    if (x < maxWidth && grid[fromY][x] == " ")
                        grid[fromY][x] = "─";
                }
                if (direction == "right" && toY < maxHeight && toX < maxWidth)
                    grid[toY][toX] = "→";
                else if (direction == "left" && toY < maxHeight && toX < maxWidth)
                    grid[toY][toX] = "←";
            }
        }
    }

}
