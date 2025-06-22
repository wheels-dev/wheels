component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that autolink", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				g.set(functionName = "autoLink", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "autoLink", encode = true)
			})

			it("links URLs", () => {
				str = 'blah blah <a href="http://cfwheels.org/download">http://cfwheels.org/download</a> Download CFWheels from http://cfwheels.org/download blah blah'
				r = _controller.autoLink(str, "URLs")
				e = 'blah blah <a href="http://cfwheels.org/download">http://cfwheels.org/download</a> Download CFWheels from <a href="http://cfwheels.org/download">http://cfwheels.org/download</a> blah blah'

				expect(e).toBe(r)
			})

			it("links email", () => {
				str = 'blah blah <a href="mailto:tpetruzzi@gmail.com">tpetruzzi@gmail.com</a> Download CFWheels from tpetruzzi@gmail.com blah blah'
				r = _controller.autoLink(str, "emailAddresses")
				e = 'blah blah <a href="mailto:tpetruzzi@gmail.com">tpetruzzi@gmail.com</a> Download CFWheels from <a href="mailto:tpetruzzi@gmail.com">tpetruzzi@gmail.com</a> blah blah'

				expect(e).toBe(r)
			})

			it("does not include punctuation", () => {
				str = 'The best http://cfwheels.org, Framework around. Download CFWheels from http://cfwheels.org/download.?!'
				r = _controller.autoLink(str, "URLs")
				e = 'The best <a href="http://cfwheels.org">http://cfwheels.org</a>, Framework around. Download CFWheels from <a href="http://cfwheels.org/download">http://cfwheels.org/download</a>.?!'

				expect(e).toBe(r)
			})

			it("overloaded arguments becomes link attributes", () => {
				str = 'Download CFWheels from http://cfwheels.org/download'
				r = _controller.autoLink(text = str, link = "URLs", target = "_blank", class = "wheels-href")
				e = 'Download CFWheels from <a class="wheels-href" href="http://cfwheels.org/download" target="_blank">http://cfwheels.org/download</a>'
				
				expect(e).toBe(r)
			})

			it("issue 560", () => {
				str = 'http://www.foo.uk'
				r = _controller.autoLink(str)
				e = '<a href="http://www.foo.uk">http://www.foo.uk</a>'
		
				expect(e).toBe(r)
			})

			it("issue 656 relative paths escaped", () => {
				str = 'Download CFWheels from <a href="/">http://x.com/x</a> blah blah'
				r = _controller.autoLink(str)
				e = 'Download CFWheels from <a href="/">http://x.com/x</a> blah blah'
				
				expect(e).toBe(r)
			})

			it("issue 656 relative paths link", () => {
				str = 'Download CFWheels from /cfwheels.org/download blah blah'
				r = _controller.autoLink(str)
				e = 'Download CFWheels from <a href="/cfwheels.org/download">/cfwheels.org/download</a> blah blah'

				expect(e).toBe(r)
			})

			it("turns off relative URL linking", () => {
				str = '155 cals/3.3miles'
				r = _controller.autoLink(text = "#str#", relative = "false")
				e = '155 cals/3.3miles'
				
				expect(e).toBe(r)
			})

			it("link www", () => {
				str = "www.foo.uk"
				r = _controller.autoLink(str)
				e = "<a href=""http://www.foo.uk"">www.foo.uk</a>"
			
				expect(e).toBe(r)
			})
		})

		describe("Tests that excerpt", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				args = {}
				args.text = "CFWheels: testing the excerpt view helper to see if it works or not."
				args.phrase = "CFWheels: testing the excerpt"
				args.radius = "0"
				args.excerptString = "[more]"
			})

			it("works with phrase at the beginning", () => {
				e = _controller.excerpt(argumentcollection = args)
				r = "CFWheels: testing the excerpt[more]"

				expect(e).toBe(r)
			})

			it("works with phrase not at the beginning", () => {
				args.phrase = "testing the excerpt"
				e = _controller.excerpt(argumentcollection = args)
				r = "[more]testing the excerpt[more]"
				
				expect(e).toBe(r)
			})

			it("works with phrase not at the beginning radius does not reach start or end", () => {
				args.phrase = "excerpt view helper"
				args.radius = "10"
				e = _controller.excerpt(argumentcollection = args)
				r = "[more]sting the excerpt view helper to see if[more]"

				expect(e).toBe(r)
			})

			it("works with phrase not at the beginning radius does not reach start", () => {
				args.phrase = "excerpt view helper"
				args.radius = "25"
				e = _controller.excerpt(argumentcollection = args)
				r = "CFWheels: testing the excerpt view helper to see if it works or no[more]"

				expect(e).toBe(r)
			})

			it("works with phrase not at the beginning radius does not reach end", () => {
				args.radius = "25"
				args.phrase = "see if it works"
				e = _controller.excerpt(argumentcollection = args)
				r = "[more]e excerpt view helper to see if it works or not."
				
				expect(e).toBe(r)
			})

			it("phrase not found", () => {
				args.radius = "25"
				args.phrase = "jklsduiermobk"
				e = _controller.excerpt(argumentcollection = args)
				r = ""

				expect(e).toBe(r)
			})
		})

		describe("Tests that highlight", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				args = {}
				args.text = "CFWheels test to do see if highlight function works or not."
				args.phrases = "highlight function"
				args.class = "cfwheels-highlight"
			})

			it("works with phrase found", () => {
				e = _controller.highlight(argumentcollection = args)
				r = 'CFWheels test to do see if <span class="cfwheels-highlight">highlight function</span> works or not.'

				expect(e).toBe(r)
			})

			it("works with phrase not found", () => {
				StructDelete(args, "phrases")
				args.phrase = "xxxxxxxxx"
				e = _controller.highlight(argumentcollection = args)
				r = 'CFWheels test to do see if highlight function works or not.'
				
				expect(e).toBe(r)
			})

			it("works with phrase found no class defined", () => {
				StructDelete(args, "class")
				args.phrases = "highlight function"
				e = _controller.highlight(argumentcollection = args)
				r = 'CFWheels test to do see if <span class="highlight">highlight function</span> works or not.'

				expect(e).toBe(r)
			})

			it("works with phrase not found no class defined", () => {
				args.phrases = "xxxxxxxxx"
				e = _controller.highlight(argumentcollection = args)
				r = 'CFWheels test to do see if highlight function works or not.'
				
				expect(e).toBe(r)
			})

			it("works with delimeter", () => {
				args.delimiter = "|"
				args.phrases = "test to|function|or not"
				e = _controller.highlight(argumentcollection = args)
				r = 'CFWheels <span class="cfwheels-highlight">test to</span> do see if highlight <span class="cfwheels-highlight">function</span> works <span class="cfwheels-highlight">or not</span>.'

				expect(e).toBe(r)
			})

			it("works with mark tag", () => {
				args.tag = "mark"
				e = _controller.highlight(argumentcollection = args)
				r = 'CFWheels test to do see if <mark class="cfwheels-highlight">highlight function</mark> works or not.'

				expect(e).toBe(r)
			})
		})

		describe("Tests that simpleformat", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				args = {}
				args.text = "Lob'ortis, <erat> feugiat jus autem

vel obruo dolor luptatum, os in interdico ex. Sit typicus

conventio consequat aptent huic dolore in, tego,
sagacitertedistineo tristique nonummy diam. Qui, nostrud
cogo vero exputo, wisi indoles duis suscipit veniam populus
te gilvus vel quia. Luptatum regula tego imputo nonummy blandit
luptatum valetudo ne, venio vero regula letalis valde vicis.

Utrum blandit bene refero ut eum eligo cogo duis bene aptent distineo duis quis.
Hendrerit nostrud abigo vicis
augue validus cui lucidus."
			})

			it("text should format", () => {
				e = _controller.simpleFormat(argumentcollection = args, encode = false)
				r = "<p>Lob'ortis, <erat> feugiat jus autem</p>

<p>vel obruo dolor luptatum, os in interdico ex. Sit typicus</p>

<p>conventio consequat aptent huic dolore in, tego,<br>
sagacitertedistineo tristique nonummy diam. Qui, nostrud<br>
cogo vero exputo, wisi indoles duis suscipit veniam populus<br>
te gilvus vel quia. Luptatum regula tego imputo nonummy blandit<br>
luptatum valetudo ne, venio vero regula letalis valde vicis.</p>

<p>Utrum blandit bene refero ut eum eligo cogo duis bene aptent distineo duis quis.<br>
Hendrerit nostrud abigo vicis<br>
augue validus cui lucidus.</p>"
				r = Replace(r, Chr(13), "", "all")

				expect(htmleditformat(e)).toBe(htmleditformat(r))
			})

			it("is encoding", () => {
				result = _controller.simpleFormat(argumentcollection = args, encode = true)
				expected = "<p>Lob&##x27;ortis, &lt;erat&gt; feugiat jus autem</p>

<p>vel obruo dolor luptatum, os in interdico ex. Sit typicus</p>

<p>conventio consequat aptent huic dolore in, tego,<br>
sagacitertedistineo tristique nonummy diam. Qui, nostrud<br>
cogo vero exputo, wisi indoles duis suscipit veniam populus<br>
te gilvus vel quia. Luptatum regula tego imputo nonummy blandit<br>
luptatum valetudo ne, venio vero regula letalis valde vicis.</p>

<p>Utrum blandit bene refero ut eum eligo cogo duis bene aptent distineo duis quis.<br>
Hendrerit nostrud abigo vicis<br>
augue validus cui lucidus.</p>"
				// Remove all carriage returns from the comparison string so that it's consistent across platforms.
				expected = Replace(expected, Chr(13), "", "all")
			})
		})

		describe("Tests that titleize", () => {

			it("should titleize sentence", () => {
				local.controller = g.controller(name = "dummy")
				local.args = {}
				local.args.word = "this is a test to see if this works or not."
				result = local.controller.titleize(argumentcollection = local.args)
				expected = "This Is A Test To See If This Works Or Not."

				expect(result).toBeWithCase(expected)
			})
		})

		describe("Tests that truncate", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				args = {}
				args.text = "this is a test to see if this works or not."
				args.length = "20"
				args.truncateString = "[more]"
			})

			it("should truncate phrase", () => {
				e = _controller.truncate(argumentcollection = args)
				r = "this is a test[more]"

				expect(e).toBeWithCase(r)
			})

			it("works with blank phrase", () => {
				args.text = ""
				e = _controller.truncate(argumentcollection = args)
				r = ""

				expect(e).toBe(r)
			})

			it("works when truncateString argument is missing", () => {
				StructDelete(args, "truncateString")
				e = _controller.truncate(argumentcollection = args)
				r = "this is a test to..."
				
				expect(e).toBe(r)
			})
		})

		describe("Tests that wordtruncate", () => {

			it("should word truncate the phrase", () => {
				local.controller = g.controller(name = "dummy")
				local.args = {}
				local.args.text = "CFWheels is a framework for ColdFusion"
				local.args.length = "4"
				result = local.controller.wordTruncate(argumentcollection = local.args)
				expected = "CFWheels is a framework..."

				expect(result).toBe(expected)
			})
		})
	}
}