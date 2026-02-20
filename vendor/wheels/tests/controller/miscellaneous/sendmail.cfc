component extends="wheels.tests.Test" {

	function setup() {
		params = {controller = "test", action = "test"};
		_controller = controller("dummy", params);
		args = StructNew();
		args.subject = "dummy subject";
		args.to = "to-dummy@dummy.com";
		args.from = "from-dummy@dummy.com";
		args.deliver = false;
		oldViewPath = application.wheels.viewPath;
		application.wheels.viewPath = "/wheels/tests/_assets/views";
		oldFilePath = application.wheels.filePath;
		application.wheels.filePath = "/wheels/tests/_assets/files";
		oldArgs = application.wheels.functions.sendEmail;
		textBody = "dummy plain email body";
		HTMLBody = "<p>dummy html email body</p>";
		filePath = ExpandPath(application.wheels.filePath) & "/" & "emailcontent.txt";
	}

	function test_allow_default_for_from_to_and_subject() {
		application.wheels.functions.sendEmail.from = "sender@example.com";
		application.wheels.functions.sendEmail.to = "recipient@example.com";
		application.wheels.functions.sendEmail.subject = "test email";
		r = default_args(template = "");
		assert('r.from eq "sender@example.com"');
		assert('r.to eq "recipient@example.com"');
		assert('r.subject eq "test email"');
		r = default_args(
			template = "",
			from = "custom_sender@example.com",
			to = "custom_recipient@example.com",
			subject = "custom suject"
		);
		assert('r.from eq "custom_sender@example.com"');
		assert('r.to eq "custom_recipient@example.com"');
		assert('r.subject eq "custom suject"');
	}

	function test_sendemail_plain() {
		args.template = "plainEmailTemplate";
		result = _controller.sendEmail(argumentCollection = args);
		assert("ListLen(StructKeyList(result)) IS 6");
		assert("StructKeyExists(result, 'to')");
		assert("StructKeyExists(result, 'from')");
		assert("StructKeyExists(result, 'subject')");
		assert("result.type IS 'text'");
		assert("result.text IS textBody");
		assert("result.html IS ''");
	}

	function test_sendemail_html() {
		args.template = "HTMLEmailTemplate";
		result = _controller.sendEmail(argumentCollection = args);
		assert("result.type IS 'html'");
		assert("result.text IS ''");
		assert("result.html IS HTMLBody");
	}

	function test_sendemail_detectmultipart_with_html() {
		args.template = "HTMLEmailTemplate";
		args.detectMultipart = true;
		result = _controller.sendEmail(argumentCollection = args);
		assert("result.type IS 'html'");
	}

	function test_sendemail_detectmultipart_with_plain() {
		args.template = "plainEmailTemplate";
		args.detectMultipart = true;
		result = _controller.sendEmail(argumentCollection = args);
		assert("result.type IS 'text'");
	}

	function test_sendemail_type_argument_without_detectmultipart() {
		args.template = "plainEmailTemplate";
		args.type = "html";
		result = _controller.sendEmail(argumentCollection = args);
		assert("result.type IS 'html'");
	}

	function test_sendemail_combined_in_correct_order() {
		args.templates = "HTMLEmailTemplate,plainEmailTemplate";
		result = _controller.sendEmail(argumentCollection = args);
		assert("result.mailparts[1].type IS 'text' AND result.mailparts[2].tagContent IS HTMLBody");
	}

	function test_sendemail_with_layout() {
		args.template = "HTMLEmailTemplate";
		args.layout = "emailLayout";
		result = _controller.sendEmail(argumentCollection = args);
		assert("result.html Contains '<div>'");
	}

	function test_sendemail_with_attachment() {
		args.template = "plainEmailTemplate";
		args.file = "cfwheels-logo.png";
		result = _controller.sendEmail(argumentCollection = args);
		assert("result.mailparams[1].file Contains '_assets' AND result.mailparams[1].file Contains 'cfwheels-logo.png'");
	}

	function test_sendemail_with_attachments_external() {
		args.template = "plainEmailTemplate";
		args.file = "cfwheels-logo.png,http://www.example.com/test.txt,c:\inetpub\wwwroot\cfwheels\something.pdf";
		result = _controller.sendEmail(argumentCollection = args);
		assert("result.mailparams[1].file Contains '_assets' AND result.mailparams[1].file Contains 'cfwheels-logo.png'");
		assert("result.mailparams[2].file eq 'http://www.example.com/test.txt'");
		assert("result.mailparams[3].file eq 'c:\inetpub\wwwroot\cfwheels\something.pdf'");
	}

	function test_sendemail_with_custom_argument() {
		args.template = "plainEmailTemplate";
		args.customArgument = "IPassedInThisAsACustomArgument";
		result = _controller.sendEmail(argumentCollection = args);
		assert("result.text Contains 'IPassedInThisAsACustomArgument'");
	}

	function test_sendemail_from_different_path() {
		args.template = "/shared/anotherPlainEmailTemplate";
		result = _controller.sendEmail(argumentCollection = args);
		assert("result.text IS 'another dummy plain email body'");
	}

	function test_sendemail_from_sub_folder() {
		args.template = "sub/anotherHTMLEmailTemplate";
		result = _controller.sendEmail(argumentCollection = args);
		assert("result.html IS '<p>another dummy html email body</p>'");
	}

	function test_sendemail_with_writetofile() {
		args.templates = "HTMLEmailTemplate,plainEmailTemplate";
		args.writeToFile = filePath;
		if (FileExists(filePath)) {
			FileDelete(filePath);
		}
		_controller.sendEmail(argumentCollection = args);
		fileContent = FileRead(filePath);
		FileDelete(filePath);
		assert("fileContent contains HTMLBody");
		assert("fileContent contains textBody");
	}

	function teardown() {
		application.wheels.viewPath = oldViewPath;
		application.wheels.filePath = oldFilePath;
		application.wheels.functions.sendEmail = oldArgs;
	}

	/**
	 * HELPERS
	 */

	function default_args() {
		$args(args = arguments, name = "sendEmail", required = "template,from,to,subject");
		return arguments;
	}

}
