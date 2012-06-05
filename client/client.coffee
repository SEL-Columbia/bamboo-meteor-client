root = global ? window
bambooUrl = "/"
observationsUrl = bambooUrl + "datasets"

constants =
    #defaultURL : 'http://localhost:8000/education/forms/schooling_status_format_18Nov11/data.csv'
    defaultURL : 'http://formhub.org/education/forms/schooling_status_format_18Nov11/data.csv'

############ UI LOGIC ############################
if root.Meteor.is_client
    root.Template.navbar.events = "click button": ->
        url = $('#datasource-url').val()
        Session.set('currentDatasetURL', url)
        #TODO: put the following in a Meteor.subscribe section?
        #TODO: eliminates null url from being registered into db
        if !Datasets.findOne(url: url)
            console.log "caching server side.."
            Meteor.call('register_dataset', url)
        else
            console.log "already cached server side.."

    root.Template.control.events = "click button": ->
        Meteor.call("charting")

    root.Template.control.groups = ->
        url = Session.get('currentDatasetURL')
        group = Session.get('currentGroup')
        datacursor = Summaries.find(datasetSourceURL: url, groupKey: group, groupVal: '(ALL)')
        _(datacursor.fetch()).pluck("name")

    root.Template.group.events = "click button": ->
       group = this
       Session.set('currentGroup',group)
       url = Session.get('currentDatasetURL')
       Meteor.call("summarize_by_group",[url,group])

    root.Template.maincontent.columns = ->
        url = Session.get('currentDatasetURL')
        console.log url
        datacursor = Summaries.find(datasetSourceURL: url, groupKey: "", groupVal: '(ALL)')
        if datacursor.count()
            console.log "data found: "
            return _(datacursor.fetch()).pluck("name")
        else
            dataset = Datasets.findOne(url: url)
            if (!dataset)
                Meteor.call('register_dataset', url)
            console.log "nada"
            return ['Loading dataset...']

    root.Template.navbar.default =Session.get('currentDatasetURL') ? constants.defaultURL

    Meteor.startup ->
        Session.set('currentDatasetURL', constants.defaultURL)
        Session.set('currentGroup', '')
    

############# UI LIB #############################


Meteor.methods(
    make_single_chart: (obj) ->
        [div, dataElement] = obj
        #dataElement.titleName = makeTitle(dataElement.name)
        dataElement.titleName = dataElement["groupVal"]
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
                    width: Math.min(dataSize*60 + 100, 220)
                    height: "270"
                    "padding-right": "50"
                    title: dataElement.titleName
                    "title-size":12
                    "legend-position":"bottom"
                ).render(div)

    clear_graphs: ->
        graph_divs = $('.gg_graph')
        for item in graph_divs
            $(item).empty()

    charting: ->
        Meteor.call('clear_graphs')
        url = Session.get("currentDatasetURL")
        group = Session.get("currentGroup") ? "" #some fallback
        item_list = Summaries.find(datasetSourceURL:url, groupKey:group).fetch()
        list = Meteor.call('grouping', item_list)
        $.each(list, (key,value)->
            for item in value
                item_name = item["name"]
                div = "#"+item["name"]+".gg"
                Meteor.call("make_single_chart",[div,item])
        )

    grouping: (list) ->
        fin = {}
        #group_list = _list.pluck("groupVal")
        #group_list = (list.map (x)->x.groupVal).unique()
        group_list = list.map (x)->x.groupVal
        for item in group_list
            fin[item]=[]
        for item in list
           group = item['groupVal']
           fin[group].push(item)
        fin

)
Array::unique = ->
    output = {}
    output[@[key]] = @[key] for key in [0...@length]
    value for key, value of output
