# Tweet: a small Wheels example app

A Twitter-style demo built with [Wheels](https://wheels.dev): sign up, log in, post short messages, like them, and follow other users. It shows the everyday Wheels pieces working together:

- models with associations and validations (`User`, `Tweet`, `Like`, `Follow`);
- RESTful resources plus a few named routes (`config/routes.cfm`);
- session-based sign-in (`Sessions` / `Users` controllers);
- migrations for the whole schema (`app/migrator/migrations/`);
- views styled with Tailwind CSS and Alpine.js, loaded from a CDN in `app/views/layout.cfm`.

The app runs on an embedded H2 database, so there's no database server to set up.

## Run it

You need [CommandBox](https://www.ortussolutions.com/products/commandbox).

1. Install the framework into `vendor/wheels/`:

   ```bash
   box install
   ```

2. Start the server:

   ```bash
   box server start
   ```

   `server.json` declares the H2 Lucee extension, so CommandBox installs it on first start. The database files are created under `db/h2/`.

3. Create the schema. Open `/wheels/migrator` on the running site (the development-mode migrator) and click **Migrate To Latest**. That creates the `users`, `tweets`, `likes` and `follows` tables.

   `wheels migrate latest` from the Wheels CLI only works against a server started with `wheels start`, not against a CommandBox server, so use the browser migrator here.

4. Open the site, choose **Sign up**, create an account, and post your first tweet.

## Tests

With the server running, open `/wheels/app/tests` to run the app's specs (`tests/specs/`).
