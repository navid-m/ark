module ark.components;

mixin template ArkComponents()
{
    import ark.foundation;
    import ark.charts;
    import ark.graphs;

    mixin ark.foundation.FoundationComponents!();
    mixin ark.charts.ArkCharts!();
    mixin ark.graphs.ArkGraphs!();
}
