/**
 * Tests for admin form template generation methods in TemplateService.
 *
 * Tests generateAdminFormFieldsCode() and generateAdminSelectParams()
 * which map AdminIntrospectionService field metadata to Wheels form helpers.
 */
component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Instantiate TemplateService directly — the admin form methods are pure functions
		// that don't depend on injected helpers.
		variables.templateService = new cli.src.models.TemplateService();
	}

	function run() {

		describe("Admin form field generation", () => {

			it("generates a text field for string input type", () => {
				var fields = [{
					name: "firstName",
					label: "First Name",
					inputType: "text",
					inForm: true,
					isForeignKey: false,
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("textField(");
				expect(result).toInclude('property="firstName"');
				expect(result).toInclude('label="First Name"');
				expect(result).toInclude('class="form-control"');
				expect(result).toInclude("form-group");
			});

			it("generates an email field for email input type", () => {
				var fields = [{
					name: "email",
					label: "Email",
					inputType: "email",
					inForm: true,
					isForeignKey: false,
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("emailField(");
				expect(result).toInclude('property="email"');
			});

			it("generates a password field for password input type", () => {
				var fields = [{
					name: "password",
					label: "Password",
					inputType: "password",
					inForm: true,
					isForeignKey: false,
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("passwordField(");
			});

			it("generates a number field for number input type", () => {
				var fields = [{
					name: "quantity",
					label: "Quantity",
					inputType: "number",
					inForm: true,
					isForeignKey: false,
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("numberField(");
			});

			it("generates a textarea for textarea input type", () => {
				var fields = [{
					name: "bio",
					label: "Bio",
					inputType: "textarea",
					inForm: true,
					isForeignKey: false,
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("textArea(");
				expect(result).toInclude('rows="5"');
			});

			it("generates a checkbox for checkbox input type", () => {
				var fields = [{
					name: "isActive",
					label: "Is Active",
					inputType: "checkbox",
					inForm: true,
					isForeignKey: false,
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("checkBox(");
				expect(result).toInclude('<div class="checkbox">');
			});

			it("generates a date field for date input type", () => {
				var fields = [{
					name: "birthDate",
					label: "Birth Date",
					inputType: "date",
					inForm: true,
					isForeignKey: false,
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("dateField(");
			});

			it("generates dateTimeSelect for datetime-local input type", () => {
				var fields = [{
					name: "startAt",
					label: "Start At",
					inputType: "datetime-local",
					inForm: true,
					isForeignKey: false,
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("dateTimeSelect(");
			});

			it("generates timeSelect for time input type", () => {
				var fields = [{
					name: "startTime",
					label: "Start Time",
					inputType: "time",
					inForm: true,
					isForeignKey: false,
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("timeSelect(");
			});

			it("generates url field for url input type", () => {
				var fields = [{
					name: "website",
					label: "Website",
					inputType: "url",
					inForm: true,
					isForeignKey: false,
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("urlField(");
			});

			it("generates tel field for tel input type", () => {
				var fields = [{
					name: "phone",
					label: "Phone",
					inputType: "tel",
					inForm: true,
					isForeignKey: false,
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("telField(");
			});

			it("generates color field for color input type", () => {
				var fields = [{
					name: "themeColor",
					label: "Theme Color",
					inputType: "color",
					inForm: true,
					isForeignKey: false,
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("colorField(");
			});

			it("generates file field for file input type", () => {
				var fields = [{
					name: "avatar",
					label: "Avatar",
					inputType: "file",
					inForm: true,
					isForeignKey: false,
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("fileFieldTag(");
			});

			it("generates select for foreign key fields", () => {
				var fields = [{
					name: "roleId",
					label: "Role",
					inputType: "select",
					inForm: true,
					isForeignKey: true,
					foreignKeyTo: "Role",
					isEnum: false
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("select(");
				expect(result).toInclude('property="roleId"');
				expect(result).toInclude("roleOptions");
				expect(result).toInclude('includeBlank="Select Role"');
			});

			it("generates select for enum fields", () => {
				var fields = [{
					name: "status",
					label: "Status",
					inputType: "select",
					inForm: true,
					isForeignKey: false,
					isEnum: true,
					enumValues: {draft: 0, published: 1, archived: 2}
				}];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("select(");
				expect(result).toInclude('property="status"');
				expect(result).toInclude('includeBlank="Select Status"');
			});

			it("skips fields where inForm is false", () => {
				var fields = [
					{name: "id", label: "Id", inputType: "number", inForm: false, isForeignKey: false, isEnum: false},
					{name: "firstName", label: "First Name", inputType: "text", inForm: true, isForeignKey: false, isEnum: false}
				];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).notToInclude('property="id"');
				expect(result).toInclude('property="firstName"');
			});

			it("generates multiple fields in order", () => {
				var fields = [
					{name: "firstName", label: "First Name", inputType: "text", inForm: true, isForeignKey: false, isEnum: false},
					{name: "email", label: "Email", inputType: "email", inForm: true, isForeignKey: false, isEnum: false},
					{name: "isActive", label: "Is Active", inputType: "checkbox", inForm: true, isForeignKey: false, isEnum: false}
				];

				var result = templateService.generateAdminFormFieldsCode(fields);

				expect(result).toInclude("textField(");
				expect(result).toInclude("emailField(");
				expect(result).toInclude("checkBox(");
				// Verify order: text before email before checkbox
				var textPos = find("textField(", result);
				var emailPos = find("emailField(", result);
				var checkPos = find("checkBox(", result);
				expect(textPos).toBeLT(emailPos);
				expect(emailPos).toBeLT(checkPos);
			});
		});

		describe("Admin select cfparam generation", () => {

			it("generates cfparam for foreign key select options", () => {
				var fields = [{
					name: "roleId",
					label: "Role",
					inputType: "select",
					inForm: true,
					isForeignKey: true,
					foreignKeyTo: "Role",
					isEnum: false
				}];

				var result = templateService.generateAdminSelectParams(fields);

				expect(result).toInclude("cfparam");
				expect(result).toInclude('name="roleOptions"');
				expect(result).toInclude("queryNew");
			});

			it("does not generate cfparam for enum selects", () => {
				var fields = [{
					name: "status",
					label: "Status",
					inputType: "select",
					inForm: true,
					isForeignKey: false,
					isEnum: true,
					enumValues: {draft: 0, published: 1}
				}];

				var result = templateService.generateAdminSelectParams(fields);

				expect(result).toBe("");
			});

			it("generates multiple cfparams for multiple foreign keys", () => {
				var fields = [
					{name: "roleId", label: "Role", inputType: "select", inForm: true, isForeignKey: true, foreignKeyTo: "Role", isEnum: false},
					{name: "categoryId", label: "Category", inputType: "select", inForm: true, isForeignKey: true, foreignKeyTo: "Category", isEnum: false}
				];

				var result = templateService.generateAdminSelectParams(fields);

				expect(result).toInclude('name="roleOptions"');
				expect(result).toInclude('name="categoryOptions"');
			});

			it("skips non-select fields", () => {
				var fields = [
					{name: "firstName", label: "First Name", inputType: "text", inForm: true, isForeignKey: false, isEnum: false},
					{name: "roleId", label: "Role", inputType: "select", inForm: true, isForeignKey: true, foreignKeyTo: "Role", isEnum: false}
				];

				var result = templateService.generateAdminSelectParams(fields);

				expect(result).toInclude('name="roleOptions"');
				expect(result).notToInclude("firstName");
			});

			it("skips fields where inForm is false", () => {
				var fields = [{
					name: "roleId",
					label: "Role",
					inputType: "select",
					inForm: false,
					isForeignKey: true,
					foreignKeyTo: "Role",
					isEnum: false
				}];

				var result = templateService.generateAdminSelectParams(fields);

				expect(result).toBe("");
			});
		});

	}

}