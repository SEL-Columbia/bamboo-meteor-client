root = global ? window
bambooUrl = "/"
observationsUrl = bambooUrl + "datasets"


#############SUBSCRIBE#######################
if root.Meteor.is_client
    #Meteor.startup ->
         
############ UI LOGIC ############################
    #every function can be accessed by the template it is defined under
    ##################BODY RENDER#####################
    root.Template.body_render.show =->
        Session.get('currentDatasetURL') and Session.get('fields')

    ###################URL-Entry###########################
    root.Template.url_entry.events = "click .btn": ->
        Backbone.history.navigate($('#dataSourceURL').val(), true)

    root.Template.url_entry.current_dataset_url = ->
        Session.get('currentDatasetURL')

    ####################PROCESSING######################
    root.Template.processing.ready =->
        Session.get('currentDatasetURL') and not Session.get('fields')

    #################INTRODUCTION###########################
    root.Template.introduction.num_cols =->
        Session.get('fields').length

    root.Template.introduction.url =->
        Session.get('currentDatasetURL')

    root.Template.introduction.schema =->
        schema = Session.get('schema')
        schema_list = _.values schema
        for item in schema_list
            if (item.simpletype is "string") and (not item.label.match /.*\*$/)
                item.label = item.label+"*"
        schema_list

    root.Template.introduction.schema_less =->
        schema = Session.get('schema')
        arr = _.values schema
        arr.slice(0,5)

    root.Template.introduction.events=
        "click #moreBtn": ->
            Session.set('show_field', true)
        "click #hideBtn": ->
            Session.set('show_field', false)

    root.Template.introduction.show_field=->
        Session.get("show_field")


    #####################Control-Panel##################

    # have to write this code to make chosen recognized in jquery
    root.Template.control_panel.chosen= ->
        Meteor.defer(->
            Meteor.call('chosen')
        )

    root.Template.control_panel.first_graph= ->
        is_first_graph = Session.get("first_graph")
        if is_first_graph is undefined
            Session.set("first_graph", true)
        result = Session.get("first_graph")
        return result
        


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

    root.Template.control_panel.toggle=->
        Meteor.defer ->
            $('#control_logic').slideToggle('fast')

    root.Template.control_panel.toggle_down=->
        Meteor.defer ->
            $('#control_logic').slideDown('fast')

    root.Template.control_panel.events=
        "click .closeBtn": ->
            $('#control_panel').hide()

        "click .chartBtn": ->
            waiting_graph = $('#waiting_graph')
            $("#control_panel").hide()
            waiting_graph.show()
            group = $('#group-by').val()
            view_field = $('#view').val()

            #check whether graph exists already
            if Session.get(view_field + '_' + group)
                alert "Graph already exists"
                waiting_graph.hide()
                return

            url = Session.get('currentDatasetURL')
            Meteor.call("summarize_by_group",[url,group])
            #Meteor.call("summarized_by_total_non_recurse",[url,group])
            Session.set('currentGroup', group)
            Session.set('currentView', view_field)
            Session.set('addNewGraphFlag', true)
            Session.set(view_field + '_' + group, true)
            
            #TODO: if the count = 1 when drawing box plot
            title = ""
            if view_field in Session.get('groupable_fields')
                title = "Bar Chart of "
            else
                title = "Box Plot of "
            frag = Meteor.ui.render( ->
                return Template.graph({
                    title: title
                    field: view_field
                    group: group
                    field_name: makeTitle(view_field)
                    group_name: makeTitle(group)
                })
            )
            Session.set("first_graph", false)
            Meteor.defer ->
                fieldInterval = setInterval(->
                    summary = Summaries.find().fetch()
                    if summary
                        waiting_graph.hide()
                        $('#graph_panel').append(frag)
                        $('[rel=tooltip]').tooltip()
                        url = Session.get("currentDatasetURL")
                        user = Session.get("currentUser")
                        Meteor.call("insert_chart",[url,user,view_field,group,summary])
                        Meteor.call('field_charting', view_field, group)
                        clearInterval(fieldInterval)
                ,1000)
                ""

    #########GRAPH###############################
    root.Template.graph.events =
        "click .deletionBtn": ->
            url = Session.get("currentDatasetURL")
            user = Session.get("currentUser")
            field = this.field
            group = this.group
            divstr = '#'+field+'_'+group+'_block'
            Session.set(field+'_'+group, false)
            Meteor.call("remove_chart",[url, user, field, group])
            $(divstr).remove()
            $('.tooltip').remove()
        "click .downloadBtn": ->
            field = this.field
            group = this.group
            divstr = '#' + field + '_' + group + '_graph'
            div = $(divstr)
            if div.children().length == 1
                svg = '<html><head><link rel="stylesheet" type="text/css" href="https://raw.github.com/novus/nvd3/master/src/nv.d3.css"></head><body>'
                svg = svg + div.eq(0).html()
                svg = svg + "</bdoy></html>"
            else
                div.eq(0).children().each (i)->
                    $(this).attr('y', i*300)
                svg = '<html><head><link rel="stylesheet" type="text/css" href="https://raw.github.com/novus/nvd3/master/src/nv.d3.css"></head><body>'
                str = div.eq(0).html()
                svg = svg + str
                svg = svg + '</body></html>'
            filename = field + '_' + group + '_graph'
            loadScripts = []
            unless BlobBuilder?
                loadScripts.push($.getScript("https://raw.github.com/eligrey/BlobBuilder.js/master/BlobBuilder.min.js"))
            unless saveAs?
                loadScripts.push($.getScript("https://raw.github.com/eligrey/FileSaver.js/master/FileSaver.js"))
            console.log loadScripts
            $.when.apply(null, loadScripts).fail( ()->
                console.log(typeof log, arguments)
                alert('Error loading scripts')
            ).done( ()->
                if !BlobBuilder?
                    alert("No BlobBuilder.. cannot download")
                blob = new BlobBuilder
                blob.append(svg)
                output = blob.getBlob("text/html;charset=" + document.characterSet)
                saveAs(output, filename)
            )

root.Template.add_button.events=
        "click #addNewGraphBtn": ->
            $('#control_panel').show()

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
            #no underscore prefix
            if not item.match /^_.*/
                obj=
                    field: item
                    group_by: group_by
                visible_fields.push(obj)
        Session.set("visible_fields",visible_fields)

    generate_groupable_fields: ->
        schema = Session.get('schema')
        fin = []
        for item of schema
            #no underscore prefix
            if not item.match /^_.*/
                if schema[item]['olap_type'] == 'dimension'
                    #restrict cardinality to < 30
                    if schema[item]['cardinality'] < CARDINAL_LIMIT
                        fin.push(item)

        Session.set('groupable_fields',fin)
    


    make_single_chart: (obj) ->
        [div, dataElement, min, max] =obj
        # chart based on groupable property
        # create individual divs
        # because nvd3 doesn't display tooltip box well
        gv = cleanBadChar(dataElement.groupVal)
        $(div).append('<div id="' + div.id + '_' + gv\
            + '" class="individual_graph span1"></div>')
        individual_div = $("#" + div.id + "_" + gv).get(0)

        if dataElement.name in Session.get("groupable_fields")
            #barchart(dataElement,div,min,max)
            #nvd3BarChart(dataElement, div, 0, max)
            nvd3BarChart(dataElement, individual_div, 0, max)
        else
            boxplot(dataElement,individual_div,min,max)

    field_list_charting: (field, group, item_list) ->
        url = Session.get("currentDatasetURL")
        user = Session.get("currentUser")
        #group = Session.get("currentGroup") ? "" #some fallback
        #field = Session.get("currentView")
        groupable = Session.get("groupable_fields")

        div = $("#" + field + "_" + group + "_graph").get(0)
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



    field_charting: (field, group) ->
        url = Session.get("currentDatasetURL")
        user = Session.get("currentUser")
        #group = Session.get("currentGroup") ? "" #some fallback
        #field = Session.get("currentView")
        groupable = Session.get("groupable_fields")
        item_list = Summaries.find
            datasetURL: url
            groupKey: group
            name: field
        .fetch()

        div = $("#" + field + "_" + group + "_graph").get(0)
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
            names = []
            schema = schema_dataset['schema']
            for name of schema
                names.push(name)
            fin = names
        try
            Session.set('schema', schema_dataset.schema)
            Session.set('fields', fin)
        catch error

    #testing only
    alert: (something)->
        display = something ? "here here"
        alert display

)

Array::unique = ->
    output = {}
    output[@[key]] = @[key] for key in [0...@length]
    value for key, value of output
