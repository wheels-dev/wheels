component extends="wheels.WheelsTest" {

    function beforeAll() {
        throw(
            type    = "Test.Setup.MissingDep",
            message = "application.wo.functionDoesNotExist is undefined"
        );
    }

    function run() {
        describe("foo", function() {
            it("bar", function() {
                expect(true).toBeTrue();
            });
        });
    }

}
