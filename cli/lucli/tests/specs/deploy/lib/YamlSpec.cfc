component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("Yaml", () => {

			it("parses a flat map", () => {
				var y = new cli.lucli.services.deploy.lib.Yaml();
				var out = y.parse("service: myapp#chr(10)#image: acme/myapp");
				expect(out.service).toBe("myapp");
				expect(out.image).toBe("acme/myapp");
			});

			it("parses nested structure", () => {
				var y = new cli.lucli.services.deploy.lib.Yaml();
				var src = "servers:#chr(10)#  web:#chr(10)#    - 1.2.3.4#chr(10)#    - 1.2.3.5";
				var out = y.parse(src);
				expect(out.servers.web[1]).toBe("1.2.3.4");
				expect(out.servers.web[2]).toBe("1.2.3.5");
			});

			it("rejects Java class tags for security", () => {
				var y = new cli.lucli.services.deploy.lib.Yaml();
				expect(() => y.parse("!!javax.script.ScriptEngineManager [null]"))
					.toThrow();
			});

			it("deepMerge overlays right onto left", () => {
				var y = new cli.lucli.services.deploy.lib.Yaml();
				var base = {env: {clear: {PORT: "3000"}, secret: ["DB"]}};
				var overlay = {env: {clear: {PORT: "4000", HOST: "x"}}};
				var merged = y.deepMerge(base, overlay);
				expect(merged.env.clear.PORT).toBe("4000");
				expect(merged.env.clear.HOST).toBe("x");
				expect(merged.env.secret[1]).toBe("DB");
			});

		});

	}

}
