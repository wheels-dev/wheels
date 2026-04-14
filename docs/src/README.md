---
description: Install Wheels and get a local development server running
---

# Getting Started

The quickest way to get started with Wheels is with a single install command. The `wheels` CLI gives you project scaffolding, code generation, database migrations, testing, and a built-in development server — all in one tool.

If you're already using [CommandBox](https://www.ortussolutions.com/products/commandbox), it continues to work with Wheels. See the [alternative setup with CommandBox](#alternative-setup-with-commandbox) section below, or the full [Migration Guide](command-line-tools/cli-guides/migration-from-commandbox.md) for a detailed comparison.

## Install Wheels CLI

```bash
# macOS
brew tap wheels-dev/wheels
brew install wheels

# Windows
choco install wheels
```

Verify the installation:

```bash
wheels --version
```

You should see the Wheels version and banner. Java 21 is installed automatically as a dependency.

## Create Your First Application

### Using the Wizard (Recommended)

The interactive wizard walks you through project setup options — template selection, database configuration, and more:

```bash
wheels new
```

Follow the prompts to configure your application. For your first project, the defaults work well.

### Using the Command Line

If you prefer a single command, use `wheels generate app` (or the shorthand `wheels g app`):

```bash
wheels generate app myApp
cd myApp
```

This scaffolds a complete Wheels application with:

- The standard MVC directory structure (`app/controllers/`, `app/models/`, `app/views/`)
- Configuration files (`config/settings.cfm`, `config/routes.cfm`)
- An embedded H2 database (ready to use, no setup needed)
- The Wheels framework in `vendor/wheels/`

{% hint style="info" %}
**Command Aliases**

`generate` can be shortened to `g`, so `wheels generate app` and `wheels g app` are identical. LuCLI also supports shorthand aliases for common generators: `m` (model), `c` (controller), `v` (view), `s` (scaffold).
{% endhint %}

## Start the Development Server

From your application directory, start the embedded Lucee server:

```bash
wheels start
```

A browser window will open automatically, showing the Wheels congratulations screen:

![Figure: Wheels congratulations screen](/wheels/guides-assets/a1f5810-Screen\_Shot\_2022-03-25\_at\_8.59.25\_AM.png)

The server runs on a local port (shown in the terminal output). Your application code is served from the `public/` directory, and code changes are reflected immediately — no restart needed.

To stop the server:

```bash
wheels stop
```

## Build a Feature

Let's create a simple blog post resource to see the full development workflow.

### 1. Generate a Scaffold

A scaffold creates the model, controller, views, migration, and tests all at once:

```bash
wheels generate scaffold Post title:string body:text published:boolean
```

### 2. Run the Migration

Apply the database migration to create the `posts` table:

```bash
wheels migrate latest
```

### 3. Add Routes

Open `config/routes.cfm` and add a resource route for posts. Place it before the wildcard route:

```cfm
mapper()
    .resources("posts")
    .wildcard()
    .root(to="wheels##congratulations", method="get")
.end();
```

### 4. Reload and Visit

Reload the application to pick up the new routes:

```bash
wheels reload
```

Visit `http://localhost:<port>/posts` in your browser. You now have a working CRUD interface for blog posts — list, create, edit, and delete — all generated from a single command.

## Run Tests

Wheels generates test files alongside your code. Run them with:

```bash
wheels test
```

To run tests for a specific area:

```bash
wheels test --filter=models
```

## Project Structure

Here's what `wheels generate app` created:

```
myApp/
├── lucee.json              # Server and project configuration
├── config/
│   ├── settings.cfm        # Framework settings (datasource, reload password)
│   ├── routes.cfm          # URL routes
│   ├── app.cfm             # Application configuration
│   └── environment.cfm     # Environment detection
├── app/
│   ├── controllers/        # Request handlers
│   ├── models/             # Database-backed objects
│   ├── views/              # HTML templates
│   │   └── layout.cfm      # Default page layout
│   ├── migrator/           # Database migrations
│   │   └── migrations/
│   └── events/             # Application event handlers
├── public/                 # Web root (static assets, entry point)
├── tests/                  # Test files
└── vendor/                 # Framework and dependencies
    └── wheels/
```

**Key files to know:**

| File | Purpose |
|------|---------|
| `config/settings.cfm` | Datasource name, reload password, framework settings |
| `config/routes.cfm` | URL routing — maps URLs to controller actions |
| `lucee.json` | Server port, JVM settings, Lucee mappings |
| `app/views/layout.cfm` | HTML layout wrapping all views |

## Configure a Database

New applications come with an embedded H2 database that works out of the box. When you're ready to use MySQL, PostgreSQL, or another database:

1. **Set the datasource name** in `config/settings.cfm`:

```cfm
set(dataSourceName="myapp_dev");
```

2. **Define the datasource connection** in `config/app.cfm`:

```cfm
this.datasources["myapp_dev"] = {
    class: "com.mysql.cj.jdbc.Driver",
    connectionString: "jdbc:mysql://localhost:3306/myapp_dev",
    username: "root",
    password: ""
};
```

3. **Run migrations** to create your tables:

```bash
wheels migrate latest
```

See the [Hello Database](introduction/readme/beginner-tutorial-hello-database.md) tutorial for a complete walkthrough of database interaction.

## Set Up AI-Assisted Development

The Wheels CLI includes a built-in MCP server that integrates with AI editors like Claude Code, Cursor, and VS Code Copilot. This gives your AI assistant direct access to Wheels commands — generating code, running migrations, and running tests.

For Claude Code, add this to your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "wheels": {
      "command": "wheels",
      "args": ["mcp"]
    }
  }
}
```

Once configured, your AI editor can use tools like `wheels_generate`, `wheels_migrate`, and `wheels_test` directly.

## Deploy to Production

When you're ready to deploy your Wheels application:

1. **Set the environment** to production in `config/environment.cfm` or via your server's configuration.

2. **Configure a production datasource** in `config/production/settings.cfm`:

```cfm
set(dataSourceName="myapp_production");
set(reloadPassword="a-strong-secret");
```

3. **Run migrations** on the production database:

```bash
wheels migrate latest
```

4. **Deploy your code** to a Lucee or Adobe ColdFusion server. Wheels runs on any CFML engine behind Apache, Nginx, IIS, or Tomcat. See the [Requirements](introduction/requirements.md) page for supported engines and databases.

{% hint style="info" %}
**Docker Deployment**

For containerized deployments, use `wheels docker init` to generate a `Dockerfile` and `docker-compose.yml` tailored to your CFML engine and database. See [Running Local Development Servers](introduction/readme/running-local-development-servers.md) for details.
{% endhint %}

## Next Steps

You now have a working Wheels application with a database-backed feature, tests, and a development server. Here's where to go next:

- **[Hello World Tutorial](introduction/readme/beginner-tutorial-hello-world.md)** — Build a controller and view from scratch to understand the MVC fundamentals
- **[Hello Database Tutorial](introduction/readme/beginner-tutorial-hello-database.md)** — Create a full CRUD application with forms, validations, and database interaction
- **[Conventions](working-with-wheels/conventions.md)** — Learn the naming conventions that make Wheels productive
- **[Routing](handling-requests-with-controllers/routing.md)** — Define URL patterns for your application
- **[CLI Command Reference](command-line-tools/commands/README.md)** — Explore all available commands

## Alternative Setup with CommandBox

[CommandBox](https://www.ortussolutions.com/products/commandbox) is a full-featured CFML toolbox that also works with Wheels. It offers additional capabilities like ForgeBox package management and support for both Lucee and Adobe ColdFusion servers.

### Install CommandBox

```bash
# macOS
brew install commandbox

# Windows
choco install commandbox
```

### Install the Wheels CLI Module

```bash
box install wheels-cli
```

### Create and Start an Application

```bash
wheels new myApp
cd myApp
box server start
```

### Command Differences

The daily workflow is nearly identical. The key differences:

| Task | Wheels CLI | CommandBox |
|------|-----------|-----------|
| Install | `brew install wheels` | `brew install commandbox` + `box install wheels-cli` |
| Start server | `wheels start` | `box server start` |
| Run migrations | `wheels migrate latest` | `wheels dbmigrate latest` |
| Run tests | `wheels test` | `wheels test run` |
| Config file | `lucee.json` | `box.json` + `server.json` |
| MCP server | `wheels mcp` | Not available |

For a complete mapping of all commands, see the [Migration Guide](command-line-tools/cli-guides/migration-from-commandbox.md).
