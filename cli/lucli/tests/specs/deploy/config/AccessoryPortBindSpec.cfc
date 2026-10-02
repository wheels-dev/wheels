/**
 * #4067: an accessory `port:` must name a bind address, as Kamal main does
 * since basecamp/kamal@00cb4cf1d. A bare `5432` (or `5432:5432`) used to be
 * passed to `docker run --publish` as written, which publishes on a random
 * host port (or on every interface) without any warning.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("accessory port: requires a bind address", () => {

			it("accepts IPv4 and bracketed IPv6 bind addresses, with an optional protocol", () => {
				for (var port in [
					"127.0.0.1:5432:5432",
					"10.0.0.20:5432:5432",
					"0.0.0.0:6379:6379",
					"[::1]:5432:5432",
					"127.0.0.1:5432:5432/tcp"
				]) {
					expect($error(port)).toBe("", port);
				}
			});

			it("accepts an accessory with no port at all", () => {
				var state = {message: ""};
				try {
					new cli.lucli.services.deploy.config.Validator().validate(
						{service: "demo", image: "a/b", servers: ["1.2.3.4"], accessories: {db: {image: "postgres:16", host: "1.2.3.5"}}},
						"test.yml"
					);
				} catch (DeployConfigError e) {
					state.message = e.message;
				}
				expect(state.message).toBe("");
			});

			it("accepts port ranges and the udp/sctp protocols", () => {
				for (var port in ["127.0.0.1:8000-8010:8000-8010", "10.0.0.20:5353:5353/udp", "[fd00::5]:3868:3868/sctp"]) {
					expect($error(port)).toBe("", port);
				}
			});

			it("rejects anything after the ports other than a protocol", () => {
				for (var port in ["127.0.0.1:5432:5432/tcp;id", "127.0.0.1:5432:5432 -v /:/x", "127.0.0.1:5432:abc", "127.0.0.1:5432:5432/http"]) {
					expect($error(port)).toInclude("must name a bind address", port);
				}
			});

			it("rejects a bare port, a host:container pair and a hostname bind", () => {
				for (var port in [5432, "5432", "5432:5432", "localhost:5432:5432", "[nope]:5432:5432", "999.1.1.1:5432:5432"]) {
					expect($error(port)).toInclude("must name a bind address", port);
				}
			});

			it("names the accessory and shows bound examples for its port", () => {
				var message = $error("5432");
				expect(message).toInclude("accessory db");
				expect(message).toInclude("""5432""");
				expect(message).toInclude("127.0.0.1:5432:5432");
				expect(message).toInclude("10.0.0.20:5432:5432");
				expect(message).toInclude("0.0.0.0:5432:5432");
			});
		});
	}

	/** The DeployConfigError message for an accessory `db` with this port, or "". */
	private string function $error(required any port) {
		var state = {message: ""};
		try {
			new cli.lucli.services.deploy.config.Validator().validate(
				{service: "demo", image: "a/b", servers: ["1.2.3.4"], accessories: {db: {image: "postgres:16", host: "1.2.3.5", port: arguments.port}}},
				"test.yml"
			);
		} catch (DeployConfigError e) {
			state.message = e.message;
		}
		return state.message;
	}
}
