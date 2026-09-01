---
title: 'bcrypt for your passwords: the post that starts with a pentest report'
slug: bcrypt-password-hashing-in-wheels-4-1
publishedAt: '2026-09-02T14:00:00.000Z'
updatedAt: null
author: Peter Amiri
tags:
  - wheels-4
  - security
  - bcrypt
categories:
  - Releases
excerpt: >-
  The story of how bcryptHash(), bcryptVerify(), and bcryptNeedsRehash() made
  it into Wheels 4.1 starts with a pentest finding and a migration that took
  three weeks. Here's the helpers, the cost trade-off, and the part where
  Adobe CF made us question our sanity.
coverImage: '/blog-images/4-1/bcrypt-password-hashing-in-wheels-4-1.png'
---

The email was four lines long, and it was fine. *Your passwords are hashed with plain SHA-256, no salt, and the database backup from March is on a shared drive.* That's not a vulnerability, that's a sentence.

The developer who filed it wasn't angry. They were tired. What they'd have to do to fix it — install a library, swap the hasher, write a second code path for the old hashes, and get a migration through review — was more than they had budget for. So they asked, reasonably: *why doesn't Wheels just have this?*

It was a good question, and two weeks later we had an answer in the framework: `bcryptHash()`, `bcryptVerify()`, and `bcryptNeedsRehash()` — global helpers, pure CFML, no Java objects, no CFX tags, no bundled JAR. The whole thing is Blowfish plus an "expensive key schedule," implemented in CFML so it runs identically on Lucee, Adobe ColdFusion, BoxLang, and RustCFML.

```cfm
hashed = bcryptHash("correct horse battery staple");       // $2b$10$...
ok = bcryptVerify("correct horse battery staple", hashed); // true
needsUpgrade = bcryptNeedsRehash(hashed, 12);              // true while cost is 10
```

But the helper is the easy part. The *story* is what happens when you actually use it, because that's where the three-week migration lives.

## The migration is the point

You can't just swap the hasher. The database has ten thousand SHA-256 rows and you can't read them — hashes aren't reversible. So you do the two-step dance:

1. **New passwords** go through `bcryptHash()`. *Now.* Not "after the migration" — now, so the attack window closes the moment you deploy.
2. **Old hashes** keep verifying through your old routine until the user next logs in. On that login, you re-hash with bcrypt and overwrite the stored value.

`bcryptNeedsRehash()` is the hook for step two. It tells you whether a stored hash's cost factor no longer matches your policy — so a user with a cost-10 hash walks into your cost-12 world, logs in, and gets upgraded on the spot, no background job required:

```cfm
if (bcryptNeedsRehash(user.passwordHash, 12)) {
    user.passwordHash = bcryptHash(inputPassword, 12);
    user.save();
}
```

That's the whole "migrate" strategy. The framework can't do it for you, and it shouldn't — you're changing a secret's format, which is exactly the kind of thing that deserves an eyeball. But the four-line helper turns three weeks into an afternoon.

## What the cost factor actually costs you

bcrypt's cost is exponential: every +1 doubles the work. The pure-CFML implementation is honest that this has teeth. A **cost-10** hash takes roughly **14 seconds of CFML on Lucee 7**. That's a real number, and it changes your sizing math:

- **Cost 4–6** for test suites and local dev.
- **Cost 10–12** for production — but measure it on *your* hardware, because the constant differs by engine. Adobe runs the same cost several times faster than Lucee.
- If you need cost 12 *and* snappy registration on Lucee, plan for the CPU. That's not a bug in bcrypt; it's the entire point of bcrypt.

The helpers validate cost up front and throw `Wheels.InvalidArgument` outside 4–31, so `bcryptHash(password, 1)` fails loud instead of quietly hashing with a cost any GPU would shrug off.

## The part where we questioned our sanity

Cross-engine CFML is where "just implement bcrypt" turns into a detective story. Two engines misbehaved in ways that no amount of reading the docs would have predicted:

- **Adobe CF 2023** bit functions reject operands above 2³¹−1, and its `mod` and `BitSHRN` coerce operands differently than Lucee. So the word arithmetic had to be rewritten to stay inside signed 32-bit range and extract bytes arithmetically.
- Then the nasty one: **Adobe passes arrays by value.** The EksBlowfish key schedule mutates the P/S arrays in place. On Adobe, those mutations were silently discarded — so hashes *computed*, but they were wrong. Same vector, wrong checksum, no error. The fix was making the key schedule return its state instead of trusting by-reference mutation, and the classic symptom — "it works on my machine" — became a test vector pinned in the suite so it can never regress.

There's also a happier engine note: **RustCFML** ships `bcryptHash()`/`bcryptVerify()` as native builtins, so Wheels detects that at boot and lets the engine serve them — and provides `bcryptNeedsRehash()` itself, since no engine has that one.

The suite now verifies the helpers against external vectors: an OpenBSD `$2b$` checksum from Apache's `htpasswd`, and the official jBCrypt `$2a$08$` vector. "It matches on every engine we support" is a sentence we can now say and mean.

## The moral

The framework shipped bcrypt because a tired developer asked a good question and we couldn't point at a good answer. If you've got a `hash()` plus SHA in your model, this is your clean exit. New hashes today, upgrade-on-login for the old ones, two helpers you'll rarely think about again.

And if it takes fourteen seconds on your test suite, that's not the framework slowing you down — that's bcrypt doing its job. Bump the cost down for tests, and stop there.

Next up in the series: read the next post — session auth in one line, and the three bugs you won't have to find the hard way. (See the [series index](https://blog.wheels.dev/posts/wheels-4-1-coming/).)
