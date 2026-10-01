component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.pub = application.wheels.public;
		variables.$$hadAllowed = StructKeyExists(application.wheels, "devToolsAllowedHosts");
		if (variables.$$hadAllowed) {
			variables.$$origAllowed = application.wheels.devToolsAllowedHosts;
		}
	}

	function afterAll() {
		if (variables.$$hadAllowed) {
			application.wheels.devToolsAllowedHosts = variables.$$origAllowed;
		} else {
			StructDelete(application.wheels, "devToolsAllowedHosts");
		}
	}

	function run() {
		describe("$wheelsHostIsLocal accepts only local host names", () => {

			beforeEach(() => {
				application.wheels.devToolsAllowedHosts = "";
			});

			it("accepts localhost, 127.0.0.0/8, and [::1] (with or without a port)", () => {
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "localhost")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "localhost:60007")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "127.0.0.1")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "127.5.5.5:8080")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "[::1]:8080")).toBeTrue();
			});

			it("accepts any *.localhost name (RFC 6761)", () => {
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "myapp.localhost")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "a.b.localhost:9000")).toBeTrue();
			});

			it("rejects foreign, empty, out-of-range, and malformed hosts", () => {
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "example.com")).toBeFalse();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "")).toBeFalse();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "127.0.0.256")).toBeFalse();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "[::1]evil")).toBeFalse();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "10.0.0.5")).toBeFalse();
			});

			it("accepts a configured extra host name", () => {
				application.wheels.devToolsAllowedHosts = "dev.test,app.internal";
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "dev.test")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "app.internal:9000")).toBeTrue();
				expect(variables.pub.$wheelsHostIsLocal(hostHeader = "other.test")).toBeFalse();
			});

		});

		describe("the gate is wired and socket-independent", () => {

			it("the dispatch chokepoint calls the dev-tools gate before invoking a public action", () => {
				var src = FileRead(ExpandPath("/wheels/Dispatch.cfc"));
				var gatePos = Find("$enforceDevToolLocalAccess()", src);
				var invokePos = Find("invokeMethod(application.wheels.public", src);
				expect(gatePos).toBeGT(0, "Dispatch must call the dev-tools gate");
				expect(invokePos).toBeGT(0);
				expect(gatePos).toBeLT(invokePos, "the gate must run before the action");
			});

			it("the gate checks the Host header, not the socket REMOTE_ADDR (Docker-safe)", () => {
				var src = FileRead(ExpandPath("/wheels/Public.cfc"));
				// The gate resolves through $wheelsHostIsLocal on the Host header...
				expect(src).toInclude("$wheelsHostIsLocal");
				// ...and its body must not gate on cgi.REMOTE_ADDR (that would break Docker).
				var body = Mid(src, Find("function $enforceDevToolLocalAccess", src), 900);
				expect(FindNoCase("REMOTE_ADDR", body)).toBe(0, "the dev-tools gate must not check the socket address");
			});

		});
	}
}
