
nvd3StackedBarChart = (item_list, div, min, max) ->
    # in datasetObj, we'll flip inner keys and outer keys 
    datasetObj = {}
    allOuterKeys = _(item_list).pluck('groupVal')
    allInnerKeys = _(item_list).chain().pluck('data').map((d) -> _.keys(d)).flatten().uniq().value()
    for ki in allInnerKeys
        datasetObj[ki] = {}
        (datasetObj[ki][ko] = 0 for ko in allOuterKeys)
    for item in item_list
        _.each(item.data, (val, key) ->
            datasetObj[key][item.groupVal] = val
        )
    # now transform datasetObj (map) to dataset (array); dataset schema = from nvd3
    dataset = []
    _.each(datasetObj, (val, key) ->
        dataset.push
            key: key
            values: _.map(val, (val2, key2) ->
                x: key2
                y: val2
            )
    )
    # we have the dataset, now ready to graph
    
    title = item_list[0].name
    nv.addGraph( () -> 
        width = 300
        height = 250
        chart = nv.models.multiBarChart()
            .margin({top: 30, right: 10, bottom:150, left: 60})
            .rotateLabels(-45)

        svg = d3.select(div)
            .append("svg")
            .attr("class", "barChartSVG")

        # show the graph, with a slight animation
        svg.datum(dataset)
            .transition().duration(500)
            .call(chart)
        #TODO:what does this line do?
        nv.utils.windowResize(chart.update)

        return chart

        return
    )

nvd3BarChart = (dataElement, div, min, max) ->
    count = 0
    str = "Bar Chart of " + dataElement.name
    arr = []
    for key of dataElement.data
        count += dataElement.data[key]
    for key of dataElement.data
        arr.push
            label : key
            value : dataElement.data[key]
            percentage : Math.round(dataElement.data[key] * 100 / count) + "%"
            
    dataset = [ { key : str, values: arr }]
    
    if (dataElement.groupKey is "") and (dataElement.groupVal is "")
        title = dataElement.name + " (" + count + ")"
    else
        title = dataElement.groupKey + " : " + dataElement.groupVal + " (" + count + ")"

    nv.addGraph( () ->
        width = 300
        height = 250
        chart = nv.models.discreteBarChart()
            .width(width)
            .height(height)
            #change the margin
            .margin({top:30, right:10, bottom:50, left:60})
            .x( (d)->
                d.label
            )
            .y( (d)->
                d.value
            )
            .rotateLabels(-45)
            .staggerLabels(true)
            .tooltips(true)
            .tooltipContent((key, x, y, e, graph)->
                for item in e.series.values
                    if item.label is x
                        per = item.percentage
                return '<h3>' + x + '</h3>' + '<p>' +  y + '</p>' + '<p>' + per + '</p>'
            )
            .showValues(false)
            .forceY([min, max])

        chart.yAxis.tickFormat(d3.format(',d'))

        svg = d3.select(div)
            .append("svg")
            .attr("class", "barChartSVG")

        svg.append("text")
            .text(title)
            .attr("x", 130)
            .attr("y", 12)
            .attr("class", "boxplot_title")
            .attr("fill", "black")
            .attr("font-family", "Helvetica")
            .attr("font-size", "15px")
            .attr("font-weight", "bold")

        # show the graph, with a slight animation
        svg.datum(dataset)
            .transition().duration(500)
            .call(chart)
        #TODO:what does this line do?
        nv.utils.windowResize(chart.update)

        return chart

        return
    )
