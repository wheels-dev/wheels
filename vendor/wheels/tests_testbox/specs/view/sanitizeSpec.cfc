component extends="wheels.Testbox" {

	function run() {

		g = application.wo

		describe("Tests for stripLinks", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				g.set(functionName = "stripLinks", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "stripLinks", encode = true)
			})

			it("should strip all links", () => {
				htmlText = 'this <a href="http://www.google.com" title="google">is</a> a <a href="mailto:someone@example.com" title="invalid email">test</a> to <a name="anchortag">see</a> if this works or not.'
				actual = _controller.stripLinks(html = htmlText)
				expected = "this is a test to see if this works or not."

				expect(actual).toBe(expected)
			})

			it("removes all links when encode=false", () => {
				htmlText = 'Here is a <a href="http://cfwheels.org">CFWheels</a> link with <strong>bold</strong> text'
				actual = _controller.stripLinks(html = htmlText, encode = false)
				expected = 'Here is a CFWheels link with <strong>bold</strong> text'
				
				expect(actual).toBe(expected)
			})
			
			it("removes all links and encodes remaining HTML when encode=true", () => {
				htmlText = 'Here is a <a href="http://cfwheels.org">CFWheels</a> link with <strong>bold</strong> text'
				actual = _controller.stripLinks(html = htmlText, encode = true)
				expected = 'Here is a CFWheels link with &lt;strong&gt;bold&lt;&##x2f;strong&gt; text'
				
				expect(actual).toBe(expected)
			})
			
			it("handles nested tags correctly when encode=false", () => {
				htmlText = 'Check out <a href="http://cfwheels.org"><strong>CFWheels</strong> framework</a> for CFML'
				actual = _controller.stripLinks(html = htmlText, encode = false)
				expected = 'Check out <strong>CFWheels</strong> framework for CFML'
				
				expect(actual).toBe(expected)
			})
			
			it("handles nested tags correctly when encode=true", () => {
				htmlText = 'Check out <a href="http://cfwheels.org"><strong>CFWheels</strong> framework</a> for CFML'
				actual = _controller.stripLinks(html = htmlText, encode = true)
				expected = 'Check out &lt;strong&gt;CFWheels&lt;&##x2f;strong&gt; framework for CFML'
				
				expect(actual).toBe(expected)
			})
			
			it("handles malformed HTML correctly", () => {
				htmlText = 'This is <a href="http://cfwheels.org"></a> link without closing tag and <strong>nested tags'
				actual = _controller.stripLinks(html = htmlText, encode = false)
				
				// Should strip the link but preserve other tags

				expect(actual).notToInclude("<a ")
				expect(actual).toInclude("<strong>")
			})
			
			it("handles links with attributes correctly", () => {
				htmlText = 'Here is <a href="http://cfwheels.org" class="external" id="wheels-link" target="_blank">CFWheels</a> link'
				actual = _controller.stripLinks(html = htmlText, encode = false)
				expected = 'Here is CFWheels link'
				
				expect(actual).toBe(expected)
			})
		})
		
		describe("Tests for stripTags", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				g.set(functionName = "stripTags", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "stripTags", encode = true)
			})

			it("should strip all tags", () => {
				htmlText = '<h1>this</h1><p><a href="http://www.google.com" title="google">is</a></p><p>a <a href="mailto:someone@example.com" title="invalid email">test</a> to<br><a name="anchortag">see</a> if this works or not.</p>'
				actual = _controller.stripTags(html = htmlText)
				expected = "thisisa test tosee if this works or not.";
				
				expect(actual).toBe(expected)
			})

			it("removes all HTML tags when encode=false", () => {
				htmlText = 'This is <strong>bold text</strong> and <em>italicized text</em> with <a href="link">a link</a>'
				actual = _controller.stripTags(html = htmlText, encode = false)
				expected = 'This is bold text and italicized text with a link'
				
				expect(actual).toBe(expected)
			})
			
			it("removes all HTML tags and encodes any remaining HTML entities when encode=true", () => {
				htmlText = 'This is <strong>bold text</strong> and <em>italicized text</em> with <a href="link">a link</a> & some entities'
				actual = _controller.stripTags(html = htmlText, encode = true)
				expected = 'This is bold text and italicized text with a link &amp; some entities'
				
				expect(actual).toBe(expected)
			})
			
			it("handles nested tags correctly", () => {
				htmlText = '<div><p>This is a <strong>paragraph with <em>nested</em> tags</strong></p></div>'
				actual = _controller.stripTags(html = htmlText, encode = false)
				expected = 'This is a paragraph with nested tags'
				
				expect(actual).toBe(expected)
			})
			
			it("strips complex HTML structures", () => {
				htmlText = '<table><tr><td>Cell 1</td><td>Cell 2</td></tr><tr><td>Cell 3</td><td>Cell 4</td></tr></table>'
				actual = _controller.stripTags(html = htmlText, encode = false)
				expected = 'Cell 1Cell 2Cell 3Cell 4'
				
				expect(actual).toBe(expected)
			})
			
			it("handles malformed HTML correctly", () => {
				htmlText = 'This <strong>tag is not closed and <em>has nesting issues'
				actual = _controller.stripTags(html = htmlText, encode = false)
				expected = 'This tag is not closed and has nesting issues'
				
				expect(actual).toBe(expected)
			})

		})
	}
}