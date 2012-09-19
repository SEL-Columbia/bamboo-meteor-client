
Datasets = new Meteor.Collection('datasets')
Summaries = new Meteor.Collection('summaries')
Schemas = new Meteor.Collection('schema')
Message = new Meteor.Collection('message')
Norecurse = new Meteor.Collection('norecurse')
Charts = new Meteor.Collection('charts')

if Meteor.is_server
    upsert = (collection, el) ->
        if not collection.findOne(el)
            collection.insert(el)

######## UTILS ###########
makeTitle = (slug) ->
    words = (word.charAt(0).toUpperCase() + word.slice(1) for word in slug.split('_'))
    words.join(' ')

cleanKeys=(str)->
    str.replace /\"([^\"]*)\"\:/g, (fstr)->
        fstr.replace(/\./g, "_")

cleanBadChar = (str) ->
    for elem in BAD_CHARACTERS
        if elem in str
            str = str.replace(elem,"")
    return str
    
######## CONSTANTS #######
CARDINAL_LIMIT = 30
BAD_CHARACTERS = "'/.,<>[]{}"
