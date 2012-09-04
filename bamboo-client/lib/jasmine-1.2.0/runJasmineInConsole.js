runJasmineInConsole = function() {
    load_test();
    jasmine.getEnv().addReporter(new jasmine.ConsoleReporter());
    jasmine.getEnv().execute();
}


