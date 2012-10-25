root = global ? window
if Meteor.is_client
    #################INTRODUCTION###########################
    root.Template.arindam_table.one =->
        schema = Session.get('schema')
        all_val = _.values schema
        result = []
        pattern = /^1_.*/
        for item in all_val
            label = item.label
            if label.match(pattern)
                obj = 
                    label : item['label'].slice(2)
                    simpletype : item['simpletype']
                result.push(obj)
        result
        
    root.Template.arindam_table.two =->
        schema = Session.get('schema')
        all_val = _.values schema
        result = []
        pattern = /^2_.*/
        for item in all_val
            label = item.label
            if label.match(pattern)
                obj = 
                    label : item['label'].slice(2)
                    simpletype : item['simpletype']
                result.push(obj)
        result
    
    root.Template.arindam_table.three =->
        schema = Session.get('schema')
        all_val = _.values schema
        result = []
        pattern = /^3_.*/
        for item in all_val
            label = item.label
            if label.match(pattern)
                obj = 
                    label : item['label'].slice(2)
                    simpletype : item['simpletype']
                result.push(obj)
        console.log "heres three"
        console.log result
        result

    root.Template.arindam_table.four =->
        schema = Session.get('schema')
        all_val = _.values schema
        result = []
        pattern = /^4_.*/
        for item in all_val
            label = item.label
            if label.match(pattern)
                obj = 
                    label : item['label'].slice(2)
                    simpletype : item['simpletype']
                result.push(obj)
        result

    root.Template.arindam_table.five =->
        schema = Session.get('schema')
        all_val = _.values schema
        result = []
        pattern = /^5_.*/
        for item in all_val
            label = item.label
            if label.match(pattern)
                obj = 
                    label : item['label'].slice(2)
                    simpletype : item['simpletype']
                result.push(obj)
        result
    
    root.Template.arindam_table.schema_lessone =->
        schema = Session.get('schema')
        all_val = _.values schema
        result = []
        pattern = /^1_.*/
        for item in all_val
            label = item.label
            if label.match(pattern)
                obj = 
                    label : item['label'].slice(2)
                    simpletype : item['simpletype']
                result.push(obj)
        result.slice(0,5)

    root.Template.arindam_table.schema_lesstwo =->
        schema = Session.get('schema')
        all_val = _.values schema
        result = []
        pattern = /^2_.*/
        for item in all_val
            label = item.label
            if label.match(pattern)
                obj = 
                    label : item['label'].slice(2)
                    simpletype : item['simpletype']
                result.push(obj)
        result.slice(0,5)

    root.Template.arindam_table.schema_lessthree =->
        schema = Session.get('schema')
        all_val = _.values schema
        result = []
        pattern = /^3_.*/
        for item in all_val
            label = item.label
            if label.match(pattern)
                obj = 
                    label : item['label'].slice(2)
                    simpletype : item['simpletype']
                result.push(obj)
        result.slice(0,5)


    root.Template.arindam_table.schema_lessfour =->
        schema = Session.get('schema')
        all_val = _.values schema
        result = []
        pattern = /^4_.*/
        for item in all_val
            label = item.label
            if label.match(pattern)
                obj = 
                    label : item['label'].slice(2)
                    simpletype : item['simpletype']
                result.push(obj)
        result.slice(0,5)

    root.Template.arindam_table.schema_lessfive =->
        schema = Session.get('schema')
        all_val = _.values schema
        result = []
        pattern = /^5_.*/
        for item in all_val
            label = item.label
            if label.match(pattern)
                obj = 
                    label : item['label'].slice(2)
                    simpletype : item['simpletype']
                result.push(obj)
        result.slice(0,5)

    root.Template.arindam_table.long =->
        Session.get('fields').length > 5

    root.Template.arindam_table.show_all =->
        Session.get('fields').length < 6 or Session.get('show_all')

    root.Template.arindam_table.events=
        "click #moreBtn": ->
            Session.set('show_all', true)
        "click #hideBtn": ->
            Session.set('show_all', false)



