component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("ConfigLoader", () => {

			it("loads minimal.yml", () => {
				var cfg = new cli.lucli.services.deploy.config.ConfigLoader()
					.load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));
				expect(cfg.service()).toBe("demo");
				expect(cfg.image()).toBe("acme/demo");
				expect(cfg.roles()[1].name()).toBe("web");
				expect(cfg.roles()[1].hosts()).toInclude("1.2.3.4");
			});

			it("resolves ${VAR} from envOverride", () => {
				var tmp = getTempFile(getTempDirectory(), "yml");
				fileWrite(tmp, "service: demo#chr(10)#image: acme/${TESTVAR}#chr(10)#servers: [1.2.3.4]#chr(10)#registry: {username: u, password: [X]}");
				var loader = new cli.lucli.services.deploy.config.ConfigLoader({envOverride: {TESTVAR: "custom"}});
				var cfg = loader.load(tmp);
				expect(cfg.image()).toBe("acme/custom");
			});

			it("merges destination overlay", () => {
				var base = getTempFile(getTempDirectory(), "yml");
				fileWrite(base, "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#env: {clear: {PORT: '3000'}}#chr(10)#registry: {username: u, password: [X]}");
				var overlay = left(base, len(base) - 4) & ".production.yml";
				fileWrite(overlay, "env:#chr(10)#  clear:#chr(10)#    PORT: '4000'");
				var cfg = new cli.lucli.services.deploy.config.ConfigLoader()
					.load(base, {destination: "production"});
				expect(cfg.env().clear().PORT).toBe("4000");
			});

			it("parses full.yml (Kamal upstream fixture) without throwing", () => {
				var cfg = new cli.lucli.services.deploy.config.ConfigLoader()
					.load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/full.yml"));
				expect(isObject(cfg)).toBeTrue();
			});

		});

	}

}
