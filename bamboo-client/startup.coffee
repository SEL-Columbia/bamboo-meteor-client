root = global ? window
constants =
    defaultURL : 'https://www.dropbox.com/s/0m8smn04oti92gr/sample_dataset_school_survey.csv?dl=1'
    #defaultURL : 'https://dl.dropbox.com/s/5mu9x13upanqpgy/file.csv?dl=1'
    bambooID : 'd42c713d958e40149484d6683829ec62'
Meteor.startup ->
    if root.Meteor.is_client
        Meteor.autosubscribe ->
            bambooID = Session.get("currentDatasetID")
            user = Session.get("currentUser")
            group = Session.get("currentGroup")
            view = Session.get("currentView")
            Meteor.subscribe "datasets", bambooID
            Meteor.subscribe "schemas", bambooID
            Meteor.subscribe "summaries", bambooID, group, view
            if user
                Meteor.subscribe "charts", bambooID, user
            return
        Meteor.defer(->
            $('.chosen').chosen()
        )
        
###
        Session.set('currentDatasetURL', constants.defaultURL)
        Session.set('currentGroup', '')
        Meteor.call('register_dataset',Session.get('currentDatasetURL'))
        Meteor.call("get_fields",Session.get('currentDatasetURL'))
        #TODO think about "everything" field, for now it is in the startup
        Meteor.call('summarize_by_group',[Session.get('currentDatasetURL'),""])
###


