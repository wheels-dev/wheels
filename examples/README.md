# Wheels Examples

Two example applications built with Wheels 4.x. Each has its own README with setup steps.

| App | What it shows | Database | Run it with |
|---|---|---|---|
| [Starter App](starter-app/) (`starter-app/`) | User management and authentication: registration with email verification, login, password reset, an admin panel with roles and permissions, and audit logging. Bootstrap 5 UI. | Embedded SQLite (H2 under CommandBox) | `wheels start`, or CommandBox |
| [Tweet](tweet/) (`tweet/`) | A small Twitter-style app: sign up, post, like and follow. Models with associations and validations, RESTful routes, session sign-in, and migrations. Tailwind CSS and Alpine.js from a CDN. | Embedded H2 | CommandBox |

## Starter App

The starter app is also published as a release zip (`wheels-starter-app-<version>.zip`) that includes the framework in `vendor/wheels/`. With the [Wheels CLI](https://guides.wheels.dev/) installed:

```bash
unzip wheels-starter-app-<version>.zip -d my-starter-app
cd my-starter-app
cp .env.example .env   # then set WHEELS_RELOAD_PASSWORD and WHEELS_LUCEE_ADMIN_PASSWORD
wheels start
wheels migrate latest
wheels reload
```

See [starter-app/README.md](starter-app/README.md) for the full walkthrough, running it under CommandBox, switching to a server-based database, and running its tests.

## Tweet

See [tweet/README.md](tweet/README.md). It runs under CommandBox (`box install`, then `box server start`), and you create its schema from the development-mode migrator at `/wheels/migrator`.

## More

- [Wheels Guides](https://guides.wheels.dev/): tutorials and reference for building your own app; `wheels new myapp` scaffolds a fresh one.
- [Wheels API Reference](https://api.wheels.dev/)

Have an example you'd like to share? See the [contributing guidelines](../CONTRIBUTING.md).
