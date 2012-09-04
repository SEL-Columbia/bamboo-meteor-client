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
        Meteor.call('register_dataset', testing_url, (error, result)->
            if error
                alert error.reason
            interval = setInterval(->
                if Schemas.findOne(datasetURL: testing_url)
                    console.log "booya"
                    Meteor.call("get_fields", testing_url)
                    ##testing####################
                    describe "database registration", ->
                        it "should have a dataset object", ->
                            dataset = Datasets.findOne()
                            expect(dataset.url).toEqual(testing_url)
                        it "should have a schema object", ->
                            schema = Schemas.findOne()
                            expect(schema.datasetURL).toEqual(testing_url)

                    describe "getting fields", ->
                        it "should have all the fields", ->
                            fileds = Session.get("fields")
                            expect(fields).toEqual(["grade","sex","name","income"])



                    clearInterval(interval)
            ,300)
        )
                
