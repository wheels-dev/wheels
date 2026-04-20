component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Form helper data-auto-id dual emission", () => {

			beforeEach(() => {
				_controller = g.controller(name = "ControllerWithModel")
			})

			describe("when formHelperDataAutoId is enabled (default)", () => {

				it("emits both dashed id and underscored data-auto-id on textField", () => {
					r = _controller.textField(
						objectName = "user",
						property = "firstname",
						label = false
					)

					expect(r).toInclude('id="user-firstname"')
					expect(r).toInclude('data-auto-id="user_firstname"')
				})

				it("emits data-auto-id on emailField", () => {
					r = _controller.emailField(
						objectName = "user",
						property = "firstname",
						label = false
					)

					expect(r).toInclude('id="user-firstname"')
					expect(r).toInclude('data-auto-id="user_firstname"')
				})

				it("emits data-auto-id on passwordField", () => {
					r = _controller.passwordField(
						objectName = "user",
						property = "firstname",
						label = false
					)

					expect(r).toInclude('id="user-firstname"')
					expect(r).toInclude('data-auto-id="user_firstname"')
				})

				it("emits data-auto-id on hiddenField", () => {
					r = _controller.hiddenField(
						objectName = "user",
						property = "firstname"
					)

					expect(r).toInclude('id="user-firstname"')
					expect(r).toInclude('data-auto-id="user_firstname"')
				})

				it("emits data-auto-id on textArea", () => {
					r = _controller.textArea(
						objectName = "user",
						property = "firstname",
						label = false
					)

					expect(r).toInclude('id="user-firstname"')
					expect(r).toInclude('data-auto-id="user_firstname"')
				})

				it("emits data-auto-id on select", () => {
					r = _controller.select(
						objectName = "user",
						property = "firstname",
						options = "a,b,c",
						label = false
					)

					expect(r).toInclude('id="user-firstname"')
					expect(r).toInclude('data-auto-id="user_firstname"')
				})

				it("emits data-auto-id on checkBox", () => {
					r = _controller.checkBox(
						objectName = "user",
						property = "isActive",
						label = false
					)

					expect(r).toInclude('id="user-isactive"')
					expect(r).toInclude('data-auto-id="user_isactive"')
				})

				it("emits data-auto-id on radioButton including value suffix", () => {
					r = _controller.radioButton(
						objectName = "user",
						property = "gender",
						tagValue = "m",
						label = false
					)

					expect(r).toInclude('id="user-gender-m"')
					expect(r).toInclude('data-auto-id="user_gender_m"')
				})

				it("emits data-auto-id on fileField", () => {
					r = _controller.fileField(
						objectName = "user",
						property = "firstname",
						label = false
					)

					expect(r).toInclude('id="user-firstname"')
					expect(r).toInclude('data-auto-id="user_firstname"')
				})

				it("does not emit data-auto-id when the caller supplies a custom id", () => {
					r = _controller.textField(
						objectName = "user",
						property = "firstname",
						id = "my-custom-id",
						label = false
					)

					expect(r).toInclude('id="my-custom-id"')
					expect(r).notToInclude('data-auto-id')
				})

				it("emits data-auto-id on the hidden companion of a checkBox with uncheckedValue", () => {
					r = _controller.checkBox(
						objectName = "user",
						property = "isActive",
						label = false,
						unCheckedValue = 0
					)

					expect(r).toInclude('id="user-isactive-checkbox"')
					expect(r).toInclude('data-auto-id="user_isactive_checkbox"')
				})
			})

			describe("when formHelperDataAutoId is disabled", () => {

				beforeEach(() => {
					g.set(formHelperDataAutoId = false)
				})

				afterEach(() => {
					g.set(formHelperDataAutoId = true)
				})

				it("emits only the dashed id without data-auto-id", () => {
					r = _controller.textField(
						objectName = "user",
						property = "firstname",
						label = false
					)

					expect(r).toInclude('id="user-firstname"')
					expect(r).notToInclude('data-auto-id')
				})
			})
		})
	}
}
