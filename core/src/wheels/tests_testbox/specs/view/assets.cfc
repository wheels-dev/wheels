component extends="testbox.system.BaseSpec" {

	function beforeAll() {

		addMatchers({
			toFindProtocol: function(expectation, args={}) {
				if(FindNoCase("http://", expectation.actual) or FindNoCase("https://", expectation.actual)) {
					return true
				} else {
					return false
				}
			}
		})
	}

	function run() {

		g = application.wo

		describe("Tests that assetDomain", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				application.wheels.assetPaths = {http = "asset0.localhost, asset2.localhost", https = "secure.localhost"}
			})

			afterEach(() => {
				application.wheels.assetPaths = false
			})

			it("returns protocol", () => {
				assetPath = "/javascripts/path/to/my/asset.js"
				e = _controller.$assetDomain(assetPath)

				expect(e).toFindProtocol()
			})

			it("returns secure protocol", () => {
				request.cgi.server_port_secure = true
				assetPath = "/javascripts/path/to/my/asset.js"
				e = _controller.$assetDomain(assetPath)

				expect(FindNoCase("https://", e)).toBeTrue()

				request.cgi.server_port_secure = ""
			})

			it("returns same domain for asset", () => {
				assetPath = "/javascripts/path/to/my/asset.js"
				e = _controller.$assetDomain(assetPath)
				iEnd = 100

				for (i = 1; i lte iEnd; i++) {
					expect(e).toBe(_controller.$assetDomain(assetPath))
				}
			})

			it("returns asset path when set false", () => {
				application.wheels.assetPaths = false
				assetPath = "/javascripts/path/to/my/asset.js"
				e = _controller.$assetDomain(assetPath)

				expect(e).toBe(assetPath)

				application.wheels.assetPaths = {http = "asset0.localhost, asset2.localhost", https = "secure.localhost"}
			})
		})

		describe("Tests that assetQueryString", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				application.wheels.assetQueryString = true
			})

			afterEach(() => {
				application.wheels.assetQueryString = false
			})

			it("returns empty string when set false", () => {
				application.wheels.assetQueryString = false
				e = _controller.$appendQueryString()

				expect(e).toHaveLength(0)
			})

			it("returns string when set true", () => {
				e = _controller.$appendQueryString()

				expect(IsSimpleValue(e)).toBeTrue()
			})

			it("returns match when set to string", () => {
				application.wheels.assetQueryString = "MySpecificBuildNumber"
				e = _controller.$appendQueryString()

				expect(e).toBe("?MySpecificBuildNumber")
			})

			it("returns same value without reload", () => {
				iEnd = 100
				application.wheels.assetQueryString = "MySpecificBuildNumber"
				e = _controller.$appendQueryString()

				for (i = 1; i lte iEnd; i++) {
					expect(_controller.$appendQueryString()).toBe(e)
				}

				expect(e).toBe("?MySpecificBuildNumber")
			})
		})

		describe("Tests that imageTag", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				args = {}
				args.source = "/wheels/core_tests/_assets/files/cfwheels-logo.png"
				args.alt = "wheelstestlogo"
				args.class = "wheelstestlogoclass"
				args.id = "wheelstestlogoid"
				imagePath = application.wheels.webPath & application.wheels.imagePath

				g.set(functionName = "imageTag", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "imageTag", encode = true)
			})

			it("works with just source", () => {
				StructDelete(args, "alt")
				StructDelete(args, "class")
				StructDelete(args, "id")
				r = '<img alt="Cfwheels logo" height="121" src="#imagePath#/#args.source#" width="93">'
				e = _controller.imageTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works with supplying an alt", () => {
				StructDelete(args, "class")
				StructDelete(args, "id")
				r = '<img alt="#args.alt#" height="121" src="#imagePath#/#args.source#" width="93">'
				e = _controller.imageTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works with supplying an id when caching is on", () => {
				cacheImages = application.wheels.cacheImages
				application.wheels.cacheImages = true
				StructDelete(args, "alt")
				StructDelete(args, "class")
				r = '<img alt="Cfwheels logo" height="121" src="#imagePath#/#args.source#" id="#args.id#" width="93">'
				e = _controller.imageTag(argumentCollection = args)

				expect(e).toBe(r)

				application.wheels.cacheImages = cacheImages
			})

			it("works with supplying class and id", () => {
				r = '<img alt="#args.alt#" class="#args.class#" height="121" src="#imagePath#/#args.source#" id="#args.id#" width="93">'
				e = _controller.imageTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works with grabbing from http", () => {
				StructDelete(args, "alt")
				StructDelete(args, "class")
				StructDelete(args, "id")
				args.source = "http://www.cfwheels.org/images/cfwheels-logo.png"
				r = '<img alt="Cfwheels logo" src="#args.source#">'
				e = _controller.imageTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works with specifying height and width", () => {
				StructDelete(args, "alt")
				StructDelete(args, "class")
				StructDelete(args, "id")
				args.height = 25
				args.width = 25
				r = '<img alt="Cfwheels logo" height="25" src="#imagePath#/#args.source#" width="25">'
				e = _controller.imageTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works with specifying height only", () => {
				StructDelete(args, "alt")
				StructDelete(args, "class")
				StructDelete(args, "id")
				args.height = 25
				r = '<img alt="Cfwheels logo" height="25" src="#imagePath#/#args.source#" width="93">'
				e = _controller.imageTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works with specifying width only", () => {
				StructDelete(args, "alt")
				StructDelete(args, "class")
				StructDelete(args, "id")
				args.width = 25
				r = '<img alt="Cfwheels logo" height="121" src="#imagePath#/#args.source#" width="25">'
				e = _controller.imageTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("removes height and width attributes when set to false", () => {
				StructDelete(args, "alt")
				StructDelete(args, "class")
				StructDelete(args, "id")
				args.height = false
				args.width = false
				r = '<img alt="Cfwheels logo" src="#imagePath#/#args.source#">'
				e = _controller.imageTag(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("throws exception on missing image", () => {
				path = "missing.jpg"

				expect(function() {
					_controller.imageTag(source=path)
				}).toThrow("Wheels.ImageFileNotFound")
			})

			it("throws exception on unsupported image", () => {
				path = "/wheels/core_tests/_assets/files/cfwheels-logo.txt"

				expect(function() {
					_controller.imageTag(source=path)
				}).toThrow("Wheels.ImageFormatNotSupported")
			})

			it("accepts missing image", () => {
				path = "missing.jpg"
				actual = _controller.imageTag(source = path, required = false, alt = "This may be broken")
				expected = '<img alt="This may be broken" src="#imagePath#/#path#">'

				expect(actual).toBe(expected)
			})
		})

		describe("Tests that javascriptIncludeTag", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				args = {}
				g.set(functionName = "javaScriptIncludeTag", encode = false)
			})

			afterEach(() => {
				g.set(functionName = "javaScriptIncludeTag", encode = true)
			})

			it("should handle extensions, nonextensions and multiple extensions", () => {
				args.source = "test,test.js,jquery.dataTables.min,jquery.dataTables.min.js"
				e = _controller.javaScriptIncludeTag(argumentcollection = args)
				r = '<script src="#application.wheels.webpath#javascripts/test.js" type="text/javascript"></script>#Chr(10)#<script src="#application.wheels.webpath#javascripts/test.js" type="text/javascript"></script>#Chr(10)#<script src="#application.wheels.webpath#javascripts/jquery.dataTables.min.js" type="text/javascript"></script>#Chr(10)#<script src="#application.wheels.webpath#javascripts/jquery.dataTables.min.js" type="text/javascript"></script>#Chr(10)#'

				expect(e).toBe(r)
			})

			it("no automatic extension when cfm", () => {
				args.source = "test.cfm,test.js.cfm"
				e = _controller.javaScriptIncludeTag(argumentcollection = args)
				r = '<script src="#application.wheels.webpath#javascripts/test.cfm" type="text/javascript"></script>#Chr(10)#<script src="#application.wheels.webpath#javascripts/test.js.cfm" type="text/javascript"></script>#Chr(10)#'

				expect(e).toBe(r)
			})

			it("supports external links", () => {
				args.source = "http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js,test,https://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"
				e = _controller.javaScriptIncludeTag(argumentcollection = args)
				r = '<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js" type="text/javascript"></script>#Chr(10)#<script src="#application.wheels.webpath#javascripts/test.js" type="text/javascript"></script>#Chr(10)#<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js" type="text/javascript"></script>#Chr(10)#'

				expect(e).toBe(r)
			})

			it("allows specification of delimeter", () => {
				args.source = "test|test.js|http://fonts.googleapis.com/css?family=Istok+Web:400,700"
				args.delim = "|"
				e = _controller.javaScriptIncludeTag(argumentcollection = args)
				r = '<script src="#application.wheels.webpath#javascripts/test.js" type="text/javascript"></script>#Chr(10)#<script src="#application.wheels.webpath#javascripts/test.js" type="text/javascript"></script>#Chr(10)#<script src="http://fonts.googleapis.com/css?family=Istok+Web:400,700" type="text/javascript"></script>#Chr(10)#'

				expect(e).toBe(r)
			})

			it("is removing type argument", () => {
				args.source = "test.js"
				args.type = ""
				e = _controller.javaScriptIncludeTag(argumentcollection = args)
				r = '<script src="#application.wheels.webpath#javascripts/test.js"></script>#Chr(10)#'

				expect(e).toBe(r)
			})
		})

		describe("Tests that styleSheetLinkTag", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				args = {}
				webPath = Replace(application.wheels.webpath, "/", "&##x2f;", "all")
			})

			it("should handle extensions, nonextensions and multiple extensions", () => {
				args.source = "test,test.css,jquery.dataTables.min,jquery.dataTables.min.css"
				result = _controller.styleSheetLinkTag(argumentcollection = args)
				expected = '<link href="#webPath#stylesheets&##x2f;test.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="#webPath#stylesheets&##x2f;test.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="#webPath#stylesheets&##x2f;jquery.dataTables.min.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="#webPath#stylesheets&##x2f;jquery.dataTables.min.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#'

				expect(result).toBe(expected)
			})

			it("no automatic extension when cfm", () => {
				args.source = "http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/themes/start/jquery-ui.css,test.css,https://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/themes/start/jquery-ui.css"
				result = _controller.styleSheetLinkTag(argumentcollection = args)
				expected = '<link href="http&##x3a;&##x2f;&##x2f;ajax.googleapis.com&##x2f;ajax&##x2f;libs&##x2f;jqueryui&##x2f;1.7.2&##x2f;themes&##x2f;start&##x2f;jquery-ui.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="#webPath#stylesheets&##x2f;test.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="https&##x3a;&##x2f;&##x2f;ajax.googleapis.com&##x2f;ajax&##x2f;libs&##x2f;jqueryui&##x2f;1.7.2&##x2f;themes&##x2f;start&##x2f;jquery-ui.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#'

				expect(result).toBe(expected)
			})

			it("supports external links", () => {
				args.source = "http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/themes/start/jquery-ui.css,test.css,https://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/themes/start/jquery-ui.css"
				result = _controller.styleSheetLinkTag(argumentcollection = args)
				expected = '<link href="http&##x3a;&##x2f;&##x2f;ajax.googleapis.com&##x2f;ajax&##x2f;libs&##x2f;jqueryui&##x2f;1.7.2&##x2f;themes&##x2f;start&##x2f;jquery-ui.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="#webPath#stylesheets&##x2f;test.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="https&##x3a;&##x2f;&##x2f;ajax.googleapis.com&##x2f;ajax&##x2f;libs&##x2f;jqueryui&##x2f;1.7.2&##x2f;themes&##x2f;start&##x2f;jquery-ui.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#'

				expect(result).toBe(expected)
			})

			it("allows specification of delimeter", () => {
				args.source = "test|test.css|http://fonts.googleapis.com/css?family=Istok+Web:400,700"
				args.delim = "|"
				result = _controller.styleSheetLinkTag(argumentcollection = args)
				expected = '<link href="#webPath#stylesheets&##x2f;test.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="#webPath#stylesheets&##x2f;test.css" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#<link href="http&##x3a;&##x2f;&##x2f;fonts.googleapis.com&##x2f;css&##x3f;family&##x3d;Istok&##x2b;Web&##x3a;400,700" media="all" rel="stylesheet" type="text&##x2f;css">#Chr(10)#'

				expect(result).toBe(expected)
			})

			it("type media arguments", () => {
				args.source = "test.css"
				args.media = ""
				args.type = ""
				result = _controller.styleSheetLinkTag(argumentcollection = args)
				expected = '<link href="#webPath#stylesheets&##x2f;test.css" rel="stylesheet">#Chr(10)#'

				expect(result).toBe(expected)
			})

			it("no encoding", () => {
				args.source = "<test>.css"
				local.encodeHtmlAttributes = application.wheels.encodeHtmlAttributes
				application.wheels.encodeHtmlAttributes = false
				result = _controller.styleSheetLinkTag(argumentcollection = args)
				application.wheels.encodeHtmlAttributes = local.encodeHtmlAttributes
				expected = '<link href="#application.wheels.webPath#stylesheets/<test>.css" media="all" rel="stylesheet" type="text/css">#Chr(10)#'

				expect(result).toBe(expected)
			})
		})
	}
}
