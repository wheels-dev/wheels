/**
 * This tests Wheels Application Bootstrapping
 */
component extends="testbox.system.BaseSpec" {


	function run() {

		describe("Mapping - Draw", function() {

               beforeEach(function( currentSpec ) {
                    m = new wheels.Mapper();
                    m.$init();
                    prepareMock(m);
               });

               afterEach(function( currentSpec ) {
                    structDelete(variables, "m");
               });

               it("Initialises with defaults", function(){
                    m.$draw();
                    expect(m.$getProperty("restful", "variables")).toBeTrue();
                    expect(m.$getProperty("methods", "variables")).toBeTrue();
               });

               it("Initialises with restful false", function(){
                    m.$draw(
                         restful = false
                    );
                    expect(m.$getProperty("restful", "variables")).toBeFalse();
               });

               it("Initialises with restful false & methods true", function(){
                    m.$draw(
                    restful = false,
                    methods = true
                    );
                    expect(m.$getProperty("restful", "variables")).toBeFalse();
                    expect(m.$getProperty("methods", "variables")).toBeTrue();
               });

               it("Initialises with mapFormat false ", function(){
                    m.$draw(
                    mapFormat=false
                    );
                    expect(m.$getProperty("mapFormat", "variables")).toBeFalse();
               });

               it("Draw() resets scopeStack", function(){
                    m.$draw();
                    expect(m.$getProperty("scopeStack", "variables")).toBeArray().toHaveLength(1);
               });
               it("End() removes top of ScopeStack", function(){
                    m.$draw();
                    expect(m.$getProperty("scopeStack", "variables")).toBeArray().toHaveLength(1);
                    m.end();
                    expect(m.$getProperty("scopeStack", "variables")).toBeArray().toHaveLength(0);
               });

          });
     }

}
