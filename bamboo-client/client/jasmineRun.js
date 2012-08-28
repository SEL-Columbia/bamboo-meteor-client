jasmineRun = function() {
    jasmine.getEnv().addReporter(new jasmine.ConsoleReporter());
    jasmine.getEnv().execute();
}
