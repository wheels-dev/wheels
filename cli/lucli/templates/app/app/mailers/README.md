# app/mailers/

Components that send email. Each mailer is a `.cfc` extending `Mailer`.

## Quick start

Generate one:

```bash
wheels generate mailer WelcomeMailer welcome
```

Creates:
- `app/mailers/WelcomeMailer.cfc` — the mailer definition
- `app/views/welcomemailer/welcome.cfm` — the email body template

A mailer action sets headers (`this.from`, `this.to`, `this.subject`) and hands rendering to the matching view.

Send from a controller with `sendMail(mailer="WelcomeMailer", method="welcome", user=user)`.

## Configuration

SMTP settings live in `config/settings.cfm`:

```cfm
set(mailerSettings = {
    server: "smtp.example.com",
    port: 587,
    username: "you@example.com",
    password: application.wo.env("SMTP_PASSWORD")
});
```

See [Sending Email](https://wheels.dev/v4-0-0-snapshot/digging-deeper/sending-email/) in the guides for the full walkthrough.
