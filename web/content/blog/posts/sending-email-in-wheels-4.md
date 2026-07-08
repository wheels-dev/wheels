---
title: 'Sending Email in Wheels 4.0: sendEmail, Templates, and Background Delivery'
slug: sending-email-in-wheels-4
publishedAt: '2026-07-08T14:00:00.000Z'
updatedAt: '2026-06-19T15:10:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - email
  - mailers
  - jobs
categories: []
excerpt: >-
  A complete how-to for sending email in Wheels 4.0 — the sendEmail controller
  helper, how email view templates resolve, multipart text+html, attachments,
  and the correct way to deliver mail from a background job. Includes the
  sharp edges that actually bite.
coverImage: null
---

A user signs up. You want to send them a welcome email. You go looking for the mailer.

There isn't one.

If you came to Wheels from Rails, this is the first thing that trips you up. There's no `WelcomeMailer < ApplicationMailer`, no `app/mailers/` directory, no `deliver_later`. You grep the framework for `Mailer` and find nothing. You grep for `ActionMailer` and find nothing. For a minute you assume email just isn't a first-class thing in Wheels.

It is. It's just spelled differently. The entire mail surface in Wheels 4.0 is one function — `sendEmail` — and it's a controller helper, not a class. That single design decision explains both why email in Wheels is delightfully simple and why one specific thing (sending mail from a background job) bites everyone who tries it. This post covers both: the happy path first, then the one correction the docs get wrong.

## sendEmail is the whole mailer

Here's a welcome email, sent the moment a user is created. This lives in a controller — `app/controllers/Users.cfc`:

```cfm
component extends="Controller" {
    function create() {
        user = model("User").new(params.user);
        if (user.save()) {
            sendEmail(
                from="welcome@example.com",
                to=user.email,
                subject="Thank You for Joining",
                template="welcomeEmail",
                recipientName=user.name,
                startDate=user.createdAt
            );
            redirectTo(route="user", key=user.id);
        } else {
            renderView(action="new");
        }
    }
}
```

That's it. No mailer class, no separate delivery step. `sendEmail` renders a view template, builds the message, and hands it to `cfmail` for delivery — all in one call.

Three arguments do exactly what you'd expect: `from`, `to`, `subject`. Those, plus `template`, are required. The interesting two are `recipientName` and `startDate` — because **those aren't email arguments at all**. They're template variables, and the mechanism that routes them there is the single most important thing to understand about `sendEmail`.

## The arg-routing rule: cfmail attribute or view variable

`sendEmail` looks at every named argument you pass and asks one question: *is this the name of a real `cfmail` attribute?*

There's a fixed allow-list of `cfmail` attribute names baked into the function — `from`, `to`, `cc`, `bcc`, `subject`, `type`, `priority`, `replyto`, `failto`, `server`, `port`, `username`, `password`, `useSSL`, `useTLS`, `charset`, `wraptext`, `mailerid`, and a couple dozen more. If your argument name is on that list, it gets passed straight through to the `cfmail` tag.

If it's *not* on the list — and isn't one of Wheels' own control arguments like `template` or `layout` — then it's stripped out of the arguments and injected into the controller's `variables` scope for the duration of template rendering. Your email view reads it as `#recipientName#` or `variables.recipientName`.

So in the example above, `recipientName` and `startDate` never touch `cfmail`. They become variables your template can render. The template itself is an ordinary `.cfm` view file at `app/views/users/welcomeemail.cfm`:

```cfm
<cfparam name="recipientName" default="there">
<cfparam name="startDate" default="#Now()#">
<cfoutput>
<p>Hi #recipientName#,</p>
<p>Welcome aboard! Your account is active as of #DateFormat(startDate, "mmm d, yyyy")#.</p>
</cfoutput>
```

Same rule you follow for every view: `cfparam` each variable at the top. An email template is a view. Nothing exotic.

This routing rule is elegant, but it has a sharp edge baked right in. If you *intend* a value to reach `cfmail` but you typo the argument name — or pick a name that isn't a real `cfmail` attribute — it silently lands in the view scope instead of the email header. Want to set a reply-to address but write `replyto` as `reply_to`? It won't fail. It'll just quietly become a view variable nobody reads, and your email will go out without a reply-to. Keep the allow-list in mind: if it's an email header, it has to be a real `cfmail` attribute name.

## How template paths resolve

The `template` argument is a view path, and it resolves through the same machinery as `renderView`. There are three forms, and the difference matters a lot once you start sending mail from anywhere other than a controller action.

| `template` value | Resolves to | When to use |
|---|---|---|
| `"welcomeEmail"` (bare name) | `app/views/<currentController>/welcomeemail.cfm` | Email belongs to the controller you're in |
| `"mailers/welcome"` (has a slash) | `app/views/<currentController>/mailers/welcome.cfm` | Subfolder under the current controller |
| `"/mailers/welcome"` (leading slash) | `app/views/mailers/welcome.cfm` | Anchored at the views root, controller-independent |

A few things to internalize:

- **Resolved paths are lower-cased.** `template="welcomeEmail"` resolves to `welcomeemail.cfm`. Name your files lowercase and save yourself a case-sensitivity bug on Linux.
- **The base directory is the `viewPath` setting**, which defaults to `/app/views`.
- **`..` and backslashes are rejected** as a path-traversal guard. You can't escape the views tree.

The leading-slash form is the one you'll reach for the moment your mail stops living next to a specific controller. `template="/mailers/welcome"` always means `app/views/mailers/welcome.cfm` no matter which controller is doing the sending. That stability is what makes it the right choice for shared mail and — as you'll see below — for mail sent from a job, where the "current controller" is whatever you made it.

## Multipart: text and html in one message

Real email is multipart. Spam filters and accessibility both want a plain-text alternative alongside the HTML. `sendEmail` handles this by accepting *two* templates instead of one:

```cfm
sendEmail(
    from="news@example.com",
    to=subscriber.email,
    subject="Your Weekly Newsletter",
    templates="newsletterText,newsletterHtml",
    layouts="newsletterText,emailLayout",
    detectMultipart=false,
    issueDate=Now()
);
```

Note `templates` and `layouts` — plural. They're aliases for `template` and `layout`. Single or plural, same argument; the plural just reads better when you're passing a list.

Two templates means one text part and one HTML part. The maximum is two — pass three and you get a `Wheels.IncorrectArguments` error. There's no three-part email in Wheels.

Now the part that trips people up: **how does Wheels know which template is text and which is HTML?**

By default (`detectMultipart=true`), it *guesses*. It counts the `<` characters in each rendered body and assumes the one with fewer is the plain-text version. Most of the time that's right — HTML is full of angle brackets, plain text usually isn't.

But "most of the time" is doing a lot of work in that sentence. If your plain-text body legitimately contains a lot of `<` characters — a code sample, a math expression, an ASCII-art table — the heuristic can flip them and send your HTML as `text/plain` and vice versa.

The fix is in the example above: `detectMultipart=false`. That turns off the guessing and tells Wheels to trust your ordering — **text first, HTML second**. `templates="newsletterText,newsletterHtml"` is then taken literally. When the order matters, this is the safe call. Disable detection and put the text template first.

`layouts="newsletterText,emailLayout"` wraps each part in a layout. A mail layout is just a layout file that calls `includeContent()` to emit the rendered body — same as any Wheels layout. Pass one layout and both parts share it; pass two and they're applied positionally. And `issueDate=Now()` follows the same arg-routing rule as before: not a `cfmail` attribute, so it becomes `variables.issueDate` in both templates.

### Single-template content type

If you send just one template and don't say `type="html"` or `type="text"`, the same `<`-counting instinct kicks in. With `detectMultipart=true` (the default) and one template, Wheels sets `type="html"` only if the body contains both a `<` and a `>` — otherwise `type="text"`. With `detectMultipart=false` and no explicit type, it defaults to `text`, matching `cfmail`'s own default.

The clean move is to stop relying on the guess entirely: if you're sending HTML, say `type="html"`. `type` is a real `cfmail` attribute, so it passes straight through and removes all ambiguity.

## Attachments

Attach files with the `file` argument (aliased `files` for a list):

```cfm
sendEmail(
    from="billing@example.com",
    to=customer.email,
    subject="Your Invoice",
    template="invoiceEmail",
    file="invoice_2024.pdf"
);
```

Attachment paths resolve relative to the `filePath` setting (default `files`), expanded under your app root — so `file="invoice_2024.pdf"` looks for `<app>/files/invoice_2024.pdf`.

The one exception: if the value already contains a path delimiter (`/` or `\`), Wheels uses it as-is and skips the `files`-folder prefix. So an absolute path or a `http://...` URL is passed straight through to the underlying `cfmailparam`. The rule is simple: bare filename, looks in `files/`; anything with a slash in it, used verbatim.

## Previewing and testing without sending

There's no `preview` API in Wheels, and you don't need one. `deliver=false` is the preview mechanism:

```cfm
result = sendEmail(
    from="billing@example.com",
    to=customer.email,
    subject="Your Invoice",
    template="invoiceEmail",
    file="invoice_2024.pdf",
    deliver=false
);

// result.subject  == "Your Invoice"
// result.text     == the rendered plain-text body (if any)
// result.html     == the rendered HTML body (if any)
// result.mailparams[1].file == the resolved attachment path
```

When `deliver=false`, `sendEmail` does everything *except* the actual `cfmail` send. It still renders the templates, resolves attachments, and assembles the message — then returns the result struct (and stashes a copy on the controller for inspection). Nothing leaves your server.

This is exactly how the framework's own test suite verifies email: render with `deliver=false`, then assert on `result.subject`, `result.html`, `result.text`. Your tests should do the same. You never need to point a test at a real SMTP server.

The returned struct is rich. It has `html` and `text` keys for the rendered bodies, plus every `cfmail` pass-through argument, plus `mailparams` (attachments) and `mailparts` (multipart bodies) when those apply. Assert on whichever you care about.

## Background delivery — and the one thing the docs get wrong

Here's the scenario this post is really about. Sending email synchronously inside a web request is a latency mistake — your user waits for the SMTP handshake before the page loads. The right move is to enqueue the email as a background job and let a worker deliver it. Wheels 4.0 has a database-backed job system for exactly this (covered in depth in the [Background Jobs without Redis](https://blog.wheels.dev/posts/background-jobs-without-redis) post — this section assumes you've seen the queue/worker side).

So you write a job. You extend `wheels.Job`, you override `config()`, you implement `perform()`, and inside `perform()` you call `sendEmail`. The Wheels docs even show you exactly this — the `Job.cfc` docblock has a `SendWelcomeEmailJob` whose `perform()` body is a bare `sendEmail(to=data.email, ...)`.

**That bare call does not work.** This is the centerpiece correction of this post, so let me be precise about why.

`sendEmail` is a *controller mixin*. It gets mixed onto controllers (and models) by the framework's component-integration step. But `wheels.Job` is a plain `component {}` — it is not a controller, it has no controller mixins, and it has no `onMissingMethod` to catch the call. Worse, when a worker actually processes your job, it runs it via `CreateObject("component", jobClass).perform(data=jobData)` — no controller context is ever established. So inside a worker-processed `perform()`, a bare `sendEmail` is an undefined method. So is a bare `model()`. The docblock snippet is illustrative pseudocode, not runnable code.

The fix is small and idiomatic: acquire a controller first, then call `sendEmail` on it. The bridge is the global `controller()` factory, which builds a real controller object — *with* the `sendEmail` mixin — that you can call into from anywhere.

Here's the working version. `app/jobs/WelcomeMailerJob.cfc`:

```cfm
component extends="wheels.Job" {

    function config() {
        super.config();
        this.queue = "mailers";
        this.maxRetries = 5;
    }

    public void function perform(struct data = {}) {
        // controller() builds an object WITH the sendEmail mixin.
        // Any controller works — here a dedicated app/controllers/Mailer.cfc.
        var mailer = controller("Mailer");
        mailer.sendEmail(
            from     = "welcome@example.com",
            to       = arguments.data.email,
            subject  = "Welcome!",
            template = "/mailers/welcome",
            userName = arguments.data.name
        );
    }
}
```

Two details earn their keep here:

1. **`controller("Mailer")` is the whole trick.** It instantiates a controller named `Mailer` — `app/controllers/Mailer.cfc`, which can be an empty `component extends="Controller" {}` — and that object carries `sendEmail`. Any controller name works; a dedicated `Mailer` controller just keeps your mail templates organized under `app/views/mailers/`.
2. **The leading-slash template path is mandatory here.** Inside the job, the "current controller" is whatever you named in `controller(...)` — but because `controller("Mailer")` (no params) returns the controller *class* — which never ran the request lifecycle and has no `params.controller` — a bare `template="welcome"` throws `Wheels.ControllerNameRequired` rather than resolving silently. `template="/mailers/welcome"` anchors at the views root: `app/views/mailers/welcome.cfm`, every time, no matter how the controller was acquired, and avoids the error. This is the payoff of understanding template resolution from earlier.

The enqueue side is unchanged from any other job — fire it from your controller action and return immediately:

```cfm
function create() {
    user = model("User").new(params.user);
    if (user.save()) {
        new app.jobs.WelcomeMailerJob().enqueue(
            data = {email: user.email, name: user.name}
        );
        redirectTo(route="users");
    } else {
        renderView(action="new");
    }
}
```

`enqueue` persists a row to the `wheels_jobs` table (auto-created on first enqueue — no migration) and returns instantly. The user gets their redirect with no SMTP wait. The email goes out when a worker picks the job up:

```bash
wheels jobs work --queue=mailers --interval=3
```

The worker deserializes your `data` struct, calls `perform(data=...)`, and your `controller("Mailer").sendEmail(...)` runs in the background. That's the full loop: enqueue in the request, deliver in the worker.

## Gotchas

The sharp edges, collected. Every one of these is real and has bitten someone.

- **Bare `sendEmail()` inside a job's `perform()` does not resolve.** The single biggest trap, and the docs perpetuate it. `wheels.Job` is a plain component with no controller mixins, and workers run `perform()` with no controller scope. Always go through `controller("Mailer").sendEmail(...)`. Same goes for `model()` inside a job — also a controller/model mixin, also undefined in a bare job context.

- **There is no Mailer base class and no ActionMailer equivalent.** Don't go looking for `wheels.Mailer` or a `deliverMail` function — they don't exist. `sendEmail` is the entire mailer surface. A "WelcomeMailer" is a *convention*: a controller you create, or a job that calls `controller(...).sendEmail`. Nothing more.

- **Custom args silently become view variables — watch for name collisions.** Any argument that isn't a `cfmail` attribute or a Wheels control arg is injected into the controller's `variables` scope during render. If a custom arg shares a name with an existing controller variable, it temporarily shadows it (Wheels restores the original afterward, so it doesn't leak — but during render, the email's value wins). And if you meant a value for `cfmail` but named it wrong, it goes to the view instead of the header. No error either way.

- **Multipart ordering is a heuristic by default.** With `detectMultipart=true` and two templates, Wheels picks text vs. HTML by counting `<` characters — fewer means text. A plain-text body full of `<` (code, math) can get mis-sorted. Set `detectMultipart=false` and pass `templates` text-first to force the order.

- **Single-template type detection uses the same `<` heuristic.** One template, `detectMultipart=true`, no explicit `type`: Wheels sets `type="html"` only if the body has both `<` and `>`, else `text`. With detection off and no type, it defaults to `text`. Pass `type="html"` explicitly to remove all doubt.

- **`layout` defaults to `false`, not to your app layout.** The framework default is no layout, and an empty-string layout is coerced to `false`. To wrap an email, pass `layout="emailLayout"` explicitly; the layout file emits the body via `includeContent()`.

- **`from`, `to`, and `subject` are hard-required in the `sendEmail` signature.** The CFML engine throws `argument is required` if you omit them — and setting a global default via `set(functionName="sendEmail", from=...)` does NOT exempt you, because the engine's required check fires before the global default is merged inside the function. `template` defaults to an empty string in the signature, so it's the only one of the four that won't trigger an engine-level required error (the global-default path can satisfy it). In practice, always pass `from`, `to`, and `subject` on every call.

- **Attachment paths: bare name looks in `files/`, anything with a slash is used as-is.** `file="invoice.pdf"` resolves to `<app>/files/invoice.pdf`. `file="http://..."` or an absolute path passes straight through. Know which behavior you're getting.

- **`deliver=false` is the preview/test path — there's no separate preview API.** It renders and assembles everything but skips the send, returning the result struct (and stashing it for inspection). The entire framework test suite uses this. So should yours.

- **From a job, the "current controller" is whatever you passed to `controller()`.** But a controller built via `controller("Mailer")` with no params is the cached *class* (no `params.controller`), so a bare template name throws `Wheels.ControllerNameRequired`. Use a leading-slash path (`/mailers/welcome`) to anchor at the views root and avoid the error.

## Wrapping up

The mental model is short. `sendEmail` is one controller function that renders a view and sends it. Arguments that match `cfmail` attributes go to the email; everything else becomes a template variable. Templates resolve like any view, lower-cased, with a leading slash to anchor at the views root. Multipart is two templates, text-first when you turn the heuristic off. Attachments live in `files/`. `deliver=false` is your preview and your test harness.

And when you move mail into the background — which you should, for anything triggered by a web request — remember the one correction: a job is not a controller. Reach `sendEmail` through `controller("Mailer")`, anchor your template with a leading slash, and let the worker do the waiting so your users don't have to.
