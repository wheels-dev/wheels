/**
 * Base controller for the browser-test fixture controllers in this
 * directory. Resolves when `$lockedLoadRoutes` appends
 * `/wheels/public/browser-fixtures/controllers` to the controller
 * search path, so `extends="Controller"` in BrowserTestHome /
 * BrowserTestLogin / BrowserTestSessions finds this stub.
 *
 * Provides a small `$renderBrowserFixtureView()` helper that renders a
 * fixture view + the shared fixture layout via explicit `cfinclude`s.
 * The fixtures cannot use the normal Wheels view-path resolver because
 * the framework's `viewPath` setting is a single string pinned to
 * `/app/views` and these fixture views live under
 * `/wheels/public/browser-fixtures/views/`.
 *
 * Mirrors `vendor/wheels/tests/_assets/controllers/Controller.cfc` in
 * spirit (minimal stub that delegates to `wheels.Controller`).
 */
component extends="wheels.Controller" {

	/**
	 * Renders `/wheels/public/browser-fixtures/views/<folder>/<action>.cfm`
	 * wrapped in the fixture folder's shared `layout.cfm`, and short-
	 * circuits the normal Wheels view-rendering pipeline via `renderText`.
	 *
	 * Callers pass the view `action` (filename without extension). The
	 * controller's `params.controller` is used for the folder name,
	 * matching Wheels' own view-folder convention. The layout is a plain
	 * CFM file that references a local `contentForLayout` variable
	 * populated here before the layout include.
	 */
	private void function $renderBrowserFixtureView(required string action) {
		var folder = LCase(variables.params.controller);
		var viewsBase = "/wheels/public/browser-fixtures/views/" & folder;

		savecontent variable="local.contentForLayout" {
			include template="#viewsBase#/#arguments.action#.cfm";
		}

		// The fixture layouts reference `contentForLayout` as a local variable
		// (not the framework helper) to avoid depending on the normal Wheels
		// layout pipeline.
		var contentForLayout = local.contentForLayout;

		savecontent variable="local.page" {
			include template="#viewsBase#/layout.cfm";
		}

		renderText(local.page);
	}

}
