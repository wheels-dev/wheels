component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		_controller = g.controller(name = "dummy")
	}

	function run() {

		g = application.wo

		describe("Tests that authenticityTokenField", () => {

			it("is working", () => {
				local.token = CsrfGenerateToken()
				tag = _controller.authenticityTokenField()
				authenticityTokenField = '<input name="authenticityToken" type="hidden" value="#local.token#">'

				expect(tag).toBe(authenticityTokenField)
			})
		})

		describe("Tests that csrfMetaTags", () => {

			it("contains csrfparam meta tag", () => {
				tags = _controller.csrfMetaTags()
				csrfParamTag = '<meta content="authenticityToken" name="csrf-param">'

				expect(tags).toInclude(csrfParamTag)
			})

			it("contains csrftoken meta tag", () => {
				local.token = CsrfGenerateToken()
				tags = _controller.csrfMetaTags()
				csrfTokenTag = '<meta content="#local.token#" name="csrf-token">'

				expect(tags).toInclude(csrfTokenTag)
			})
		})
	}
}