/**
 * Tests for HTML5 form helper functions:
 * emailField, urlField, numberField, telField, dateField, colorField, rangeField, searchField
 * and their corresponding Tag variants.
 */
component extends="wheels.Testbox" {

	function run() {

		g = application.wo;

		// =============================================
		// HTML5 Form Helpers (via tag-based API)
		// =============================================

		describe("emailField", function() {

			beforeEach(function() {
				_controller = g.controller(name = "dummy");
			});

			it("generates an input with type=email", function() {
				local.result = _controller.emailFieldTag(name = "userEmail", value = "test@example.com");
				expect(local.result).toInclude('type="email"');
			});

			it("sets the correct value attribute", function() {
				local.result = _controller.emailFieldTag(name = "userEmail", value = "test@example.com", encode = false);
				expect(local.result).toInclude('value="test@example.com"');
			});

			it("generates proper id attribute", function() {
				local.result = _controller.emailFieldTag(name = "userEmail", value = "");
				expect(local.result).toInclude('id="userEmail"');
			});

			it("supports label parameter", function() {
				local.result = _controller.emailFieldTag(name = "userEmail", value = "", label = "Email Address");
				expect(local.result).toInclude("Email Address");
				expect(local.result).toInclude("<label");
			});

			it("passes through additional HTML attributes", function() {
				local.result = _controller.emailFieldTag(
					name = "userEmail",
					value = "",
					class = "form-control",
					placeholder = "you@example.com",
					encode = false
				);
				expect(local.result).toInclude('class="form-control"');
				expect(local.result).toInclude('placeholder="you@example.com"');
			});
		});

		describe("urlField", function() {

			beforeEach(function() {
				_controller = g.controller(name = "dummy");
			});

			it("generates an input with type=url", function() {
				local.result = _controller.urlFieldTag(name = "website", value = "https://example.com");
				expect(local.result).toInclude('type="url"');
			});

			it("sets the correct value", function() {
				local.result = _controller.urlFieldTag(name = "website", value = "https://example.com", encode = false);
				expect(local.result).toInclude('value="https://example.com"');
			});
		});

		describe("numberField", function() {

			beforeEach(function() {
				_controller = g.controller(name = "dummy");
			});

			it("generates an input with type=number", function() {
				local.result = _controller.numberFieldTag(name = "quantity", value = "5");
				expect(local.result).toInclude('type="number"');
			});

			it("supports min attribute", function() {
				local.result = _controller.numberFieldTag(name = "quantity", value = "5", min = "1");
				expect(local.result).toInclude('min="1"');
			});

			it("supports max attribute", function() {
				local.result = _controller.numberFieldTag(name = "quantity", value = "5", max = "100");
				expect(local.result).toInclude('max="100"');
			});

			it("supports step attribute", function() {
				local.result = _controller.numberFieldTag(name = "price", value = "9.99", step = "0.01");
				expect(local.result).toInclude('step="0.01"');
			});

			it("supports min, max, and step together", function() {
				local.result = _controller.numberFieldTag(
					name = "rating",
					value = "3",
					min = "1",
					max = "5",
					step = "1"
				);
				expect(local.result).toInclude('min="1"');
				expect(local.result).toInclude('max="5"');
				expect(local.result).toInclude('step="1"');
				expect(local.result).toInclude('type="number"');
			});
		});

		describe("telField", function() {

			beforeEach(function() {
				_controller = g.controller(name = "dummy");
			});

			it("generates an input with type=tel", function() {
				local.result = _controller.telFieldTag(name = "phone", value = "+1234567890");
				expect(local.result).toInclude('type="tel"');
			});

			it("sets the correct value", function() {
				local.result = _controller.telFieldTag(name = "phone", value = "+1234567890", encode = false);
				expect(local.result).toInclude('value="+1234567890"');
			});
		});

		describe("dateField", function() {

			beforeEach(function() {
				_controller = g.controller(name = "dummy");
			});

			it("generates an input with type=date", function() {
				local.result = _controller.dateFieldTag(name = "birthday", value = "2000-01-15");
				expect(local.result).toInclude('type="date"');
			});

			it("supports min date", function() {
				local.result = _controller.dateFieldTag(name = "startDate", value = "", min = "2020-01-01");
				expect(local.result).toInclude('min="2020-01-01"');
			});

			it("supports max date", function() {
				local.result = _controller.dateFieldTag(name = "endDate", value = "", max = "2030-12-31");
				expect(local.result).toInclude('max="2030-12-31"');
			});
		});

		describe("colorField", function() {

			beforeEach(function() {
				_controller = g.controller(name = "dummy");
			});

			it("generates an input with type=color", function() {
				local.result = _controller.colorFieldTag(name = "themeColor", value = "##ff0000");
				expect(local.result).toInclude('type="color"');
			});

			it("sets the color value", function() {
				local.result = _controller.colorFieldTag(name = "themeColor", value = "##336699", encode = false);
				expect(local.result).toInclude('value="##336699"');
			});
		});

		describe("rangeField", function() {

			beforeEach(function() {
				_controller = g.controller(name = "dummy");
			});

			it("generates an input with type=range", function() {
				local.result = _controller.rangeFieldTag(name = "volume", value = "50");
				expect(local.result).toInclude('type="range"');
			});

			it("supports min, max, and step", function() {
				local.result = _controller.rangeFieldTag(
					name = "volume",
					value = "50",
					min = "0",
					max = "100",
					step = "5"
				);
				expect(local.result).toInclude('min="0"');
				expect(local.result).toInclude('max="100"');
				expect(local.result).toInclude('step="5"');
			});
		});

		describe("searchField", function() {

			beforeEach(function() {
				_controller = g.controller(name = "dummy");
			});

			it("generates an input with type=search", function() {
				local.result = _controller.searchFieldTag(name = "query", value = "wheels framework");
				expect(local.result).toInclude('type="search"');
			});

			it("sets the correct value", function() {
				local.result = _controller.searchFieldTag(name = "query", value = "wheels framework", encode = false);
				expect(local.result).toInclude('value="wheels framework"');
			});

			it("supports label", function() {
				local.result = _controller.searchFieldTag(name = "query", value = "", label = "Search");
				expect(local.result).toInclude("Search");
			});
		});

		// =============================================
		// Tag-Based Form Helpers (verify delegation works)
		// =============================================

		describe("Tag-based HTML5 helpers", function() {

			beforeEach(function() {
				_controller = g.controller(name = "dummy");
			});

			it("emailFieldTag generates type=email", function() {
				local.result = _controller.emailFieldTag(name = "email", value = "");
				expect(local.result).toInclude('type="email"');
				expect(local.result).toInclude('name="email"');
			});

			it("urlFieldTag generates type=url", function() {
				local.result = _controller.urlFieldTag(name = "website", value = "");
				expect(local.result).toInclude('type="url"');
			});

			it("numberFieldTag generates type=number", function() {
				local.result = _controller.numberFieldTag(name = "qty", value = "1");
				expect(local.result).toInclude('type="number"');
			});

			it("telFieldTag generates type=tel", function() {
				local.result = _controller.telFieldTag(name = "mobile", value = "");
				expect(local.result).toInclude('type="tel"');
			});

			it("dateFieldTag generates type=date", function() {
				local.result = _controller.dateFieldTag(name = "dob", value = "");
				expect(local.result).toInclude('type="date"');
			});

			it("colorFieldTag generates type=color", function() {
				local.result = _controller.colorFieldTag(name = "color", value = "");
				expect(local.result).toInclude('type="color"');
			});

			it("rangeFieldTag generates type=range", function() {
				local.result = _controller.rangeFieldTag(name = "slider", value = "50");
				expect(local.result).toInclude('type="range"');
			});

			it("searchFieldTag generates type=search", function() {
				local.result = _controller.searchFieldTag(name = "q", value = "");
				expect(local.result).toInclude('type="search"');
			});
		});

		// =============================================
		// Encoding Tests
		// =============================================

		describe("HTML5 helpers encoding support", function() {

			beforeEach(function() {
				_controller = g.controller(name = "dummy");
			});

			it("emailFieldTag encodes values when encode=true", function() {
				local.result = _controller.emailFieldTag(
					name = "email",
					value = 'test@example.com" onclick="alert(1)',
					encode = true
				);
				// Should NOT contain raw double quotes in value attribute
				expect(local.result).notToInclude('onclick=');
			});

			it("numberFieldTag preserves numeric values", function() {
				local.result = _controller.numberFieldTag(
					name = "amount",
					value = "99.95",
					min = "0",
					max = "1000"
				);
				expect(local.result).toInclude('value="99.95"');
			});
		});

		// =============================================
		// All helpers generate <input> tags
		// =============================================

		describe("HTML5 helpers produce valid input elements", function() {

			beforeEach(function() {
				_controller = g.controller(name = "dummy");
			});

			it("all helpers generate input tags", function() {
				local.helpers = [
					{fn = "emailFieldTag", args = {name = "e", value = ""}},
					{fn = "urlFieldTag", args = {name = "u", value = ""}},
					{fn = "numberFieldTag", args = {name = "n", value = "0"}},
					{fn = "telFieldTag", args = {name = "t", value = ""}},
					{fn = "dateFieldTag", args = {name = "d", value = ""}},
					{fn = "colorFieldTag", args = {name = "c", value = ""}},
					{fn = "rangeFieldTag", args = {name = "r", value = "50"}},
					{fn = "searchFieldTag", args = {name = "s", value = ""}}
				];

				for (local.helper in local.helpers) {
					local.result = invoke(_controller, local.helper.fn, local.helper.args);
					expect(local.result).toInclude("<input", "Failed for #local.helper.fn#");
				}
			});
		});
	}
}
