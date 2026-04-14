component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("h() view helper", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			});

			it("encodes HTML special characters", () => {
				var result = _controller.h("<script>alert('xss')</script>");
				expect(result).toInclude("&lt;script&gt;");
			});

			it("returns empty string for empty input", () => {
				expect(_controller.h("")).toBe("");
			});

			it("passes through safe text unchanged", () => {
				expect(_controller.h("Hello World")).toBe("Hello World");
			});

			it("encodes ampersands", () => {
				var result = _controller.h("Tom & Jerry");
				expect(result).toInclude("&amp;");
			});

			it("encodes double quotes", () => {
				var result = _controller.h('He said "hello"');
				expect(result).toInclude("&quot;");
			});

			it("handles numeric input by converting to string", () => {
				expect(_controller.h(42)).toBe("42");
			});

		});

		describe("hAttr() view helper", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			});

			it("encodes for HTML attribute context", () => {
				var result = _controller.hAttr('"><script>alert(1)</script>');
				expect(result).notToInclude("<script>");
			});

			it("returns empty string for empty input", () => {
				expect(_controller.hAttr("")).toBe("");
			});

		});

	}

}
