/**
 * LocalRunner executes deploy's local commands (registry login, image build
 * and push) for real: argv only, stdin for secrets, merged output drained as
 * it arrives (so a chatty process can never block on a full pipe), every
 * output line redacted before it is shown, and a redacted tail kept for
 * failure messages.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("LocalRunner", () => {

			beforeEach(() => {
				new cli.lucli.services.deploy.lib.SecretRedaction().reset();
			});

			var $sink = () => {
				var state = {lines: []};
				state.fn = function(line) { arrayAppend(state.lines, line); };
				return state;
			};

			it("passes each argument verbatim with no shell ($, quotes, spaces, ;)", () => {
				var s = $sink();
				var r = new cli.lucli.services.deploy.lib.LocalRunner(s.fn).run(
					["printf", "%s|", "robot$ci", "it's", "a b", "x;id", "$(echo nope)"]
				);
				expect(r.exitCode).toBe(0);
				expect(arrayToList(s.lines, chr(10))).toBe("robot$ci|it's|a b|x;id|$(echo nope)|");
			});

			it("delivers stdin and drains large merged output without blocking", () => {
				var s = $sink();
				var started = getTickCount();
				// Read stdin first, then write ~2 MB to stdout and stderr.
				var r = new cli.lucli.services.deploy.lib.LocalRunner(s.fn).run(
					["bash", "-c", "read -r pw; echo got-$pw; head -c 1000000 /dev/zero | tr '\\0' 'a'; echo; head -c 1000000 /dev/zero | tr '\\0' 'b' 1>&2; echo; echo done"],
					"stdin-value"
				);
				expect(r.exitCode).toBe(0);
				expect(getTickCount() - started).toBeLT(60000);
				expect(s.lines[1]).toBe("got-stdin-value");
				expect(s.lines[arrayLen(s.lines)]).toBe("done");
			});

			it("redacts registered secrets in streamed lines and in the failure tail", () => {
				new cli.lucli.services.deploy.lib.SecretRedaction().register("s3cret-value-77");
				var s = $sink();
				var r = new cli.lucli.services.deploy.lib.LocalRunner(s.fn).run(
					["bash", "-c", "echo token s3cret-value-77; echo failing 1>&2; exit 3"]
				);
				expect(r.exitCode).toBe(3);
				expect(arrayToList(s.lines, chr(10))).notToInclude("s3cret-value-77");
				expect(arrayToList(s.lines, chr(10))).toInclude("token [REDACTED]");
				expect(r.outputTail).notToInclude("s3cret-value-77");
				expect(r.outputTail).toInclude("failing");
			});

			it("bounds the failure tail", () => {
				var s = $sink();
				var r = new cli.lucli.services.deploy.lib.LocalRunner(s.fn).run(
					["bash", "-c", "for i in $(seq 1 500); do echo line-$i; done; exit 1"]
				);
				expect(r.exitCode).toBe(1);
				expect(r.outputTail).toInclude("line-500");
				expect(r.outputTail).notToInclude("line-1" & chr(10));
			});
		});
	}
}
