root = global ? window
bambooUrl = "/"
observationsUrl = bambooUrl + "datasets"

constants =
    #defaultURL : 'http://formhub.org/education/forms/schooling_status_format_18Nov11/data.csv'
    defaultURL : 'https://www.dropbox.com/s/0m8smn04oti92gr/sample_dataset_school_survey.csv?dl=1'
    #defaultURL : 'http://localhost:8000/education/forms/schooling_status_format_18Nov11/data.csv'
    #defaultURL : 'http://formhub.org/mberg/forms/good_eats/data.csv'


############ UI LOGIC ############################
if root.Meteor.is_client
    
    #every function can be accessed by the template it is defined under
    root.Template.url_entry.events = "click .btn": ->
        url = $('#dataSourceURL').val()
        Session.set('currentDatasetURL', url)
        #Meteor.call('chosen')
        if !Datasets.findOne(url: url)
            console.log "caching server side.."
            #todo: add async to serize register & get_fields
            Meteor.call('register_dataset', url, ->
                interval = setInterval(->
                    #Meteor.call("get_fields", url)
                    #if Session.get('fields')
                    if Schemas.findOne(datasetURL: url)
                        console.log "booya"
                        Meteor.call("get_fields", url)
                        clearInterval(interval)
                ,300)
            )
        else
            console.log "already cached server side.."
            Meteor.call("get_fields",url)
    
    root.Template.url_entry.current_dataset_url = ->
        Session.get('currentDatasetURL')

    root.Template.control_panel.show = ->
        #if there is currentDatasetURL in session-> show
        Session.get('currentDatasetURL') and Session.get('fields')

    # have to write this code to make chosen recognized in jquery
    root.Template.control_panel.chosen= ->
        Meteor.defer(->
            Meteor.call('chosen')
        )

    root.Template.control_panel.fields= ->
        fields = Session.get('fields')
        Meteor.call('generate_visible_fields', fields)
        visible_fields = Session.get('visible_fields')
        display = []
        for item in visible_fields
            display.push(item['field'])
        display

    root.Template.control_panel.groups= ->
        # call summarize_by_group
        Meteor.call('generate_groupable_fields')
        fields = Session.get('groupable_fields')

    root.Template.control_panel.num_graph= ->
        20
    
    root.Template.control_panel.events= "click .btn": ->
        group = $('#group-by').val()
        view_field = $('#view').val()
        url = Session.get('currentDatasetURL')
        Meteor.call("summarize_by_group",[url,group])
        Session.set('currentGroup', group)
        Session.set('currentView', view_field)
        Session.set('graph', false)

    root.Template.graph.show=->
        url = Session.get('currentDatasetURL')
        group = Session.get('currentGroup')
        view = Session.get('currentView')
        url and view

    root.Template.graph.field =->
        div = Session.get('currentView')
    
    root.Template.graph.charting =->
        #todo: move summarize_by_group here?
        #todo: use async to serize sum & charting
        fieldInterval = setInterval(->
                console.log "hardcore summary action"
                summary = Summaries.findOne( {groupKey : Session.get('currentGroup')} )
                if summary
                    Meteor.call('field_charting')
                    Session.set('graph', true)
                    clearInterval(fieldInterval)
            ,1000)
        ""

    root.Template.processing.ready =->
        Session.get('currentDatasetURL') and not Session.get('fields')

    root.Template.introduction.ready =->
        Session.get('currentDatasetURL') and Session.get('fields')

    root.Template.introduction.num_cols =->
        Session.get('fields').length

    root.Template.introduction.schema =->
        url = Session.get('currentDatasetURL')
        obj = Schemas.findOne
            datasetURL:url
        _.values obj.schema

    root.Template.body_render.show =->
        Session.get('currentDatasetURL') and Session.get('fields')

    root.Template.waiting_graph.exist =->
        exist  = Session.get('graph')

############# UI LIB #############################


Meteor.methods(
    chosen: ->
            $(".chosen").chosen(
                no_results_text: "No Result Matched"
                allow_single_deselect: true
            )

    generate_visible_fields: (fields)->
        group_by = Session.get('currentGroup')
        visible_fields = []
        for item in fields
            obj=
                field: item
                group_by: group_by
            visible_fields.push(obj)
        Session.set("visible_fields",visible_fields)

    generate_groupable_fields: ->
        schema = Session.get('schema')
        fin = []
        for item of schema
            if schema[item]['olap_type'] == 'dimension'
                fin.push(item)

        Session.set('groupable_fields',fin)
    


    make_poly_chart: (obj) ->
        [div, dataElement] = obj
        #dataElement.titleName = makeTitle(dataElement.name)
        dataElement.titleName = dataElement["groupVal"]
        data = dataElement.data
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
    make_single_chart: (obj) ->
        [div, dataElement] =obj
        #chart based on groupable property
        if dataElement.name in Session.get("groupable_fields")
            barchart(dataElement,div)
        else
            boxplot(dataElement,div)

    d3testing: (data)->
        char_element = data ? mock_element
        d3chart(char_element, "#d3select")

    boxtesting: (data) ->
        char_element = data ? mock_element_2
        boxplot(char_element, "#d3select")


    clear_graphs: ->
        graph_divs = $('.gg_graph')
        for item in graph_divs
            $(item).empty()

#    charting: ->
#        Meteor.call('clear_graphs')
#        url = Session.get("currentDatasetURL")
#        group = Session.get("currentGroup") ? "" #some fallback
#        item_list = Summaries.find(datasetURL:url, groupKey:group).fetch()
#        list = Meteor.call('grouping', item_list)
#        $.each(list, (key,value)->
#            for item in value
#                div = "#"+item["name"]+".gg"
#                Meteor.call("make_single_chart",[div,item])
#        )

    field_charting: ->
        Meteor.call('clear_graphs')
        url = Session.get("currentDatasetURL")
        group = Session.get("currentGroup") ? "" #some fallback
        field = Session.get("currentView")
        item_list = Summaries.find
            datasetURL: url
            groupKey: group
            name: field
        .fetch()
        div = "#" + field+"_graph"
        for item in item_list
            Meteor.call("make_single_chart", [div, item])

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

    get_fields:(url)->
        fin = []
        schema_dataset = Schemas.findOne
            datasetURL: url
            #alert "in get_fields:schema_dataset " + schema_dataset
        if schema_dataset
            console.log "data found: "
            names = []
            schema = schema_dataset['schema']
            for name of schema
                names.push(name)
            #fields is an array []
            fin = names
            #alert "found schema" + fin
        ###
        else
            dataset = Datasets.findOne(url: url)
            if (!dataset)
                Meteor.call('register_dataset', url)
        ###
        try
            Session.set('schema', schema_dataset.schema)
            Session.set('fields', fin)
        catch error
            console.log "no schema yet.. waiting"
        #alert fin

    #testing only
    alert: (something)->
        display = something ? "here here"
        alert display

)

Array::unique = ->
    output = {}
    output[@[key]] = @[key] for key in [0...@length]
    value for key, value of output
