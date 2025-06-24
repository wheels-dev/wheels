component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests association validations", () => {

			beforeEach(() => {
				user = g.model("user").new({username = "Mike", password = "password", firstname = "Michael", lastname = "Jackson"})
				user.$classData().associations.author.nested.allow = true
				user.$classData().associations.author.nested.autoSave = true
			})

			it("model valid returns whether associations are not valid", () => {
				user.author = g.model("author").new()
				user.author.firstname = ""
				userValid = user.valid(validateAssociations = true)

				expect(userValid).toBeFalse()
			})

			it("model valid returns whether nested associations are not valid", () => {
				user.author = g.model("author").new()
				user.author.profile = g.model("profile").new()
				user.author.$classData().associations.profile.nested.allow = true
				user.author.$classData().associations.profile.nested.autoSave = true
				user.author.profile.dateOfBirth = ""
				userValid = user.valid(validateAssociations = true)

				expect(userValid).toBeFalse()
			})

			it("model valid returns whether associations are not valid with errors on parent and associations", () => {
				user.author = g.model("author").new()
				user.author.firstname = ""
				user.author.profile = g.model("profile").new()
				user.author.$classData().associations.profile.nested.allow = true
				user.author.$classData().associations.profile.nested.autoSave = true
				user.author.profile.dateOfBirth = ""
				userValid = user.valid(validateAssociations = true)

				expect(userValid).toBeFalse()
			})

			it("model valid returns whether associations are valid", () => {
				userValid = user.valid(validateAssociations = true)

				expect(userValid).toBeTrue()
			})
		})

		describe("Tests automatic validations", () => {

			it("tests automatic validations should validate primary keys", () => {
				user = g.model("UserAutoMaticValidations").new(
					username = 'tonyp1',
					password = 'tonyp123',
					firstname = 'Tony',
					lastname = 'Petruzzi',
					address = '123 Petruzzi St.',
					city = 'SomeWhere1',
					state = 'TX',
					zipcode = '11111',
					phone = '1235551212',
					fax = '4565551212',
					birthday = '11/01/1975',
					birthdaymonth = 11,
					birthdayyear = 1975,
					isactive = 1
				)

				/* should be valid since id is not passed in */
				expect(user.valid()).toBeTrue()

				/* should _not_ be valid since id is not a number */
				user.id = 'ABC'
				expect(user.valid()).toBeFalse()

				/* should be valid since id is blank */
				user.id = ''
				expect(user.valid()).toBeTrue()

				/* should be valid since id is a number */
				user.id = 1
				expect(user.valid()).toBeTrue()
			})

			it("automatic validations can be turned off for property", () => {
				user = g.model("UserAutoMaticValidationsOff").new(
					username = 'tonyp1',
					password = 'tonyp123',
					firstname = 'Tony',
					lastname = 'Petruzzi',
					address = '123 Petruzzi St.',
					city = 'SomeWhere1',
					state = 'TX',
					zipcode = '11111',
					phone = '1235551212',
					fax = '4565551212',
					birthday = '11/01/1975',
					birthdaymonth = 11,
					birthdayyear = 1975,
					isactive = 1
				)

				/* should be valid even though id is not a number because we have turned off automatic validations for the id property */
				user.id = 'ABC'
				expect(user.valid()).toBeTrue()
			})
		})

		describe("Tests conditional validations", () => {

			beforeEach(() => {
				user = application.wirebox.getInstance("wheels.tests._assets.models.Model").$initModelClass(
					name = "c_o_r_e_Users",
					path = g.get("modelPath")
				)
				user.username = "TheLongestNameInTheWorld"
				args = {}
				args.property = "username"
				args.maximum = "5"
			})

			it("unless validation using expression valid", () => {
				args.unless = "1 eq 1"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, true)
			})

			it("unless validation using expression invalid", () => {
				args.unless = "1 eq 0"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, false)
			})

			it("unless validation using method valid", () => {
				args.unless = "isnew()"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, true)
			})

			it("unless validation using method invalid", () => {
				args.unless = "!isnew()"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, false)
			})

			it("unless validation using method mixin and parameters valid", () => {
				user.stupid_mixin = stupid_mixin
				args.unless = "this.stupid_mixin(b='1' , a='2') eq 3"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, true)
			})

			it("unless validation using method mixin and parameters invalid", () => {
				user.stupid_mixin = stupid_mixin
				args.unless = "this.stupid_mixin(b='1' , a='2') neq 3"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, false)
			})

			it("if validation using expression invalid", () => {
				args.condition = "1 eq 1"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, false)
			})

			it("if validation using expression valid", () => {
				args.condition = "1 eq 0"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, true)
			})

			it("if validation using method invalid", () => {
				args.condition = "isnew()"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, false)
			})

			it("if validation using method valid", () => {
				args.condition = "!isnew()"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, true)
			})

			it("if validation using method mixin and parameters invalid", () => {
				user.stupid_mixin = stupid_mixin
				args.condition = "this.stupid_mixin(b='1' , a='2') eq 3"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, false)
			})

			it("if validation using method mixin and parameters valid", () => {
				user.stupid_mixin = stupid_mixin
				args.condition = "this.stupid_mixin(b='1' , a='2') neq 3"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, true)
			})

			it("both validations if triggered unless not triggered valid", () => {
				args.condition = "1 eq 1"
				args.unless = "this.username eq 'TheLongestNameInTheWorld'"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, true)
			})

			it("both validations if triggered unless triggered invalid", () => {
				args.condition = "1 eq 1"
				args.unless = "this.username eq ''"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, false)
			})

			it("both validations if not triggered unless not triggered valid", () => {
				args.condition = "1 eq 0"
				args.unless = "this.username eq 'TheLongestNameInTheWorld'"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, true)
			})

			it("both validations if not triggered unless triggered valid", () => {
				args.condition = "1 eq 0"
				args.unless = "this.username eq ''"
				user.validatesLengthOf(argumentCollection = args)
				assert_test(user, true)
			})
		})

		describe("Tests default validations", () => {

			beforeEach(() => {
				user = g.model("UserBlank").new()
				user.username = "gavin@cfwheels.org"
				user.password = "disismypassword"
				user.firstName = "Gavin"
				user.lastName = "Gavinsson"
			})

			it("validates presence of invalid", () => {
				/* missing key */
				StructDelete(user, "username")
				/* zero length string */
				user.password = ""
				user.valid()

				expect(user.allErrors()).toHaveLength(2)
			})

			it("validates presence of valid", () => {
				user.password = "something"
				user.firstName = "blahblah"

				expect(user.valid()).toBeTrue()
			})

			it("validates presence of valid with default on update", () => {
				user = g.model("UserBlank").findOne() // use existing user to test update
				user.birthtime = ""
				user.save(transaction = "rollback")
				arrResult = user.errorsOn("birthtime")

				expect(arrResult).toHaveLength(1)
				expect(arrResult[1].message).toBe("Birthtime can't be empty")
			})

			it("validates length of invalid", () => {
				user.state = "Too many characters!"
				user.valid()
				arrResult = user.errorsOn("state")

				expect(arrResult).toHaveLength(1)
				expect(arrResult[1].message).toBe("State is the wrong length")
			})

			it("validates length of valid", () => {
				user.state = "FL"
				expect(user.valid()).toBeTrue()
			})

			it("validates numericality of invalid", () => {
				user.birthDayMonth = "This is not a number!"
				user.valid()
				arrResult = user.errorsOn("birthDayMonth")

				expect(arrResult).toHaveLength(1)
				expect(arrResult[1].message).toBe("Birthdaymonth is not a number")
			})

			it("validates numericality of valid", () => {
				user.birthDayMonth = "7"
				
				expect(user.valid()).toBeTrue()
			})

			it("validates numericality of integer invalid", () => {
				user.birthDayMonth = "7.825"
				user.valid()
				arrResult = user.errorsOn("birthDayMonth")

				expect(arrResult).toHaveLength(1)
				expect(arrResult[1].message).toBe("Birthdaymonth is not a number")
			})

			it("validates format of date invalid", () => {
				user.birthDay = "This is not a date!"
				user.valid()
				arrResult = user.errorsOn("birthDay")

				expect(arrResult).toHaveLength(1)
				expect(arrResult[1].message).toBe("Birth day is invalid")
			})

			it("validates format of date valid", () => {
				user.birthDay = "01/01/2000"

				expect(user.valid()).toBeTrue()
			})

			it("validates format of time invalid", () => {
				user.birthTime = "This is not a time!"
				user.valid()
				arrResult = user.errorsOn("birthTime")

				expect(arrResult).toHaveLength(1)
				expect(arrResult[1].message).toBe("Birthtime is invalid")
			})

			it("validates format of time valid", () => {
				user.birthTime = "6:15 PM"

				expect(user.valid()).toBeTrue()
			})
		})

		describe("Tests low level validations", () => {

			it("validate and validateOnCreate should be called when creating", () => {
				user = g.model("user").new()
				user.valid()

				expect(user).toHaveKey("_validateCalled")
				expect(user._validateCalled).toBeTrue()
				expect(user).toHaveKey("_validateOnCreateCalled")
				expect(user._validateOnCreateCalled).toBeTrue()
			})

			it("validate and validateOnUpdate should be called when updating", () => {
				user = g.model("user").findOne(where = "username = 'perd'")
				user.valid()

				expect(user).toHaveKey("_validateCalled")
				expect(user._validateCalled).toBeTrue()
				expect(user).toHaveKey("_validateOnUpdateCalled")
				expect(user._validateOnUpdateCalled).toBeTrue()
			})
		})

		describe("Tests skip validations", () => {

			beforeEach(() => {
				user = g.model("user")
				args = {username = "myusername", password = "mypassword", firstname = "myfirstname", lastname = "mylastname"}
			})

			it("can create new record validation execute", () => {
				transaction {
					u = user.new(args)
					e = u.isnew()
					r = u.save()
					transaction action="rollback";
				}

				expect(e).toBeTrue()
				expect(r).toBeTrue()
			})

			it("cannot create new record validation execute", () => {
				transaction {
					args.username = "1"
					u = user.new(args)
					e = u.isnew()
					r = u.save()
					transaction action="rollback";
				}

				expect(e).toBeTrue()
				expect(r).toBeFalse()
			})

			it("can create new record validation skipped", () => {
				transaction {
					args.username = "1"
					u = user.new(args)
					e = u.isnew()
					r = u.save(validate = "false")
					transaction action="rollback";
				}

				expect(e).toBeTrue()
				expect(r).toBeTrue()
			})

			it("can update existing record validation execute", () => {
				transaction {
					u = user.findOne(where = "lastname = 'Petruzzi'")
					p = u.properties()
					r = u.update(args)
					e = u.isnew()
					u.update(p)
					transaction action="rollback";
				}

				expect(e).toBeFalse()
				expect(r).toBeTrue()
			})

			it("cannot update existing record validation execute", () => {
				transaction {
					args.password = "1"
					u = user.findOne(where = "lastname = 'Petruzzi'")
					p = u.properties()
					r = u.update(args)
					e = u.isnew()
					u.update(p)
					transaction action="rollback";
				}

				expect(e).toBeFalse()
				expect(r).toBeFalse()
			})

			it("cannot update existing record validation skipped", () => {
				transaction {
					args.password = "1"
					u = user.findOne(where = "lastname = 'Petruzzi'")
					p = u.properties()
					u.setProperties(args)
					e = u.isnew()
					r = u.save(validate = "false")
					u.update(p)
					transaction action="rollback";
				}

				expect(e).toBeFalse()
				expect(r).toBeTrue()
			})
		})

		describe("Tests standard validations", () => {

			beforeEach(() => {
				StructDelete(application.wheels.models, "c_o_r_e_users", false)
				user = g.model("c_o_r_e_users").new()
			})

			afterEach(() => {
				StructDelete(variables, "user")
			})

			/* validatesConfirmationOf */
			// ConfirmProperty and Property exist. CaseSensitive is OFF. Both match including case - VALID
			it("validatesConfirmationOf_valid", () => {
				user.password = "hamsterjelly"
				user.passwordConfirmation = "hamsterjelly"
				user.validatesConfirmationOf(property = "password")
				expect(user.valid()).toBeTrue()
				expect(user.allErrors()).toHaveLength(0)
			})

			// ConfirmProperty and Property exist. CaseSensitive is OFF. Both match except case - VALID
			it("validatesConfirmationOf_valid_allowcase", () => {
				user.password = "hamsterjelly"
				user.passwordConfirmation = "hamsterJelly"
				user.validatesConfirmationOf(property = "password")
				expect(user.valid()).toBeTrue()
				expect(user.allErrors()).toHaveLength(0)
			})

			// ConfirmProperty and Property exist. CaseSensitive is OFF. They don't match - INVALID
			it("validatesConfirmationOf_invalid", () => {
				user.password = "hamsterjelly"
				user.passwordConfirmation = "hamsterjellysucks"
				user.validatesConfirmationOf(property = "password")
				expect(user.valid()).toBeFalse()
				expect(user.allErrors()).toHaveLength(1)
			})

			// ConfirmProperty doesn't exist. No other checks are made. - INVALID (check errors array length is 1)
			it("validatesConfirmationOf_missing_property_confirmation_invalid", () => {
				user.password = "hamsterjelly"
				user.validatesConfirmationOf(property = "password")
				expect(user.valid()).toBeFalse()
				expect(user.allErrors()).toHaveLength(1)
			})

			// ConfirmProperty and Property exist. CaseSensitive is ON. Both match including case - VALID
			it("validatesConfirmationOf_valid_case", () => {
				user.password = "HamsterJelly"
				user.passwordConfirmation = "HamsterJelly"
				user.validatesConfirmationOf(property = "password", caseSensitive = true)
				expect(user.valid()).toBeTrue()
				expect(user.allErrors()).toHaveLength(0)
			})

			// ConfirmProperty and Property exist. CaseSensitive is ON. Both match except case - INVALID
			it("validatesConfirmationOf_invalid_case", () => {
				user.password = "HamsterJelly"
				user.passwordConfirmation = "hamsterjelly"
				user.validatesConfirmationOf(property = "password", caseSensitive = true)
				expect(user.valid()).toBeFalse()
				expect(user.allErrors()).toHaveLength(1)
			})

			// ConfirmProperty and Property exist. CaseSensitive is ON.  They don't match - INVALID
			it("validatesConfirmationOf_invalid_no_matchcase", () => {
				user.password = "HamsterJelly"
				user.passwordConfirmation = "duckjelly"
				user.validatesConfirmationOf(property = "password", caseSensitive = true)
				expect(user.valid()).toBeFalse()
				expect(user.allErrors()).toHaveLength(1)
			})

			// check content of message when ConfirmProperty doesn't exist
			// nb, this validation method only has a single error message returned and
			// can be overridden by the developer
			it("validatesConfirmationOf_missing_property_confirmation_msg", () => {
				user.password = "hamsterjelly"
				user.validatesConfirmationOf(property = "password")
				expect(user.valid()).toBeFalse()
				expect(user.allErrors()[1]["property"]).toBe("passwordConfirmation")
				expect(user.allErrors()[1]["message"]).toBe("Password should match confirmation")
			})

			/* validatesExclusionOf */
			it("validatesExclusionOf_valid", () => {
				user.firstname = "tony"
				user.validatesExclusionOf(property = "firstname", list = "per, raul, chris")
				expect(user.valid()).toBeTrue()
			})

			it("validatesExclusionOf_invalid", () => {
				user.firstname = "tony"
				user.validatesExclusionOf(property = "firstname", list = "per, raul, chris, tony")
				expect(user.valid()).toBeFalse()
			})

			it("validatesExclusionOf_missing_property_invalid", () => {
				user.validatesExclusionOf(property = "firstname", list = "per, raul, chris, tony")
				expect(user.valid()).toBeFalse()
			})

			it("validatesExclusionOf_missing_property_valid", () => {
				user.validatesExclusionOf(property = "firstname", list = "per, raul, chris, tony", allowblank = "true")
				expect(user.valid()).toBeTrue()
			})

			it("validatesExclusionOf_allowblank_valid", () => {
				user.firstname = ""
				user.validatesExclusionOf(property = "firstname", list = "per, raul, chris", allowblank = "true")
				expect(user.valid()).toBeTrue()
			})

			it("validatesExclusionOf_allowblank_invalid", () => {
				user.firstname = ""
				user.validatesExclusionOf(property = "firstname", list = "per, raul, chris", allowblank = "false")
				expect(user.valid()).toBeFalse()
			})

			/* validatesFormatOf */
			it("validatesFormatOf_valid", () => {
				user.phone = "954-555-1212"
				user.validatesFormatOf(property = "phone", regex = "(\d{3,3}-){2,2}\d{4,4}")
				expect(user.valid()).toBeTrue()
			})

			it("validatesFormatOf_invalid", () => {
				user.phone = "(954) 555-1212"
				user.validatesFormatOf(property = "phone", regex = "(\d{3,3}-){2,2}\d{4,4}")
				expect(user.valid()).toBeFalse()
			})

			it("validatesFormatOf_missing_property_invalid", () => {
				user.validatesFormatOf(property = "phone", regex = "(\d{3,3}-){2,2}\d{4,4}")
				expect(user.valid()).toBeFalse()
			})

			it("validatesFormatOf_missing_property_valid", () => {
				user.validatesFormatOf(property = "phone", regex = "(\d{3,3}-){2,2}\d{4,4}", allowBlank = "true")
				expect(user.valid()).toBeTrue()
			})

			it("validatesFormatOf_allowblank_valid", () => {
				user.phone = ""
				user.validatesFormatOf(property = "phone", regex = "(\d{3,3}-){2,2}\d{4,4}", allowBlank = "true")
				expect(user.valid()).toBeTrue()
			})

			it("validatesFormatOf_allowblank_invalid", () => {
				user.phone = ""
				user.validatesFormatOf(property = "phone", regex = "(\d{3,3}-){2,2}\d{4,4}", allowBlank = "false")
				expect(user.valid()).toBeFalse()
			})

			/* validatesInclusionOf */
			it("validatesInclusionOf_invalid", () => {
				user.firstname = "tony"
				user.validatesExclusionOf(property = "firstname", list = "per, raul, chris")
				expect(user.valid()).toBeTrue()
			})

			it("validatesInclusionOf_valid", () => {
				user.firstname = "tony"
				user.validatesExclusionOf(property = "firstname", list = "per, raul, chris, tony")
				expect(user.valid()).toBeFalse()
			})

			it("validatesInclusionOf_missing_property_invalid", () => {
				user.validatesExclusionOf(property = "firstname", list = "per, raul, chris, tony")
				expect(user.valid()).toBeFalse()
			})

			it("validatesInclusionOf_missing_property_valid", () => {
				user.validatesExclusionOf(property = "firstname", list = "per, raul, chris, tony", allowblank = "true")
				expect(user.valid()).toBeTrue()
			})

			it("validatesInclusionOf_allowblank_valid", () => {
				user.firstname = ""
				user.validatesExclusionOf(property = "firstname", list = "per, raul, chris", allowblank = "true")
				expect(user.valid()).toBeTrue()
			})

			it("validatesInclusionOf_allowblank_invalid", () => {
				user.firstname = ""
				user.validatesExclusionOf(property = "firstname", list = "per, raul, chris", allowblank = "false")
				expect(user.valid()).toBeFalse()
			})

			/* validatesLengthOf */
			it("validatesLengthOf_maximum_minimum_invalid", () => {
				user.firstname = "thi"
				user.validatesLengthOf(property = "firstname", minimum = "5", maximum = "20")
				expect(user.valid()).toBeFalse()
			})

			it("validatesLengthOf_maximum_valid", () => {
				user.firstname = "thisisatestagain"
				user.validatesLengthOf(property = "firstname", maximum = "20")
				expect(user.valid()).toBeTrue()
			})

			it("validatesLengthOf_maximum_invalid", () => {
				user.firstname = "thisisatestagain"
				user.validatesLengthOf(property = "firstname", maximum = "15")
				expect(user.valid()).toBeFalse()
			})

			it("validatesLengthOf_missing_property_invalid", () => {
				user.validatesLengthOf(property = "firstname", maximum = "15")
				expect(user.valid()).toBeFalse()
			})

			it("validatesLengthOf_missing_property_valid", () => {
				user.validatesLengthOf(property = "firstname", maximum = "15", allowblank = "true")
				expect(user.valid()).toBeTrue()
			})

			it("validatesLengthOf_minimum_valid", () => {
				user.firstname = "thisisatestagain"
				user.validatesLengthOf(property = "firstname", minimum = "15")
				expect(user.valid()).toBeTrue()
			})

			it("validatesLengthOf_minimum_invalid", () => {
				user.firstname = "thisisatestagain"
				user.validatesLengthOf(property = "firstname", minimum = "20")
				expect(user.valid()).toBeFalse()
			})

			it("validatesLengthOf_within_valid", () => {
				user.firstname = "thisisatestagain"
				user.validatesLengthOf(property = "firstname", within = "15,20")
				expect(user.valid()).toBeTrue()
			})

			it("validatesLengthOf_within_invalid", () => {
				user.firstname = "thisisatestagain"
				user.validatesLengthOf(property = "firstname", within = "10,15")
				expect(user.valid()).toBeFalse()
			})

			it("validatesLengthOf_exactly_valid", () => {
				user.firstname = "thisisatestagain"
				user.validatesLengthOf(property = "firstname", exactly = "16")
				expect(user.valid()).toBeTrue()
			})

			it("validatesLengthOf_exactly_invalid", () => {
				user.firstname = "thisisatestagain"
				user.validatesLengthOf(property = "firstname", exactly = "20")
				expect(user.valid()).toBeFalse()
			})

			it("validatesLengthOf_allowblank_valid", () => {
				user.firstname = ""
				user.validatesLengthOf(property = "firstname", allowblank = "true")
				expect(user.valid()).toBeTrue()
			})

			it("validatesLengthOf_allowblank_invalid", () => {
				user.firstname = ""
				user.validatesLengthOf(property = "firstname", allowblank = "false")
				expect(user.valid()).toBeFalse()
			})

			/* validatesNumericalityOf */
			it("validatesNumericalityOf_valid", () => {
				user.birthdaymonth = "10"
				user.validatesNumericalityOf(property = "birthdaymonth")
				expect(user.valid()).toBeTrue()
			})

			it("validatesNumericalityOf_invalid", () => {
				user.birthdaymonth = "1,000.00"
				user.validatesNumericalityOf(property = "birthdaymonth")
				expect(user.valid()).toBeFalse()
			})

			it("validatesNumericalityOf_missing_property_invalid", () => {
				user.validatesNumericalityOf(property = "birthdaymonth", onlyInteger = "true")
				expect(user.valid()).toBeFalse()
			})

			it("validatesNumericalityOf_missing_property_valid", () => {
				user.validatesNumericalityOf(property = "birthdaymonth", onlyInteger = "true", allowblank = "true")
				expect(user.valid()).toBeTrue()
			})

			it("validatesNumericalityOf_onlyInteger_valid", () => {
				user.birthdaymonth = "1000"
				user.validatesNumericalityOf(property = "birthdaymonth", onlyInteger = "true")
				expect(user.valid()).toBeTrue()
			})

			it("validatesNumericalityOf_onlyInteger_invalid", () => {
				user.birthdaymonth = "1000.25"
				user.validatesNumericalityOf(property = "birthdaymonth", onlyInteger = "true")
				expect(user.valid()).toBeFalse()
			})

			it("validatesNumericalityOf_allowBlank_valid", () => {
				user.birthdaymonth = ""
				user.validatesNumericalityOf(property = "birthdaymonth", allowBlank = "true")
				expect(user.valid()).toBeTrue()
			})

			it("validatesNumericalityOf_allowBlank_invalid", () => {
				user.birthdaymonth = ""
				user.validatesNumericalityOf(property = "birthdaymonth", allowBlank = "false")
				expect(user.valid()).toBeFalse()
			})

			it("validatesNumericalityOf_greaterThan_valid", () => {
				user.birthdaymonth = "11"
				user.validatesNumericalityOf(property = "birthdaymonth", greatThan = "10")
				expect(user.valid()).toBeTrue()
			})

			it("validatesNumericalityOf_greaterThan_invalid", () => {
				user.birthdaymonth = "10"
				user.validatesNumericalityOf(property = "birthdaymonth", greaterThan = "10")
				expect(user.valid()).toBeFalse()
			})

			it("validatesNumericalityOf_greaterThanOrEqualTo_valid", () => {
				user.birthdaymonth = "10"
				user.validatesNumericalityOf(property = "birthdaymonth", greaterThanOrEqualTo = "10")
				expect(user.valid()).toBeTrue()
			})

			it("validatesNumericalityOf_greaterThanOrEqualTo_invalid", () => {
				user.birthdaymonth = "9"
				user.validatesNumericalityOf(property = "birthdaymonth", greaterThanOrEqualTo = "10")
				expect(user.valid()).toBeFalse()
			})

			it("validatesNumericalityOf_greaterThanOrEqualTo_invalid_float", () => {
				user.birthdaymonth = "11.25"
				user.validatesNumericalityOf(property = "birthdaymonth", greaterThanOrEqualTo = "11.30")
				expect(user.valid()).toBeFalse()
			})

			it("validatesNumericalityOf_equalTo_valid", () => {
				user.birthdaymonth = "10"
				user.validatesNumericalityOf(property = "birthdaymonth", equalTo = "10")
				expect(user.valid()).toBeTrue()
			})

			it("validatesNumericalityOf_equalTo_invalid", () => {
				user.birthdaymonth = "9"
				user.validatesNumericalityOf(property = "birthdaymonth", equalTo = "10")
				expect(user.valid()).toBeFalse()
			})

			it("validatesNumericalityOf_lessThan_valid", () => {
				user.birthdaymonth = "9"
				user.validatesNumericalityOf(property = "birthdaymonth", lessThan = "10")
				expect(user.valid()).toBeTrue()
			})

			it("validatesNumericalityOf_lessThan_invalid", () => {
				user.birthdaymonth = "10"
				user.validatesNumericalityOf(property = "birthdaymonth", lessThan = "10")
				expect(user.valid()).toBeFalse()
			})

			it("validatesNumericalityOf_lessThanOrEqualTo_valid", () => {
				user.birthdaymonth = "10"
				user.validatesNumericalityOf(property = "birthdaymonth", lessThanOrEqualTo = "10")
				expect(user.valid()).toBeTrue()
			})

			it("validatesNumericalityOf_lessThanOrEqualTo_invalid", () => {
				user.birthdaymonth = "11"
				user.validatesNumericalityOf(property = "birthdaymonth", lessThanOrEqualTo = "10")
				expect(user.valid()).toBeFalse()
			})

			it("validatesNumericalityOf_odd_valid", () => {
				user.birthdaymonth = "13"
				user.validatesNumericalityOf(property = "birthdaymonth", odd = "true")
				expect(user.valid()).toBeTrue()
			})

			it("validatesNumericalityOf_odd_invalid", () => {
				user.birthdaymonth = "14"
				user.validatesNumericalityOf(property = "birthdaymonth", odd = "true")
				expect(user.valid()).toBeFalse()
			})

			it("validatesNumericalityOf_even_valid", () => {
				user.birthdaymonth = "14"
				user.validatesNumericalityOf(property = "birthdaymonth", even = "true")
				expect(user.valid()).toBeTrue()
			})

			it("validatesNumericalityOf_even_invalid", () => {
				user.birthdaymonth = "13"
				user.validatesNumericalityOf(property = "birthdaymonth", even = "true")
				expect(user.valid()).toBeFalse()
			})

			/* validatesPresenceOf */
			it("validatesPresenceOf_valid", () => {
				user.firstname = "tony"
				user.validatesPresenceOf(property = "firstname")
				expect(user.valid()).toBeTrue()
			})

			it("validatesPresenceOf_invalid", () => {
				user.validatesPresenceOf(property = "firstname")
				expect(user.valid()).toBeFalse()
			})

			it("validatesPresenceOf_invalid_when_blank", () => {
				user.firstname = ""
				user.validatesPresenceOf(property = "firstname")
				expect(user.valid()).toBeFalse()
			})

			it("validatesPresenceOf_does_not_trim_properties", () => {
				user.firstname = " "
				user.validatesPresenceOf(property = "firstname")
				expect(user.valid()).toBeTrue()
			})

			/* validatesUniquenessOf */
			it("validatesUniquenessOf_valid", () => {
				user.firstname = "Tony"
				user.validatesUniquenessOf(property = "firstname")
				if (!IsBoolean(user.tableName()) OR user.tableName()) {
					expect(user.valid()).toBeFalse()
				} else {
					expect(user.valid()).toBeTrue()
				}
			})

			it("validatesUniquenessOf_valids_when_updating_existing_record", () => {
				user = g.model("user").findOne(where = "firstName = 'Tony'")
				user.validatesUniquenessOf(property = "firstName")
				expect(user.valid()).toBeTrue()
				// Special case for testing when we already have duplicates in the database:
				// https://github.com/cfwheels/cfwheels/issues/480
				transaction action="begin" {
					user.create(firstName = "Tony", username = "xxxx", password = "xxxx", lastname = "xxxx", validate = false)
					firstUser = g.model("user").findOne(where = "firstName = 'Tony'", order = "id ASC")
					lastUser = g.model("user").findOne(where = "firstName = 'Tony'", order = "id DESC")
					expect(firstUser.valid()).toBeFalse()
					expect(lastUser.valid()).toBeFalse()
					transaction action="rollback";
				}
			})

			it("validatesUniquenessOf_takes_softdeletes_into_account", () => {
				transaction action="begin" {
					org_post = g.model('post').findOne()
					properties = org_post.properties()
					new_post = g.model('post').new(properties)
					org_post.delete()
					valid = new_post.valid()
					expect(valid).toBeFalse()
					transaction action="rollback";
				}
			})

			it("validatesUniquenessOf_with_blank_integer_values", () => {
				combiKey = g.model("combiKey").new(id1 = "", id2 = "")
				expect(combiKey.valid()).toBeFalse()
			})

			it("validatesUniquenessOf_with_blank_property_value", () => {
				user.blank = ""
				user.validatesUniquenessOf(property = "blank")
				expect(user.valid()).toBeFalse()
			})

			it("validatesUniquenessOf_with_blank_property_value_with_allowBlank", () => {
				user.blank = ""
				user.validatesUniquenessOf(property = "blank", allowBlank = true)
				expect(user.valid()).toBeTrue()
			})

			/* validate */
			it("validate_registering_methods", () => {
				user.firstname = "tony"
				user.validate(method = "fakemethod")
				user.validate(method = "fakemethod2", when = "onCreate")
				v = user.$classData().validations
				onsave = v["onsave"]
				oncreate = v["oncreate"]
				expect(onsave).toHaveLength(1)
				expect(onsave[1].method).toBe("fakemethod")
				expect(oncreate).toHaveLength(1)
				expect(oncreate[1].method).toBe("fakemethod2")
			})			
		})

		describe("Tests validation error messages", () => {

			beforeEach(() => {
				StructDelete(application.wheels.models, "c_o_r_e_users", false)
				user = g.model("c_o_r_e_users").new()
				user.username = "TheLongestNameInTheWorld"
				args = {}
				args.property = "username"
				args.minimum = "5"
				args.maximum = "20"
				args.message = "Please shorten your [property] please. [maximum] characters is the maximum length allowed."
			})

			it("replaces bracketed argument markers", () => {
				user.validatesLengthOf(argumentCollection = args)
				user.valid()
				asset_test(user, "Please shorten your username please. 20 characters is the maximum length allowed.")
			})

			it("capitalizes bracketed property argument marker at beginning", () => {
				args.message = "[property] must be between [minimum] and [maximum] characters."
				user.validatesLengthOf(argumentCollection = args)
				user.valid()
				asset_test(user, "Username must be between 5 and 20 characters.")
			})

			it("escapes bracketed argument markers", () => {
				args.message = "[property] must be between [[minimum]] and [maximum] characters."
				user.validatesLengthOf(argumentCollection = args)
				user.valid()
				asset_test(user, "Username must be between [minimum] and 20 characters.")
			})
		})
	}

	function assert_test(required any obj, required boolean expected) {
		e = arguments.obj.valid()

		expect(e).toBe(arguments.expected)
	}

	function stupid_mixin(required numeric a, required numeric b) {
		return a + b
	}

	function asset_test(required any obj, required string expected) {
		e = arguments.obj.errorsOn("username")
		e = e[1].message
		r = arguments.expected

		expect(e).toBe(r)
	}
}