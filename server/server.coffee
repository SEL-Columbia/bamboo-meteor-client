root = global ? window

require = __meteor_bootstrap__.require
request = require('request')
#bambooURL = 'http://localhost:8080'
bambooURL = 'http://bamboo.modilabs.org/'
datasetsURL = bambooURL + '/datasets'
summaryURLf = (id,group) -> datasetsURL + '/' + id + '/summary' + if group then '?group=' + group else ''

#Note: methods can live anywhere, regardless of server or client
Meteor.methods(
    register_dataset: (url) ->
        if url is null
            console.log "null url! discard!"
        else
            console.log "server received url " + url
            unless Datasets.findOne({url: url})
                post_options =
                    uri: datasetsURL
                    method: 'POST'
                    form: {url: url}
                request post_options, (e, b, response) ->
                    Fiber(->
                        Datasets.insert
                            bambooID: JSON.parse(response).id
                            url: url
                            cached_at: Date.now()
                    ).run()
                    summaryCallback = -> Fiber( ->
                        Meteor.call('summarize_by_group', [url, ''])).run()
                    setTimeout summaryCallback, 1000
    summarize_by_group: (obj) ->
        # tease out individual summary objects from bamboo output + store
        [datasetURL, groupkey] = obj
        dataset =  Datasets.findOne(url: datasetURL)
        datasetID = dataset._id
        bambooID = dataset.bambooID
        dataset console.log "dataset not found" unless dataset
        return unless dataset
        # TODO: should we do a stricter check?
        if Summaries.findOne(datasetID: datasetID, groupKey: groupkey)
            console.log "already cached: group splits for " + groupkey + " on dataset " + datasetID
        else
            console.log "calculating: group splits for " + groupkey + " on dataset " + datasetID
            request.get summaryURLf(bambooID, groupkey), (e, b, response) ->
                    obj = JSON.parse(response) # a dict split by dict_val
                    dataElToDbObj = (groupval) -> (dataEl) ->
                            groupKey: groupkey
                            groupVal: groupval
                            data: dataEl.data
                            name: dataEl.name
                            datasetID: datasetID
                            datasetSourceURL: datasetURL
                    res = _(obj).chain()
                            .keys()
                            .map((key) -> _.map(obj[key], dataElToDbObj(key)))
                            .flatten()
                    Fiber( -> res.each((el) -> Summaries.insert el))
                        .run()
)
