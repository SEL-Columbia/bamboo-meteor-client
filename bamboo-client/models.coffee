
Datasets = new Meteor.Collection('datasets')
Summaries = new Meteor.Collection('summaries')
Schemas = new Meteor.Collection('schema')
Message = new Meteor.Collection('message')
Norecurse = new Meteor.Collection('norecurse')


######## UTILS ###########
makeTitle = (slug) ->
    words = (word.charAt(0).ToUpperCase() + word.slice(1) for word in slug.split('_'))
    words.join(' ')

cleanKeys=(str)->
    str.replace /\"([^\"]*)\"\:/g, (fstr)->
        fstr.replace(/\./g, "_")
