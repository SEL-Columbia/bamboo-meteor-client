#This is the backbone router
if Meteor.is_client
    URLRouter = Backbone.Router.extend
        routes:
            "*url": "default_url"
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
                Meteor.call('register_dataset', url, ()->
                    interval = setInterval(->
                        #Meteor.call("get_fields", url)
                        #if Session.get('fields')
                        if Schemas.findOne(datasetURL: url)
                            console.log "booya"
                            Meteor.call("get_fields", url)
                            clearInterval(interval)
                    ,300)
                )
                console.log "already cached server side.."
                Meteor.call("get_fields",url)
                
    app_router = new URLRouter
    Backbone.history.start
        pushState:true
