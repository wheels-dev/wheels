---
title: 'bcrypt password hashing lands in Wheels 4.1'
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
  Wheels 4.1 ships bcryptHash(), bcryptVerify(), and bcryptNeedsRehash() as
  global helpers — pure CFML, OpenBSD/htpasswd/jBCrypt-compatible, no Java
  objects or CFX. Here's how they work, what the cost factor costs you, and
  how to migrate from the PBKDF2 hashes wheels generate auth produced in 4.0.6.
coverImage: null
---

Wheels 4.1 adds a password-hashing primitive the framework hasn't had before: **bcrypt**, directly in the global function namespace, with no dependencies.

```cfm
hashed = bcryptHash("correct horse battery staple");       // $2b$10$...
ok = bcryptVerify("correct horse battery staple", hashed); // true
needsUpgrade = bcryptNeedsRehash(hashed, 12);              // true while cost is 10
```

The interesting part isn't the API — it's the implementation. There is no Java object, no CFX tag, no bundled JAR. The entire thing is CFML: the Blowfish block cipher, the EksBlowfish ("expensive key schedule") setup, and the 64-round ciphertext phase are implemented in pure CFML so the helpers run identically on Lucee, Adobe ColdFusion, BoxLang, and RustCFML.

## Why bcrypt?

The short version: bcrypt is the boring choice. It has been the default password hash for OpenBSD's `htpasswd` for decades, jBCrypt made it the standard Java implementation, and every language with an opinion has settled on it. Wheels 4.0.6's `wheels generate auth` scaffolds PBKDF2 hashing, which is fine and defensible — but bcrypt is what most teams expect when they hear "password hashing," and it's what existing password databases (htpasswd files, other frameworks' `$2a$`/`$2b$` columns) already contain.

The helpers are format-compatible with all of it:

- `bcryptHash()` produces the standard 60-character `$2b$<cost>$<salt><checksum>` format.
- `bcryptVerify()` accepts existing `$2$`, `$2a$`, `$2x$`, `$2y$`, and `$2b$` hashes, so migrating from another tool is just a matter of keeping the stored strings.
- `bcryptNeedsRehash(hash, cost)` tells you whether a stored hash's cost factor no longer matches your current policy — the hook you need to transparently upgrade hashes when a user logs in.

The implementation is pinned against external vectors in the test suite: an OpenBSD `$2b$` checksum produced by Apache's `htpasswd` for "password", and the official jBCrypt `$2a$08$` vector for "abc".

## What the cost factor costs

bcrypt's cost is exponential: every +1 doubles the work. The pure-CFML implementation is honest about that trade-off — a cost-10 hash takes roughly 14 seconds of CFML on Lucee 7. That is not a typo.

What this means in practice:

- **Cost 4–6** is the right neighborhood for test suites and local development.
- **Cost 10–12** is production-grade for a pure-CFML implementation, but you should measure it on *your* server, because the constant factor matters: the same cost runs several times faster on Adobe ColdFusion than on Lucee.
- If you need cost 12 *and* sub-second registration times on Lucee, generate the hashes with bcrypt but consider that your traffic pattern is now CPU-bound — which is exactly what bcrypt is designed to do, so size your app servers accordingly.

The helpers validate the cost factor up front and throw `Wheels.InvalidArgument` for anything outside 4–31, so a typo like `bcryptHash(password, 1)` fails loudly instead of silently hashing with an effectively useless cost.

## RustCFML and the Adobe story

Two engine-specific notes worth knowing:

- **RustCFML** ships `bcryptHash()`/`bcryptVerify()` as *native builtins*. Wheels detects that at boot and skips its own definitions, so the same API is served by the engine's native implementation there — and `bcryptNeedsRehash()` (which no engine has) is always the CFML one.
- Getting the pure-CFML core correct on **Adobe CF 2023** required fixing three genuinely Adobe-shaped bugs: bit functions reject operands above 2³¹−1, `mod` and `BitSHRN` coerce their operands in ways Lucee doesn't, and — the sneaky one — Adobe passes arrays *by value*, which silently discarded every mutation the key schedule made to the P/S arrays. The result was "hashes that computed, but wrongly." The fix made the key schedule return its state instead of relying on by-reference mutation, and the full BcryptSpec now passes on Adobe's matrix leg.

## Migrating from PBKDF2

If you generated auth scaffolding in 4.0.6, you have a `User` model with `PasswordHasher`-style PBKDF2 logic. Moving to bcrypt is a two-step dance:

1. **New passwords** go through `bcryptHash()`.
2. **Existing hashes** keep verifying through your old routine until the user next logs in, at which point you re-hash with bcrypt and store the new value.

There's no framework migration tool for this, and there shouldn't be — you're replacing a stored secret's format, which is the kind of thing that deserves a code review, not a generator.

If you've never generated auth and just want the helpers, they're already in scope in every Wheels 4.1 app: `bcryptHash`, `bcryptVerify`, `bcryptNeedsRehash`, no configuration required.
