/**
 * Pins the encoder-agnostic comparison used by the view encoding specs
 * (`wheels.tests._assets.view.HtmlEncoding`): cosmetic differences between encoders compare
 * equal, while a missing encoding of a markup-significant character never does.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("HtmlEncoding spec helper", () => {

			beforeEach(() => {
				enc = new wheels.tests._assets.view.HtmlEncoding()
			})

			it("treats the encodings of inert characters as equal", () => {
				expect(enc.normalize("a&##x2f;b&##x20;c&##x28;d&##x29;")).toBe("a/b c(d)")
				expect(enc.normalize("&quot;x&quot;")).toBe(enc.normalize("&##34;x&##x22;"))
				expect(enc.normalize("&##39;")).toBe(enc.normalize("&##x27;"))
				expect(enc.normalize("&lt;b&gt;")).toBe(enc.normalize("&lt;b>"))
			})

			it("never treats a literal markup character as its encoding", () => {
				expect(enc.normalize('say "hi"')).notToBe(enc.normalize("say &quot;hi&quot;"))
				expect(enc.normalize("it's")).notToBe(enc.normalize("it&##39;s"))
				expect(enc.normalize("<b>")).notToBe(enc.normalize("&lt;b&gt;"))
				expect(enc.normalize("a & b")).notToBe(enc.normalize("a &amp; b"))
			})

			it("decodes character references", () => {
				expect(enc.decode("&lt;a href=&##34;x&##x22;&gt; &amp; &##39;")).toBe('<a href="x"> & ''')
				expect(enc.decode("&unknown; stays")).toBe("&unknown; stays")
			})

			it("finds an attribute injected through an unencoded quote", () => {
				var broken = '<input class="x" onclick="alert(1)" type="text">'
				var safe = '<input class="x&quot; onclick=&quot;alert(1)" type="text">'
				expect(enc.attributeProblem(broken, "class", 'x" onclick="alert(1)')).toInclude("onclick")
				expect(enc.attributeProblem(safe, "class", 'x" onclick="alert(1)')).toBe("")
			})

			it("rejects text that keeps a literal markup character", () => {
				expect(enc.textProblem("&lt;b>", "<b>")).toInclude("literal")
				expect(enc.textProblem("&lt;b&gt;", "<b>")).toBe("")
				expect(enc.textProblem("&lt;i&gt;", "<b>")).toInclude("decodes")
			})

			it("reads tags whose attribute values contain a literal >", () => {
				var tags = enc.tags('<input value="a>b"><input value="c">', "input")
				expect(ArrayLen(tags)).toBe(2)
				expect(enc.attributeValue(tags[1], "value")).toBe("a>b")
			})

		})

	}

}
