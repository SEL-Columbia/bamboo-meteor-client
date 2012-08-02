mock_element =
    name:"birthrate"
    groupVal:"sexywomen"
    groupKey:"attractiveness"
    datasetURL:"http://google.com"
    data:
        blonde:3
        brunette:5
        redhead:18
        ariana:10
        peter:28


mock_element_2 =
    name:"birthrate"
    groupVal:"sexywomen"
    groupKey:"attractiveness"
    datasetURL:"http://google.com"
    data:
        count:14
        min:10
        max:20
        "25%":12
        "50%":15
        "75%":19
        std: 1.17
        mean:16

#it will take a dataset object and reder svg graph out of it
data_massage = (data)->
    massaged = []
    $.each data, (k, v)->
        if typeof v is "string"
            return
        massaged.push({key:k,value:v})
    massaged

Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1
maxing = (data) ->
    values = _.values(data)
    for elem in values
        if typeof elem is 'string'
            values.remove(elem)
    _.max(values)

mining = (data) ->
    values = _.values(data)
    for elem in values
        if typeof elem is 'string'
            values.remove(elem)
    _.min(values)


#div is <div>location on the html page
d3chart = (dataElement,div)->
    alert "enter"
    data = dataElement.data
    display = ['min','25%','50%','75%','max']
    keys = _.keys(data)
    box_flag = true
    for item in display
        if item not in keys
            box_flag = false
    str = ""
    if dataElement.groupVal is ""
        str = "" + dataElement.name
    else
        str = "" + dataElement.name + "grouped by " + dataElement.groupVal
    console.log str
    if box_flag is true
        Session.set("titles", "Box Plot of " + str)
        boxplot(dataElement,div)
    else
        Session.set("titles", "Bar Chart of " + str)
        barchart(dataElement,div)

barchart= (dataElement, div, min, max)->
    
    if dataElement.groupKey is ""
        str = "" + dataElement.name
    else
        str = "" + dataElement.name + " grouped by " + dataElement.groupKey
    Session.set("titles", "Bar Chart of " + str)
   
    console.log dataElement

    name = dataElement.name
    data = data_massage(dataElement.data)
    font = 10
    ###
    name_max = _.max(_.map(_.keys(dataElement.data), (word)->
        word.length
    ))
    
    width = _.max([name_max*font*data.length,200])
    height = width*0.75
    bar_width = (width-x_padding) / data.length
    y_ele_max = _.max([name_max*font,bar_width])
    bar_padding = _.max([name_max*font-bar_width,2])
    ###
    
    width = 300
    height = 200
    y_padding = 20
    x_padding = 20
    bar_padding = 2
    svg = d3.select(div)
            .append('svg:svg')
            .attr('width', width)
            .attr('height',height)
    

    #domain maps to range pixels
    #i.e. if you have a data of 20 it appears to be 100px

    y_scale = d3.scale.linear()
                .domain([0,max])
                .range([height - y_padding,  y_padding])

    x_scale = d3.scale.linear()
                .domain([0, data.length])
                .range([x_padding, width - x_padding])

    tick= 5
    tick_num = tick
    
    linearr = []
    for i in [1...(tick_num+1)]
        linearr.push(height - y_padding - (height - 2*y_padding)/max * Math.floor(max/tick_num) * i)
    linearr.push(y_padding)
    console.log linearr

    svg.selectAll("line")
        .data(linearr)
        .enter().append("line")
        .style("stroke", "grey")
        .style("stroke-width", "1px")
        .attr("x1", x_padding)
        .attr("x2", width - x_padding)
        .attr("y1", (d) -> d)
        .attr("y2", (d) -> d)

    svg.selectAll('rect')
        .data(data)
        .enter()
        .append('rect')
        .attr('x',(d,i)->
            #       x_scale i*(width/data.length)
            w = (width-x_padding*2) / data.length - bar_padding
            if ( w > 30 )
               (w - 30)/2 +  x_padding + bar_padding + (width - 2*x_padding) / data.length * i
            else
                x_padding + bar_padding + (width - 2*x_padding) / data.length * i
        )
        .attr('y',(d)->
            y_scale d.value
        )
        .attr('width',(d)->
            w = (width-2*x_padding) / data.length - bar_padding
            if ( w > 30 )
                w = 30
            w
        )
        .attr('height',(d)->
            height - y_padding - y_scale d.value
        )
        .style('fill', 'rgba(46, 139, 87, 0.7)')
        .on('mouseover', (d)->
            d3.select(this)
                .style('fill','seagreen')
                #add the name of the bar
            posx = this.x.animVal.value + x_padding
            if posx + 100 > width
                posx = width - 100
            g = svg.append('g')
            g.append('rect')
                .attr('x', posx)
                .attr('y', this.y.animVal.value - y_padding)
                .attr('width', '100')
                .attr('height', '50')
                .attr('fill', 'white')
                .attr('class', 'borderset')
            g.append('text')
                .text(d.key + ":" + d.value)
                .attr("font-size", "12px")
                .attr('x', posx)
                .attr('y', this.y.animVal.value)

        )
        .on('mouseout', ->
            d3.select(this.parentNode.lastChild).remove()
            d3.select(this)
                .style('fill', 'rgba(46, 139, 87, 0.7)')
        )

    ###
    svg.selectAll('text')
        .data(data)
        .enter().append('text')
        .text((d)->
            if typeof d.value is 'string'
                d.value
            else
                d.value.toFixed(2)
        )
        .attr("x", (d, i) ->
            x_scale i*(width/data.length)
        )
        .attr("y", (d)->
            y_scale(d.value)+y_padding
        )
        .attr("font-family", "Monospace")
        .attr("font-size", y_padding)
        .attr("fill", "white")

    svg.selectAll('text.yAxis')
        .data(data)
        .enter().append('text')
        .text((d)->
            d.key
        )
        .attr("x", (d, i) ->
            x_scale i*(width/data.length)
        )
        .attr("y", height)
        .attr("font-family", "Monospace")
        .attr("font-size", font.toString + "px")
        .attr("fill", "black")
    ###

    svg.append("g")
        .attr("transform", "translate(0, " + (height-y_padding) + ")")
        .attr("fill", "none")
        .attr("stroke", "black")
        .attr("shape-rendering", "crispEdges")
        .attr("font-family", "Helvetica, sans-serif")
        .attr("font-size", "8px")
        .call(d3.svg.axis().scale(x_scale).orient("bottom").ticks(data.length))

    svg.append("text")
        .text("Amount")
        .attr("x", "0")
        .attr("y", y_padding/2)
        .attr("font-family", "Monospace")
        .attr("font-size", "15px")
        .attr("fill", "black")

    y_axis = d3.svg.axis()
                .scale(y_scale)
                .orient("left")
                .ticks(tick)

    svg.append("g")
        .attr("transform", "translate(" + x_padding + ", 0)")
        .attr("fill", "none")
        .attr("stroke", "black")
        .attr("shape-rendering", "crispEdges")
        .attr("font-family", "Helvetica, sans-serif")
        .attr("font-size", "8px")
        .call(y_axis)
                
boxplot= (dataElement, div, min, max)->
    console.log "box plot a a a enter"
    name = dataElement.name
    data = dataElement.data
    if data.count is 1
        console.log "data.count is one"
        display_name = dataElement.groupVal
        display_value = dataElement.data.min
        dataElement.data = {}
        dataElement.data[display_name]=display_value
        return nvd3BarChart(dataElement, div)
    

    y_padding = 20
    x_padding = 20
    font = 10
    display = ['min','25%','50%','75%','max']
    
    width = 200
    height = width * 1.5

    console.log div
    svg = d3.select(div)
            .append('svg:svg')
            .attr('class', 'boxPlotSVG')
            
    y_scale = d3.scale.linear()
		        .domain([min, max])
		        .range([height-y_padding, y_padding])

    y_axis = d3.svg.axis()
                .scale(y_scale)
                .orient("left")
                .ticks(5)

    svg.append("text")
        .text(name)
        .attr("x", "0")
        .attr("y", y_padding/2)
        .attr("font-family", "Monospace")
        .attr("font-size", "15px")
        .attr("fill", "black")

    svg.append("text")
        .text(dataElement.groupVal)
        .attr('x', width/3)
        .attr('y', height)
        .attr("font-family", "Monospace")
        .attr("font-size", 15 + "px")
        .attr("fill", "black")

    svg.selectAll("text")
        .data(data_massage(data))
        .enter().append("text")
        .text((d)->
            if d.key in display
                d.value.toString()
        )
        .attr('x', width/6*5)
        .attr('y',(d)->
            y_scale d.value
        )
        .attr("font-size", font.toString()+"px")
        .attr("fill","black")

    svg.append("line")
        .style("stroke", "rgba(46, 139, 87, 0.7)")
        .style("stroke-width", "5px")
        .attr("x1", width / 6)
        .attr("y1", y_scale(data["50%"]))
        .attr("x2", width / 6 * 5)
        .attr("y2", y_scale(data["50%"]))

    svg.append("line")
        .style("stroke", "black")
        .style("stroke-width", "4px")
        .attr("x1", width / 4)
        .attr("y1", y_scale(data["25%"]))
        .attr("x2", width / 4 * 3)
        .attr("y2", y_scale(data["25%"]))

    svg.append("line")
        .style("stroke", "black")
        .style("stroke-width", "4px")
        .attr("x1", width / 4)
        .attr("y1", y_scale(data["75%"]))
        .attr("x2", width / 4 * 3)
        .attr("y2", y_scale(data["75%"])) 
    
    svg.append("line")
        .style("stroke", "black")
        .style("stroke-width", "3px")
        .attr("x1", width / 2)
        .attr("y1", y_scale(data.min))
        .attr("x2", width / 2)
        .attr("y2", y_scale(data.max))

    svg.append("line")
        .style("stroke", "black")
        .style("stroke-width", "1px")
        .attr("x1", width / 6 * 2)
        .attr("y1", y_scale(data.min))
        .attr("x2", width / 6 * 4)
        .attr("y2", y_scale(data.min))
   
    svg.append("line")
        .style("stroke", "black")
        .style("stroke-width", "1px")
        .attr("x1", width / 6 * 2)
        .attr("y1", y_scale(data.max))
        .attr("x2", width / 6 * 4)
        .attr("y2", y_scale(data.max))

    svg.append("rect")
        .attr("x", width / 4)
        .attr("y", y_scale(data["75%"]))
        .attr("width", width / 2)
        .attr("height", y_scale(data["25%"]) - y_scale(data["75%"]))
        .style("fill", "rgba(250, 128, 114, 0.7)")
    
    svg.append("g")
        .attr("transform", "translate(" + width / 6  + ", 0)")
        .attr("fill", "none")
        .attr("stroke", "black")
        .attr("shape-rendering", "crispEdges")
        .style("font-family", "sans-serif")
        .style("font-size", "11px")
        .call(y_axis)
    ""


