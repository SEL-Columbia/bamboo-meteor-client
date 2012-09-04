load_test=->
    describe "register URL", ->
        Session.set "currentDatasetURL", "https://www.dropbox.com/s/0m8smn04oti92gr/sample_dataset_school_survey.csv?dl=1"
        describe "url", ->
            it "should find url after registeration", ->
                url = Session.get "currentDatasetURL"
                expect(url).toEqual("https://www.dropbox.com/s/0m8smn04oti92gr/sample_dataset_school_survey.csv?dl=1")
                
