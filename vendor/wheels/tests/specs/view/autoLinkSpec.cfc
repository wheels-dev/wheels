component extends="wheels.WheelsTest" {

    function run() {

        g = application.wo
		
		describe("Testing with plain text (no HTML)", () => {

			beforeEach(() => {
				_controller = g.controller(name="dummy")
			})
				
			it("should link URLs with encode=false", () => {
				args = {}
				args.text = "Visit Wheels at http://wheels.dev"
				args.encode = false
				result = _controller.autoLink(argumentCollection=args)
				expect(result).toInclude('<a href="http://wheels.dev">http://wheels.dev</a>')
			})
			
			it("should link URLs with encode=true", () => {
				args = {}
				args.text = "Visit Wheels at http://wheels.dev"
				args.encode = true
				result = _controller.autoLink(argumentCollection=args)
				expect(result).toInclude('Visit Wheels at <a href="http&##x3a;&##x2f;&##x2f;wheels.dev">http&##x3a;&##x2f;&##x2f;wheels.dev</a>')
				expect(result).toInclude('&##x2f;')
				expect(result).notToInclude('<script')
			})
			
			it("should link URLs with encode='attributes'", () => {
				args = {}
				args.text = "Visit Wheels at http://wheels.dev"
				args.encode = "attributes"
				result = _controller.autoLink(argumentCollection=args)
				expect(result).toInclude('Visit Wheels at <a href="http&##x3a;&##x2f;&##x2f;wheels.dev">http://wheels.dev</a>')
				expect(result).notToInclude('&lt;')
			})
			
			it("should link email addresses with encode=false", () => {
				args = {}
				args.text = "Contact us at info@wheels.dev"
				args.encode = false
				result = _controller.autoLink(argumentCollection=args)
				expect(result).toInclude('<a href="mailto:info@wheels.dev">info@wheels.dev</a>')
			})
			
			it("should link email addresses with encode=true", () => {
				args = {}
				args.text = "Contact us at info@wheels.dev"
				args.encode = true
				result = _controller.autoLink(argumentCollection=args)
				expect(result).toInclude('Contact us at <a href="mailto&##x3a;info&##x40;wheels.dev">info&##x40;wheels.dev</a>')
				expect(result).toInclude('&##x3a;')
				expect(result).notToInclude('<script')
			})
			
			it("should link email addresses with encode='attributes'", () => {
				args = {}
				args.text = "Contact us at info@wheels.dev"
				args.encode = "attributes"
				result = _controller.autoLink(argumentCollection=args)
				expect(result).toInclude('Contact us at <a href="mailto&##x3a;info&##x40;wheels.dev">info@wheels.dev</a>')
			})
		})
    }
}