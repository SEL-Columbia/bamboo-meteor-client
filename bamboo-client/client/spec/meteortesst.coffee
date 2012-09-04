load_test=->
    testing_url = "https://www.dropbox.com/s/0m8smn04oti92gr/sample_dataset_school_survey.csv?dl=1"
    describe "register URL", ->
        #SESSION############################
        Session.set "currentDatasetURL", "https://www.dropbox.com/s/0m8smn04oti92gr/sample_dataset_school_survey.csv?dl=1"

        #TEST###############################
        describe "url", ->
            it "should find url after registeration", ->
                url = Session.get "currentDatasetURL"
                expect(url).toEqual("https://www.dropbox.com/s/0m8smn04oti92gr/sample_dataset_school_survey.csv?dl=1")
            it "should find Preparing block", ->
                h1 = $("h1")
                expect(h1.text()).toEqual("Preparing your dataset, just a split second..")

        #SESSION######################################
        describe "test after dataset register", ->
            it "should have datebase registered and all dom element", ->
                runs(->
                    Meteor.call('register_dataset', testing_url, (error, result)->
                        if error
                            alert error.reason
                        interval = setInterval(->
                            if Schemas.findOne(datasetURL: testing_url)
                                console.log "booya"
                                Meteor.call("get_fields", testing_url)
                                clearInterval(interval)

                        ,300)
                    )
                )
                waits(2000)
                runs(->
                    dataset = Datasets.findOne()
                    expect(dataset.url).toEqual(testing_url)

                    schema = Schemas.findOne()
                    expect(schema.datasetURL).toEqual(testing_url)

                    fields = Session.get("fields")
                    expect(fields).toEqual(["grade","sex","name","income"])
                    
                    control_panel = $("#control_panel")
                    expect(control_panel).toBeDefined()

                    chosen = $(".chosen")
                    expect(chosen).toBeDefined()

                    chartBtn = $(".chartBtn")
                    expect(chartBtn.text()).toMatch(/Chart/)
                )



