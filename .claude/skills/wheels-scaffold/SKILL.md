---
name: Wheels Scaffold
description: Generate authentication systems, RESTful APIs, email/mailer functionality, and plugins. Use when implementing login/logout, API endpoints, transactional emails, or reusable plugin packages.
---

# Wheels Scaffold

Activate when user mentions: auth, login, signup, API, REST, JSON endpoint, email, mailer, notification, plugin, ForgeBox.

---

## 1. Authentication Scaffold

### User Model with Password Hashing

```cfm
component extends="Model" {
    function config() {
        validatesPresenceOf(property="email,password");
        validatesUniquenessOf(property="email");
        validatesFormatOf(property="email", regEx="^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$");
        validatesLengthOf(property="password", minimum=8);
        validatesConfirmationOf(property="password");
        beforeSave("hashPassword");
    }

    private function hashPassword() {
        if (structKeyExists(this, "password") && len(this.password) && !isHashed(this.password))
            this.password = hash(this.password, "SHA-512");
    }

    private boolean function isHashed(required string password) {
        return len(arguments.password) == 128;
    }

    public any function authenticate(required string email, required string password) {
        var user = this.findOne(where="email = '#arguments.email#'");
        if (!isObject(user)) return false;
        return (user.password == hash(arguments.password, "SHA-512")) ? user : false;
    }

    public void function generateResetToken() {
        this.resetToken = hash(createUUID() & now(), "SHA-256");
        this.resetTokenExpiry = dateAdd("h", 1, now());
    }

    public boolean function isResetTokenValid() {
        if (!structKeyExists(this, "resetToken") || !len(this.resetToken)) return false;
        if (!structKeyExists(this, "resetTokenExpiry")) return false;
        return dateCompare(now(), this.resetTokenExpiry) < 0;
    }

    public void function clearResetToken() {
        this.resetToken = "";
        this.resetTokenExpiry = "";
    }
}
```

### Sessions Controller (Login/Logout)

```cfm
component extends="Controller" {
    function new() { /* Show login form */ }

    function create() {
        var user = model("User").authenticate(email=params.email, password=params.password);
        if (isObject(user)) {
            session.userId = user.id;
            flashInsert(success="Welcome back!");
            redirectTo(controller="home", action="index");
        } else {
            flashInsert(error="Invalid email or password");
            renderPage(action="new");
        }
    }

    function delete() {
        structDelete(session, "userId");
        flashInsert(success="You have been logged out");
        redirectTo(controller="home", action="index");
    }
}
```

### Authentication Filter (add to any controller)

```cfm
function config() { filters(through="requireAuth"); }

private function requireAuth() {
    if (!structKeyExists(session, "userId")) {
        flashInsert(error="Please log in");
        redirectTo(controller="sessions", action="new");
    }
}
```

### Password Reset Controller

```cfm
component extends="Controller" {
    // SECURITY: Always show same message to prevent email enumeration
    function create() {
        user = model("User").findOne(where="email = '#params.email#' AND deletedAt IS NULL");
        if (isObject(user)) { user.generateResetToken(); user.save(); /* Send email */ }
        flashInsert(success="If that email is in our system, we've sent reset instructions.");
        redirectTo(controller="sessions", action="new");
    }

    function edit() {
        user = model("User").findOne(where="resetToken = '#params.token#' AND deletedAt IS NULL");
        if (!isObject(user) || !user.isResetTokenValid()) {
            flashInsert(error="Invalid or expired reset link.");
            redirectTo(controller="sessions", action="new"); return;
        }
        token = params.token;
    }

    function update() {
        user = model("User").findOne(where="resetToken = '#params.token#' AND deletedAt IS NULL");
        if (!isObject(user) || !user.isResetTokenValid()) {
            flashInsert(error="Invalid or expired reset link.");
            redirectTo(controller="sessions", action="new"); return;
        }
        user.password = params.password;
        user.passwordConfirmation = params.passwordConfirmation;
        user.clearResetToken();
        if (user.save()) {
            session.userId = user.id;
            redirectTo(controller="home", action="index");
        }
    }
}
```

**Security:** Same success message on reset (prevents enumeration), 1-hour single-use tokens, SHA-256 hash with UUID, HTTPS only in production.

---

## 2. API Scaffold

### RESTful API Controller

```cfm
component extends="Controller" {
    function config() {
        provides("json");
        verifies(only="show,update,delete", params="key", paramsTypes="integer");
        filters(through="requireApiAuth");
    }

    function index() {
        renderWith(data=model("Resource").findAll(order="createdAt DESC"), format="json", status=200);
    }

    function show() {
        resource = model("Resource").findByKey(key=params.key);
        if (!isObject(resource)) { renderWith(data={error="Not found"}, format="json", status=404); return; }
        renderWith(data=resource, format="json", status=200);
    }

    function create() {
        resource = model("Resource").new(params.resource);
        if (resource.save())
            renderWith(data=resource, format="json", status=201, location=urlFor(action="show", key=resource.key()));
        else
            renderWith(data={errors=resource.allErrors()}, format="json", status=422);
    }

    function update() {
        resource = model("Resource").findByKey(key=params.key);
        if (!isObject(resource)) { renderWith(data={error="Not found"}, format="json", status=404); return; }
        if (resource.update(params.resource))
            renderWith(data=resource, format="json", status=200);
        else
            renderWith(data={errors=resource.allErrors()}, format="json", status=422);
    }

    function delete() {
        resource = model("Resource").findByKey(key=params.key);
        if (!isObject(resource)) { renderWith(data={error="Not found"}, format="json", status=404); return; }
        resource.delete();
        renderWith(data={message="Deleted"}, format="json", status=204);
    }

    private function requireApiAuth() {
        var headers = getHTTPRequestData().headers;
        if (!structKeyExists(headers, "Authorization")) {
            renderWith(data={error="Unauthorized"}, format="json", status=401); abort;
        }
        var token = replace(headers.Authorization, "Bearer ", "");
        if (!isValidApiToken(token)) {
            renderWith(data={error="Invalid token"}, format="json", status=401); abort;
        }
    }
}
```

**Status codes:** 200 OK, 201 Created, 204 No Content, 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 422 Validation Errors, 500 Server Error.

---

## 3. Email Scaffold

### Mailer Controller

```cfm
component extends="Controller" {
    function config() {
        set(functionName="sendEmail", from="noreply@yourapp.com", layout="email", detectMultipart=true);
    }

    function welcome(required user) {
        sendEmail(to=arguments.user.email, subject="Welcome!",
            template="mailer/welcome", user=arguments.user);
    }

    function resetPassword(required user, required token) {
        local.resetUrl = URLFor(route="passwordReset", token=arguments.token, onlyPath=false);
        sendEmail(to=arguments.user.email, subject="Reset Your Password",
            template="mailer/resetPassword", user=arguments.user, resetUrl=local.resetUrl);
    }
}
```

### HTML Email Layout (views/mailer/layouts/email.cfm)

```cfm
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: ##333;
               max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: ##007bff; color: white; padding: 20px; text-align: center; }
        .content { background: ##f9f9f9; padding: 30px; border: 1px solid ##ddd; }
        .button { display: inline-block; padding: 12px 24px; background: ##007bff;
                  color: white; text-decoration: none; border-radius: 4px; }
        .footer { text-align: center; padding: 20px; color: ##666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header"><h1>Your App</h1></div>
    <div class="content"><cfoutput>##contentForLayout()##</cfoutput></div>
    <div class="footer"><p>&copy; #Year(Now())# Your Company</p></div>
</body>
</html>
```

### Plain Text Layout (views/mailer/layouts/email.txt.cfm)

```cfm
<cfoutput>==== YOUR APP ====
##contentForLayout()##
==== (c) #Year(Now())# Your Company ====</cfoutput>
```

### Email Templates

**Welcome** (views/mailer/welcome.cfm):
```cfm
<cfparam name="user">
<cfoutput>
<h2>Welcome, ##user.firstName##!</h2>
<p><a href="##URLFor(route='dashboard', onlyPath=false)##" class="button">Get Started</a></p>
</cfoutput>
```

**Password Reset** (views/mailer/resetPassword.cfm):
```cfm
<cfparam name="user"><cfparam name="resetUrl">
<cfoutput>
<h2>Reset Your Password</h2>
<p><a href="##resetUrl##" class="button">Reset Password</a></p>
<p>Or copy: ##resetUrl##</p>
<p><strong>Expires in 1 hour.</strong></p>
</cfoutput>
```

### SMTP Configuration (config/settings.cfm)

```cfm
<cfscript>
set(functionName="sendEmail", server="smtp.gmail.com", port=587,
    useTLS=true, from="noreply@yourapp.com", type="html", charset="utf-8");
if (application.wheels.environment == "development")
    set(functionName="sendEmail", debug=true, deliver=false);
if (application.wheels.environment == "production")
    set(functionName="sendEmail", server=getEnv("SMTP_SERVER"),
        username=getEnv("SMTP_USERNAME"), password=getEnv("SMTP_PASSWORD"), deliver=true);
</cfscript>
```

**SMTP providers:** Gmail (smtp.gmail.com:587), SendGrid (smtp.sendgrid.net:587, user="apikey"), Mailgun (smtp.mailgun.org:587), AWS SES (email-smtp.REGION.amazonaws.com:587).

### Email Queue Pattern

```cfm
function queueEmail(required struct emailData) {
    model("EmailQueue").create(recipient=arguments.emailData.to,
        subject=arguments.emailData.subject, data=serializeJSON(arguments.emailData), status="pending");
}

function processEmailQueue() {
    pending = model("EmailQueue").findAll(where="status='pending'", order="createdAt", maxRows=50);
    for (local.email in pending) {
        try {
            sendEmail(argumentCollection=deserializeJSON(local.email.data));
            local.email.update(status="sent", sentAt=now());
        } catch (any e) { local.email.update(status="failed", errorMessage=e.message); }
    }
}
```

### Calling Mailer from Controllers

```cfm
if (user.save()) {
    controller("Mailer").welcome(user);
    redirectTo(route="home", success="Account created!");
}
```

---

## 4. Plugin Scaffold

### Directory Structure

```
/plugins/YourPlugin/
├── index.cfm              # Entry point (required)
├── box.json               # ForgeBox metadata
├── config/settings.cfm    # Plugin config
├── db/migrate/            # Migrations (optional)
└── tests/PluginTest.cfc
```

### Plugin Entry Point (index.cfm)

```cfm
<cfcomponent output="false" mixin="global">
    <cffunction name="init">
        <cfset this.version = "1,0,0,0">
        <cfreturn this>
    </cffunction>

    <!--- Global: available everywhere --->
    <cffunction name="myPluginMethod" returntype="string" access="public" output="false">
        <cfargument name="text" type="string" required="true">
        <cfreturn "Plugin: " & arguments.text>
    </cffunction>

    <!--- Model-only: mixin="model" --->
    <cffunction name="softDelete" returntype="void" access="public" output="false" mixin="model">
        <cfset this.deletedAt = now()>
        <cfset this.save()>
    </cffunction>

    <!--- Controller/view: mixin="controller" --->
    <cffunction name="formatCurrency" returntype="string" access="public" output="false" mixin="controller">
        <cfargument name="amount" type="numeric" required="true">
        <cfreturn dollarFormat(arguments.amount)>
    </cffunction>
</cfcomponent>
```

### Plugin box.json

```json
{
    "name": "YourPlugin", "slug": "your-plugin", "version": "1.0.0",
    "type": "cfwheels-plugins",
    "shortDescription": "Brief description",
    "keywords": ["cfwheels", "plugin"],
    "engines": [
        { "type": "lucee", "version": ">=5.0.0" },
        { "type": "adobe", "version": ">=2018.0.0" }
    ],
    "license": [{ "type": "Apache-2.0" }],
    "ignore": ["**/.*", "tests"]
}
```

### Plugin Event Handlers

```cfm
<cfcomponent output="false" mixin="global">
    <cffunction name="init">
        <cfset this.version = "1,0,0,0">
        <cfset variables.wheels.events.register(
            eventName="onApplicationStart", object=this, method="onAppStart")>
        <cfreturn this>
    </cffunction>
    <cffunction name="onAppStart" returntype="void" access="public" output="false">
        <!--- Runs when application starts --->
    </cffunction>
</cfcomponent>
```

Available events: `onApplicationStart`, `onRequestStart`, `onRequestEnd`, `onSessionStart`, `onSessionEnd`, `onError`, `onMissingMethod`, `onMissingTemplate`.

### Plugin Database Migration

```cfm
component extends="wheels.migrator.Migration" {
    function up() {
        transaction {
            t = createTable(name="plugin_data");
            t.string(columnNames="name");
            t.text(columnNames="data");
            t.timestamps();
            t.create();
        }
    }
    function down() { dropTable("plugin_data"); }
}
```

### Plugin Testing

```cfm
component extends="wheels.Test" {
    function testPluginMethodExists() {
        assert("structKeyExists(variables.wheels, 'myPluginMethod')");
    }
    function testPluginMethodReturnsCorrectly() {
        result = myPluginMethod("test");
        assert("result == 'Plugin: test'");
    }
}
```

### ForgeBox Publishing

```bash
box forgebox login && box forgebox publish
# Version bumps: box bump --major | --minor | --patch
```

**Best practices:** Prefix function names to avoid conflicts. Never overwrite core methods. Provide config via settings. Include tests, README, LICENSE. Use semantic versioning.
