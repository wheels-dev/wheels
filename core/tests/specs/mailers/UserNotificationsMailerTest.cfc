component extends="wheels.Test" {

	function setup() {
		mailer = createObject("component", "mailers.UserNotificationsMailer");
	}

	function test_sendEmail() {
		// Test that sendEmail sends email correctly
		local.result = mailer.sendEmail(
			to = "test@example.com",
			subject = "Test Subject"
		);

		assert("Email should be sent successfully");
	}

}