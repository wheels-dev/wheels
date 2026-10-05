/**
 * isSafeRedirectUrl(redirectUrl): the public form of the check redirectTo(url=...)
 * applies, so an app can ask whether a return-to URL stays on this site
 * without attempting the redirect.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("isSafeRedirectUrl", () => {

			beforeEach(() => {
				variables.ctrl = application.wo.controller("test", {controller = "test", action = "index"});
				variables.here = request.cgi.server_name;
			});

			it("accepts a relative URL", () => {
				expect(ctrl.isSafeRedirectUrl("/safe/path")).toBeTrue();
				expect(ctrl.isSafeRedirectUrl("/page?email=a@b.com")).toBeTrue();
			});

			it("accepts an absolute or protocol-relative URL on this host", () => {
				expect(ctrl.isSafeRedirectUrl("http://" & here & "/page")).toBeTrue();
				expect(ctrl.isSafeRedirectUrl("https://" & here & ":8443/page")).toBeTrue();
				expect(ctrl.isSafeRedirectUrl("//" & here & "/page")).toBeTrue();
			});

			it("rejects another host, however it is written", () => {
				expect(ctrl.isSafeRedirectUrl("http://evil.com/phish")).toBeFalse();
				expect(ctrl.isSafeRedirectUrl("//evil.com/phish")).toBeFalse();
				expect(ctrl.isSafeRedirectUrl("/\evil.com")).toBeFalse();
				expect(ctrl.isSafeRedirectUrl("\/evil.com")).toBeFalse();
				expect(ctrl.isSafeRedirectUrl("\\evil.com")).toBeFalse();
				expect(ctrl.isSafeRedirectUrl("https:/evil.com")).toBeFalse();
				expect(ctrl.isSafeRedirectUrl("https://" & here & ":1@evil.com/phish")).toBeFalse();
				expect(ctrl.isSafeRedirectUrl(Chr(9) & "//evil.com")).toBeFalse();
			});

			it("rejects userinfo in front of this host", () => {
				expect(ctrl.isSafeRedirectUrl("https://user:pass@" & here & "/page")).toBeFalse();
			});

			it("compares against the serverName it is given", () => {
				expect(ctrl.isSafeRedirectUrl(redirectUrl = "https://app.example.com/page", serverName = "app.example.com")).toBeTrue();
				expect(ctrl.isSafeRedirectUrl(redirectUrl = "https://" & here & "/page", serverName = "app.example.com")).toBeFalse();
			});

			it("agrees with the check redirectTo uses", () => {
				for (var candidate in ["/a", "//evil.com", "http://" & here & "/b", "/\evil.com"]) {
					expect(ctrl.isSafeRedirectUrl(candidate)).toBe(ctrl.$isSafeRedirectUrl(url = candidate, serverName = here));
				}
			});

			it("is a protected framework helper, not a routable action", () => {
				expect(StructKeyExists(application.wheels.protectedControllerMethodsLookup, "isSafeRedirectUrl")).toBeTrue();
			});

		});

	}

}
