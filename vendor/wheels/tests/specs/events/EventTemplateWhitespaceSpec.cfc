/**
 * The per-request / lifecycle event templates are $include'd straight into the
 * response buffer (EventMethods.$runOnRequestStart / $runOnRequestEnd / onSessionStart).
 * A bare cfscript block emits a stray newline when included, and a trailing newline after
 * the file leaks too — so an unwrapped template prepends whitespace to every response,
 * which breaks XML emitted by renderText (the declaration must be the first byte). The
 * templates are wrapped in a cfsilent block with no trailing newline; this pins that they
 * produce zero output when included the way the framework includes them. (#3882)
 */
component extends="wheels.WheelsTest" {

	function run() {
		describe("Event template whitespace (##3882)", function() {

			it("per-request and lifecycle event templates emit no output when included", function() {
				var events = [
					"onabort",
					"onapplicationend",
					"onapplicationstart",
					"onrequestend",
					"onrequeststart",
					"onsessionend",
					"onsessionstart"
				];
				for (var name in events) {
					var captured = "";
					savecontent variable="captured" {
						application.wo.$include(template = "#application.wheels.eventPath#/#name#.cfm");
					}
					expect(Len(captured)).toBe(
						0,
						"#name#.cfm must emit zero bytes when $include'd — leading whitespace breaks XML from renderText"
					);
				}
			});
		});
	}

}
