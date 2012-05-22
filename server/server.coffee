root = global ? window

require = __meteor_bootstrap__.require
request = require('request')
bambooURL = 'http://localhost:8080'
datasetsURL = bambooURL + '/datasets'
summaryURLf = (id,group) -> datasetsURL + '/' + id + '/summary' + if group then '?group=' + group else ''

#Note: methods can live anywhere, regardless of server or client
Meteor.methods(
    register_dataset: (url) ->
        console.log "server received url: " + url
        cursor = Datasets.find({url: url})
        if(!cursor.count())
            post_options =
                uri: datasetsURL
                method: 'POST'
                form: {url: url}
            request(post_options, (e, b, response) ->
                ts = Date.now()
                console.log response
                bambooID = JSON.parse(response).id
                Fiber(->
                    Datasets.insert
                        id: bambooID
                        url: url
                        cached_at: ts
                # else figure out caching
                ).run()
                callback = ->request.get(summaryURLf(bambooID), (e, b, response) ->
                    Fiber(->
                        Datasets.update({id: bambooID}, {$set: {summary:JSON.parse(response)}})
                    ).run()
                )
                setTimeout callback, 1000
            )
    summarize_by_group: (obj) ->
        #caching
        [bambooID, group] = obj
        cached = false
        data =Datasets.find({id:bambooID}).fetch()[0]
        if data.bummary
            for item in data.bummary
                if item[group]
                    cached = true

        if !(cached)
            request.get(summaryURLf(bambooID, group), (e, b, response) ->
                    obj = {}
                    obj[group] = JSON.parse(response)
                    Fiber(->
                        Datasets.update({id: bambooID}, {$addToSet: {bummary: obj}})
                    ).run()
            )
        else
            console.log bambooID + " on " + group + " is already logged"
)

