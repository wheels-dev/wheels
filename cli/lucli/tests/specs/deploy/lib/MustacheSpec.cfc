component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("Mustache", () => {

			it("renders a simple variable", () => {
				var m = new cli.lucli.services.deploy.lib.Mustache();
				expect(m.render("Hello {{name}}", {name: "World"})).toBe("Hello World");
			});

			it("renders a missing key as empty by default", () => {
				var m = new cli.lucli.services.deploy.lib.Mustache();
				expect(m.render("Hello {{missing}}", {})).toBe("Hello ");
			});

			it("renderStrict() throws on missing key", () => {
				var m = new cli.lucli.services.deploy.lib.Mustache();
				expect(() => m.renderStrict("{{missing}}", {})).toThrow();
			});

			it("renders a section loop", () => {
				var m = new cli.lucli.services.deploy.lib.Mustache();
				var ctx = {hosts: [{name: "a"}, {name: "b"}]};
				expect(m.render("{{##hosts}}[{{name}}]{{/hosts}}", ctx)).toBe("[a][b]");
			});

		});

	}

}
