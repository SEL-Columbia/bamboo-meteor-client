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

#div is <div>location on the html page
barchart= (dataElement,div)->
    name = dataElement.name
    data = data_massage(dataElement.data)
    y_padding = 15
    x_padding = 20
    font = 10
    max = maxing(dataElement.data)
    
    name_max = _.max(_.map(_.keys(dataElement.data), (word)->
        word.length
    ))
    width = _.max([name_max*font*data.length,200])
    height = width*0.75
    bar_width = (width-x_padding) / data.length
    y_ele_max = _.max([name_max*font,bar_width])
    bar_padding = _.max([name_max*font-bar_width,2])

    svg = d3.select(div)
            .append('svg:svg')
            .attr('width', width)
            .attr('height',height)
    

    #domain maps to range pixels
    #i.e. if you have a data of 20 it appears to be 100px

    y_scale = d3.scale.linear()
                .domain([0,max])
                .range([height - y_padding, 0])


    x_scale = d3.scale.linear()
                .domain([0,width])
                .range([x_padding, width])

    svg.selectAll('rect')
        .data(data)
        .enter()
        .append('rect')
        .attr('x',(d,i)->
           x_scale i*(width/data.length)
        )
        .attr('y',(d)->
            y_scale d.value
        )
        .attr('width',(d)->
            (width-x_padding) / data.length - bar_padding
        )
        .attr('height',(d)->
            height - y_padding - y_scale d.value
        )
        .style('fill', 'SeaGreen')
        .on('mouseover', ->
            d3.select(this)
                .style('fill','rgba(46, 139, 87, 0.7)')
        )
        .on('mouseout', ->
            d3.select(this)
                .style('fill', 'SeaGreen')
        )

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


    y_axis = d3.svg.axis()
                .scale(y_scale)
                .orient("left")
                .ticks(5)

    svg.append("g")
        .attr("transform", "translate(" + x_padding + ", 0)")
        .attr("fill", "none")
        .attr("stroke", "black")
        .attr("shape-rendering", "crispEdges")
        .attr("font-family", "Helvetica, sans-serif")
        .attr("font-size", "10px")
        .call(y_axis)
                
boxplot= (dataElement, div)->
    console.log "enter"
    name = dataElement.name
    data = dataElement.data
    y_padding = 15
    x_padding = 20
    font = 10
    max = maxing(dataElement.data)
    display = ['min','25%','50%','75%','max']
    
    width = 200
    height = width*1.5

    svg = d3.select(div)
            .append('svg:svg')
            .attr('width', width)
            .attr('height',height)
            
    y_scale = d3.scale.linear()
		        .domain([data.min, data.max])
		        .range([height-y_padding, y_padding])

    y_axis = d3.svg.axis()
                .scale(y_scale)
                .orient("left")
                .ticks(5)

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


