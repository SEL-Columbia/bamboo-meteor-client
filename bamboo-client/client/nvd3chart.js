/*
dataset = [
	{	key: "Bar Chart of Sex",
		values: [ {"label" : "M", "value" : 6 }, {"label" : "F", "value" : 8 }]}
];
*/

nvd3BarChart = function (dataElement, div) {
/*    var dataElement = {data: {F:8, M:6}, groupKey: "", groupVal: "", name: "sex"};
*/
    var str = "Bar Chart of " + dataElement.name;

    var arr = [];
    for (var key in dataElement.data) {
        arr.push( { label : key, value : dataElement.data[key]});
    }

    var dataset = [ { key : str, values: arr }];

    nv.addGraph(function() {  
      var width = 400, height = 250;
      var chart = nv.models.discreteBarChart()
            .width(width)
            .height(height)
          .x(function(d) { return d.label })
          .y(function(d) { return d.value })
          .rotateLabels(-45)
          .staggerLabels(true)
          //.staggerLabels(historicalBarChart[0].values.length > 8)
          .tooltips(false)
          .showValues(true)

      d3.select(div)
          .datum(dataset)
        .transition().duration(500)
          .call(chart);

      nv.utils.windowResize(chart.update);

      return chart;
});

}
