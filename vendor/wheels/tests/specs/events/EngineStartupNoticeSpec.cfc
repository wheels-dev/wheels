/**
 * EngineStartupNotice.isBenign() lets onError() pass over exactly one engine
 * notice: Adobe ColdFusion 2025 reporting a missing optional graphqlclient
 * package while it applies the application's datasources, before the
 * application starts (#3726). Everything else must still render as an error.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("EngineStartupNotice.isBenign (##3726)", () => {

			var notice = CreateObject("component", "wheels.events.EngineStartupNotice");
			var stack = "coldfusion.runtime.ServiceFactory.getGraphQLClientService(ServiceFactory.java:1467)" & Chr(10)
				& Chr(9) & "at coldfusion.runtime.ApplicationSettings.loadAppDatasources(ApplicationSettings.java:160)" & Chr(10)
				& Chr(9) & "at coldfusion.runtime.ApplicationScope.setApplicationSettings(ApplicationScope.java:328)";
			var signature = function() {
				return {
					Type = "Application",
					Message = "The graphqlclient package is not installed.",
					Detail = "You can install package through CLI package manager (cfpm) by running the command : install graphqlclient.",
					StackTrace = stack
				};
			};

			it("recognizes the exact pre-start graphqlclient notice", () => {
				expect(notice.isBenign(signature(), "")).toBeTrue();
			});

			it("is not benign once the application has an event name", () => {
				expect(notice.isBenign(signature(), "onRequest")).toBeFalse();
				expect(notice.isBenign(signature(), "onApplicationStart")).toBeFalse();
			});

			it("is not benign for a different exception type", () => {
				var e = signature();
				e.Type = "Expression";
				expect(notice.isBenign(e, "")).toBeFalse();
			});

			it("is not benign for a different message, including a localized one", () => {
				var e = signature();
				e.Message = "Le package graphqlclient n'est pas installe.";
				expect(notice.isBenign(e, "")).toBeFalse();
				e.Message = "The graphqlclient package is not installed. Something else failed.";
				expect(notice.isBenign(e, "")).toBeFalse();
			});

			it("is not benign when either stack frame is missing", () => {
				var e = signature();
				e.StackTrace = Replace(stack, "ApplicationSettings.loadAppDatasources", "ApplicationSettings.somethingElse");
				expect(notice.isBenign(e, "")).toBeFalse();
				e.StackTrace = Replace(stack, "ServiceFactory.getGraphQLClientService", "ServiceFactory.getOtherService");
				expect(notice.isBenign(e, "")).toBeFalse();
				e.StackTrace = "";
				expect(notice.isBenign(e, "")).toBeFalse();
			});

			it("never throws on an unexpected exception shape", () => {
				expect(notice.isBenign("not an exception", "")).toBeFalse();
				expect(notice.isBenign({}, "")).toBeFalse();
				var e = signature();
				e.Message = {nested = true};
				expect(notice.isBenign(e, "")).toBeFalse();
			});

		});

	}

}
