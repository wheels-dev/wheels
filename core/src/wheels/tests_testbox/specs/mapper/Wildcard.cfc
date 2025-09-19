/**
 * This tests Wheels Application Bootstrapping
 */
component extends="wheels.Testbox" {


	function run() {


		describe("Wildcards", function() {

            beforeEach(function( currentSpec ) {
                m = new wheels.Mapper();
                m.$init();
                prepareMock(m);
            });

            afterEach(function( currentSpec ) {
                structDelete(variables, "m");
                structDelete(variables, "r");
            });

            it("default wildcard produces routes", function() {
                m.$draw()
                    .wildcard()
                    .end();

                    r = m.getRoutes();
                    expect(r).toBeArray().toHaveLength(2);
            });

            it("default wildcard only allows get requests", function() {
                m.$draw()
                    .wildcard()
                    .end();

                    r = m.getRoutes();

                    for (loc.route in m.getRoutes()) {
                        expect(loc.route.methods).toBe("get");
                    }
            });

            it("default wildcard generates correct patterns", function() {
                m.$draw()
                    .wildcard()
                    .end();

                    r = m.getRoutes();

                expect(r[1].pattern).toBe("/[controller]/[action]");
                expect(r[2].pattern).toBe("/[controller]");
            });

            it("wildcard with methods produces routes", function() {
                m.$draw()
                    .wildcard(methods = "get,post")
                    .end();

                    r = m.getRoutes();
                    expect(r).toBeArray().toHaveLength(4);
            });

            it("wildcard with methods generates correct patterns", function() {
                m.$draw()
                    .wildcard(methods = "get,post")
                    .end();

                    r = m.getRoutes();

                expect(r).toBeArray().toHaveLength(4);
                expect(r[1].pattern).toBe("/[controller]/[action]");
                expect(r[2].pattern).toBe("/[controller]");
                expect(r[3].pattern).toBe("/[controller]/[action]");
                expect(r[4].pattern).toBe("/[controller]");

            });

            it("controller scoped wildcard produces routes", function() {
                m.$draw()
                    .controller("cats")
                    .wildcard()
                    .end()
                    .end();

                    r = m.getRoutes();
                    expect(r).toBeArray().toHaveLength(2);

            });

            it("controller scoped wildcard only allows get requests", function() {
                m.$draw()
                    .controller("cats")
                    .wildcard()
                    .end()
                    .end();

                    r = m.getRoutes();

                for (loc.route in m.getRoutes()) {
                    expect(loc.route.methods).toBe("get");
                }
            });

            it("controller scoped wildcard generates correct patterns", function() {
                m.$draw()
                    .controller("cats")
                    .wildcard()
                    .end()
                    .end();

                    r = m.getRoutes();

                expect(r[1].pattern).toBe("/cats/[action]");
                expect(r[2].pattern).toBe("/cats");
            });

            it("wildcard with map format", function() {
                m.$draw()
                    .controller("cats")
                    .wildcard(mapFormat = true)
                    .end()
                    .end();

                    r = m.getRoutes();

                expect(r[1].pattern).toBe("/cats/[action].[format]");
                expect(r[2].pattern).toBe("/cats/[action]");
                expect(r[3].pattern).toBe("/cats.[format]");
                expect(r[4].pattern).toBe("/cats");
            });

            it("wildcard with map key", function() {
                m.$draw()
                    .controller("cats")
                    .wildcard(mapKey = true)
                    .end()
                    .end();

                    r = m.getRoutes();

                expect(r[1].pattern).toBe("/cats/[action]/[key]");
                expect(r[2].pattern).toBe("/cats/[action]");
                expect(r[3].pattern).toBe("/cats");
            });

		});
	}

}
