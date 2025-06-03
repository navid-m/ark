module ark.components;

mixin template ArkComponents()
{
    import ark.foundations;
    import ark.charts;
    import ark.graphs;

    mixin ark.foundations.ArkFoundationComponents!();
    mixin ark.charts.ArkCharts!();
    mixin ark.graphs.ArkGraphs!();
}
