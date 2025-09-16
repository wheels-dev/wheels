# Email Sending

## Description
Send emails directly from controllers using Wheels' built-in email functionality with support for templates, attachments, and SMTP configuration.

## Key Points
- Use `sendEmail()` method in controllers to send emails
- Support for HTML and plain text email templates
- File attachments and embedded images
- SMTP server configuration in settings
- Template-based emails with dynamic content
- Batch email sending capabilities

## Code Sample
```cfm
// Basic email sending
component extends="Controller" {
    function create() {
        user = model("User").create(params.user);

        if (user.valid()) {
            // Send welcome email
            sendEmail(
                to=user.email,
                subject="Welcome to our application!",
                template="users/welcome",
                user=user
            );

            redirectTo(route="user", key=user.id, success="Account created!");
        } else {
            renderView(action="new");
        }
    }

    function sendNewsletter() {
        subscribers = model("Subscriber").findAll(where="active = 1");

        // Send to multiple recipients
        sendEmail(
            to=ValueList(subscribers.email),
            subject="Monthly Newsletter - #DateFormat(Now(), 'mmmm yyyy')#",
            template="newsletters/monthly",
            articles=getMonthlyArticles(),
            unsubscribeUrl=urlFor(controller="subscriptions", action="unsubscribe")
        );

        flashInsert(success="Newsletter sent to #subscribers.recordCount# subscribers");
        redirectTo(action="index");
    }

    function sendReport() {
        admin = model("User").findByKey(session.userId);
        reportData = generateMonthlyReport();

        // Email with attachment
        sendEmail(
            to=admin.email,
            subject="Monthly Report - #DateFormat(Now(), 'mmmm yyyy')#",
            template="reports/monthly",
            attachment=expandPath("./temp/monthly_report.pdf"),
            reportData=reportData
        );

        flashInsert(success="Report sent to your email address");
        redirectTo(action="dashboard");
    }

    function contactForm() {
        // Send email from contact form
        if (structKeyExists(params, "contact")) {
            sendEmail(
                to="support@example.com",
                from=params.contact.email,
                replyTo=params.contact.email,
                subject="Contact Form: #params.contact.subject#",
                template="contact/inquiry",
                contactData=params.contact
            );

            flashInsert(success="Your message has been sent!");
            redirectTo(action="new");
        }
    }

    // Advanced email with multiple attachments
    function sendInvoice() {
        invoice = model("Invoice").findByKey(params.key);
        customer = invoice.customer();

        local.attachments = [
            expandPath("./invoices/invoice_#invoice.id#.pdf"),
            expandPath("./terms/terms_of_service.pdf")
        ];

        sendEmail(
            to=customer.email,
            cc="accounting@example.com",
            bcc="archive@example.com",
            subject="Invoice ##invoice.number# - Due #DateFormat(invoice.dueDate, 'mm/dd/yyyy')#",
            template="invoices/customer",
            attachment=ArrayToList(local.attachments),
            invoice=invoice,
            customer=customer
        );

        invoice.update(emailSentAt=Now());
        flashInsert(success="Invoice emailed to #customer.email#");
        redirectTo(route="invoice", key=invoice.id);
    }
}

// Email template: /app/views/users/welcome.cfm
<cfparam name="user">
<cfoutput>
<h2>Welcome to Our Application, #user.firstName#!</h2>

<p>Thank you for joining our community. Your account has been successfully created.</p>

<p><strong>Account Details:</strong></p>
<ul>
    <li>Email: #user.email#</li>
    <li>Member since: #DateFormat(user.createdAt, "mmmm d, yyyy")#</li>
</ul>

<p>
    <a href="#urlFor(controller='sessions', action='new', onlyPath=false)#"
       style="background: ##007cba; color: white; padding: 10px 20px; text-decoration: none;">
        Login to Your Account
    </a>
</p>

<p>If you have any questions, please contact us at support@example.com</p>

<p>Best regards,<br>
The Team</p>
</cfoutput>

// Plain text version: /app/views/users/welcome.txt
<cfparam name="user">
<cfoutput>
Welcome to Our Application, #user.firstName#!

Thank you for joining our community. Your account has been successfully created.

Account Details:
- Email: #user.email#
- Member since: #DateFormat(user.createdAt, "mmmm d, yyyy")#

Login to your account: #urlFor(controller='sessions', action='new', onlyPath=false)#

If you have any questions, please contact us at support@example.com

Best regards,
The Team
</cfoutput>

// Email settings in /config/settings.cfm
<cfscript>
    // SMTP Configuration
    set(mailServer="smtp.gmail.com");
    set(mailPort=587);
    set(mailUsername="your-email@gmail.com");
    set(mailPassword="your-app-password");
    set(mailUseTLS=true);
    set(mailUseSSL=false);

    // Default email settings
    set(sendEmailOnError=true);
    set(errorEmailAddress="admin@example.com");
    set(sendEmailFromAddress="noreply@example.com");
    set(sendEmailSubjectPrefix="[MyApp] ");
</cfscript>
```

## Usage
1. Configure SMTP settings in `/config/settings.cfm`
2. Create email templates in `/app/views/[controller]/[template].cfm`
3. Call `sendEmail()` with required parameters in controller actions
4. Use dynamic content by passing variables to templates
5. Handle email sending errors appropriately

## Parameters
- `to` (required) - Recipient email address(es), comma-separated
- `subject` (required) - Email subject line
- `template` (required) - Template path (controller/action format)
- `from` - Sender email address (uses default if not specified)
- `cc` - Carbon copy recipients
- `bcc` - Blind carbon copy recipients
- `replyTo` - Reply-to email address
- `attachment` - File path(s) for attachments, comma-separated
- Additional variables passed to template

## Related
- [Mailer Components](../patterns/mailer-components.md)
- [View Templates](../views/layouts/structure.md)
- [Configuration](../configuration/environments.md)

## Important Notes
- Templates support both HTML (.cfm) and plain text (.txt) versions
- SMTP credentials should be stored securely (use environment variables)
- Large attachments may cause timeout issues
- Test email delivery in development with mail catcher tools
- Use queuing systems for bulk email sending
- Always validate email addresses before sending

## Error Handling
```cfm
try {
    sendEmail(
        to=user.email,
        subject="Important Notification",
        template="notifications/important",
        user=user
    );

    flashInsert(success="Email sent successfully");
} catch (any e) {
    // Log error and show user-friendly message
    WriteLog(file="email", text="Failed to send email to #user.email#: #e.message#");
    flashInsert(error="Unable to send email. Please try again later.");
}
```

## Testing
```cfm
// Disable email sending in test environment
if (get("environment") == "testing") {
    set(sendEmailOnError=false);
    set(mailServer=""); // Prevents actual email sending
}

// Use mail catcher in development
if (get("environment") == "development") {
    set(mailServer="localhost");
    set(mailPort=1025);
    set(mailUseTLS=false);
}
```

## Security Best Practices
- Validate all email addresses before sending
- Sanitize user input in email content
- Use authentication for SMTP servers
- Implement rate limiting for email sending
- Never expose SMTP credentials in code
- Use secure connections (TLS/SSL) for SMTP