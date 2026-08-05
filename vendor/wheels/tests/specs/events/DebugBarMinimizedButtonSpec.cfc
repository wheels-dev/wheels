component extends="wheels.WheelsTest" {

	function run() {
		describe("debug bar minimized restore button placement", () => {
			// wdbMinimize() (public/assets/js/debugbar.js) sets #wheels-debugbar to
			// display:none and #wdb-minimized to display:block. A descendant of a
			// display:none element is never rendered regardless of its own display
			// value, so the "Debug" restore button must be a SIBLING of the
			// container, not a child — otherwise clicking the X hides the bar for
			// the whole browser session with no visible recovery (issue #3345).
			// This spec renders debug.cfm and asserts structurally that
			// id="wdb-minimized" appears only after the div balance for
			// #wheels-debugbar has returned to zero (sibling, not descendant).
			it("renders the wdb-minimized button as a sibling of the debug bar container", () => {
				var priorReqWheels = StructKeyExists(request, "wheels") ? Duplicate(request.wheels) : {};

				try {
					if (!StructKeyExists(request, "wheels")) {
						request.wheels = {};
					}
					request.wheels.execution = {total = 0};
					request.wheels.params = {controller = "wheels", action = "tests", route = ""};

					// debug.cfm bails out (cfexit) when url.format is one of
					// json/xml/csv/pdf so it never breaks an API response. The
					// test runner is hit with format=json — clear it for the
					// duration of the include so the template renders.
					var hadUrlFormat = StructKeyExists(url, "format");
					var priorUrlFormat = hadUrlFormat ? url.format : "";
					if (hadUrlFormat) {
						StructDelete(url, "format");
					}

					var output = "";
					try {
						output = application.wo.$includeAndReturnOutput($template = "/wheels/events/onrequestend/debug.cfm");
					} finally {
						if (hadUrlFormat) {
							url.format = priorUrlFormat;
						}
					}

					var containerPos = FindNoCase('id="wheels-debugbar"', output);
					expect(containerPos).toBeGT(0, "the ##wheels-debugbar container should render");

					var minimizedPos = FindNoCase('id="wdb-minimized"', output);
					expect(minimizedPos).toBeGT(0, "the ##wdb-minimized restore button should render");

					// Walk <div / </div tokens starting just inside the container's
					// opening tag and find where its balance returns to zero (the
					// position of the container's own closing tag).
					var depth = 1;
					var pos = containerPos;
					var containerClosePos = 0;
					while (depth > 0) {
						var nextOpen = FindNoCase("<div", output, pos + 1);
						var nextClose = FindNoCase("</div", output, pos + 1);
						expect(nextClose).toBeGT(0, "unbalanced markup: ##wheels-debugbar never closes");
						if (nextOpen > 0 && nextOpen < nextClose) {
							depth += 1;
							pos = nextOpen;
						} else {
							depth -= 1;
							pos = nextClose;
							containerClosePos = nextClose;
						}
					}

					expect(minimizedPos).toBeGT(
						containerClosePos,
						"##wdb-minimized must render AFTER ##wheels-debugbar closes (sibling, not descendant) — " &
						"nested inside the container, wdbMinimize()'s display:none makes the restore button unreachable (##3345)"
					);
				} finally {
					request.wheels = priorReqWheels;
				}
			});
		});
	}

}
