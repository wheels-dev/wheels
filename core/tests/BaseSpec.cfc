component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        super.beforeAll();
        application.wheels = createObject("component", "wheels.Wheels").init();
    }

}
