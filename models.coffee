Datasets = new Meteor.Collection('datasets')
Summaries = new Meteor.Collection('summaries')

######## UTILS ###########
makeTitle = (slug) ->
    words = (word.charAt(0).ToUpperCase() + word.slice(1) for word in slug.split('_'))
    words.join(' ')
