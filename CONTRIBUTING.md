# Contributing to Wheels

A warm welcome and a huge thank you for considering contributing to Wheels!
It's the people in our community who make this framework what it is. Whether you're fixing a bug, adding a feature, improving documentation, or helping in discussions, your effort matters.

These guidelines are here to make the contribution process clear, smooth, and respectful for everyone. They also let you know what you can expect from the maintainers in return — timely responses, thoughtful reviews, and support to help you get your changes merged.

---

## Quick Links

* [Code of Conduct](#code-of-conduct)
* [Developer Certificate of Origin (DCO)](#developer-certificate-of-origin-dco)
* [Getting Started](#getting-started)
  * [Development Environment Setup](#development-environment-setup)
  * [Issues](#issues)
  * [Pull Requests](#pull-requests)
  * [Testing](#testing)
  * [Developing with Docker](#developing-with-docker)
* [Project Structure](#project-structure)
* [Technical Requirements](#technical-requirements)
* [Getting Help](#getting-help)

---

## Code of Conduct

We value an open, welcoming, and respectful community. By participating in Wheels projects, you agree to follow our [Code of Conduct](https://github.com/wheels-dev/wheels/blob/develop/CODE_OF_CONDUCT.md). This applies to all community spaces, including GitHub, forums, and events.

---

## Developer Certificate of Origin (DCO)

Wheels uses the [Developer Certificate of Origin](https://developercertificate.org/) (DCO) for all contributions. The DCO is a lightweight, per-commit attestation that you have the right to submit the work you're contributing. It's a simpler alternative to a Contributor License Agreement (CLA) and is the same model used by the Linux kernel, Docker, and GitLab.

By signing off on a commit, you certify that:

> 1. The contribution was created in whole or in part by you and you have the right to submit it under the open source license indicated in the file; or
> 2. The contribution is based upon previous work that is covered by an appropriate open source license and you have the right under that license to submit that work with modifications; or
> 3. The contribution was provided directly to you by some other person who certified (1), (2), or (3); and you have not modified it.
> 4. You understand and agree that this project and the contribution are public and that a record of the contribution (including all personal information you submit with it) is maintained indefinitely.

Read the [full DCO text](https://developercertificate.org/) for the authoritative wording.

### How to sign off

Add a `Signed-off-by:` trailer to every commit. The easiest way is `git commit -s`, which appends the trailer automatically using your configured `user.name` and `user.email`:

```bash
git commit -s -m "fix(model): handle null in validatesPresenceOf"
```

The resulting commit message looks like this:

```
fix(model): handle null in validatesPresenceOf

Signed-off-by: Jane Contributor <jane@example.com>
```

The name and email **must match** the identity you use on GitHub. Anonymous or pseudonymous sign-offs are not accepted.

### Forgot to sign off?

If you've already pushed a branch without sign-offs, you can amend the last commit:

```bash
git commit --amend -s --no-edit
git push --force-with-lease
```

For multiple unsigned commits, rebase and add sign-off to each:

```bash
git rebase --signoff develop
git push --force-with-lease
```

### Enforcement

The [DCO GitHub App](https://github.com/apps/dco) runs as a required status check on every PR. It verifies that every commit in the PR carries a valid `Signed-off-by:` trailer and blocks merge if any are missing. The app comments on the PR with a fixup suggestion when it finds an unsigned commit.

### Grandfathering

The DCO is enforced on **new PRs only**. Commits authored before DCO adoption are grandfathered and do not need to be retroactively signed.

---

## Getting Started

Wheels 3.0 is now maintained in a **monorepo** at [wheels-dev/wheels](https://github.com/wheels-dev/wheels). This single repository contains the framework core, CLI, documentation, and examples, making it easier for contributors to work across the project.

We welcome contributions via **Issues** and **Pull Requests (PRs)**. Before you start:

* If it's a **security issue**, please use our [Responsible Disclosure Program](mailto:webmaster@wheels.dev?subject=Responsible%20Disclosure%20Program) — do not post it publicly.
* Search existing Issues and PRs to avoid duplicates.
* If your issue is urgent or blocking, you can leave a polite comment pinging the maintainers.
* If you're new to contributing, check out the [Contributing to Wheels Guide](https://wheels.dev/3.1.0/guides/working-with-wheels/contributing-to-wheels) for tips and examples.

### Development Environment Setup

**Quick Start (recommended):**

```bash
git clone https://github.com/wheels-dev/wheels.git
cd wheels
bash tools/scripts/setup.sh
```

This single command checks prerequisites, starts a MySQL container, installs dependencies via CommandBox, and verifies the environment. Run `bash tools/scripts/setup.sh --help` for options including `--full` (all databases) and `--docker` (no local CommandBox needed).

**System Requirements:**

* Docker and Docker Compose
* Adobe ColdFusion 2018/2021/2023/2025 OR Lucee 5/6/7
* CommandBox (optional with `--docker` mode)
* Supported database: H2, Microsoft SQL Server, PostgreSQL, MySQL, Oracle, SQLite
* Git for version control

**Initial Setup:**
In general, we follow the ["fork-and-pull" Git workflow](https://github.com/susam/gitpr)

1. Fork the [wheels-dev/wheels](https://github.com/wheels-dev/wheels) repository to your own Github account
2. Clone the project to your machine
3. Run `bash tools/scripts/setup.sh` to set up your dev environment
4. Create a branch locally with a succinct but descriptive name
5. Commit changes to the branch with `git commit -s` to add the required [DCO sign-off](#developer-certificate-of-origin-dco)
6. Following the formatting and testing guidelines
7. Push changes to your fork
8. Open a PR in the [wheels-dev/wheels](https://github.com/wheels-dev/wheels) repository and follow the PR template so that we can efficiently review the changes.

---

### Issues

Use Issues to:

* Report bugs (include CFML engine version, database type/version, and HTTP server details)
* Request features
* Discuss potential changes before starting a PR

**Good First Issues:** Look for issues labeled `good-first-issue` or `help-wanted` if you're new to the codebase.

If you find an existing Issue that matches your problem:

* Add any extra details or reproduction steps
* Add a [reaction](https://github.blog/2016-03-10-add-reactions-to-pull-requests-issues-and-comments/) to show it affects others, this helps maintainers prioritize

---

### Pull Requests

We welcome PRs of all sizes — from typo fixes to major features. To make reviews smooth:

**Branch Naming Conventions:**

* `fix/issue-number-short-description` (e.g., `fix/1234-oracle-orm-bug`)
* `feature/short-description` (e.g., `feature/improved-error-handling`)
* `docs/short-description` (e.g., `docs/update-installation-guide`)

**PR Guidelines:**

* Keep your PR focused on one thing. If you're fixing a bug, don't also reformat unrelated files.
* Add unit or integration tests when changing functionality.
* Include relevant documentation updates under `/docs` if needed.
* Follow the repo's formatting guidelines (see `.cfformat.json` and `.editorconfig`).
* Write clear, descriptive commit messages.

**Code Style:**

* Follow the project's `.cfformat.json` configuration
* Respect the `.editorconfig` settings for consistent formatting
* Use meaningful variable and function names
* Add comments for complex logic

**Definition of Done:**

A feature or enhancement is not complete until all of the following are satisfied:

* **Tests** -- Unit tests covering happy path, edge cases, and error conditions in `vendor/wheels/tests/specs/`
* **Framework Docs** -- New or updated MDX page under `web/sites/guides/src/content/docs/v4-0-0-snapshot/` with a matching sidebar entry
* **AI Reference Docs** -- New or updated file in `.ai/wheels/` so AI assistants have accurate context
* **CLAUDE.md** -- Updated if the feature changes model, controller, or view conventions
* **CHANGELOG.md** -- Entry under the `[Unreleased]` section
* **Test runner passes** -- All existing tests still pass (`/wheels/app/tests?format=json`)

Bug-fix PRs require tests and a CHANGELOG entry at minimum. Documentation-only PRs are exempt from the test requirement.

If you're making a **breaking change** or working on **core functionality**, it's best to open an Issue first to discuss the approach.

**Fork-and-Pull Workflow:**

1. Fork the repo to your GitHub account
2. Clone it locally
3. Create a descriptive branch name
4. Make your changes
5. Run tests and check formatting
6. Commit with `git commit -s` to add the required [DCO sign-off](#developer-certificate-of-origin-dco)
7. Push to your fork
8. Open a PR to `wheels-dev/wheels` and follow the PR template

**Review Process:**

* Expect initial feedback within 3-5 business days
* Be prepared to make revisions based on maintainer feedback
* PRs require approval from at least one maintainer before merging

---

### Testing

**Running Tests:**

1. Ensure all debugging is turned OFF in your CFML engine
2. Navigate to the Wheels Welcome Page in your browser
3. In the navigation bar, click "Tests > Run Core Tests"

**Test Database Requirements:**

* Supported engines: H2, Microsoft SQL Server, PostgreSQL, MySQL, Oracle, SQLite

**Writing Tests:**

* Use WheelsTest for new test cases
* Place tests in the appropriate `/tests` directory
* Follow existing test patterns and naming conventions
* Include both positive and negative test cases

---

### Developing with Docker

You can develop and test Wheels locally on multiple CFML engines using Docker.
Follow the [Docker Instructions](https://wheels.dev/3.1.0/guides/working-with-wheels/contributing-to-wheels#developing-with-docker) to get set up quickly.

---

## Project Structure

Understanding the monorepo structure will help you navigate contributions:

**Key Directories:**

* `/cli/` — Wheels CLI tool
* `/core/` — Framework core code (main contribution area)
* `/docs/` — API documentation and guides
* `/examples/` — Sample applications
* `/templates/` — Scaffolding templates for new apps
* `/tests/` — WheelsTest test suites
* `/tools/` — Build scripts, Docker configs, utilities

**Important Files:**

* `.cfformat.json` — Code formatting rules
* `.editorconfig` — Editor configuration
* `CONTRIBUTING.md` — This document
* `CHANGELOG.md` — Release history

---

## Technical Requirements

**Dependencies:**
Wheels 3.0 includes these core dependencies (automatically managed):

* **wheelsdi** — Dependency injection and object management (in-house; formerly WireBox)
* **WheelsTest** — Testing framework (in-house; formerly TestBox)

**Database Support:**

* SQLite (new in 3.0)
* Oracle (new in 3.0)
* Microsoft SQL Server
* PostgreSQL  
* MySQL
* H2

**CFML Engine Compatibility:**

* Adobe ColdFusion 2018+ (2018,2021,2023,2025)
* Lucee 5+ (5,6,7)
* ❌ Adobe ColdFusion 2016 (deprecated)

---

## Wheels Bot

Issues and PRs on this repo are processed by an automated Claude-powered bot
(`wheels-bot[bot]`). Five stages: triage, cross-framework research,
propose-fix, Reviewer A, Reviewer B. See
[`docs/contributing/wheels-bot.md`](docs/contributing/wheels-bot.md) for the
full reference, or [`CLAUDE.md`](CLAUDE.md#wheels-bot) for a quick summary.

**To opt a single issue or PR out of bot activity**: add the `[skip-claude]`
label, or include `[skip-claude]` in the title. The bot will halt all
processing for that issue/PR immediately. Any human comment to the bot
asking it to stop is also honored.

**To interpret bot output**: every bot comment / review opens with a clear
H2 header (`## Wheels Bot — Triage`, `## Wheels Bot — Reviewer A`, etc.) and
ends with an HTML-comment marker. Bot-authored draft PRs are clearly
labelled and require a human approving review on `develop` before merge.

## Getting Help

Need assistance? Here are your options:

* **Community Discussion:** [Wheels GitHub Discussions](https://github.com/wheels-dev/wheels/discussions)
* **Documentation:** [wheels.dev](https://wheels.dev/guides)
* **Issue Tracker:** [GitHub Issues](https://github.com/wheels-dev/wheels/issues)

When asking for help:

* Use clear, descriptive titles
* Include your CFML engine and version
* Provide code examples or error messages
* Mention what you've already tried

---

💡 **New to Wheels 3.0?** The framework now uses a monorepo architecture with wheelsdi and WheelsTest as core components. The directory structure has been modernized with `/app`, `/public`, and `/vendor` directories. Take time to explore these changes.

**Thank you for contributing to Wheels!**