/**
 * This tests Wheels Application Bootstrapping
 */
component extends="testbox.system.BaseSpec" {


	function run() {


		describe("Resource/Resources", function() {

            beforeEach(function( currentSpec ) {
               m = new wheels.Mapper();
               m.$init();
                prepareMock(m);
            });

            afterEach(function( currentSpec ) {
                structDelete(variables, "m");
                structDelete(variables, "r");
            });

            it("Resource Produces Routes with list", function(){
               m.$draw()
			    .resource(name = "pigeon,pudding")
                .end();
               r = m.getRoutes();
               expect(r).toBeArray().toHaveLength(28);
			});

			it("Resource Raises Error with list and nesting", function(){
               expect(function() {
                    m.$draw()
                    .resource(name = "pigeon,pudding", nested=true)
                    .end()
               }).toThrow(type="Wheels.InvalidResource");
            });

			it("Resource Produces Simple Routes", function(){
               m.$draw()
               .resource(name = "pigeon")
               .end();
              r = m.getRoutes();
              expect(r).toBeArray().toHaveLength(14);
            });

            // CHECK THIS? on original 2.x tests wants 8 not 7?
            // Might be lack of root route
			it("Resource Produces Simple Routes without Format", function(){
               m.$draw()
               .resource(name = "pigeon", mapFormat = false)
               .end();
              r = m.getRoutes();
              expect(r).toBeArray().toHaveLength(7);
            });

			it("Resource Produces Simple Routes without Format Set by mapper", function(){
               m.$draw(mapFormat = false)
               .resource(name = "pigeon")
               .end();
              r = m.getRoutes();
              expect(r).toBeArray().toHaveLength(7);
            });

			it("Resource Produces Simple Routes without Format Set by mapper, override", function(){
               m.$draw(mapFormat = false)
               .resource(name = "pigeon", mapFormat = true)
               .end();
              r = m.getRoutes();
              expect(r).toBeArray().toHaveLength(14);
            });

            it("Resources Produces Routes with list", function(){
               m.$draw()
			    .resources(name = "pigeon,pudding")
                .end();
               r = m.getRoutes();
               expect(r).toBeArray().toHaveLength(32);
			});
            it("Resources Produces Routes with list without format", function(){
               m.$draw()
			    .resources(name = "pigeon,pudding", mapFormat=false)
                .end();
               r = m.getRoutes();
               expect(r).toBeArray().toHaveLength(16);
			});

			it("Resource Raises Error with list and nesting", function(){
                expect(function() {
                     m.$draw()
                     .resources(name = "pigeon,pudding", nested=true)
                     .end()
                }).toThrow(type="Wheels.InvalidResource");
             });
		});
	}

}
