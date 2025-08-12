# Wheels Directory Structure Guide

Understanding the Wheels directory structure is essential whether you're building applications or [contributing](https://github.com/wheels-dev/wheels) to the framework itself.

## Two Structures for Different Workflows

Wheels uses different directory layouts depending on your role:

**Application Development:** A streamlined structure optimized for building applications, available through ForgeBox or the CLI.

**Framework Development:** A comprehensive monorepo structure that includes development tools, tests, and documentation for framework contributors.

Both structures serve specific purposes, and understanding each will help you work more effectively with Wheels.

---

## Application Development Structure

When you create a new Wheels application using `wheels new` or download from [ForgeBox](https://forgebox.io/view/wheels-core), you'll work with this focused project structure:

```
app/
  controllers/
    Controller.cfc
  events/
  global/
  migrator/
    migrations/
  models/
    Model.cfc
  plugins/
  views/
config/
public/
  files/
  images/
  javascripts/
  stylesheets/
  miscellaneous/
    Application.cfc
  urlrewrite.xml
  Application.cfc
  index.cfm
tests/
  TestBox/
vendor
```

### Core Application Directories

**app/controllers/** - Contains your controller files with a base `Controller.cfc` file already present. Place shared controller methods in `Controller.cfc` since all controllers inherit from this base class.

**app/models/** - Houses your model files, typically one per database table. The existing `Model.cfc` file serves as the base class for all models and should contain shared model functionality.

**app/views/** - Stores your view templates, organized by controller (e.g., views for the `Users` controller go in `app/views/users/`). This is where you prepare content for your users.

**app/events/** - Contains event handlers that respond to ColdFusion application events, providing a cleaner alternative to placing code directly in `Application.cfc`.

**app/global/** - Holds globally accessible functions available throughout your application.

**app/plugins/** - Contains downloaded Wheels plugins that extend your application's functionality.

**Database Management** - Use the migration system (`wheels db migrate`) rather than manual SQL scripts for database schema changes.

**Package Management** - Use CommandBox and the `box.json` file to manage dependencies. The `vendor/` directory contains installed packages and should be excluded from version control.

**Local Development** - Configure your development environment using `server.json` for server settings and `.env` for environment variables. Never commit sensitive data in `.env` files to version control.

### Configuration and Assets

**config/** - All configuration changes should be made here. Set environments, routes, and other application settings. Individual setting files in subdirectories can override main configuration.

**public/files/** - Files intended for delivery to users via the `sendFile()` function should be placed here. Also serves as general file storage.

**public/images/** - Recommended location for image assets. While not required, Wheels functions involving images assume this conventional location.

**public/javascripts/** - Recommended location for JavaScript files.

**public/stylesheets/** - Recommended location for CSS files.

**public/miscellaneous/** - Special directory for code that must run completely outside the framework. Contains an empty `Application.cfc` that prevents Wheels involvement. Ideal for Flash AMF binding or `<cfajaxproxy>` connections to CFCs.

### System Files and Testing

**app/migrator/migrations** - Database [migration](https://wheels.dev/3.0.0/guides/command-line-tools/cli-guides/migrations) CFC files.

**tests/TestBox/** - Location for your application's unit tests.

**public/urlrewrite.xml** - Required for Tomcat/Tuckey or CommandBox URL rewriting.

**public/Application.cfc** and **public/index.cfm** - Framework bootstrap files. Do not modify these files.

---

## Framework Development Structure

Contributors working on the Wheels framework itself will encounter this comprehensive repository structure:

```
cli/
core/
  src/
    wheels/
design_docs/
docs/
examples/
templates/
  base/
    src/
      app/
      config/
      public/
      tests/
      vendor/
      .env
      box.json
      server.json
test-artifacts/
tests/
tools/
.cfformat.json
.editorconfig
CFConfig.json
CHANGELOG.md
compose.yml
```

### Framework Development Components

**cli/** - Source code for command-line interface tools including generators and database migration utilities.

**core/src/wheels/** - The core Wheels framework code. This is the actual framework that gets distributed. When new versions are released, this directory often contains all necessary updates.

**design_docs/** - Architecture documentation, design decisions, and planning materials explaining the framework's structural choices.

**docs/** - Official documentation in Markdown format, synchronized with the public website at [wheels.dev](https://wheels.dev/).

**examples/** - Sample applications demonstrating various Wheels features, useful for testing framework changes in realistic scenarios.

**/** - The exact application template structure that developers receive when creating new projects. This mirrors the application development structure described above and includes essential configuration files like `box.json`, `server.json`, and `.env`.

**vendor/** - Third-party dependencies and packages used by the framework development environment. Contains libraries managed through CommandBox/ForgeBox package management.

**test-artifacts/** - Files generated during test suite execution, typically excluded from version control.

**tests/** - Complete TestBox test suite for framework validation and regression testing.

**tools/** - Build scripts, Docker configurations, and development utilities for maintaining the framework.

Configuration files (`.cfformat.json`, `.editorconfig`, `CFConfig.json`) maintain consistent development standards across contributor environments.

---

## Key Directory Relationships

### Application Context

When working on applications, your primary focus areas are:

- **Configuration:** `config/` directory for all settings
- **Application Logic:** `app/controllers/`, `app/models/`, `app/migrator/migrations`, `app/views/`, and `app/events/`
- **Static Assets:** `public/files/`, `public/images/`, `public/javascripts/`, and `public/stylesheets/`
- **Extensions:** `app/plugins/` for third-party functionality

### Framework Context

The `/` folder in the framework repository becomes the root directory of every new Wheels application. When contributing to the framework:

- Work primarily in `core/src/wheels/` for framework code
- Update `docs/` for documentation changes
- Test changes using applications in `/` or `examples/`
- Use `tests/` for framework testing

---

## Directory Customization

You can add additional directories to your application structure. When doing so:

- Include a blank `Application.cfc` file in custom directories to prevent Wheels from processing requests in those locations
- Follow the established naming conventions for consistency
- Consider whether new directories belong in `public/` (web-accessible) or `app/` (application logic)

---

## Guidelines for Contributors

**Environment Setup** - Use the provided `compose.yml` file to test changes across multiple CFML engines, ensuring broad compatibility.

**Testing Requirements** - Execute the complete test suite located in `/tests` before submitting pull requests to prevent regressions.

**Code Standards** - Follow the formatting rules defined in `.cfformat.json`. Most development environments can automatically apply these standards.

**Documentation Updates** - Update relevant documentation in `/docs` when adding features or modifying existing behavior.

**CLI Development** - When working on command-line tools, ensure corresponding documentation updates in `/docs/command-line-tools`.

---

## Guidelines for Application Developers

**Configuration First** - Begin development by setting up routes, environments, and database connections in the `config/` directory.

**MVC Architecture** - Organize code according to the Model-View-Controller pattern that the directory structure supports:
  
- Controllers handle requests and coordinate between models and views
- Models manage data and business logic
- Views present information to users

**Asset Organization** - Use the conventional `public/` subdirectories for different asset types. This ensures Wheels functions work as expected and maintains project organization.

**Plugin Integration** - Evaluate existing plugins in `app/plugins/` before developing custom solutions.

**Database Management** - Use the migration system (`wheels db migrate`) rather than manual SQL scripts for database schema changes.

**Package Management** - Use CommandBox and the `box.json` file to manage dependencies. The `vendor/` directory contains installed packages and should be excluded from version control.

**Local Development** - Configure your development environment using `server.json` for server settings and `.env` for environment variables. Never commit sensitive data in `.env` files to version control.

**Testing Strategy** - Implement unit tests in `tests/TestBox/` to ensure application reliability.

---

This directory structure reflects years of framework development and community feedback. Each directory serves a specific purpose that supports either application development or framework contribution. The clear separation between public assets, application logic, and configuration ensures maintainable and scalable Wheels applications.
