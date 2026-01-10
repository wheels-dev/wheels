/**
 * UserNotificationsMailer - Handles email notifications
 */
component extends="wheels.Mailer" {

	/**
	 * Constructor - Configure default settings
	 */
	function config() {
	}

	/**
	 * Send Send Email email
	 * @to.hint Recipient email address
	 * @subject.hint Email subject line
	 * @data.hint Additional data to pass to the view
	 */
	function sendEmail(
		required string to,
		string subject = "Send Email",
		struct data = {}
	) {
		// Prepare email data
		local.emailData = duplicate(arguments.data);
		local.emailData.to = arguments.to;
		local.emailData.subject = arguments.subject;

		// Set email properties
		to(arguments.to);
		subject(arguments.subject);

		// Render email template
		template("/usernotificationsmailer/sendEmail");

		// Send the email
		return deliver();
	}

}