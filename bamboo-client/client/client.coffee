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
    ##################BODY RENDER#####################
    root.Template.body_render.show =->
        Session.get('currentDatasetURL') and Session.get('fields')

    ###################URL-Entry###########################
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

    ####################PROCESSING######################
    root.Template.processing.ready =->
        Session.get('currentDatasetURL') and not Session.get('fields')

    #################INTRODUCTION###########################
    root.Template.introduction.ready =->
        Session.get('currentDatasetURL') and Session.get('fields')

    root.Template.introduction.num_cols =->
        Session.get('fields').length

    root.Template.introduction.schema =->
        schema = Session.get('schema')
        _.values schema

    root.Template.introduction.schema_less =->
        schema = Session.get('schema')
        arr = _.values schema
        arr.slice(0,5)

    root.Template.introduction.events= {
        "click #moreBtn": ->
            Session.set('show_all', true)
        "click #hideBtn": ->
            Session.set('show_all', false)
    }

    root.Template.introduction.long =->
        Session.get('fields').length > 5

    root.Template.introduction.show_all =->
        Session.get('fields').length < 6 or Session.get('show_all')

    #####################Control-Panel##################
    root.Template.control_panel.show = ->
        #if there is currentDatasetURL in session-> show
        Session.get('currentDatasetURL') and Session.get('fields') and not Session.get('graph')
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

    ##################WAITING_GRAPH######################
    root.Template.waiting_graph.exist =->
        exist  = Session.get('graph')

    root.Template.waiting_graph.titles =->
        Session.get("titles")

    #####################GRAPH#######################333
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

    ##########ADDNEW GRAPH#####################################
    root.Template.add_new_graph.show =->
        Session.get('graph')

    root.Template.add_new_graph.events = "click #addGraphBtn":->
        Session.set('add_new_graph_flag', true)
        
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
    


    make_single_chart: (obj) ->
        [div, dataElement, min, max] =obj
        #chart based on groupable property
        if dataElement.name in Session.get("groupable_fields")
            barchart(dataElement,div,min,max)
        else
            boxplot(dataElement,div,min,max)


    clear_graphs: ->
        graph_divs = $('.gg_graph')
        for item in graph_divs
            $(item).empty()


    field_charting: ->
        Meteor.call('clear_graphs')
        url = Session.get("currentDatasetURL")
        group = Session.get("currentGroup") ? "" #some fallback
        field = Session.get("currentView")
        groupable = Session.get("groupable_fields")
        item_list = Summaries.find
            datasetURL: url
            groupKey: group
            name: field
        .fetch()
        div = "#" + field+"_graph"
        max_arr = item_list.map (item)->
            if item.name in groupable
                maxing(item.data)
            else
                item.data.max
        max = _.max(max_arr)
        min_arr = item_list.map (item)->
            if item.name in groupable
                mining(item.data)
            else
                item.data.min
        min = _.min(min_arr)
        for item in item_list
            Meteor.call("make_single_chart", [div, item, min, max])


    get_fields:(url)->
        fin = []
        schema_dataset = Schemas.findOne
            datasetURL: url
        if schema_dataset
            console.log "data found: "
            names = []
            schema = schema_dataset['schema']
            for name of schema
                names.push(name)
            fin = names
        try
            Session.set('schema', schema_dataset.schema)
            Session.set('fields', fin)
        catch error
            console.log "no schema yet.. waiting"

    #testing only
    alert: (something)->
        display = something ? "here here"
        alert display

)

Array::unique = ->
    output = {}
    output[@[key]] = @[key] for key in [0...@length]
    value for key, value of output
