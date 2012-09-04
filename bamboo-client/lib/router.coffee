#This is the backbone router
if Meteor.is_client
    URLRouter = Backbone.Router.extend
        routes:
            "?user=*user&&?csvFile=*url": "persistent_chart"
            "*url": "default_url"
        ,
        persistent_chart: (user, url)->
            if not (url is "") and not (url is undefined) and not (user is undefined)
                if Session.get('currentDatasetURL')
                    keys = Session.keys
                    for item of keys
                        Session.set(item, false)
                Session.set('currentDatasetURL', url)
                Session.set('currentUser', user)
                console.log "caching server side.."
                Meteor.call('register_dataset', url, (error, result)->
                    if error
                        alert error.reason
                    interval = setInterval(->
                        if Schemas.findOne(datasetURL: url)
                            Meteor.call("get_fields", url)
                            clearInterval(interval)
                    ,300)
                )
            else
                console.log "already cached server side.."
                Meteor.call("get_fields",url)
           
            #wait for the function get_fields
            schemaInterval = setInterval(->
                if not (Session.get('groupable_fields') is false) && not (Session.get('fields') is false)
                    console.log Session.get('groupable_fields')
                    console.log Session.get('fields') #TODO: the for loops problem we used to know!!!uh oh
                    previousCharts = Charts.find
                        url:url
                        user:user
                    .fetch()
                    for chart in previousCharts
                        Meteor.call('summarize_by_group', [url, chart.group])

                        Session.set(chart.field + '_' + chart.group, true)
                        #Session.set('currentView', chart.field)
                        #Session.set('currentGroup', chart.group)

                        if chart.field in Session.get('groupable_fields')
                            title = "Bar Chart of "
                        else
                            title = "Box Plot of "
                        console.log "output the title: " + title
                        frag = Meteor.render( ->
                            return Template.graph({
                                title: title
                                field: chart.field
                                group: chart.group
                                field_name: makeTitle(chart.field)
                                group_name: makeTitle(chart.group)
                            })
                        )
                        $('#graph_panel').append(frag)
                        $('[rel=tooltips]').tooltip()

                        Meteor.call('field_list_charting', chart.field, chart.group, chart.summary)
                        console.log "what?"
            #Backbone.history.navigate(url, true)
                    clearInterval(schemaInterval)
            , 1000)

        ,
        default_url: (url)->
            if not(url is "") and not(url is undefined)
                if Session.get('currentDatasetURL')
                    keys = Session.keys
                    for item of keys
                        Session.set(item, false)
                Session.set('currentDatasetURL', url)
                #Meteor.call('chosen')
                console.log "caching server side.."
                #todo: add async to serize register & get_fields
                Meteor.call('register_dataset', url, (error, result)->
                    if error
                        alert error.reason
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
                
    app_router = new URLRouter
    Backbone.history.start()
