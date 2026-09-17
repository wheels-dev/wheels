component extends="wheels.WheelsTest" {

	function run() {
		describe("debug bar collapse chrome (issue 3547)", () => {
			// Closing the bar used to hide ##wheels-debugbar and reveal a floating
			// sibling button labeled "Debug" (the ##3345 restore control). Collapse
			// now keeps the container visible and shrinks it to the stylized W logo
			// via a CSS width transition. These specs lock the chrome contract:
			// logo first, X last, no floating Debug button, no inline width fight,
			// collapsed-chrome CSS hides non-logo bar children.

			it("renders the stylized W logo first and the X close last, with no floating Debug button", () => {
				var output = $renderDebugBar();

				expect(output contains 'id="wheels-debugbar"').toBeTrue(
					"the debug bar container should render"
				);
				expect(output contains 'id="wdb-minimized"').toBeFalse(
					"the floating ##wdb-minimized restore control must not render"
				);
				expect(output contains "</svg>Debug</button>").toBeFalse(
					"the collapsed chrome must not be a floating button labeled Debug"
				);
				expect(
					FindNoCase('id="wheels-debugbar" style="all:initial;display:block;', output)
				).toBeGT(
					0,
					"all:initial isolation must restore display:block so width can layout and transition"
				);
				expect(
					FindNoCase('id="wheels-debugbar" style="all:initial;display:block;position:fixed;bottom:0;left:0;width:', output)
				).toBe(
					0,
					"the root inline style must not pin width — stylesheet width has to animate"
				);

				var barStart = FindNoCase('id="wdb-bar"', output);
				expect(barStart).toBeGT(0, "the ##wdb-bar chrome row should render");

				var panelStart = FindNoCase('id="wdb-panel-request"', output);
				expect(panelStart).toBeGT(barStart, "the Request panel should follow the chrome row");

				var barHtml = Mid(output, barStart, panelStart - barStart);
				var logoPos = FindNoCase('wdb-logo', barHtml);
				var closePos = FindNoCase('wdb-close', barHtml);
				expect(logoPos).toBeGT(0, "the stylized W logo button should be in the chrome row");
				expect(closePos).toBeGT(logoPos, "the X close button must be the last chrome element after the logo");

				var firstButton = FindNoCase("<button", barHtml);
				expect(firstButton).toBeGT(0, "the chrome row should contain buttons");
				expect(FindNoCase("wdb-logo", barHtml, firstButton)).toBeGT(
					0,
					"the first button in the chrome row must be the stylized W logo"
				);
				expect(logoPos).toBeLT(
					FindNoCase("<button", barHtml, firstButton + 1),
					"no chrome button should precede the stylized W logo"
				);

				var lastButton = 0;
				var scan = 0;
				while (true) {
					var nextButton = FindNoCase("<button", barHtml, scan + 1);
					if (nextButton == 0) {
						break;
					}
					lastButton = nextButton;
					scan = nextButton;
				}
				expect(lastButton).toBeGT(0, "the chrome row should end with a button");
				expect(FindNoCase("wdb-close", Mid(barHtml, lastButton, 120))).toBeGT(
					0,
					"the last chrome button must be the X close control"
				);
				expect(FindNoCase("wdbMinimize()", barHtml, lastButton)).toBeGT(
					0,
					"the X close control must call wdbMinimize()"
				);
			});

			it("collapses and expands with a CSS width transition instead of hiding the container", () => {
				var css = FileRead(ExpandPath("/wheels/public/assets/css/debugbar.css"));
				var js = FileRead(ExpandPath("/wheels/public/assets/js/debugbar.js"));

				expect(FindNoCase("wdb-collapsed", css)).toBeGT(
					0,
					"debugbar.css must define the collapsed chrome class"
				);
				expect(FindNoCase("transition", css)).toBeGT(
					0,
					"debugbar.css must animate collapse/expand with a CSS transition"
				);
				expect(FindNoCase("width:40px", css)).toBeGT(
					0,
					"collapsed chrome must shrink to a logo-sized width"
				);
				expect(FindNoCase("width:100% !important", css)).toBeGT(
					0,
					"expanded width must be stylesheet-driven with !important so it beats all:initial and interpolates with the collapsed 40px rule"
				);
				expect(FindNoCase(".wdb-bar>:not(.wdb-logo)", css)).toBeGT(
					0,
					"collapsed chrome must hide non-logo children of .wdb-bar, not only clip them"
				);
				expect(FindNoCase("wdb-collapsed", js)).toBeGT(
					0,
					"debugbar.js must toggle the collapsed class"
				);
				expect(FindNoCase("wdbLogoClick", js)).toBeGT(
					0,
					"debugbar.js must expand the bar when the collapsed logo is clicked"
				);
				// Was a file-wide `display = 'none'` search, which is a blunt
				// proxy: it also trips on the panels' legitimate display
				// toggles for their own result blocks, and those have nothing
				// to do with the collapse. Assert the documented intent
				// directly instead — the collapse must animate through the
				// width transition, so wdbMinimize() must not hide anything,
				// and the bar element itself must never be display-hidden.
				var minimizeAt = FindNoCase("window.wdbMinimize", js);
				expect(minimizeAt).toBeGT(0, "debugbar.js must define wdbMinimize()");
				expect(FindNoCase("display", Mid(js, minimizeAt, 85))).toBe(
					0,
					"wdbMinimize() must collapse via the width transition, not hide the container with display:none"
				);
				expect(FindNoCase("debugRoot()).style.display", js)).toBe(
					0,
					"nothing may hide ##wheels-debugbar itself with display:none"
				);
				expect(js contains "wdb-minimized").toBeFalse(
					"debugbar.js must not drive a floating ##wdb-minimized restore button"
				);
			});
		});
	}

	/**
	 * Renders the debug bar template with the request state the template
	 * requires, restoring url.format and request.wheels afterwards.
	 */
	private string function $renderDebugBar() {
		var priorReqWheels = StructKeyExists(request, "wheels") ? Duplicate(request.wheels) : {};
		var hadUrlFormat = StructKeyExists(url, "format");
		var priorUrlFormat = hadUrlFormat ? url.format : "";
		var output = "";
		try {
			if (!StructKeyExists(request, "wheels")) {
				request.wheels = {};
			}
			request.wheels.execution = {total = 0};
			request.wheels.params = {controller = "wheels", action = "tests", route = ""};
			if (hadUrlFormat) {
				StructDelete(url, "format");
			}
			output = application.wo.$includeAndReturnOutput($template = "/wheels/events/onrequestend/debug.cfm");
		} finally {
			if (hadUrlFormat) {
				url.format = priorUrlFormat;
			}
			request.wheels = priorReqWheels;
		}
		return output;
	}

}
