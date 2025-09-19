component extends="wheels.Testbox" {

    function run() {

        g = application.wo
		
		describe("Testing with plain text (no HTML)", () => {

			beforeEach(() => {
				_controller = g.controller(name="dummy")
			})
				
			it("should link URLs with encode=false", () => {
				args = {}
				args.text = "Visit CFWheels at http://cfwheels.org"
				args.encode = false
				result = _controller.autoLink(argumentCollection=args)
				expect(result).toInclude('<a href="http://cfwheels.org">http://cfwheels.org</a>')
			})
			
			it("should link URLs with encode=true", () => {
				args = {}
				args.text = "Visit CFWheels at http://cfwheels.org"
				args.encode = true
				result = _controller.autoLink(argumentCollection=args)
				expect(result).toInclude('Visit CFWheels at <a href="http&##x3a;&##x2f;&##x2f;cfwheels.org">http&##x3a;&##x2f;&##x2f;cfwheels.org</a>')
				expect(result).toInclude('&##x2f;')
				expect(result).notToInclude('<script')
			})
			
			it("should link URLs with encode='attributes'", () => {
				args = {}
				args.text = "Visit CFWheels at http://cfwheels.org"
				args.encode = "attributes"
				result = _controller.autoLink(argumentCollection=args)
				expect(result).toInclude('Visit CFWheels at <a href="http&##x3a;&##x2f;&##x2f;cfwheels.org">http://cfwheels.org</a>')
				expect(result).notToInclude('&lt;')
			})
			
			it("should link email addresses with encode=false", () => {
				args = {}
				args.text = "Contact us at info@cfwheels.org"
				args.encode = false
				result = _controller.autoLink(argumentCollection=args)
				expect(result).toInclude('<a href="mailto:info@cfwheels.org">info@cfwheels.org</a>')
			})
			
			it("should link email addresses with encode=true", () => {
				args = {}
				args.text = "Contact us at info@cfwheels.org"
				args.encode = true
				result = _controller.autoLink(argumentCollection=args)
				expect(result).toInclude('Contact us at <a href="mailto&##x3a;info&##x40;cfwheels.org">info&##x40;cfwheels.org</a>')
				expect(result).toInclude('&##x3a;')
				expect(result).notToInclude('<script')
			})
			
			it("should link email addresses with encode='attributes'", () => {
				args = {}
				args.text = "Contact us at info@cfwheels.org"
				args.encode = "attributes"
				result = _controller.autoLink(argumentCollection=args)
				expect(result).toInclude('Contact us at <a href="mailto&##x3a;info&##x40;cfwheels.org">info@cfwheels.org</a>')
			})
		})
    }
}