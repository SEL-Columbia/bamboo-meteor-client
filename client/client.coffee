root = global ? window
bambooUrl = "/"
observationsUrl = bambooUrl + "datasets"

if root.Meteor.is_client
    populate = (u)->
        dataset = Datasets.find({url: u}).fetch()[0]
        ida = dataset.id
        summary = dataset.summary
        name_list =_(summary["(ALL)"]).pluck("name")

    


    root.Template.maincontent.columns = ->
        u = "http://formhub.org/education/forms/schooling_status_format_18Nov11/data.csv"
        console.log 'data count: ' + Datasets.find({url:u}).count()
        data = Datasets.findOne({url:u})
        if data
            summary = data.summary
            name_list =_(summary["(ALL)"]).pluck("name")
        name_list

    root.Template.navbar.events = "click button": ->
        url = $('#datasource-url').val()
        ###
        #logic: separate cached and uncahced case for 
        #setTimeout beceause it does take time for bamboo
        #to populate the result into the database
        ###
        if !(Datasets.find(url:url).count())
            console.log "caching..."
            Meteor.call('register_dataset', url)
            setTimeout populate(url), 2000
        else
            console.log "cahced"
            populate(url)



Meteor.methods(
    make_chart: (obj) ->
        [div, dataElement] = obj
        #dataElement.titleName = makeTitle(dataElement.name)
        dataElement.titleName = "testing"
        data = dataElement.data
        console.log data
        dataSize = _.size(data)

        unless (dataSize is 0) or (dataElement.name.charAt(0) is '_')
            keyValSeparated =
                x: _.keys(data)
                y: _.values(data)
            if typeof keyValSeparated.y[0] is "number"
                #if number make pure histogram
                #histogram logic
                gg.graph(keyValSeparated).layer(gg.layer.bar().map('x','x').map('y','y')).opts(
                    width: Math.min(dataSize*60 + 100, 550)
                    height: "270"
                    "padding-right": "50"
                    title: dataElement.titleName
                    "title-size":12
                    "legend-position":"bottom"
                ).render(div)

    charting: (url) ->
        item_list = Datasets.findOne({url:url}).summary["(ALL)"]
        for item in item_list
            item_name = item["name"]
            div = "#"+item["name"]+".gg"
            Meteor.call("make_chart",[div,item])

)
