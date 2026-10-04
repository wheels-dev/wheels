# Mailers Quick Reference

Part of the Wheels application guide; start with `../CLAUDE.md`.

A mailer is a plain CFC in `app/mailers/`; there is no base class. `sendEmail()` is a controller function, so each mailer method gets a controller from the `controller()` factory and calls `sendEmail()` on it. You don't need an `app/controllers/Mailer.cfc`.

```cfm
// app/mailers/UserMailer.cfc
component {
    public any function sendWelcome(required any user) {
        local.mailer = new wheels.Global().controller(
            name = "Mailer",
            params = {controller: "mailer", action: "sendWelcome"}
        );
        return local.mailer.sendEmail(
            template = "/mailers/user/welcome",  // app/views/mailers/user/welcome.cfm
            from = "noreply@example.com",
            to = arguments.user.email,
            subject = "Welcome, #arguments.user.firstName#!",
            user = arguments.user                // other arguments become view variables
        );
    }
}
```

```cfm
<!--- app/views/mailers/user/welcome.cfm --->
<cfparam name="user">
<cfoutput><p>Hi #user.firstName#, welcome aboard.</p></cfoutput>
```

Send it from a controller or a job (`.ai/jobs.md`):

```cfm
new app.mailers.UserMailer().sendWelcome(user);
```

- `template`, `from`, `to` and `subject` are required on every call. Two templates (a text one and an HTML one) make a multipart email.
- The email is not wrapped in `app/views/layout.cfm`. To use a mail layout, pass it: `layout = "/mailers/layout"` renders `app/views/mailers/layout.cfm`, which outputs `#includeContent()#` where the template goes.

## SMTP settings

Set them once as `sendEmail()` defaults in `config/settings.cfm`:

```cfm
set(
    functionName = "sendEmail",
    server = "smtp.example.com",
    port = 587,
    useTLS = true,
    username = "you@example.com",
    password = env("SMTP_PASSWORD")
);
```

## Testing a mailer

`deliver = false` builds the email without sending it, and `sendEmail()` returns it as a struct (`to`, `subject`, `html` or `text`, …). Turn it off for one spec through the function defaults, and restore them (see `.ai/testing.md`):

```cfm
// tests/specs/UserMailerSpec.cfc
component extends="wheels.WheelsTest" {
    function run() {
        describe("UserMailer", () => {
            it("builds the welcome email without sending it", () => {
                var defaults = application.wheels.functions.sendEmail;
                var original = StructKeyExists(defaults, "deliver") ? defaults.deliver : true;
                defaults.deliver = false;
                try {
                    var email = new app.mailers.UserMailer().sendWelcome({email: "ada@example.com", firstName: "Ada"});
                    expect(email.to).toBe("ada@example.com");
                    expect(email.subject).toBe("Welcome, Ada!");
                    expect(email.html).toInclude("Hi Ada");
                } finally {
                    defaults.deliver = original;
                }
            });
        });
    }
}
```

Guide: https://guides.wheels.dev/v4-2-0/digging-deeper/sending-email/
