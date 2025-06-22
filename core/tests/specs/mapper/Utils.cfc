/**
 * This tests Wheels Application Bootstrapping
 */
component extends="testbox.system.BaseSpec" {


	function run() {


		describe("Utils", function() {

            beforeEach(function( currentSpec ) {
                m = new wheels.Mapper();
                prepareMock(m);
                makePublic(m, "$compileRegex");
                makePublic(m, "$normalizePattern");
                makePublic(m, "$stripRouteVariables");
            });

            afterEach(function( currentSpec ) {
                structDelete(variables, "m");
                structDelete(variables, "r");
                structDelete(variables, "t");
            });

            //???? it("regex compiles successfully", function(){
            //????     t.pattern = "[controller]/[action]/[key]";
            //????     r.regex = m.patternToRegex(pattern = t.pattern)
            //????     r.output = m.$compileRegex(regex = r.regex, pattern=t.pattern);
            //????     //debug(r);
            //????  });

             it("$compileRegex throws regex compiles with error", function(){
                expect(function() {
                    m.$compileRegex(regex="*", pattern="*")
                }).toThrow(type="Wheels.InvalidRegex");
             });

            it("$normalizePattern no_starting_slash", function(){
               expect( m.$normalizePattern("controller/action"))
                .toBe("/controller/action");
            });

            it("$normalizePattern Double slash no starting slash", function(){
                expect(m.$normalizePattern("controller//action"))
                 .toBe("/controller/action");
             });

            it("$normalizePattern ending_slash_no_starting_slash", function(){
               expect( m.$normalizePattern("controller/action/"))
               .toBe("/controller/action");
            });

            it("$normalizePattern slashes_everywhere_with_format", function(){
               expect( m.$normalizePattern("////controller///action///.asdf/////"))
               .toBe("/controller/action.asdf");
            });

            it("$normalizePattern with_single_quote_in_pattern", function(){
               expect( m.$normalizePattern("////controller///action///.asdf'"))
               .toBe("/controller/action.asdf'");
            });

            // it("patternToRegex root", function (){
            //      r = m.patternToRegex("/");
            //      expect(r.regex).toBe("^\/?$");
            //  });
            //  it("patternToRegex root with format", function (){
            //      r = m.patternToRegex("/.[format]");
            //      expect(r.regex).toBe("^\.(\w+)\/?$");
            //  });
            //  it("patternToRegex with basic catch all pattern", function (){
            //      r = m.patternToRegex("/[controller]/[action]/[key].[format]");
            //      expect(r.regex).toBe("^([^\/]+)\/([^\.\/]+)\/([^\.\/]+)\.(\w+)\/?$");
            //  });

            it("$stripRouteVariables no variables", function (){
                expect(m.$stripRouteVariables("/")).toBe("");
            });
            it("$stripRouteVariables root with format", function (){
                expect(m.$stripRouteVariables("/.[format]")).toBe("format");
            });
            it("$stripRouteVariables with basic catch all pattern", function (){
                expect(m.$stripRouteVariables("/[controller]/[action]/[key].[format]"))
                .toBe("controller,action,key,format");
            });
            it("$stripRouteVariables with nested restful route", function (){
                expect(m.$stripRouteVariables("/posts(/[id](/comments(/[commentid](.[format]))))"))
                .toBe("id,commentid,format");
            });
		});
	}

}
