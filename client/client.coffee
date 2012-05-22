root = global ? window
bambooUrl = "/"
observationsUrl = bambooUrl + "datasets"
name_html = "oh hai"

if root.Meteor.is_client
    populate = (u)->
        dataset = Datasets.find({url: u}).fetch()[0]
        ida = dataset.id
        summary = dataset.summary
        name_list =_(summary["(ALL)"]).pluck("name")


    root.Template.maincontent.columns = ->
        u = "http://formhub.org/education/forms/schooling_status_format_18Nov11/data.csv"
        console.log 'data count: ' + Datasets.find({url:u}).count()
        if Datasets.find({url:u}).count() > 0
            summary = Datasets.find({url: u}).fetch()[0].summary
            name_list =_(summary["(ALL)"]).pluck("name")
        name_list

    root.Template.navbar.events = "click button": ->
        url = $('#datasource-url').val()
        ###
        #logic: separate cached and uncahced case for 
        #setTimeout beceause it does take time for bamboo
        #to populate the result into the database
        ###
        if !(Datasets.find(url:url).count())
            console.log "caching..."
            Meteor.call('register_dataset', url)
            setTimeout populate(url), 2000
        else
            console.log "cahced"
            populate(url)
    ###
        
    $tabsUl = $('#tabs')
    $altTabsUl = $('#alt-tabs')
    $sideBySide = $('#side-by-side')
    $contentDiv = $('#content')
    $groupingSelect = $('#grouping-select')
    $histogramSelect = $('#histogram-select')
    $datasourceUrl = $('#datasource-url')


    clearPage = () ->
        _([$contentDiv, $tabsUl, $altTabsUl, $groupingSelect, $histogramSelect]).each((x) -> x.empty)
        _([$groupingSelect, $histogramSelect, $sideBySide]).each((x) -> x.unbind('change'))
    #making the page shell
    makePageShell = (groups, currentGroup) ->
        group2select = (groups, $select) ->
            $select.append('<option value="' + x + '">' + makeTitle(x) + '</option>')

        group2select groups, $histogramSelect

        $histogramSelect.change ->
            $.each $histogramSelect.children(), (i, groupOption)->
                $('#' + groupOption.value + '.gg').hide()
            
            $.each $histogramSelect.val(), (i, group) ->
                $('#' + group + '.gg').show()
            
        
        # Populate the grouping select with possible grouping options; only once per datasets (at the (ALL) key)  
        groups.unshift ""  # unshift = prepend 
        groups2Select groups, $groupingSelect
        $groupingSelect.val currentGroup

    #glue, needs to be rewritten getting from the database
    jsonUrlFromIDAndGroup = (id, group) ->
        bambooUrl + "datasets/" + id + "/summary" + (if group then ("?group=" + group) else "")

    #graphing
    makeNavAndContainerForGroup = (groupKey) ->
        $("<li />").html(
            $("<a />",
                text: groupKey
                "data-toggle": "tab"
                href: "#" + groupKey
            )
        ).appendTo($tabsUl)
        $("<div />").attr("id", groupKey).addClass("tab-pane group-nav").appendTo($contentDiv)

    makeAltNavAndContainerForGroup = (groupKey) ->
        $("<div />").html(
            $("<a />",
                text: groupKey
                href: "#" + groupKey
            )
        ).attr("id", groupKey).addClass("span3 group-nav").appendTo($altTabsUl)

    makeInternalContainerForGroup = (groupKey) ->
        $tabPane = $("#" + groupKey + ".group-nav")
        $("<div />").addClass("gg").data("target", groupKey).appendTo $("<div />",
            style: "float:left"
        ).appendTo($tabPane)

    #render data set
    renderDataSet= (dataset, groupKey) ->
        for datakey of dataset
            dataElement = dataset[dataKey]
            dataElement.titleName = makeTitle(dataElement.name)

            $thisDiv = makeInternalContainerForGroup(groupKey)
            $thisDiv.attr(id, dataElement.name)
            
            data = dataElement.data
            dataSize = _.size(data)

            if (dataSize is 0) or (dataElement.name.charAt(0) is '_')
                continue
            else
                keyValSeparated =
                    x: _.keys(data)
                    y: _.values(data)
                if typeof keyValSeparated.y[0] is "number"
                    #if number make pure histogram
                    #histogram logic
                    gg.graph(keyValSeparated).layer(gg.layer.bar().map('x','x').map('y','y')).opts(
                        width: Math.min(dataSize*60 + 100, 300)
                        height: "200"
                        "padding-right": "50"
                        title: dataElement.titleName
                        "title-size":12
                        "legend-position":"bottom"
                    ).render($thisDiv.get(0))
    loadPage = (datasetURL) ->
        $.post observationsUrl,
            url:datasetURL
        , ((bambooIdDict) ->
            makeGraphs = (id, group) ->
                $.getJSON(jsonUrlFromIDAndGroup(id, group), (datasets) ->
                    #deal with (ALL)
                    datasets["ALL"] = datasets["(ALL)"]
                    delete datasets["(ALL)"]
                    #clear page first
                    clearPage()
                    #set up controls for this page
                    makePageShell(_(datasets["ALL"]).pluck("name"),group)
                    $groupingSelect.change -> #TODO: can refacot into makePageShell somehow?
                        makeGraphs(id, $(this).val())
                    $sideBySide.change ->
                        makeGraphs(id, $groupingSelect.val())
                    if $('#side-by-side:checked').length
                        count = 3
                        _.each(datasets, (dataset, groupKey) ->
                            if count
                                makeAltNavAndContainerForGroup(groupKey)
                                renderDataSet(dataset, groupKey)
                                count--
                        )
                    else
                        _.each(datasets, (dataset, groupKey) ->
                            makeNavAndContainerForGroup(groupKey)
                            renderDataSet(dataset, groupKey)
                        )
                    $('#tabs a:last').tab('show')
                )
            makeGraphs bambooIdDict['id']
        ), 'json'

    $(->
        sampleDataSetUrl = 'http://formhub.org/education/forms/schooling_status_format_18Nov11/data.csv'
        loadPage(sampleDataSetUrl)
        #console.log "hey it's here"
        #make the datasource change button change the whole page
        $('#datasource-change-botton').click(->
            loadPage($datasourceUrl.val())
        )
    )
        
    ###
