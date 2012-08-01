nvd3BarChart = (dataElement, div) ->
    str = "Bar Chart of " + dataElement.name
    arr = []
    for key of dataElement.data
        arr.push( { label : key, value : dataElement.data[key]})
    dataset = [ { key : str, values: arr }]

    nv.addGraph( () ->
        width = 400
        height = 250
        chart = nv.models.discreteBarChart()
            .width(width)
            .height(height)
            .x( (d)->
                d.label
            )
            .y( (d)->
                d.value
            )
            .rotateLabels(-45)
            .staggerLabels(true)
            .tooltips(false)
            .showValues(true)
    
        d3.select(div)
            .append("svg")
            .attr("width", 400)
            .attr("height", 250)
            .datum(dataset)
            .transition().duration(500)
            .call(chart)

        nv.utils.windowResize(chart.update)

        return chart

        return
    )
