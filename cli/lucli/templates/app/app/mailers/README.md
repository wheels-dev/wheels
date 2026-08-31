# app/mailers/

Components that send email. Mailers are **plain CFCs** — there is no
framework base class — that wrap the controller's `sendEmail()` behind a
named method.

Because `sendEmail()` is a controller function (it needs a
request-capable controller instance with a `params` struct), each mailer
method obtains one through the `controller()` factory:

```cfm
component {
    public any function sendWelcome(required any user) {
        local.mailer = new wheels.Global().controller(
            name = "Mailer",
            params = { controller: "mailer", action: "sendWelcome" }
        );
        return local.mailer.sendEmail(
            template = "/mailers/user/welcome",
            from = "noreply@example.com",
            to = arguments.user.email,
            subject = "Welcome, #arguments.user.firstName#!",
            user = arguments.user
        );
    }
}
```

Send from a controller:

```cfm
new app.mailers.UserMailer().sendWelcome(user);
```

## Configuration

SMTP settings live in `config/settings.cfm` as `sendEmail` function
defaults (Wheels does not define a `mailerSettings` struct):

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

`from`, `to`, and `subject` are required at every call site — configure
everything else as defaults, pass those three explicitly.

See [Sending Email](https://guides.wheels.dev/v4-0-0/digging-deeper/sending-email/) in the guides for the full walkthrough.
