component extends="wheels.Testbox" {

    function beforeAll() {
        super.beforeAll();
        application.wheels = createObject("component", "wheels.Wheels").init();
    }

}