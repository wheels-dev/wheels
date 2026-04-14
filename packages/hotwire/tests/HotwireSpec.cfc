component extends="wheels.WheelsTest" {

	function beforeAll() {
		hw = new plugins.hotwire.Hotwire();
		hw.init();
	}

	function run() {

		describe("hotwireIncludes()", () => {

			it("outputs Turbo script tag by default", () => {
				var result = hw.hotwireIncludes();
				expect(result).toInclude("@hotwired/turbo");
				expect(result).toInclude('type="module"');
			})

			it("outputs Stimulus script tag by default", () => {
				var result = hw.hotwireIncludes();
				expect(result).toInclude("@hotwired/stimulus");
				expect(result).toInclude("Application.start()");
			})

			it("outputs turbo-cache-control meta tag by default", () => {
				var result = hw.hotwireIncludes();
				expect(result).toInclude('name="turbo-cache-control"');
				expect(result).toInclude('content="no-preview"');
			})

			it("omits Turbo when turbo=false", () => {
				var result = hw.hotwireIncludes(turbo=false);
				expect(result).notToInclude("@hotwired/turbo");
			})

			it("omits Stimulus when stimulus=false", () => {
				var result = hw.hotwireIncludes(stimulus=false);
				expect(result).notToInclude("@hotwired/stimulus");
			})

			it("omits cache-control meta when turboCacheControl is empty", () => {
				var result = hw.hotwireIncludes(turboCacheControl="");
				expect(result).notToInclude("turbo-cache-control");
			})

		})

		describe("turboFrame()", () => {

			it("generates opening tag with required id attribute", () => {
				var result = hw.turboFrame(id="my-frame");
				expect(result).toInclude('<turbo-frame');
				expect(result).toInclude('id="my-frame"');
			})

			it("includes src attribute when provided", () => {
				var result = hw.turboFrame(id="lazy-frame", src="/content/load");
				expect(result).toInclude('src="/content/load"');
			})

			it("includes loading attribute when provided", () => {
				var result = hw.turboFrame(id="lazy-frame", src="/load", loading="lazy");
				expect(result).toInclude('loading="lazy"');
			})

			it("includes target attribute when provided", () => {
				var result = hw.turboFrame(id="nav-frame", target="_top");
				expect(result).toInclude('target="_top"');
			})

			it("omits optional attributes when not provided", () => {
				var result = hw.turboFrame(id="bare-frame");
				expect(result).notToInclude("src=");
				expect(result).notToInclude("loading=");
				expect(result).notToInclude("target=");
			})

		})

		describe("turboFrameEnd()", () => {

			it("returns closing turbo-frame tag", () => {
				var result = hw.turboFrameEnd();
				expect(result).toBe("</turbo-frame>");
			})

		})

		describe("Turbo Stream helpers", () => {

			it("turboStreamAppend() generates append action with template", () => {
				var result = hw.turboStreamAppend(target="list", content="<li>item</li>");
				expect(result).toInclude('action="append"');
				expect(result).toInclude('target="list"');
				expect(result).toInclude("<template>");
				expect(result).toInclude("<li>item</li>");
				expect(result).toInclude("</template>");
			})

			it("turboStreamPrepend() generates prepend action with template", () => {
				var result = hw.turboStreamPrepend(target="list", content="<li>first</li>");
				expect(result).toInclude('action="prepend"');
				expect(result).toInclude('target="list"');
				expect(result).toInclude("<template>");
			})

			it("turboStreamReplace() generates replace action with template", () => {
				var result = hw.turboStreamReplace(target="row-1", content="<tr>new</tr>");
				expect(result).toInclude('action="replace"');
				expect(result).toInclude('target="row-1"');
				expect(result).toInclude("<template>");
			})

			it("turboStreamUpdate() generates update action with template", () => {
				var result = hw.turboStreamUpdate(target="sidebar", content="<p>updated</p>");
				expect(result).toInclude('action="update"');
				expect(result).toInclude('target="sidebar"');
				expect(result).toInclude("<template>");
			})

			it("turboStreamBefore() generates before action with template", () => {
				var result = hw.turboStreamBefore(target="header", content="<div>before</div>");
				expect(result).toInclude('action="before"');
				expect(result).toInclude('target="header"');
				expect(result).toInclude("<template>");
			})

			it("turboStreamAfter() generates after action with template", () => {
				var result = hw.turboStreamAfter(target="footer", content="<div>after</div>");
				expect(result).toInclude('action="after"');
				expect(result).toInclude('target="footer"');
				expect(result).toInclude("<template>");
			})

			it("turboStreamRemove() generates remove action with no template element", () => {
				var result = hw.turboStreamRemove(target="stale-row");
				expect(result).toInclude('action="remove"');
				expect(result).toInclude('target="stale-row"');
				expect(result).notToInclude("<template>");
			})

			it("turboStreamRefresh() generates refresh action with no template element", () => {
				var result = hw.turboStreamRefresh();
				expect(result).toInclude('action="refresh"');
				expect(result).notToInclude("<template>");
			})

		})

		describe("Stimulus helpers", () => {

			it("stimulusController() generates data-controller attribute", () => {
				var result = hw.stimulusController(controllers="toggle");
				expect(result).toBe('data-controller="toggle"');
			})

			it("stimulusController() supports multiple controllers", () => {
				var result = hw.stimulusController(controllers="toggle clipboard");
				expect(result).toInclude("toggle");
				expect(result).toInclude("clipboard");
			})

			it("stimulusAction() generates data-action attribute", () => {
				var result = hw.stimulusAction(actions="click->toggle##switch");
				expect(result).toInclude('data-action=');
				expect(result).toInclude("click->toggle");
			})

			it("stimulusTarget() generates data-{controller}-target attribute", () => {
				var result = hw.stimulusTarget(controller="toggle", name="content");
				expect(result).toBe('data-toggle-target="content"');
			})

			it("stimulusValue() generates data-{controller}-{name}-value attribute", () => {
				var result = hw.stimulusValue(controller="counter", name="count", value="0");
				expect(result).toBe('data-counter-count-value="0"');
			})

		})

	}

}
