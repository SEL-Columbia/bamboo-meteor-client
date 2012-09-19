root = global ? window
require = __meteor_bootstrap__.require
request = require 'request'
#bambooURL = 'http://localhost:8080'
#bambooURL = 'http://bamboo.modilabs.org/'
bambooURL = 'http://bamboo.io'
#bambooURL = 'http://starscream.modilabs.org:8080/'
datasetsURL = bambooURL + '/datasets'
#TODO: change select to dynamic
summaryURLf = (id,group) -> datasetsURL + '/' + id + '/summary' +
    '?select=all' + if group then '&group=' + group else ''

schemaURLf = (id) -> datasetsURL + '/' + id + '/info'

###########PUBLISHES##########################
Meteor.publish "datasets", (url)->
    Datasets.find
        url:url

Meteor.publish "schemas", (url)->
    Schemas.find
        datasetURL:url

Meteor.publish "summaries", (url,group, view)->
    Summaries.find
        datasetURL:url
        groupKey:group
        name:view

Meteor.publish "charts", (url,user)->
    Charts.find
        url:url
        user:user

            
#########METHODS################################
#Note: methods can live anywhere, regardless of server or client
Meteor.methods(

    insert_chart: (obj)->
        [url,user,field,group,item_list] = obj
        chart =
            url:url
            user:user
            field:field
            group:group
            summary:item_list
        if not Charts.findOne(chart)
            console.log "user: ", user, " added charts of", field, group
            Fiber(->
                Charts.insert(chart)
            ).run()

    remove_chart: (obj)->
        [url,user,field,group] = obj
        chart =
            url:url
            user:user
            field:field
            group:group
        if Charts.findOne(chart)
            console.log "user: ", user, " remove charts of", field, group
            Fiber(->
                Charts.remove(chart)
            ).run()

    register_dataset: (url) ->
        if (url is null) or (url is "")
            console.log "null url! discard!"
            throw new Meteor.Error 404, "alex sucks"
        else
            console.log "server received url " + url
            unless Datasets.findOne({url: url})
                result = Meteor.http.call "POST", datasetsURL,
                    params:
                        url:url
                try
                    if result.error is null
                        if result.statusCode is 200
                            r = JSON.parse(cleanKeys(result.content))
                            if r.error
                                msg = "bamboo error message: " + r.error
                                console.log msg
                                throw new Meteor.Error 404, msg
                            else
                                Fiber(->
                                    unless Datasets.findOne({url: url})
                                        Datasets.insert
                                            bambooID: r.id
                                            url: url
                                            cached_at: Date.now()
                                        Meteor.call('insert_schema', url)
                                ).run()
                        else
                            msg = "bad status" + result.statusCode
                            console.log msg
                            throw new Meteor.Error 404, msg
                    else
                        msg = "Meteor http error: "+ result.error
                        console.log msg
                        throw new Meteor.Error 404, msg
                catch error
                    throw error


    insert_schema: (datasetURL) ->
        dataset = Datasets.findOne(url: datasetURL)
        if !(dataset)
            msg = "no dataset yet, get your schema dataset first"
            throw new Meteor.Error 404,msg
        else
            datasetID = dataset._id
            bambooID = dataset.bambooID

            # TODO: not sure about the updated time or created time
            if Schemas.findOne(datasetID: datasetID)
                console.log("schema with datasetID " + datasetID +
                    " and bambooID " + bambooID + " is already cached")
            else
                Meteor.http.call "GET", schemaURLf(bambooID), (error, result)->
                    #TODO: delete this consolelog
                    console.log schemaURLf(bambooID)
                    if not(error is null)
                        console.log error
                        throw new Meteor.Error 404, errormsg
                    else
                        obj = JSON.parse(cleanKeys(result.content))
                        updateTime = obj['updated_at']
                        createTime = obj['created_at']
                        schema = obj['schema']
                        res =
                            updateTime : updateTime
                            createTime : createTime
                            schema : schema
                            datasetID : datasetID
                            datasetURL : datasetURL
                        Fiber( -> Schemas.insert res).run()

    summarize_by_group: (obj) ->
        # tease out individual summary objects from bamboo output + store
        [datasetURL, groupkey] = obj
        dataset =  Datasets.findOne(url: datasetURL)
        # check if dataset valid
        if !(dataset)
            console.log datasetURL, groupkey
            console.log "no dataset yet, get your summary dataset first"
        else
            datasetID = dataset._id
            bambooID = dataset.bambooID
            if Summaries.findOne(datasetID: datasetID, groupKey: groupkey)
                console.log("summary with datasetID " + datasetID +
                    " and groupkey " + groupkey + " is already cached")
            else
                groupKey = groupkey
                Meteor.http.call "GET", summaryURLf(bambooID, groupkey),(error,result)->
                    if not(error is null)
                        console.log summaryURLf(bambooID, groupkey) + error
                    else
                        obj = JSON.parse(cleanKeys(result.content))
                        if groupKey is ""
                            for field of obj
                                res=
                                    groupKey: groupKey
                                    groupVal: groupKey
                                    data: obj[field]["summary"]
                                    name:field
                                    datasetID: datasetID
                                    datasetURL: datasetURL
                                Fiber( -> Summaries.insert res).run()
                        else
                            if obj["error"]
                                console.log "error on group_by: "+obj['error']
                            else
                                for groupkey of obj
                                    for groupval of obj[groupkey]
                                        for field of obj[groupkey][groupval]
                                            res=
                                                groupKey: groupkey
                                                groupVal: groupval
                                                data: obj[groupkey][groupval][field]["summary"]
                                                name:field
                                                datasetID: datasetID
                                                datasetURL: datasetURL
                                            Fiber( -> Summaries.insert res).run()
    summarized_by_total_non_recurse:(obj)->
        [datasetURL, groupkey] = obj
        dataset = Datasets.findOne(url: datasetURL)
        # check if dataset valid
        if !(dataset)
            console.log datasetURL, groupkey
            console.log "no dataset yet, get your summary dataset first"
            #TODO:publish this error message to the front
        else
            datasetID = dataset._id
            bambooID = dataset.bambooID
            if Summaries.findOne(datasetID: datasetID, groupKey: groupkey)
                console.log("summary with datasetID " + datasetID +
                    " and groupkey " + groupkey + " is already cached")
                #TODO: would we want to push this to client?
            else
                groupKey = groupkey
                request.get summaryURLf(bambooID, groupkey), (error, body, response) ->
                    if error
                        console.log error
                    else
                        obj = JSON.parse(response)
                        Fiber(-> Norecurse.insert obj).run()
)
