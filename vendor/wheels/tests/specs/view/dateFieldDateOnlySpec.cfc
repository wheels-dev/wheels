component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo;

		describe("dateField emits an HTML5 date-only value", () => {

			it("formats a bound datetime property to yyyy-mm-dd (type=date cannot show a time)", () => {
				// Post.createdat is a datetime column; the loaded value carries a time
				// component, which <input type=date> cannot display.
				var _controller = g.controller(name = "DateFieldObjectController");
				var out = _controller.dateField(objectName = "post", property = "createdat", encode = false);
				var m = ReFind('value="([^"]*)"', out, 1, true);
				var val = (ArrayLen(m.pos) > 1 && m.pos[2] > 0) ? Mid(out, m.pos[2], m.len[2]) : "";
				expect(out).toInclude('type="date"');
				expect(ReFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", val) > 0).toBeTrue(
					"dateField value must be a bare yyyy-mm-dd for type=date; actual = [" & val & "]"
				);
			});

			it("leaves an explicit date-only value unchanged (idempotent)", () => {
				var _controller = g.controller(name = "DateFieldObjectController");
				var out = _controller.dateField(objectName = "post", property = "createdat", value = "2026-02-03", encode = false);
				expect(out).toInclude('value="2026-02-03"');
			});

			it("leaves an empty value empty", () => {
				var _controller = g.controller(name = "DateFieldObjectController");
				var out = _controller.dateField(objectName = "post", property = "nonexistentblank", value = "", encode = false);
				expect(out).toInclude('type="date"');
				expect(FindNoCase('value="', out) == 0 || FindNoCase('value=""', out) > 0).toBeTrue("empty stays empty");
			});

		});
	}
}
