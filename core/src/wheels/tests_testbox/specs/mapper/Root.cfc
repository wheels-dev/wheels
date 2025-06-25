/**
 * This tests Wheels Application Bootstrapping
 */
component extends="testbox.system.BaseSpec" {


	function run() {


		describe("Root", function() {

            beforeEach(function( currentSpec ) {
                m = new wheels.Mapper();
                m.$init();
                prepareMock(m);
            });

            afterEach(function( currentSpec ) {
                structDelete(variables, "m");
                structDelete(variables, "r");
            });

            it("Top level root excludes format but keeps its on sub level", function(){
               m.$draw()
               .namespace("test")
               .root(to = "test##test")
               .end()
               .root(to = "test##test")
               .end();
               r = m.getRoutes();
               expect(r[1].pattern).toBe("/test.[format]");
               expect(r[2].pattern).toBe("/test");
               expect(r[3].pattern).toBe("/");
			});
            it("Overriding default for map_format", function(){
               m.$draw()
               .namespace("test")
               .root(to = "test##test", mapFormat = false)
               .end()
               .root(to = "test##test", mapFormat = true)
               .end();
               r = m.getRoutes();
               expect(r[1].pattern).toBe("/test");
               expect(r[2].pattern).toBe("/.[format]");
               expect(r[3].pattern).toBe("/");
			});

		});
	}

}
