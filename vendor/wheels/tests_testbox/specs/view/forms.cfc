component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that $objectName", () => {

			beforeEach(() => {
				_controller = g.controller(name = "ControllerWithNestedModel")
			})

			it("works with objectName", () => {
				objectName = _controller.$objectName(objectName = "author")

				expect(objectName).toBe("author")
			})

			it("works with objectName as struct", () => {
				struct = {formField = "formValue"}
				objectName = _controller.$objectName(objectName = struct)

				expect(objectName).toBeStruct()
			})

			it("works with hasOne association", () => {
				objectName = _controller.$objectName(objectName = "author", association = "profile")

				expect(objectName).toBe("author['profile']")
			})

			it("works with hasMany associations", () => {
				objectName = _controller.$objectName(objectName = "author", association = "posts", position = "1")

				expect(objectName).toBe("author['posts'][1]")
			})

			it("works with hasMany associations nested", () => {
				objectName = _controller.$objectName(objectName = "author", association = "posts,_c_o_r_e_comments", position = "1,2")

				expect(objectName).toBe("author['posts'][1]['_c_o_r_e_comments'][2]")
			})

			it("throws error without correct positions", () => {
				expect(() => {
					_controller.$objectName(objectName="author", association="posts,_c_o_r_e_comments", position="1")
				}).toThrow("Wheels.InvalidArgument")
			})
		})

		describe("Tests that buttonTag", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				imagePath = application.wheels.webPath & application.wheels.imagePath
				g.set(functionName = "buttonTag", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "buttonTag", encode = true)
			})

			it("works with defaults", () => {
				r = _controller.buttonTag()
				e = '<button type="submit" value="save">Save changes</button>'

				expect(e).toBe(r)
			})

			it("works with icon as html", () => {
				r = _controller.buttonTag(content = "<i class='fa fa-icon' /> Edit", encode = "attributes")
				e = '<button type="submit" value="save"><i class=''fa fa-icon'' /> Edit</button>'

				expect(e).toBe(r)
			})

			it("works with image", () => {
				r = _controller.buttonTag(image = "http://www.cfwheels.com/logo.jpg")
				e = '<button type="submit" value="save"><img alt="Logo" src="http://www.cfwheels.com/logo.jpg" type="image"></button>'

				expect(e).toBe(r)
			})

			it("works with disable", () => {
				r = _controller.buttonTag(disable = "disable-value")
				e = '<button disable="disable-value" type="submit" value="save">Save changes</button>'

				expect(e).toBe(r)
			})

			it("works with append prepend", () => {
				r = _controller.buttonTag(append = "a", prepend = "p")
				e = 'p<button type="submit" value="save">Save changes</button>a'

				expect(e).toBe(r)
			})
			
			it("encodes HTML content when encode=true", () => {
				r = _controller.buttonTag(content = "Button with <strong>bold</strong> text", encode = true)
				e = '<button type="submit" value="save">Button with &lt;strong&gt;bold&lt;&##x2f;strong&gt; text</button>'
				
				expect(e).toBe(r)
			})
			
			it("does not encode HTML content when encode=false", () => {
				r = _controller.buttonTag(content = "Button with <strong>bold</strong> text", encode = false)
				e = '<button type="submit" value="save">Button with <strong>bold</strong> text</button>'
				
				expect(e).toBe(r)
			})
			
			it("encodes HTML attributes when encode=true", () => {
				r = _controller.buttonTag(
					content = "Click me", 
					class = 'btn btn-danger" onclick="alert(\"xss\")',
					encode = true
				)
				e = '<button class="btn&##x20;btn-danger&quot;&##x20;onclick&##x3d;&quot;alert&##x28;&quot;xss&quot;&##x29;" type="submit" value="save">Click me</button>'
				
				expect(e).toBe(r)
			})
			
			it("handles complex HTML content with encode=true", () => {
				htmlContent = 'Button with <strong>bold</strong> and <script>alert("XSS")</script>'
				r = _controller.buttonTag(content = htmlContent, encode = true)
				e = '<button type="submit" value="save">Button with &lt;strong&gt;bold&lt;&##x2f;strong&gt; and &lt;script&gt;alert&##x28;&quot;XSS&quot;&##x29;&lt;&##x2f;script&gt;</button>'
				
				expect(e).toBe(r)
			})
			
			it("handles both attributes and content correctly when encode=attributes", () => {
				r = _controller.buttonTag(
					content = "Button with <strong>bold</strong> text",
					class = 'button" onclick="alert(\"xss\")',
					encode = "attributes"
				)
				e = '<button class="button&quot;&##x20;onclick&##x3d;&quot;alert&##x28;&quot;xss&quot;&##x29;" type="submit" value="save">Button with <strong>bold</strong> text</button>'
				
				expect(e).toBe(r)
			})
			
			it("supports HTML entities in content with encode=false", () => {
				r = _controller.buttonTag(content = "Button with &lt;strong&gt;HTML entities&lt;/strong&gt;", encode = false)
				e = '<button type="submit" value="save">Button with &lt;strong&gt;HTML entities&lt;/strong&gt;</button>'
				
				expect(e).toBe(r)
			})
		})

		describe("Tests that checkbox", () => {

			beforeEach(() => {
				_controller = g.controller(name = "ControllerWithModel")
				args = {}
				args.objectName = "user"
				args.label = false
				g.set(functionName = "checkBox", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "checkBox", encode = true)
			})

			it("checks when property value equals checkedValue", () => {
				args.property = "birthdaymonth"
				args.checkedvalue = "11"
				e = '<input checked="checked" id="user-birthdaymonth" name="user[birthdaymonth]" type="checkbox" value="11"><input id="user-birthdaymonth-checkbox" name="user[birthdaymonth]($checkbox)" type="hidden" value="0">'
				r = _controller.checkBox(argumentcollection = args)

				expect(e).toBe(r)

				args.checkedvalue = "12"
				e = '<input id="user-birthdaymonth" name="user[birthdaymonth]" type="checkbox" value="12"><input id="user-birthdaymonth-checkbox" name="user[birthdaymonth]($checkbox)" type="hidden" value="0">'
				r = _controller.checkBox(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("is unchecked with checkedvalue when property value is 1", () => {
				args.property = "isactive"
				args.checkedvalue = "0"
				actual = _controller.checkBox(argumentcollection = args)

				expect(actual).notToInclude("checked")
			})

			it("is checked with checkedvalue when property value is 1", () => {
				args.property = "isactive"
				args.checkedvalue = "1"
				actual = _controller.checkBox(argumentcollection = args)

				expect(actual).toInclude("checked")
			})

			it("is checked with default checkedvalue when property value is 1", () => {
				args.property = "isactive"
				actual = _controller.checkBox(argumentcollection = args)

				expect(actual).toInclude("checked")
			})
		})

		describe("Tests that checkboxTag", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("is not checked", () => {
				e = _controller.checkBoxTag(name = "subscribe", value = "1", label = "Subscribe to our newsletter", checked = false)
				r = '<label for="subscribe-1">Subscribe to our newsletter<input id="subscribe-1" name="subscribe" type="checkbox" value="1"></label>'

				expect(e).toBe(r)
			})

			it("is checked", () => {
				e = _controller.checkBoxTag(name = "subscribe", value = "1", label = "Subscribe to our newsletter", checked = true)
				r = '<label for="subscribe-1">Subscribe to our newsletter<input checked="checked" id="subscribe-1" name="subscribe" type="checkbox" value="1"></label>'

				expect(e).toBe(r)
			})

			it("works with blank value and not checked", () => {
				e = _controller.checkBoxTag(name = "gender", value = "", checked = false)
				r = '<input id="gender" name="gender" type="checkbox" value="">'

				expect(e).toBe(r)
			})

			it("is encoding attributes", () => {
				e = _controller.checkBoxTag(name = "gender", value = "", checked = false, uncheckedvalue = 1, encode = "attributes")
				r = '<input id="gender" name="gender" type="checkbox" value=""><input id="gender-checkbox" name="gender&##x28;&##x24;checkbox&##x29;" type="hidden" value="1">'

				expect(e).toBe(r)
			})
		})

		describe("Tests that endFormTag", () => {

			it("is valid", () => {
				_controller = g.controller(name = "dummy")

				e = _controller.endFormTag()
				expect(e).toBe("</form>")
			})
		})

		describe("Tests that fileField", () => {

			it("is valid", () => {
				_controller = g.controller(name = "ControllerWithModel")

				e = _controller.fileField(objectName = "user", property = "firstname")
				r = '<label for="user-firstname">Firstname<input id="user-firstname" name="user&##x5b;firstname&##x5d;" type="file"></label>'

				expect(e).toBe(r)
			})
		})

		describe("Tests that fileFieldTag", () => {

			it("is valid", () => {
				_controller = g.controller(name = "dummy")

				e = _controller.fileFieldTag(name = "photo")
				r = '<input id="photo" name="photo" type="file">'

				expect(e).toBe(r)
			})
		})

		describe("Tests that hiddenField", () => {

			it("is valid", () => {
				_controller = g.controller(name = "ControllerWithModel")

				e = _controller.hiddenField(objectName = "user", property = "firstname")
				r = '<input id="user-firstname" name="user&##x5b;firstname&##x5d;" type="hidden" value="Tony">'

				expect(e).toBe(r)
			})

			it("encodes HTML in value when encode=false", () => {
				_controller = g.controller(name = "ControllerWithModel")

				e = _controller.hiddenField(objectName = "user", property = "firstname", encode = "false")
				r = '<input id="user-firstname" name="user[firstname]" type="hidden" value="Tony">'

				expect(e).toBe(r)
			})
		})

		describe("Tests that hiddenFieldTag", () => {

			it("is valid", () => {
				_controller = g.controller(name = "dummy")

				e = _controller.hiddenFieldTag(name = "userId", value = "tony")
				r = '<input id="userId" name="userId" type="hidden" value="tony">'

				expect(e).toBe(r)
			})

			it("encodes HTML in value when encode=true", () => {
				_controller = g.controller(name = "dummy")

				e = _controller.hiddenFieldTag(name = "userId", value = "tony with <strong>bold</strong> text", encode = "true")
				r = '<input id="userId" name="userId" type="hidden" value="tony&##x20;with&##x20;&lt;strong&gt;bold&lt;&##x2f;strong&gt;&##x20;text">'

				expect(e).toBe(r)
			})
			
			it("encodes HTML in value when encode=false", () => {
				_controller = g.controller(name = "dummy")

				e = _controller.hiddenFieldTag(name = "userId", value = "tony with <strong>bold</strong> text", encode = "false")
				r = '<input id="userId" name="userId" type="hidden" value="tony with <strong>bold</strong> text">'

				expect(e).toBe(r)
			})
		})

		describe("Tests that htmlAttributes", () => {

			beforeEach(() => {
				_controller = g.controller(name = "ControllerWithModel")
				oldBooleanAttributes = application.wheels.booleanAttributes
			})

			afterEach(() => {
				application.wheels.booleanAttributes = oldBooleanAttributes
			})

			it("tag with disabled and readonly set to true", () => {
				textField = _controller.textFieldTag(label = "First Name", name = "firstName", disabled = true, readonly = true)
				expected = '<label for="firstName">First Name<input disabled id="firstName" name="firstName" readonly type="text" value=""></label>'

				expect(textField).toBe(expected)
			})

			it("tag with disabled and readonly set to false", () => {
				textField = _controller.textFieldTag(label = "First Name", name = "firstName", disabled = false, readonly = false)
				expected = '<label for="firstName">First Name<input id="firstName" name="firstName" type="text" value=""></label>'

				expect(textField).toBe(expected)
			})

			it("tag with disabled and readonly set to string", () => {
				textField = _controller.textFieldTag(
					label = "First Name",
					name = "firstName",
					disabled = "cheese",
					readonly = "crackers"
				)
				expected = '<label for="firstName">First Name<input disabled="cheese" id="firstName" name="firstName" readonly="crackers" type="text" value=""></label>'

				expect(textField).toBe(expected)
			})

			it("supported attributes should be boolean", () => {
				result = _controller.textFieldTag(name = "num", checked = true, disabled = "true")
				expected = '<input checked disabled id="num" name="num" type="text" value="">'

				expect(result).toBe(expected)
			})

			it("non supported attributes should be non boolean", () => {
				result = _controller.textFieldTag(name = "num", class = "true", value = "true")
				expected = '<input class="true" id="num" name="num" type="text" value="true">'

				expect(result).toBe(expected)
			})

			it("supported attribute should be ommitted when false", () => {
				result = _controller.textFieldTag(name = "num", readonly = false)
				expected = '<input id="num" name="num" type="text" value="">'

				expect(result).toBe(expected)
			})

			it("supported attribute should be non boolean when setting is off", () => {
				application.wheels.booleanAttributes = false
				result = _controller.textFieldTag(name = "num", checked = true)
				expected = '<input checked="true" id="num" name="num" type="text" value="">'

				expect(result).toBe(expected)
			})

			it("non supported attribute should be boolean when setting is on", () => {
				application.wheels.booleanAttributes = true
				result = _controller.textFieldTag(name = "num", whatever = true)
				expected = '<input id="num" name="num" type="text" value="" whatever>'

				expect(result).toBe(expected)
			})
		})

		describe("Tests that label", () => {

			beforeEach(() => {
				c = g.controller(name = "ControllerWithModel")
				g.set(functionName = "checkBoxTag", encode = false)
				g.set(functionName = "textField", encode = false)
				g.set(functionName = "textFieldTag", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "checkBoxTag", encode = true)
				g.set(functionName = "textField", encode = true)
				g.set(functionName = "textFieldTag", encode = true)
			})

			it("adds label to the left", () => {
				actual = c.checkBoxTag(name = "the-name", label = "The Label:")
				expected = '<label for="the-name-1">The Label:<input id="the-name-1" name="the-name" type="checkbox" value="1"></label>'

				expect(actual).toBe(expected)

				actual = c.checkBoxTag(name = "the-name", label = "The Label:", labelPlacement = "around")

				expect(actual).toBe(expected)

				actual = c.checkBoxTag(name = "the-name", label = "The Label:", labelPlacement = "aroundLeft")

				expect(actual).toBe(expected)
			})

			it("adds label to the right", () => {
				actual = c.checkBoxTag(name = "the-name", label = "The Label", labelPlacement = "aroundRight")
				expected = '<label for="the-name-1"><input id="the-name-1" name="the-name" type="checkbox" value="1">The Label</label>'

				expect(actual).toBe(expected)
			})

			it("adds custom label on plain helper", () => {
				actual = c.checkBoxTag(name = "the-name", label = "The Label:")
				expected = '<label for="the-name-1">The Label:<input id="the-name-1" name="the-name" type="checkbox" value="1"></label>'

				expect(actual).toBe(expected)
			})

			it("adds custom label on plain helper and overriding id", () => {
				actual = c.checkBoxTag(name = "the-name", label = "The Label:", id = "the-id")
				expected = '<label for="the-id">The Label:<input id="the-id" name="the-name" type="checkbox" value="1"></label>'

				expect(actual).toBe(expected)
			})

			it("adds blank label on plain helper", () => {
				actual = c.textFieldTag(name = "the-name", label = "")
				expected = '<input id="the-name" name="the-name" type="text" value="">'

				expect(actual).toBe(expected)
			})

			/* RocketUnit was using Tag model but Testbox is using User model to test object based helpers */

			it("adds custom label on object helper", () => {
				actual = c.textField(objectName = "user", property = "username", label = "The Label:")
				expected = '<label for="user-username">The Label:<input id="user-username" maxlength="50" name="user[username]" type="text" value="tonyp"></label>'

				expect(actual).toBe(expected)
			})

			it("adds custom label on object helper and overriding id", () => {
				actual = c.textField(objectName = "user", property = "username", label = "The Label:", id = "the-id")
				expected = '<label for="the-id">The Label:<input id="the-id" maxlength="50" name="user[username]" type="text" value="tonyp"></label>'

				expect(actual).toBe(expected)
			})

			it("adds blank label on object helpers", () => {
				actual = c.textField(objectName = "user", property = "username", label = "")
				expected = '<input id="user-username" maxlength="50" name="user[username]" type="text" value="tonyp">'

				expect(actual).toBe(expected)
			})

			it("adds automatic label on object helpers with around placement", () => {
				actual = c.textField(objectName = "user", property = "username", labelPlacement = "around")
				expected = '<label for="user-username">Username<input id="user-username" maxlength="50" name="user[username]" type="text" value="tonyp"></label>'

				expect(actual).toBe(expected)
			})

			it("adds automatic label on object helpers with before placement", () => {
				actual = c.textField(objectName = "user", property = "username", labelPlacement = "before")
				expected = '<label for="user-username">Username</label><input id="user-username" maxlength="50" name="user[username]" type="text" value="tonyp">'

				expect(actual).toBe(expected)
			})

			it("adds automatic label on object helpers with after placement", () => {
				actual = c.textField(objectName = "user", property = "username", labelPlacement = "after")
				expected = '<input id="user-username" maxlength="50" name="user[username]" type="text" value="tonyp"><label for="user-username">Username</label>'

				expect(actual).toBe(expected)
			})

			it("adds automatic label on object helpers with non persisted property", () => {
				actual = c.textField(objectName = "user", property = "virtual")
				expected = '<label for="user-virtual">Virtual property<input id="user-virtual" name="user[virtual]" type="text" value=""></label>'

				expect(actual).toBe(expected)
			})

			it("adds automatic label in error message", () => {
				tag = Duplicate(g.model("tag").new())
				/* use a deep copy so as not to affect the cached model */
				tag.validatesPresenceOf(property = "name")
				tag.valid()
				errors = tag.errorsOn(property = "name")

				expect(errors).toHaveLength(1)
				expect(errors[1].message).toBe("Tag name can't be empty")
			})

			it("adds automatic label in error message with non persisted property", () => {
				tag = Duplicate(g.model("tag").new())
				tag.validatesPresenceOf(property = "virtual")
				tag.valid()
				errors = tag.errorsOn(property = "virtual")

				expect(errors).toHaveLength(1)
				expect(errors[1].message).toBe("Virtual property can't be empty")
			})
		})

		describe("Tests that passwordField", () => {

			it("is valid", () => {
				_controller = g.controller(name = "ControllerWithModel")
				e = _controller.passwordField(objectName = "User", property = "password")
				r = '<label for="User-password">Password<input id="User-password" maxlength="50" name="User&##x5b;password&##x5d;" type="password" value="tonyp123"></label>'

				expect(e).toBe(r)
			})
		})

		describe("Tests that passwordFieldTag", () => {

			it("is valid", () => {
				_controller = g.controller(name = "dummy")
				e = _controller.passwordFieldTag(name = "password")
				r = '<input id="password" name="password" type="password" value="">'

				expect(e).toBe(r)
			})
		})

		describe("Tests that radioButton", () => {

			it("is valid", () => {
				_controller = g.controller(name = "ControllerWithModel")
				e = _controller.radioButton(objectName = "user", property = "gender", tagValue = "m", label = "Male")
				r = '<label for="user-gender-m">Male<input id="user-gender-m" name="user&##x5b;gender&##x5d;" type="radio" value="m"></label>'

				expect(e).toBe(r)
			})
		})

		describe("Tests that radioButtonTag", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("works with not blank value", () => {
				e = _controller.radioButtonTag(name = "gender", value = "m", label = "Male", checked = true)
				r = '<label for="gender-m">Male<input checked="checked" id="gender-m" name="gender" type="radio" value="m"></label>'

				expect(e).toBe(r)
			})

			it("works with blank value", () => {
				e = _controller.radioButtonTag(name = "gender", value = "", label = "Male", checked = true)
				r = '<label for="gender">Male<input checked="checked" id="gender" name="gender" type="radio" value=""></label>'

				expect(e).toBe(r)
			})

			it("works with blank value and not checked", () => {
				e = _controller.radioButtonTag(name = "gender", value = "", label = "Male", checked = false)
				r = '<label for="gender">Male<input id="gender" name="gender" type="radio" value=""></label>'

				expect(e).toBe(r)
			})
		})

		describe("Tests that select", () => {

			beforeEach(() => {
				_controller = g.controller(name = "ControllerWithModel")
				user = g.model("user")
				g.set(functionName = "select", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "select", encode = true)
			})

			it("works with list as options", () => {
				options = "Opt1,Opt2"
				r = _controller.select(objectName = "user", property = "firstname", options = options, label = false)
				e = '<select id="user-firstname" name="user[firstname]"><option value="Opt1">Opt1</option><option value="Opt2">Opt2</option></select>'

				expect(e).toBe(r)
			})

			it("works with array as options", () => {
				options = ArrayNew(1)
				options[1] = "Opt1"
				options[2] = "Opt2"
				options[3] = "Opt3"
				r = _controller.select(objectName = "user", property = "firstname", options = options, label = false)
				e = '<select id="user-firstname" name="user[firstname]"><option value="Opt1">Opt1</option><option value="Opt2">Opt2</option><option value="Opt3">Opt3</option></select>'

				expect(e).toBe(r)
			})

			it("works with struct as options", () => {
				options = {}
				options.x = "xVal"
				options.y = "yVal"
				r = _controller.select(objectName = "user", property = "firstname", options = options, label = false)
				e = '<select id="user-firstname" name="user[firstname]"><option value="x">xVal</option><option value="y">yVal</option></select>'

				expect(e).toBe(r)
			})

			it("is setting text field", () => {
				users = user.findAll(returnAs = "objects", order = "id")
				r = _controller.select(
					objectName = "user",
					property = "firstname",
					options = users,
					valueField = "id",
					textField = "firstName",
					label = false
				)
				e = '<select id="user-firstname" name="user[firstname]"><option value="#users[1].id#">Tony</option><option value="#users[2].id#">Chris</option><option value="#users[3].id#">Per</option><option value="#users[4].id#">Raul</option><option value="#users[5].id#">Joe</option></select>'

				expect(e).toBe(r)
			})

			it("first non numeric property defaults text field on query", () => {
				users = user.findAll(returnAs = "query", order = "id")
				r = _controller.select(objectName = "user", property = "firstname", options = users, label = false)
				e = '<select id="user-firstname" name="user[firstname]"><option value="#users["id"][1]#">tonyp</option><option value="#users["id"][2]#">chrisp</option><option value="#users["id"][3]#">perd</option><option value="#users["id"][4]#">raulr</option><option value="#users["id"][5]#">joeb</option></select>'

				expect(e).toBe(r)
			})

			it("first non numeric property defaults text field on objects", () => {
				users = user.findAll(returnAs = "objects", order = "id")
				r = _controller.select(objectName = "user", property = "firstname", options = users, label = false)
				e = '<select id="user-firstname" name="user[firstname]"><option value="#users[1].id#">tonyp</option><option value="#users[2].id#">chrisp</option><option value="#users[3].id#">perd</option><option value="#users[4].id#">raulr</option><option value="#users[5].id#">joeb</option></select>'

				expect(e).toBe(r)
			})

			it("works with array of structs as options", () => {
				options = []
				options[1] = {}
				options[1].tp = "tony petruzzi"
				options[2] = {}
				options[2].pd = "per djurner"
				r = _controller.select(objectName = "user", property = "firstname", options = options, label = false)
				e = '<select id="user-firstname" name="user[firstname]"><option value="tp">tony petruzzi</option><option value="pd">per djurner</option></select>'

				expect(e).toBe(r)
			})

			it("works with array of structs as options 2", () => {
				options = []
				options[1] = {}
				options[1] = {value = "petruzzi", name = "tony"}
				options[2] = {}
				options[2] = {value = "djurner", name = "per"}
				r = _controller.select(
					objectName = "user",
					property = "firstname",
					options = options,
					valueField = "value",
					textField = "name",
					label = false
				)
				e = '<select id="user-firstname" name="user[firstname]"><option value="petruzzi">tony</option><option value="djurner">per</option></select>'

				expect(e).toBe(r)
			})

			it("works with htmlsafe", () => {
				badValue = "<invalidTag;alert('hello');</script>"
				badName = "<invalidTag;alert('tony');</script>"
				goodValue = EncodeForHTMLAttribute(badValue)
				goodName = EncodeForHTML(badName)
				options = []
				options[1] = {value = "#badValue#", name = "#badName#"}
				g.set(functionName = "select", encode = true)
				r = _controller.select(
					objectName = "user",
					property = "firstname",
					options = options,
					valueField = "value",
					textField = "name",
					label = false
				)

				expect(r).toInclude(goodValue)
				expect(r).toInclude(goodName)
			})
		})

		describe("Tests that selectTag", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy");
				options = {}
				options.simplevalues = '<select id="testselect" name="testselect"><option value="first">first</option><option value="second">second</option><option value="third">third</option></select>'
				options.complexvalues = '<select id="testselect" name="testselect"><option value="1">first</option><option value="2">second</option><option value="3">third</option></select>'
				options.single_key_struct = '<select id="testselect" name="testselect"><option value="firstKeyName">first Value</option><option value="secondKeyName">second Value</option></select>'
				options.single_column_query = '<select id="testselect" name="testselect"><option value="first">first</option><option value="second">second</option><option value="third">third</option></select>'
				options.empty_query = '<select id="testselect" name="testselect"></select>'
			})

			it("encodes for html and encode for html attribute", () => {
				result = g.controller("dummy").selectTag(name = "x", options = "<t e s t>,<2>,3", selected = "<2>")
				expected = '<select id="x" name="x"><option value="&lt;t&##x20;e&##x20;s&##x20;t&gt;">&lt;t e s t&gt;</option><option selected="selected" value="&lt;2&gt;">&lt;2&gt;</option><option value="3">3</option></select>'

				expect(result).toBe(expected)
			})

			it("works with list for option values", () => {
				args.name = "testselect"
				args.options = "first,second,third"
				r = _controller.selectTag(argumentcollection = args)

				expect(r).toBe(options.simplevalues)
			})

			it("works with struct for option values", () => {
				args.name = "testselect"
				args.options = {1 = "first", 2 = "second", 3 = "third"}
				r = _controller.selectTag(argumentcollection = args)

				expect(r).toBe(options.complexvalues)
			})

			it("works with array of structs for option values single key", () => {
				args.name = "testselect"
				args.options = []
				temp = {firstKeyName = "first Value"}
				ArrayAppend(args.options, temp)
				temp = {secondKeyName = "second Value"}
				ArrayAppend(args.options, temp)
				r = _controller.selectTag(argumentcollection = args)

				expect(r).toBe(options.single_key_struct)
			})

			it("works with one dimensional array for option values", () => {
				args.name = "testselect"
				args.options = ["first", "second", "third"]
				r = _controller.selectTag(argumentcollection = args)

				expect(r).toBe(options.simplevalues)
			})

			it("works with two dimensional array for option values", () => {
				args.name = "testselect"
				first = [1, "first"]
				second = [2, "second"]
				third = [3, "third"]
				args.options = [first, second, third]
				r = _controller.selectTag(argumentcollection = args)

				expect(r).toBe(options.complexvalues)
			})

			it("works with three dimensional array for option values", () => {
				args.name = "testselect"
				first = [1, "first", "a"]
				second = [2, "second", "b"]
				third = [3, "third", "c"]
				args.options = [first, second, third]
				r = _controller.selectTag(argumentcollection = args)

				expect(r).toBe(options.complexvalues)
			})

			it("works with query for option values", () => {
				q = QueryNew("")
				id = ["first", "second", "third"]
				QueryAddColumn(q, "id", id)
				args.name = "testselect"
				args.options = q
				r = _controller.selectTag(argumentcollection = args)

				expect(r).toBe(options.single_column_query)
			})

			it("works with one column query for options", () => {
				q = QueryNew("")
				id = ["first", "second", "third"]
				QueryAddColumn(q, "id", id)
				args.name = "testselect"
				args.options = q
				r = _controller.selectTag(argumentcollection = args)

				expect(r).toBe(options.single_column_query)
			})

			it("works with query with no records for option values", () => {
				q = QueryNew("")
				id = []
				name = []
				QueryAddColumn(q, "id", id)
				QueryAddColumn(q, "name", name)
				args.name = "testselect"
				args.options = q
				r = _controller.selectTag(argumentcollection = args)

				expect(r).toBe(options.empty_query)
			})

			it("works with query with no records or columns for option values", () => {
				q = QueryNew("")
				args.name = "testselect"
				args.options = q
				r = _controller.selectTag(argumentcollection = args)

				expect(r).toBe(options.empty_query)
			})

			it("works with array for structs for option values", () => {
				args.name = "testselect"
				args.options = []
				temp = {value = "1", text = "first"}
				ArrayAppend(args.options, temp)
				temp = {value = "2", text = "second"}
				ArrayAppend(args.options, temp)
				temp = {value = "3", text = "third"}
				ArrayAppend(args.options, temp)
				r = _controller.selectTag(argumentcollection = args)

				expect(r).toBe(options.complexvalues)
			})
		})

		describe("Tests that startFormTag", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				args = {}
				args.host = ""
				args.method = "post"
				args.multipart = false
				args.onlypath = true
				args.port = 0
				args.protocol = ""
				args.controller = "testcontroller"
				g.set(functionName = "startFormTag", encode = false)
				request.$wheelsProtectedFromForgery = true
			})

			afterEach(() => {
				g.set(functionName = "startFormTag", encode = true)
				request.$wheelsProtectedFromForgery = false
			})

			it("works with no csrf when not enabled", () => {
				if (StructKeyExists(request, "$wheelsProtectedFromForgery")) {
					local.$wheelsProtectedFromForgery = request.$wheelsProtectedFromForgery
					StructDelete(request, "$wheelsProtectedFromForgery")
				}
				StructDelete(args, "controller")
				argsction = _controller.urlfor(argumentCollection = args)
				e = '<form action="#argsction#" method="post">'
				r = _controller.startFormTag(argumentcollection = args)

				expect(e).toBe(r)

				if (StructKeyExists(local, "$wheelsProtectedFromForgery")) {
					request.$wheelsProtectedFromForgery = local.$wheelsProtectedFromForgery
				}
			})

			it("should point to current page with no controller or action or route", () => {
				StructDelete(args, "controller")
				argsction = _controller.urlfor(argumentCollection = args)
				e = '<form action="#argsction#" method="post">' & _controller.authenticityTokenField()
				r = _controller.startFormTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works with controller", () => {
				argsction = _controller.urlfor(argumentCollection = args)
				e = '<form action="#argsction#" method="post">' & _controller.authenticityTokenField()
				r = _controller.startFormTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works with GET method", () => {
				args.method = "get"
				argsction = _controller.urlfor(argumentCollection = args)
				e = '<form action="#argsction#" method="get">'
				r = _controller.startFormTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works with PUT method", () => {
				args.method = "put"
				argsction = _controller.urlfor(argumentCollection = args)
				e = '<form action="#argsction#" method="put">' & _controller.authenticityTokenField()
				r = _controller.startFormTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works with PATCH method", () => {
				args.method = "patch"
				argsction = _controller.urlfor(argumentCollection = args)
				e = '<form action="#argsction#" method="patch">' & _controller.authenticityTokenField()
				r = _controller.startFormTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works with DELETE method", () => {
				args.method = "delete"
				argsction = _controller.urlfor(argumentCollection = args)
				e = '<form action="#argsction#" method="delete">' & _controller.authenticityTokenField()
				r = _controller.startFormTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works with multipart", () => {
				args.multipart = "true"
				argsction = _controller.urlfor(argumentCollection = args)
				e = _controller.startFormTag(argumentcollection = args)
				r = '<form action="#argsction#" enctype="multipart/form-data" method="post">' & _controller.authenticityTokenField()

				expect(e).toBe(r)
			})

			it("works with root route", () => {
				args.route = "root"
				argsction = _controller.urlfor(argumentCollection = args)
				e = _controller.startFormTag(argumentcollection = args)
				r = '<form action="#argsction#" method="post">' & _controller.authenticityTokenField()

				expect(e).toBe(r)
			})

			it("works with external link", () => {
				args.multipart = true
				argsction = _controller.urlfor(argumentCollection = args)
				e = _controller.startFormTag(argumentcollection = args)
				r = '<form action="#argsction#" enctype="multipart/form-data" method="post">' & _controller.authenticityTokenField()

				expect(e).toBe(r)
			})

			it("works with controller and action", () => {
				argsction = _controller.urlfor(argumentCollection = args, action = "test")
				e = _controller.startFormTag(argumentcollection = args, action = "test")
				r = '<form action="#argsction#" method="post">' & _controller.authenticityTokenField()

				expect(e).toBe(r)
			})
		})

		describe("Tests that submitTag", () => {

			beforeEach(() => {
				_controller = g.controller(name = "ControllerWithModel")
				g.set(functionName = "submitTag", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "submitTag", encode = true)
			})

			it("works with defaults", () => {
				actual = _controller.submitTag()
				expected = '<input type="submit" value="Save changes">'

				expect(actual).toBe(expected)
			})

			it("works with submittag arguments", () => {
				actual = _controller.submitTag(disable = "disable-value")
				expected = '<input disable="disable-value" type="submit" value="Save changes">'

				expect(actual).toBe(expected)
			})

			it("works with append prepend arguments", () => {
				actual = _controller.submitTag(append = "a", prepend = "p")
				expected = 'p<input type="submit" value="Save changes">a'

				expect(actual).toBe(expected)
			})
		})

		describe("Tests that textArea", () => {

			it("is valid", () => {
				_controller = g.controller(name = "ControllerWithModel")
				e = _controller.textArea(objectName = "user", property = "firstname")
				r = '<label for="user-firstname">Firstname<textarea id="user-firstname" maxlength="50" name="user&##x5b;firstname&##x5d;">Tony</textarea></label>'

				expect(e).toBe(r)
			})
		})

		describe("Tests that textAreaTag", () => {

			it("is encoding nothing", () => {
				result = g.controller(name = "dummy").textAreaTag(
					name = "x",
					class = "x x",
					content = "Per's Test",
					encode = false,
					label = "Per's Label"
				)
				expected = "<label for=""x"">Per's Label<textarea class=""x x"" id=""x"" name=""x"">Per's Test</textarea></label>"

				expect(result).toBe(expected)
			})

			it("is encoding everything", () => {
				result = g.controller(name = "dummy").textAreaTag(
					name = "x",
					class = "x x",
					content = "Per's Test",
					encode = true,
					label = "Per's Label"
				)
				expected = "<label for=""x"">Per&##x27;s Label<textarea class=""x&##x20;x"" id=""x"" name=""x"">Per&##x27;s Test</textarea></label>"

				expect(result).toBe(expected)
			})

			it("is encoding only attributes", () => {
				result = g.controller(name = "dummy").textAreaTag(
					name = "x",
					class = "x x",
					content = "Per's Test",
					encode = "attributes",
					label = "Per's Label"
				)
				expected = "<label for=""x"">Per's Label<textarea class=""x&##x20;x"" id=""x"" name=""x"">Per's Test</textarea></label>"

				expect(result).toBe(expected)
			})
		})

		describe("Tests that textField", () => {

			it("adds automatic label for id property", () => {
				_controller = g.controller(name = "Galleries")
				textField = _controller.textField(objectName = "gallery", property = "id", labelPlacement = "before")

				expect(textField).toInclude("<label for=""gallery-id"">ID</label>")
			})

			it("adds automatic label ending with id", () => {
				_controller = g.controller(name = "Galleries")
				textField = _controller.textField(objectName = "gallery", property = "userId", labelPlacement = "before")

				expect(textField).toInclude("<label for=""gallery-userId"">User</label>")
			})

			it("overrides value", () => {
				_controller = g.controller(name = "ControllerWithModel")
				textField = _controller.textField(
					label = "First Name",
					objectName = "user",
					property = "firstName",
					value = "override"
				)
				foundValue = YesNoFormat(FindNoCase('value="override"', textField))

				expect(foundValue).toBeTrue()
			})

			it("is valid with maxlength text field", () => {
				_controller = g.controller(name = "ControllerWithModel")
				textField = _controller.textField(label = "First Name", objectName = "user", property = "firstName")
				foundMaxLength = YesNoFormat(FindNoCase('maxlength="50"', textField))

				expect(foundMaxLength).toBeTrue()
			})
		})

		describe("Tests that textFieldTag", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("is valid", () => {
				e = _controller.textFieldTag(name = "someName")
				r = '<input id="someName" name="someName" type="text" value="">'

				expect(e).toBe(r)
			})

			it("works with custom textFieldTag type", () => {
				textField = _controller.textFieldTag(name = "search", label = "Search me", type = "search")
				foundCustomType = YesNoFormat(FindNoCase('type="search"', textField))

				expect(foundCustomType).toBeTrue()
			})

			it("works with data attribute underscore conversion", () => {
				result = _controller.textFieldTag(
					name = "num",
					type = "range",
					min = 5,
					max = 10,
					data_dom_cache = "cache",
					data_role = "button"
				)
				correct = '<input data-dom-cache="cache" data-role="button" id="num" max="10" min="5" name="num" type="range" value="">'

				expect(result).toBe(correct)
			})

			it("works with data attribute camelcase conversion when not in quotes", () => {
				result = _controller.textFieldTag(
					name = "num",
					type = "range",
					min = 5,
					max = 10,
					dataDomCache = "cache",
					dataRole = "button"
				)
				correct = '<input data-dom-cache="cache" data-role="button" id="num" max="10" min="5" name="num" type="range" value="">'

				expect(result).toBe(correct)
			})

			it("works with data attribute camelcase conversion", () => {
				args = {}
				args["dataDomCache"] = "cache"
				args["dataRole"] = "button"
				result = _controller.textFieldTag(name = "num", type = "range", min = 5, max = 10, argumentCollection = args)
				correct = '<input data-dom-cache="cache" data-role="button" id="num" max="10" min="5" name="num" type="range" value="">'

				expect(result).toBe(correct)
			})

			it("works with data attribute set to true", () => {
				args = {}
				args["data-dom-cache"] = "true"
				result = _controller.textFieldTag(name = "num", argumentCollection = args)
				correct = '<input data-dom-cache="true" id="num" name="num" type="text" value="">'

				expect(result).toBe(correct)
			})
		})

		describe("Tests that yearSelect", () => {

			beforeEach(() => {
				_controller = application.wirebox.getInstance("wheels.tests._assets.controllers.ControllerWithModel")
				args = {}
				args.objectName = "user"
				args.property = "birthday"
				args.includeblank = false
				args.order = "year"
				args.label = false
				_controller.changeBirthday = changeBirthday
				g.set(functionName = "dateSelect", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "dateSelect", encode = true)
			})

			it("works with startyear lt endyear value lt startyear", () => {
				args.startyear = "1980"
				args.endyear = "1990"
				e = _controller.dateSelect(argumentCollection = args)
				r = '<select id="user-birthday-year" name="user[birthday]($year)"><option selected="selected" value="1975">1975</option><option value="1976">1976</option><option value="1977">1977</option><option value="1978">1978</option><option value="1979">1979</option><option value="1980">1980</option><option value="1981">1981</option><option value="1982">1982</option><option value="1983">1983</option><option value="1984">1984</option><option value="1985">1985</option><option value="1986">1986</option><option value="1987">1987</option><option value="1988">1988</option><option value="1989">1989</option><option value="1990">1990</option></select>';

				expect(e).toBe(r)
			})

			it("works with startyear lt endyear value gt startyear", () => {
				_controller.changeBirthday(CreateDate(1995, 11, 1))
				args.startyear = "1980"
				args.endyear = "1990"
				r = _controller.dateSelect(argumentCollection = args)
				e = '<select id="user-birthday-year" name="user[birthday]($year)"><option value="1980">1980</option><option value="1981">1981</option><option value="1982">1982</option><option value="1983">1983</option><option value="1984">1984</option><option value="1985">1985</option><option value="1986">1986</option><option value="1987">1987</option><option value="1988">1988</option><option value="1989">1989</option><option value="1990">1990</option></select>'

				expect(e).toBe(r)
			})

			it("works with startyear gt endyear value lt endyear", () => {
				args.startyear = "1990"
				args.endyear = "1980"
				e = _controller.dateSelect(argumentCollection = args)
				r = '<select id="user-birthday-year" name="user[birthday]($year)"><option value="1990">1990</option><option value="1989">1989</option><option value="1988">1988</option><option value="1987">1987</option><option value="1986">1986</option><option value="1985">1985</option><option value="1984">1984</option><option value="1983">1983</option><option value="1982">1982</option><option value="1981">1981</option><option value="1980">1980</option><option value="1979">1979</option><option value="1978">1978</option><option value="1977">1977</option><option value="1976">1976</option><option selected="selected" value="1975">1975</option></select>'

				expect(e).toBe(r)
			})

			it("works with startyear gt endyear value gt endyear", () => {
				_controller.changeBirthday(CreateDate(1995, 11, 1))
				args.startyear = "1990"
				args.endyear = "1980"
				e = _controller.dateSelect(argumentCollection = args)
				r = '<select id="user-birthday-year" name="user[birthday]($year)"><option value="1990">1990</option><option value="1989">1989</option><option value="1988">1988</option><option value="1987">1987</option><option value="1986">1986</option><option value="1985">1985</option><option value="1984">1984</option><option value="1983">1983</option><option value="1982">1982</option><option value="1981">1981</option><option value="1980">1980</option></select>'

				expect(e).toBe(r)
			})
		})
	}

	function changeBirthday(required any value) {
		user.birthday = arguments.value;
	}
}
