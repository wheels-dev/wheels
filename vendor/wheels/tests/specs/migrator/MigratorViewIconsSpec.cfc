component extends="wheels.WheelsTest" {

	function run() {

		describe("Migrator view icons", () => {

			// Convention guard for the migrator dashboard. The Database Error
			// placeholder in vendor/wheels/public/views/migrator.cfm originally
			// used a Semantic UI icon-font tag (an i element with class
			// "database icon") while the rest of the file had been migrated
			// to inline SVG. That one reference rendered as a broken glyph
			// (#2427 / #2425) because semantic.min.css is included via
			// cfinclude and its @font-face URLs resolved against the page
			// URL rather than the CSS source path, so the icon font never
			// loaded.
			//
			// The symptom was fixed by #2562 (swap to inline SVG on this line)
			// and the root cause was fixed by #2563 (inline the Semantic UI
			// icon font as a base64 data URI in _header.cfm). These tests
			// enforce the inline-SVG convention going forward so the migrator
			// view does not drift back to icon-font tags.
			it("renders the database-error placeholder with an inline SVG icon, not a font-based glyph", () => {
				var source = FileRead(ExpandPath("/wheels/public/views/migrator.cfm"));

				// Anchor on the "Database Error" string the view emits when
				// the datasource is unavailable.
				var anchor = Find("Database Error", source);
				expect(anchor).toBeGT(0, "migrator.cfm must contain a Database Error placeholder.");

				// Examine ~1500 chars before the anchor — the inline-SVG path
				// data for the database icon alone is ~700 chars, so the
				// window has to be wide enough to capture it.
				var windowStart = Max(anchor - 1500, 1);
				var windowLen = anchor - windowStart;
				var iconBlock = Mid(source, windowStart, windowLen);

				// The placeholder must contain an inline svg tag (the project
				// convention used everywhere else in this view), and must not
				// contain an icon-font opener of the form `i class="...icon..."`.
				expect(iconBlock).toInclude(
					Chr(60) & "svg",
					"Database error placeholder must use an inline svg icon to match the convention used elsewhere in migrator.cfm."
				);

				var fontIconHit = reFindNoCase(
					Chr(60) & "i[\s>][^>]*\bicon\b",
					iconBlock
				);
				expect(fontIconHit).toBe(
					0,
					"Database error placeholder must not use a Semantic UI icon-font tag. Use an inline svg to match the rest of the view."
				);
			});

			// Belt-and-suspenders: the whole view should be free of icon-font
			// tags. Every other glyph in the file is already an inline svg;
			// adding any new icon-font usage would break the convention.
			it("uses no Semantic UI icon-font tags anywhere in the migrator view", () => {
				var source = FileRead(ExpandPath("/wheels/public/views/migrator.cfm"));
				// reMatchNoCase returns every opener tag of the form i ...icon... in the file.
				var pattern = Chr(60) & "i[\s>][^>]*\bicon\b[^>]*>";
				var hits = reMatchNoCase(pattern, source);
				expect(ArrayLen(hits)).toBe(
					0,
					"migrator.cfm should not contain any icon-font tags — convert them to inline svg to match the rest of the view. Found: " & ArrayToList(hits, " | ")
				);
			});

		});

	}

}
