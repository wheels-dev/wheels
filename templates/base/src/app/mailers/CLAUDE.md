# CLAUDE.md - Mailers (Email Components)

This file provides guidance to Claude Code (claude.ai/code) when working with Wheels mailer components.

## Overview

The `/app/mailers/` folder contains mailer components that organize and standardize email sending functionality in your Wheels application. Mailers extend `wheels.Mailer` and provide a clean, object-oriented approach to sending emails, separating email logic from controllers and models.

**Why Use Mailers:**
- Organize email functionality in dedicated components
- Reuse email logic across controllers and models
- Maintain clean separation between email logic and business logic
- Provide a consistent interface for sending different types of emails
- Enable easier testing of email functionality
- Support complex email workflows and templates

**Note:** Mailers work alongside Wheels' `sendEmail()` function but provide a more structured approach for applications with complex email requirements.

## Mailer Architecture

### Base Mailer Class
All mailers extend `wheels.Mailer`, which provides:
- Configuration methods for default settings
- Template rendering functionality
- Email composition and delivery methods
- Support for layouts and multipart emails
- Integration with Wheels view system

### Core Mailer Methods

#### Configuration
- **`config()`** - Configure default mailer settings (required method)
- **`defaultFrom`** - Set default from address
- **`defaultLayout`** - Set default layout template

#### Email Composition
- **`to(string email)`** - Set recipient email address
- **`from(string email)`** - Set sender email address
- **`subject(string text)`** - Set email subject line
- **`template(string path)`** - Set email template path
- **`layout(string name)`** - Set email layout

#### Delivery
- **`deliver()`** - Send the composed email
- **`deliverLater()`** - Queue email for background delivery (if queue system available)

## Mailer Generation

### CLI Generator
Use the Wheels CLI to generate mailer classes:

```bash
# Basic mailer
wheels g mailer Welcome

# Mailer with specific methods
wheels g mailer UserNotifications --methods="accountCreated,passwordReset,orderConfirmation"

# Mailer with configuration
wheels g mailer OrderMailer --from="orders@example.com" --layout="email"

# Mailer without view templates
wheels g mailer SystemMailer --createViews=false
```

### Generator Options
- **`name`** - Mailer name (automatically suffixed with "Mailer")
- **`methods`** - Comma-separated list of email methods to generate
- **`from`** - Default from email address
- **`layout`** - Default layout template
- **`createViews`** - Create view templates for each method (default: true)
- **`force`** - Overwrite existing files

## Basic Mailer Structure

### Mailer Template
```cfm
/**
 * UserNotificationsMailer - Handles user notification emails
 */
component extends="wheels.Mailer" {

    /**
     * Constructor - Configure default settings
     */
    function config() {
        // Set default from address
        defaultFrom = "noreply@yourapp.com";
        
        // Set default layout
        defaultLayout = "email";
        
        // Additional configuration
        defaultReplyTo = "support@yourapp.com";
    }

    /**
     * Send welcome email to new users
     * @to.hint Recipient email address
     * @user.hint User object
     * @data.hint Additional template data
     */
    function welcomeEmail(
        required string to,
        required any user,
        struct data = {}
    ) {
        // Prepare email data for the template
        local.emailData = {
            user = arguments.user,
            appName = get("appName"),
            supportUrl = "https://yourapp.com/support"
        };
        structAppend(local.emailData, arguments.data);

        // Configure email
        to(arguments.to);
        subject("Welcome to #get('appName')#!");
        from(defaultFrom);
        template("/usernotificationsmailer/welcomeEmail");

        // Pass data to template
        for (local.key in local.emailData) {
            variables[local.key] = local.emailData[local.key];
        }

        // Send the email
        return deliver();
    }
}
```

### Associated View Template
```cfm
<!--- /app/views/usernotificationsmailer/welcomeEmail.cfm --->
<cfoutput>
<h2>Welcome to #appName#!</h2>

<p>Hello #user.name#,</p>

<p>
    Thank you for joining #appName#! We're excited to have you as a member of our community.
</p>

<p>
    Your account has been successfully created with the email address: <strong>#user.email#</strong>
</p>

<h3>Get Started</h3>
<ul>
    <li><a href="#buildUrl('users.profile')#">Complete your profile</a></li>
    <li><a href="#buildUrl('dashboard.index')#">Explore your dashboard</a></li>
    <li><a href="#supportUrl#">Get help from our support team</a></li>
</ul>

<p>
    If you have any questions, please don't hesitate to contact us at 
    <a href="mailto:support@yourapp.com">support@yourapp.com</a>.
</p>

<p>Welcome aboard!</p>
</cfoutput>
```

## Advanced Mailer Patterns

### 1. User Management Mailer
```cfm
/**
 * UserMailer - Handles all user-related email notifications
 */
component extends="wheels.Mailer" {

    function config() {
        defaultFrom = "accounts@yourapp.com";
        defaultLayout = "user_email";
    }

    /**
     * Send account activation email
     */
    function accountActivation(required any user, required string activationToken) {
        local.activationUrl = buildUrl(
            controller = "accounts",
            action = "activate",
            params = {token: arguments.activationToken},
            host = get("baseUrl")
        );

        to(arguments.user.email);
        subject("Activate Your Account");
        template("/usermailer/accountActivation");

        // Pass data to template
        variables.user = arguments.user;
        variables.activationUrl = local.activationUrl;
        variables.expirationHours = 24;

        return deliver();
    }

    /**
     * Send password reset email
     */
    function passwordReset(required any user, required string resetToken) {
        local.resetUrl = buildUrl(
            controller = "passwords",
            action = "reset",
            params = {token: arguments.resetToken},
            host = get("baseUrl")
        );

        to(arguments.user.email);
        subject("Reset Your Password");
        template("/usermailer/passwordReset");

        variables.user = arguments.user;
        variables.resetUrl = local.resetUrl;
        variables.expirationMinutes = 60;

        return deliver();
    }

    /**
     * Send account deletion confirmation
     */
    function accountDeleted(required any user, struct options = {}) {
        to(arguments.user.email);
        subject("Your Account Has Been Deleted");
        template("/usermailer/accountDeleted");

        variables.user = arguments.user;
        variables.deletedAt = now();
        variables.dataRetentionDays = arguments.options.retentionDays ?: 30;
        variables.supportEmail = "support@yourapp.com";

        return deliver();
    }

    /**
     * Send security alert email
     */
    function securityAlert(
        required any user,
        required string alertType,
        struct alertData = {}
    ) {
        local.subjects = {
            "login_new_location": "New Login from Unknown Location",
            "password_changed": "Your Password Was Changed",
            "email_changed": "Your Email Address Was Changed",
            "two_factor_enabled": "Two-Factor Authentication Enabled",
            "suspicious_activity": "Suspicious Activity Detected"
        };

        to(arguments.user.email);
        subject(local.subjects[arguments.alertType] ?: "Security Alert");
        template("/usermailer/securityAlert");

        variables.user = arguments.user;
        variables.alertType = arguments.alertType;
        variables.alertData = arguments.alertData;
        variables.alertTime = now();
        variables.securityUrl = buildUrl("account.security", host=get("baseUrl"));

        return deliver();
    }
}
```

### 2. Order Management Mailer
```cfm
/**
 * OrderMailer - Handles order-related email notifications
 */
component extends="wheels.Mailer" {

    function config() {
        defaultFrom = "orders@yourstore.com";
        defaultLayout = "order_email";
    }

    /**
     * Send order confirmation email
     */
    function orderConfirmation(required any order) {
        to(arguments.order.customerEmail);
        subject("Order Confirmation - ##" & arguments.order.orderNumber);
        template("/ordermailer/orderConfirmation");

        variables.order = arguments.order;
        variables.customer = arguments.order.customer;
        variables.orderItems = arguments.order.orderItems;
        variables.trackingUrl = buildUrl(
            controller = "orders",
            action = "track", 
            params = {number: arguments.order.orderNumber},
            host = get("baseUrl")
        );

        return deliver();
    }

    /**
     * Send shipping notification
     */
    function orderShipped(required any order, required string trackingNumber) {
        to(arguments.order.customerEmail);
        subject("Your Order Has Shipped - ##" & arguments.order.orderNumber);
        template("/ordermailer/orderShipped");

        variables.order = arguments.order;
        variables.customer = arguments.order.customer;
        variables.trackingNumber = arguments.trackingNumber;
        variables.estimatedDelivery = dateAdd("d", 3, now()); // Estimate 3 days
        variables.carrierTrackingUrl = buildCarrierTrackingUrl(arguments.trackingNumber);

        return deliver();
    }

    /**
     * Send order delivery notification
     */
    function orderDelivered(required any order) {
        to(arguments.order.customerEmail);
        subject("Order Delivered - ##" & arguments.order.orderNumber);
        template("/ordermailer/orderDelivered");

        variables.order = arguments.order;
        variables.customer = arguments.order.customer;
        variables.reviewUrl = buildUrl(
            controller = "reviews",
            action = "create",
            params = {orderId: arguments.order.id},
            host = get("baseUrl")
        );
        variables.supportUrl = buildUrl("support.contact", host=get("baseUrl"));

        return deliver();
    }

    /**
     * Send refund processed email
     */
    function refundProcessed(required any order, required numeric refundAmount) {
        to(arguments.order.customerEmail);
        subject("Refund Processed - ##" & arguments.order.orderNumber);
        template("/ordermailer/refundProcessed");

        variables.order = arguments.order;
        variables.customer = arguments.order.customer;
        variables.refundAmount = arguments.refundAmount;
        variables.processingDate = now();
        variables.businessDays = 3; // Typical refund processing time

        return deliver();
    }

    // Helper method for tracking URLs
    private string function buildCarrierTrackingUrl(required string trackingNumber) {
        // This would vary by shipping carrier
        return "https://www.fedex.com/apps/fedextrack/?tracknumbers=#arguments.trackingNumber#";
    }
}
```

### 3. Newsletter Mailer
```cfm
/**
 * NewsletterMailer - Handles newsletter and promotional emails
 */
component extends="wheels.Mailer" {

    function config() {
        defaultFrom = "newsletter@yourcompany.com";
        defaultLayout = "newsletter";
    }

    /**
     * Send weekly newsletter
     */
    function weeklyNewsletter(
        required any subscriber,
        required array articles,
        struct data = {}
    ) {
        local.weekOf = dateFormat(now(), "mmmm d, yyyy");

        to(arguments.subscriber.email);
        subject("Weekly Newsletter - Week of #local.weekOf#");
        template("/newslettermailer/weeklyNewsletter");

        variables.subscriber = arguments.subscriber;
        variables.articles = arguments.articles;
        variables.weekOf = local.weekOf;
        variables.unsubscribeUrl = buildUnsubscribeUrl(arguments.subscriber);
        variables.webVersionUrl = buildWebVersionUrl(arguments.subscriber, "weekly");

        // Add any additional data
        for (local.key in arguments.data) {
            variables[local.key] = arguments.data[local.key];
        }

        return deliver();
    }

    /**
     * Send product announcement
     */
    function productAnnouncement(
        required any subscriber,
        required any product,
        struct options = {}
    ) {
        to(arguments.subscriber.email);
        subject("Introducing #arguments.product.name#!");
        template("/newslettermailer/productAnnouncement");

        variables.subscriber = arguments.subscriber;
        variables.product = arguments.product;
        variables.productUrl = buildUrl(
            controller = "products",
            action = "show",
            key = arguments.product.id,
            host = get("baseUrl")
        );
        variables.launchDate = arguments.product.launchDate;
        variables.specialOffer = arguments.options.specialOffer ?: false;
        variables.unsubscribeUrl = buildUnsubscribeUrl(arguments.subscriber);

        return deliver();
    }

    /**
     * Send personalized recommendations
     */
    function personalizedRecommendations(
        required any subscriber,
        required array recommendations,
        struct data = {}
    ) {
        to(arguments.subscriber.email);
        subject("Personalized Recommendations Just for You");
        template("/newslettermailer/personalizedRecommendations");

        variables.subscriber = arguments.subscriber;
        variables.recommendations = arguments.recommendations;
        variables.baseUrl = get("baseUrl");
        variables.unsubscribeUrl = buildUnsubscribeUrl(arguments.subscriber);
        
        // Calculate recommendation categories
        variables.categories = getRecommendationCategories(arguments.recommendations);

        return deliver();
    }

    // Helper methods
    private string function buildUnsubscribeUrl(required any subscriber) {
        return buildUrl(
            controller = "subscriptions",
            action = "unsubscribe",
            params = {token: arguments.subscriber.unsubscribeToken},
            host = get("baseUrl")
        );
    }

    private string function buildWebVersionUrl(required any subscriber, required string type) {
        return buildUrl(
            controller = "newsletter",
            action = "view",
            params = {
                token: arguments.subscriber.viewToken,
                type: arguments.type,
                date: dateFormat(now(), "yyyy-mm-dd")
            },
            host = get("baseUrl")
        );
    }

    private array function getRecommendationCategories(required array recommendations) {
        local.categories = [];
        local.seen = {};

        for (local.item in arguments.recommendations) {
            if (!structKeyExists(local.seen, local.item.category)) {
                arrayAppend(local.categories, local.item.category);
                local.seen[local.item.category] = true;
            }
        }

        return local.categories;
    }
}
```

### 4. System Notification Mailer
```cfm
/**
 * SystemMailer - Handles system and administrative emails
 */
component extends="wheels.Mailer" {

    function config() {
        defaultFrom = "system@yourapp.com";
        defaultLayout = "system_email";
    }

    /**
     * Send error notification to administrators
     */
    function errorNotification(
        required string errorMessage,
        required string errorDetail,
        struct context = {}
    ) {
        local.adminEmails = get("adminNotificationEmails");

        to(local.adminEmails);
        subject("Application Error Alert - #get('environment')#");
        template("/systemmailer/errorNotification");

        variables.errorMessage = arguments.errorMessage;
        variables.errorDetail = arguments.errorDetail;
        variables.context = arguments.context;
        variables.environment = get("environment");
        variables.serverName = cgi.server_name;
        variables.timestamp = now();
        variables.requestUrl = cgi.script_name & cgi.path_info;
        variables.userAgent = cgi.http_user_agent;

        return deliver();
    }

    /**
     * Send maintenance notification
     */
    function maintenanceNotification(
        required array recipients,
        required date maintenanceStart,
        required date maintenanceEnd,
        string description = "Scheduled maintenance"
    ) {
        for (local.email in arguments.recipients) {
            to(local.email);
            subject("Scheduled Maintenance Notice - #dateFormat(arguments.maintenanceStart, 'mm/dd/yyyy')#");
            template("/systemmailer/maintenanceNotification");

            variables.maintenanceStart = arguments.maintenanceStart;
            variables.maintenanceEnd = arguments.maintenanceEnd;
            variables.description = arguments.description;
            variables.duration = dateDiff("n", arguments.maintenanceStart, arguments.maintenanceEnd);
            variables.statusUrl = buildUrl("system.status", host=get("baseUrl"));

            deliver();
        }
    }

    /**
     * Send backup completion notification
     */
    function backupCompleted(
        required string backupType,
        required numeric fileSize,
        boolean success = true,
        string errorMessage = ""
    ) {
        local.adminEmails = get("backupNotificationEmails");

        to(local.adminEmails);
        subject("Backup #arguments.success ? 'Completed' : 'Failed'# - #arguments.backupType#");
        template("/systemmailer/backupCompleted");

        variables.backupType = arguments.backupType;
        variables.fileSize = arguments.fileSize;
        variables.success = arguments.success;
        variables.errorMessage = arguments.errorMessage;
        variables.completedAt = now();
        variables.environment = get("environment");
        variables.formattedSize = formatFileSize(arguments.fileSize);

        return deliver();
    }

    /**
     * Send security breach notification
     */
    function securityBreachAlert(
        required string breachType,
        required string description,
        struct affectedData = {},
        numeric affectedUsers = 0
    ) {
        local.securityEmails = get("securityNotificationEmails");

        to(local.securityEmails);
        subject("SECURITY ALERT: #arguments.breachType# - Immediate Attention Required");
        template("/systemmailer/securityBreachAlert");

        variables.breachType = arguments.breachType;
        variables.description = arguments.description;
        variables.affectedData = arguments.affectedData;
        variables.affectedUsers = arguments.affectedUsers;
        variables.detectedAt = now();
        variables.severity = determineSeverity(arguments.breachType, arguments.affectedUsers);
        variables.incidentId = generateIncidentId();

        return deliver();
    }

    // Helper methods
    private string function formatFileSize(required numeric bytes) {
        if (arguments.bytes < 1024) return "#arguments.bytes# B";
        if (arguments.bytes < 1048576) return "#numberFormat(arguments.bytes/1024, '9.9')# KB";
        if (arguments.bytes < 1073741824) return "#numberFormat(arguments.bytes/1048576, '9.9')# MB";
        return "#numberFormat(arguments.bytes/1073741824, '9.9')# GB";
    }

    private string function determineSeverity(required string breachType, required numeric affectedUsers) {
        switch (arguments.breachType) {
            case "data_leak":
                return arguments.affectedUsers > 100 ? "CRITICAL" : "HIGH";
            case "unauthorized_access":
                return "HIGH";
            case "ddos_attack":
                return "MEDIUM";
            default:
                return "HIGH";
        }
    }

    private string function generateIncidentId() {
        return "INC-" & dateFormat(now(), "yyyymmdd") & "-" & timeFormat(now(), "hhmmss") & "-" & randRange(1000, 9999);
    }
}
```

## Email Templates and Layouts

### Email Layout Example
```cfm
<!--- /app/views/layouts/email.cfm --->
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><cfoutput>#variables.subject ?: 'Email from ' & get('appName')#</cfoutput></title>
    <style>
        /* Email-safe CSS */
        body {
            font-family: Arial, sans-serif;
            font-size: 14px;
            line-height: 1.6;
            color: #333333;
            margin: 0;
            padding: 0;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border: 1px solid #dddddd;
        }
        .header {
            background-color: #007cba;
            color: #ffffff;
            padding: 20px;
            text-align: center;
        }
        .content {
            padding: 30px;
        }
        .footer {
            background-color: #f8f8f8;
            color: #666666;
            padding: 20px;
            font-size: 12px;
            text-align: center;
            border-top: 1px solid #eeeeee;
        }
        .button {
            display: inline-block;
            padding: 12px 24px;
            background-color: #007cba;
            color: #ffffff;
            text-decoration: none;
            border-radius: 4px;
            margin: 10px 0;
        }
        .button:hover {
            background-color: #005a87;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <cfoutput>
                <h1>#get('appName')#</h1>
            </cfoutput>
        </div>
        
        <div class="content">
            <cfoutput>#includeContent()#</cfoutput>
        </div>
        
        <div class="footer">
            <cfoutput>
                <p>&copy; #year(now())# #get('companyName')#. All rights reserved.</p>
                <p>
                    #get('companyAddress')#<br>
                    <a href="mailto:#get('supportEmail')#">#get('supportEmail')#</a>
                </p>
                <cfif structKeyExists(variables, "unsubscribeUrl")>
                    <p><a href="#variables.unsubscribeUrl#">Unsubscribe from these emails</a></p>
                </cfif>
            </cfoutput>
        </div>
    </div>
</body>
</html>
```

### Complex Email Template Example
```cfm
<!--- /app/views/ordermailer/orderConfirmation.cfm --->
<cfoutput>
<h2>Thank You for Your Order!</h2>

<p>Hi #customer.firstName#,</p>

<p>
    We've received your order and are getting it ready for shipment. 
    Here are the details of your order:
</p>

<div style="border: 1px solid #ddd; padding: 15px; margin: 20px 0; background-color: #f9f9f9;">
    <h3>Order Details</h3>
    <p><strong>Order Number:</strong> ##order.orderNumber#</p>
    <p><strong>Order Date:</strong> #dateFormat(order.createdAt, "mmmm d, yyyy")#</p>
    <p><strong>Total:</strong> #dollarFormat(order.total)#</p>
</div>

<h3>Items Ordered</h3>
<table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
    <thead>
        <tr style="background-color: #f0f0f0;">
            <th style="border: 1px solid #ddd; padding: 10px; text-align: left;">Item</th>
            <th style="border: 1px solid #ddd; padding: 10px; text-align: center;">Quantity</th>
            <th style="border: 1px solid #ddd; padding: 10px; text-align: right;">Price</th>
        </tr>
    </thead>
    <tbody>
        <cfloop array="#orderItems#" index="item">
            <tr>
                <td style="border: 1px solid #ddd; padding: 10px;">
                    <strong>#item.productName#</strong><br>
                    <small style="color: #666;">#item.productDescription#</small>
                </td>
                <td style="border: 1px solid #ddd; padding: 10px; text-align: center;">
                    #item.quantity#
                </td>
                <td style="border: 1px solid #ddd; padding: 10px; text-align: right;">
                    #dollarFormat(item.price * item.quantity)#
                </td>
            </tr>
        </cfloop>
    </tbody>
    <tfoot>
        <tr style="background-color: #f0f0f0; font-weight: bold;">
            <td colspan="2" style="border: 1px solid #ddd; padding: 10px; text-align: right;">
                Total:
            </td>
            <td style="border: 1px solid #ddd; padding: 10px; text-align: right;">
                #dollarFormat(order.total)#
            </td>
        </tr>
    </tfoot>
</table>

<h3>Shipping Information</h3>
<div style="border-left: 4px solid #007cba; padding-left: 15px; margin: 20px 0;">
    <p>
        #order.shippingAddress.name#<br>
        #order.shippingAddress.street#<br>
        <cfif len(order.shippingAddress.street2)>
            #order.shippingAddress.street2#<br>
        </cfif>
        #order.shippingAddress.city#, #order.shippingAddress.state# #order.shippingAddress.zipCode#<br>
        #order.shippingAddress.country#
    </p>
</div>

<p>
    <strong>Estimated Delivery:</strong> 
    #dateFormat(dateAdd("d", 5, now()), "mmmm d, yyyy")# - 
    #dateFormat(dateAdd("d", 7, now()), "mmmm d, yyyy")#
</p>

<p style="text-align: center; margin: 30px 0;">
    <a href="#trackingUrl#" class="button">Track Your Order</a>
</p>

<h3>Need Help?</h3>
<p>
    If you have any questions about your order, please don't hesitate to contact us:
</p>
<ul>
    <li>Email: <a href="mailto:orders@yourstore.com">orders@yourstore.com</a></li>
    <li>Phone: 1-800-YOUR-STORE</li>
    <li>Live Chat: Available 24/7 on our website</li>
</ul>

<p>Thank you for shopping with us!</p>
</cfoutput>
```

## Testing Mailers

### Mailer Test Structure
```cfm
/**
 * UserNotificationsMailerTest
 */
component extends="wheels.Test" {

    function setup() {
        // Create mailer instance
        variables.mailer = createObject("component", "mailers.UserNotificationsMailer");
        
        // Create test user
        variables.testUser = model("User").create(
            name = "Test User",
            email = "test@example.com",
            createdAt = now()
        );
    }

    function teardown() {
        // Clean up test data
        variables.testUser.delete();
    }

    function test_welcomeEmail_sends_successfully() {
        // Arrange
        local.expectedSubject = "Welcome to #get('appName')#!";

        // Act
        local.result = variables.mailer.welcomeEmail(
            to = variables.testUser.email,
            user = variables.testUser
        );

        // Assert
        assert(local.result, "Welcome email should send successfully");
        // Additional assertions would depend on your mailer implementation
    }

    function test_welcomeEmail_contains_user_name() {
        // This test would verify that the email template includes the user's name
        // Implementation depends on your testing framework's email inspection capabilities
        
        local.result = variables.mailer.welcomeEmail(
            to = variables.testUser.email,
            user = variables.testUser
        );

        // Verify email content (pseudo-code - actual implementation varies)
        // local.emailContent = getLastSentEmailContent();
        // assert(find(variables.testUser.name, local.emailContent) > 0, "Email should contain user name");
    }

    function test_passwordReset_with_valid_token() {
        // Arrange
        local.resetToken = generateResetToken();

        // Act
        local.result = variables.mailer.passwordReset(
            user = variables.testUser,
            resetToken = local.resetToken
        );

        // Assert
        assert(local.result, "Password reset email should send");
        // Verify that email contains the reset link
    }

    function test_securityAlert_with_different_alert_types() {
        local.alertTypes = ["login_new_location", "password_changed", "suspicious_activity"];

        for (local.alertType in local.alertTypes) {
            local.result = variables.mailer.securityAlert(
                user = variables.testUser,
                alertType = local.alertType,
                alertData = {location: "New York, NY"}
            );

            assert(local.result, "Security alert email should send for type: #local.alertType#");
        }
    }

    // Helper method for generating test tokens
    private string function generateResetToken() {
        return hash(variables.testUser.email & now(), "MD5");
    }
}
```

### Integration Testing Example
```cfm
/**
 * EmailIntegrationTest - Test email delivery in different scenarios
 */
component extends="wheels.Test" {

    function setup() {
        // Set up test email configuration
        originalEmailConfig = duplicate(application.wheels.sendEmailFunctionArguments);
        
        // Configure test email settings
        set(
            functionName = "sendEmail",
            server = "smtp.mailtrap.io", // Test SMTP server
            port = 2525,
            username = get("testEmailUsername"),
            password = get("testEmailPassword")
        );
    }

    function teardown() {
        // Restore original email configuration
        application.wheels.sendEmailFunctionArguments = originalEmailConfig;
    }

    function test_order_confirmation_workflow() {
        // Create test order
        local.testOrder = createTestOrder();

        // Send confirmation email
        local.orderMailer = createObject("component", "mailers.OrderMailer");
        local.result = local.orderMailer.orderConfirmation(local.testOrder);

        // Verify email was sent
        assert(local.result, "Order confirmation email should send");

        // Clean up
        local.testOrder.delete();
    }

    function test_bulk_newsletter_sending() {
        // Create test subscribers
        local.subscribers = createTestSubscribers(count = 5);

        local.newsletterMailer = createObject("component", "mailers.NewsletterMailer");
        local.testArticles = createTestArticles();

        local.successCount = 0;
        for (local.subscriber in local.subscribers) {
            try {
                local.result = local.newsletterMailer.weeklyNewsletter(
                    subscriber = local.subscriber,
                    articles = local.testArticles
                );
                if (local.result) local.successCount++;
            } catch (any e) {
                // Log but don't fail test for individual failures
                writeLog(text = "Newsletter failed for subscriber #local.subscriber.email#: #e.message#");
            }
        }

        assert(local.successCount >= 4, "At least 4 out of 5 newsletters should send successfully");

        // Clean up
        deleteTestSubscribers(local.subscribers);
    }

    // Helper methods
    private any function createTestOrder() {
        return model("Order").create(
            orderNumber = "TEST-" & randRange(10000, 99999),
            customerEmail = "test@example.com",
            total = 99.99,
            status = "confirmed"
        );
    }

    private array function createTestSubscribers(numeric count = 3) {
        local.subscribers = [];
        for (local.i = 1; local.i <= arguments.count; local.i++) {
            local.subscriber = model("Subscriber").create(
                email = "test#local.i#@example.com",
                name = "Test User #local.i#",
                subscribed = true
            );
            arrayAppend(local.subscribers, local.subscriber);
        }
        return local.subscribers;
    }
}
```

## Usage Examples

### In Controllers
```cfm
component extends="Controller" {

    function create() {
        // Create new user account
        local.user = model("User").create(
            name = params.user.name,
            email = params.user.email,
            password = params.user.password
        );

        if (!local.user.hasErrors()) {
            // Send welcome email
            local.userMailer = createObject("component", "mailers.UserMailer");
            local.emailSent = local.userMailer.welcomeEmail(
                to = local.user.email,
                user = local.user
            );

            if (local.emailSent) {
                flashInsert(success = "Account created! Check your email for a welcome message.");
            } else {
                flashInsert(warning = "Account created, but welcome email could not be sent.");
            }

            redirectTo(action = "show", key = local.user.id);
        } else {
            renderView(action = "new");
        }
    }

    function requestPasswordReset() {
        local.user = model("User").findOne(where = "email = ?", whereParams = [params.email]);

        if (isObject(local.user)) {
            // Generate reset token
            local.resetToken = generateSecureToken();
            local.user.update(
                passwordResetToken = local.resetToken,
                passwordResetExpires = dateAdd("h", 1, now())
            );

            // Send password reset email
            local.userMailer = createObject("component", "mailers.UserMailer");
            local.emailSent = local.userMailer.passwordReset(
                user = local.user,
                resetToken = local.resetToken
            );

            flashInsert(success = "Password reset instructions have been sent to your email.");
        } else {
            flashInsert(error = "No account found with that email address.");
        }

        redirectTo(action = "passwordResetForm");
    }
}
```

### In Models (Callbacks)
```cfm
component extends="Model" {

    function config() {
        afterCreate("sendWelcomeEmail");
        afterUpdate("sendAccountUpdateNotification");
        beforeDelete("sendAccountDeletionNotice");
    }

    private void function sendWelcomeEmail() {
        // Only send for new user accounts
        if (hasChanged("id")) {
            local.userMailer = createObject("component", "mailers.UserMailer");
            local.userMailer.welcomeEmail(
                to = this.email,
                user = this
            );
        }
    }

    private void function sendAccountUpdateNotification() {
        // Send notification if email or critical information changed
        if (hasChanged("email") || hasChanged("name")) {
            local.userMailer = createObject("component", "mailers.UserMailer");
            local.userMailer.accountUpdated(
                user = this,
                changedFields = changedProperties()
            );
        }
    }

    private void function sendAccountDeletionNotice() {
        local.userMailer = createObject("component", "mailers.UserMailer");
        local.userMailer.accountDeleted(
            user = this
        );
    }
}
```

### In Background Jobs
```cfm
// /app/jobs/SendNewsletterJob.cfc
component extends="wheels.Job" {

    public void function perform(struct data = {}) {
        try {
            // Get newsletter content
            local.newsletter = model("Newsletter").findByKey(arguments.data.newsletterId);
            
            // Get active subscribers
            local.subscribers = model("Subscriber").findAll(
                where = "active = ? AND subscriptionType IN (?)",
                whereParams = [true, "newsletter,all"]
            );

            local.newsletterMailer = createObject("component", "mailers.NewsletterMailer");
            local.successCount = 0;
            local.errorCount = 0;

            // Send to each subscriber
            for (local.subscriber in local.subscribers) {
                try {
                    local.result = local.newsletterMailer.weeklyNewsletter(
                        subscriber = local.subscriber,
                        articles = local.newsletter.articles,
                        data = {
                            campaignId = arguments.data.campaignId,
                            sendDate = now()
                        }
                    );

                    if (local.result) {
                        local.successCount++;
                        
                        // Track delivery
                        model("EmailDelivery").create(
                            subscriberId = local.subscriber.id,
                            newsletterId = local.newsletter.id,
                            status = "sent",
                            sentAt = now()
                        );
                    } else {
                        local.errorCount++;
                    }

                    // Rate limiting - pause between sends
                    sleep(100); // 100ms delay

                } catch (any e) {
                    local.errorCount++;
                    logError("Newsletter send failed for subscriber #local.subscriber.email#: #e.message#");
                    
                    // Track failure
                    model("EmailDelivery").create(
                        subscriberId = local.subscriber.id,
                        newsletterId = local.newsletter.id,
                        status = "failed",
                        errorMessage = e.message
                    );
                }
            }

            // Update campaign statistics
            local.newsletter.update(
                totalSent = local.successCount,
                totalErrors = local.errorCount,
                sentAt = now()
            );

            logInfo("Newsletter campaign completed: #local.successCount# sent, #local.errorCount# failed");

        } catch (any e) {
            logError("Newsletter job failed: #e.message#", e);
            throw(object = e);
        }
    }
}
```

## Best Practices

### 1. Configuration Management
```cfm
function config() {
    // Environment-specific settings
    if (get("environment") == "production") {
        defaultFrom = "noreply@yourapp.com";
        defaultReplyTo = "support@yourapp.com";
    } else {
        defaultFrom = "test@yourapp.dev";
        defaultReplyTo = "dev@yourapp.dev";
    }
    
    // Default layout for all emails
    defaultLayout = "email";
    
    // Default retry settings
    maxRetries = 3;
    retryDelay = 300; // 5 minutes
}
```

### 2. Template Data Organization
```cfm
function welcomeEmail(required string to, required any user, struct data = {}) {
    // Prepare all template data in one place
    local.templateData = {
        user = arguments.user,
        appName = get("appName"),
        welcomeUrl = buildUrl("dashboard.index", host=get("baseUrl")),
        supportUrl = buildUrl("support.contact", host=get("baseUrl")),
        unsubscribeUrl = buildUnsubscribeUrl(arguments.user),
        socialLinks = getSocialMediaLinks(),
        currentYear = year(now())
    };

    // Merge with additional data
    structAppend(local.templateData, arguments.data);

    // Set email properties
    to(arguments.to);
    subject("Welcome to #local.templateData.appName#!");
    template("/usermailer/welcomeEmail");

    // Pass all data to template
    for (local.key in local.templateData) {
        variables[local.key] = local.templateData[local.key];
    }

    return deliver();
}
```

### 3. Error Handling and Logging
```cfm
function sendOrderConfirmation(required any order) {
    try {
        // Configure email
        to(arguments.order.customerEmail);
        subject("Order Confirmation - ##" & arguments.order.orderNumber);
        template("/ordermailer/orderConfirmation");
        
        // Set template variables
        variables.order = arguments.order;
        
        // Attempt delivery
        local.result = deliver();
        
        // Log successful delivery
        logInfo("Order confirmation sent for order #arguments.order.orderNumber# to #arguments.order.customerEmail#");
        
        return local.result;
        
    } catch (any e) {
        // Log error
        logError("Failed to send order confirmation for order #arguments.order.orderNumber#: #e.message#", e);
        
        // Optionally, queue for retry
        queueEmailForRetry("orderConfirmation", {orderId: arguments.order.id});
        
        // Don't re-throw in production to avoid breaking order process
        if (get("environment") == "development") {
            throw(object = e);
        }
        
        return false;
    }
}
```

### 4. Multipart Email Support
```cfm
function multipartNewsletter(required any subscriber, required array articles) {
    // Set recipient and subject
    to(arguments.subscriber.email);
    subject("Weekly Newsletter - #dateFormat(now(), 'mmmm d, yyyy')#");

    // Set both plain text and HTML templates
    templates = "/newsletter/weeklyNewsletterText,/newsletter/weeklyNewsletterHtml";
    
    // Set corresponding layouts
    layouts = "emailText,emailHtml";

    // Set template variables
    variables.subscriber = arguments.subscriber;
    variables.articles = arguments.articles;
    variables.unsubscribeUrl = buildUnsubscribeUrl(arguments.subscriber);

    return deliver();
}
```

### 5. Template Security
```cfm
function sendUserGeneratedContent(required string to, required string content) {
    // Sanitize user-generated content before including in email
    local.sanitizedContent = sanitizeHtmlForEmail(arguments.content);
    
    to(arguments.to);
    subject("New Content Notification");
    template("/notifications/userContent");
    
    // Pass sanitized content to template
    variables.safeContent = local.sanitizedContent;
    variables.originalContent = arguments.content; // For comparison if needed
    
    return deliver();
}

private string function sanitizeHtmlForEmail(required string html) {
    // Remove potentially dangerous HTML
    local.cleaned = reReplaceNoCase(arguments.html, "<script[^>]*>.*?</script>", "", "all");
    local.cleaned = reReplaceNoCase(local.cleaned, "<style[^>]*>.*?</style>", "", "all");
    local.cleaned = reReplaceNoCase(local.cleaned, "javascript:", "", "all");
    local.cleaned = reReplaceNoCase(local.cleaned, "vbscript:", "", "all");
    
    return local.cleaned;
}
```

## Important Notes

- **Framework Integration**: Mailers integrate with Wheels' view system and configuration
- **Template Location**: Email templates follow the same path conventions as regular views
- **Layout Support**: Mailers support layouts just like regular Wheels views
- **Testing**: Always test mailers thoroughly, including template rendering and delivery
- **Error Handling**: Implement robust error handling to prevent email failures from breaking application flow
- **Performance**: Consider using background jobs for bulk email sending
- **Security**: Sanitize user-generated content before including in emails
- **Deliverability**: Follow email best practices for better inbox delivery rates
- **Compliance**: Ensure emails comply with CAN-SPAM and GDPR requirements when applicable

Mailers provide a structured, object-oriented approach to email management in Wheels applications, promoting code organization and reusability while maintaining the framework's conventions and ease of use.