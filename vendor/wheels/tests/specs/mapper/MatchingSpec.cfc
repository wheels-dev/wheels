/**
 * This tests Wheels Application Bootstrapping
 */
component extends="wheels.WheelsTest" {


	function run() {


		describe("Matching", function() {

            beforeEach(function( currentSpec ) {
                m = new wheels.Mapper();
                m.$init();
                prepareMock(m);
                makePublic(m, "$match");
            });

            afterEach(function( currentSpec ) {
                structDelete(variables, "m");
                structDelete(variables, "r");
            });

            it("Matches with Basic Arguments and provide default controller + action", function(){
                m.$draw()
                .$match(
                    name = "signIn", method = "get", controller = "sessions", action = "new"
                ).end();
                r = m.getRoutes();
                expect(r).toBeArray().toHaveLength(1);
                expect(r[1].pattern).toBe("/sign-in");
                expect(r[1].constraints).toBeStruct().toBeEmpty();
                expect(r[1].name).toBe("signIn");
                //expect(r[1].to).toBeNull();
                expect(r[1].methods).toBe("get");
                //expect(r[1].package).toBeNull();
                //expect(r[1].on).toBeNull();
                expect(r[1].controller).toBe("sessions");
                expect(r[1].action).toBe("new");
                expect(r[1].REGEX).toBe("^sign-in\/?$");
            });

            it("Matches with to Argument", function(){
            m.$draw()
                .$match(
                name = "signIn", method = "get", to = "sessions##yes"
                ).end();
            r = m.getRoutes();
                expect(r[1].pattern).toBe("/sign-in");
                expect(r[1].name).toBe("signIn");
                expect(r[1].methods).toBe("get");
                expect(r[1].controller).toBe("sessions");
                expect(r[1].action).toBe("yes");
            });
            it("Matches without name", function(){
                m.$draw()
                .$match(
                pattern = "/sign-in", method = "get", to = "sessions##new"
                ).end();
                r = m.getRoutes();
                expect(r[1].pattern).toBe("/sign-in");
                // expect(r[1].name).toBeNull();
                expect(r[1].methods).toBe("get");
                expect(r[1].controller).toBe("sessions");
                expect(r[1].action).toBe("new");
            });
            it("Raises MapperArgumentMissing without name or pattern", function(){
                expect(function() {
                    m.$draw().$match(
                    method = "get", to = "sessions##new"
                    ).end()
                }).toThrow(type="Wheels.MapperArgumentMissing");
            });
            it("Raises without name or pattern", function(){
                expect(function() {
                    m.$draw().$match(
                        method = "get", to = "sessions##new"
                        ).end()
                }).toThrow(type="Wheels.MapperArgumentMissing");
            });
            it("Raises invalid route", function(){
                expect(function() {
                    m.$draw().$match(
                    pattern="[controller](/[action])(/[key])"
                    ).end()
                }).toThrow(type="Wheels.InvalidRoute");
            });
            it("Matches basic arguments and controller scope", function(){
                m.$draw()
                .controller("sessions")
                .$match(name = "signIn", method = "get", action = "new")
                .end()
                .end();
                r = m.getRoutes();
                expect(r[1].pattern).toBe("/sessions/sign-in");
                expect(r[1].controller).toBe("sessions");
                expect(r[1].action).toBe("new");
            });

            it("Matches basic arguments and package scope", function(){
                m.$draw()
                .namespace("admin")
                .$match(name = "signIn", method = "get", action = "new", controller="sessions")
                .end()
                .end();
                r = m.getRoutes();
                expect(r[1].pattern).toBe("/admin/sign-in");
                expect(r[1].controller).toBe("admin.Sessions");
                expect(r[1].action).toBe("new");
            });
            it("Matches package and controller scope", function(){
                m.$draw()
                .namespace("admin")
                .controller("sessions")
                .$match(name = "signIn", method = "get", action = "new", controller="sessions")
                .end()
                .end();
                r = m.getRoutes();
                expect(r[1].pattern).toBe("/admin/sessions/sign-in");
                expect(r[1].controller).toBe("admin.Sessions");
                expect(r[1].action).toBe("new");
            });
            it("Match after disabling methods", function(){
                m.$draw(restful = false, methods = false)
                .$match(pattern = "/sign-in", method = "get", to = "sessions##new")
                .end();
                r = m.getRoutes();
                expect(r[1]).notToHaveKey("method");
                expect(r[1].controller).toBe("sessions");
                expect(r[1].action).toBe("new");
            });
            it("Match with optional pattern segment", function(){
                m.$draw()
                .$match(pattern = "/sign-in(.[format])", method = "get", to = "sessions##new")
                .end();
                r = m.getRoutes();
                expect(r).toHaveLength(2);
                expect(r[1].pattern).toBe("/sign-in.[format]");
                expect(r[2].pattern).toBe("/sign-in");
            });
            it("Match with multiple pattern segment", function(){
                m.$draw()
                .$match(pattern = "/[controller](/[action](/[key](.[format])))", action = "index", method = "get")
                .end();
                r = m.getRoutes();
                expect(r).toHaveLength(4);
                expect(r[1].pattern).toBe("/[controller]/[action]/[key].[format]");
                expect(r[2].pattern).toBe("/[controller]/[action]/[key]");
                expect(r[3].pattern).toBe("/[controller]/[action]");
                expect(r[4].pattern).toBe("/[controller]");
            });
            it("Match with globing", function(){
                m.$draw()
                .$match(name = "profile", pattern = "profiles/*[userseo]/[userid]", to = "profile##show")
                .end();
                r = m.getRoutes();
                expect(r).toHaveLength(1);
                expect(r[1].pattern).toBe("/profiles/[userseo]/[userid]");
                expect(REFindNoCase(r[1].regex, "profiles/this/is/some/seo/text/id123")).toBe(1);
            });
            it("Match with multiple globs", function(){
                m.$draw()
                .$match(name = "profile", pattern = "*[before]/foo/*[after]", to = "profile##show")
                .end();
                r = m.getRoutes();
                expect(r).toHaveLength(1);
                expect(r[1].pattern).toBe("/[before]/foo/[after]");
                expect(REFindNoCase(r[1].regex, "this/is/before/foo/this/is/after")).toBe(1);
            });

            it("Generates URL Pattern without Name", function(){
                m.$draw()
                .package("public")
                .root(to = "pages##home")
                .end()
                .end();
                r = m.getRoutes();
                expect(r).toBeArray().toHaveLength(2);
                expect(r[1].pattern).toBe("/.[format]");
                expect(r[2].pattern).toBe("/");
                expect(r[1].controller).toBe("public.pages");
                expect(r[2].controller).toBe("public.pages");
            });
            it("Passes through redirect argument", function(){
                m.$draw()
                .get(name = "testredirect1", redirect = "https://www.google.com")
                .post(name = "testredirect2", redirect = "https://www.google.com")
                .put(name = "testredirect3", redirect = "https://www.google.com")
                .patch(name = "testredirect4", redirect = "https://www.google.com")
                .delete(name = "testredirect5", redirect = "https://www.google.com")
                .end();
                r = m.getRoutes();
                expect(r).toBeArray().toHaveLength(5);
                expect(r[1]).toHaveKey("redirect")
                expect(r[2]).toHaveKey("redirect")
                expect(r[3]).toHaveKey("redirect")
                expect(r[4]).toHaveKey("redirect")
                expect(r[5]).toHaveKey("redirect")
            });

            // Guard against redundant namespace prefix in `to=` / `controller=`.
            // See #2791: inside .namespace("foo"), writing to="foo/dashboard##index"
            // silently produced a "foo.foo/dashboard" controller path which downstream
            // got flattened to a Foodashboard class lookup with an opaque error.
            it("Rejects to= with redundant namespace prefix", function(){
                expect(function() {
                    m.$draw()
                    .namespace("datapai")
                        .get(name = "datapaiDashboard", pattern = "dashboard", to = "datapai/dashboard##index")
                    .end()
                    .end();
                }).toThrow(type = "Wheels.MapperArgumentInvalid");
            });
            it("Rejects controller= with redundant namespace prefix", function(){
                expect(function() {
                    m.$draw()
                    .namespace("admin")
                        .$match(name = "dashboard", method = "get", controller = "admin/dashboard", action = "index")
                    .end()
                    .end();
                }).toThrow(type = "Wheels.MapperArgumentInvalid");
            });
            it("Rejects redundant prefix in nested namespaces", function(){
                expect(function() {
                    m.$draw()
                    .namespace("admin")
                        .namespace("users")
                            .get(name = "edit", pattern = "edit", to = "admin/users/profile##edit")
                        .end()
                    .end()
                    .end();
                }).toThrow(type = "Wheels.MapperArgumentInvalid");
            });
            it("Rejects redundant prefix inside .package() too", function(){
                expect(function() {
                    m.$draw()
                    .package("admin")
                        .get(name = "users", pattern = "users", to = "admin/users##index")
                    .end()
                    .end();
                }).toThrow(type = "Wheels.MapperArgumentInvalid");
            });
            it("Allows controllers whose name only happens to share a prefix with the namespace", function(){
                // "foobar/dashboard" inside .namespace("foo") is NOT a redundant prefix
                // — "foobar" != "foo". Must not be rejected.
                m.$draw()
                .namespace("foo")
                    .get(name = "dashboard", pattern = "dashboard", to = "foobar/dashboard##index")
                .end()
                .end();
                r = m.getRoutes();
                expect(r).toBeArray();
                expect(ArrayLen(r) >= 1).toBeTrue();
            });
            it("Accepts the correct (non-redundant) form inside a namespace", function(){
                m.$draw()
                .namespace("datapai")
                    .get(name = "datapaiDashboard", pattern = "dashboard", to = "dashboard##index")
                .end()
                .end();
                r = m.getRoutes();
                expect(r).toBeArray();
                expect(ArrayLen(r) >= 1).toBeTrue();
                expect(r[1].controller).toBe("datapai.dashboard");
                expect(r[1].action).toBe("index");
            });
        });
    }

}
