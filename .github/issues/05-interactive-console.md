# [Feature] Interactive Console / REPL (`wheels console`)

**Priority:** #5 — Essential developer tool
**Labels:** `enhancement`, `feature-request`, `developer-experience`

## Summary

Add a `wheels console` command that boots the Wheels application and provides an interactive REPL (Read-Eval-Print Loop) where developers can run model queries, test code snippets, inspect data, and debug issues — all without writing a controller action or refreshing a browser.

## Justification

### Every major framework has an interactive console

| Framework | Console | Key Features |
|-----------|---------|--------------|
| **Laravel** | `php artisan tinker` | PsySH-based, auto-imports models, query inspection |
| **Rails** | `rails console` | IRB/Pry, full app context, sandbox mode |
| **Django** | `python manage.py shell` | IPython support, auto-imports, `shell_plus` |
| **Phoenix** | `iex -S mix` | Elixir REPL with full app context |
| **AdonisJS** | `node ace repl` | REPL with model loading, query inspection |
| **Wheels** | **Nothing** | Must create throw-away controller actions or use the test runner |

### The development workflow gap

Without a console, Wheels developers who want to quickly:
- Test a model query → Must create a controller action, reload the app, hit the URL
- Check if a validation works → Must write a test or submit a form
- Inspect database data → Must open a separate database client
- Experiment with associations → Must write code, reload, test, repeat

This friction adds up to significant lost productivity throughout a development day. A REPL provides **instant feedback** — type a query, see results immediately.

### Debugging without a console is slow

When a bug report comes in, developers need to:
1. Reproduce the state
2. Query the database to understand the data
3. Test potential fixes

With a console: `model("User").findByKey(42)` → instant answer. Without: write a controller, reload, navigate to URL, read the output, delete the controller.

## Specification

### Basic Usage

```bash
$ wheels console

Wheels Console v3.2 (development)
Connected to: myapp_dev (MySQL)
Type 'help' for commands, 'exit' to quit.

wheels> model("User").findAll(maxRows=3)
╔════╦═══════════════════╦═══════════╦════════╗
║ id ║ email             ║ firstName ║ role   ║
╠════╬═══════════════════╬═══════════╬════════╣
║  1 ║ admin@example.com ║ Admin     ║ admin  ║
║  2 ║ jane@example.com  ║ Jane      ║ member ║
║  3 ║ bob@example.com   ║ Bob       ║ member ║
╚════╩═══════════════════╩═══════════╩════════╝
3 records returned (12ms)

wheels> user = model("User").findByKey(1)
=> User#1 (admin@example.com)

wheels> user.orders().count()
=> 7

wheels> user.valid()
=> true

wheels> user.email = ""
wheels> user.valid()
=> false

wheels> user.allErrors()
=> [{property: "email", message: "Email can't be blank"}]
```

### Console Modes

```bash
# Standard mode (reads and writes)
wheels console

# Sandbox mode (all changes rolled back on exit)
wheels console --sandbox
# Wraps entire session in a transaction that rolls back

# Production mode (requires confirmation)
wheels console --environment=production
# WARNING: You are connecting to PRODUCTION. Type 'yes' to continue:
```

### Built-in Commands

```
wheels> help

Available commands:
  model("Name")          - Access any model
  reload                 - Reload the application
  routes                 - Display all routes
  schema("tableName")    - Show table schema
  sql("SELECT ...")      - Run raw SQL
  inspect(variable)      - Pretty-print any variable
  benchmark { code }     - Time code execution
  clear                  - Clear the screen
  history                - Show command history
  exit / quit            - Exit console
```

### Query Result Formatting

```bash
# Queries displayed as formatted tables
wheels> model("Product").findAll(where="price > 50", order="price DESC", maxRows=5)
╔════╦═══════════════╦═══════╦══════════╗
║ id ║ name          ║ price ║ category ║
╠════╬═══════════════╬═══════╬══════════╣
║ 12 ║ Premium Widget║ 99.99 ║ widgets  ║
║  7 ║ Deluxe Gadget ║ 79.50 ║ gadgets  ║
║  3 ║ Pro Thingamaj ║ 64.99 ║ things   ║
╚════╩═══════════════╩═══════╩══════════╝
3 records returned (8ms)

# Single objects displayed as key-value pairs
wheels> model("User").findByKey(1)
User#1:
  email:           admin@example.com
  firstName:       Admin
  lastName:        User
  role:            admin
  status:          active
  createdAt:       2025-01-15 10:30:00
  updatedAt:       2025-03-01 14:22:00
```

### Implementation Approach

The console needs to:

1. **Boot the Wheels application** — Initialize the framework, load models, connect to database
2. **Accept CFML input** — Parse and evaluate CFML expressions
3. **Format output** — Pretty-print queries as tables, objects as key-value pairs
4. **Handle multiline input** — Support code blocks that span multiple lines
5. **Maintain state** — Variables persist across commands within a session

#### Technical Options

**Option A: CommandBox Integration (Recommended)**
- Extend the existing `wheels` CLI (which runs on CommandBox)
- Use CommandBox's CFML runtime to evaluate expressions
- Leverage existing Lucee/BoxLang CFML evaluation capabilities
- `evaluate()` function with app context loaded

**Option B: HTTP-Based REPL**
- Console sends commands to a running Wheels server via HTTP
- Server-side endpoint evaluates and returns results
- Works with any CFML engine
- Requires a running server instance

**Option C: Hybrid**
- Direct CFML evaluation for simple queries (Option A)
- HTTP bridge for complex operations requiring full request lifecycle

### Files Generated / Modified

| Component | File | Purpose |
|-----------|------|---------|
| **CLI command** | `wheels/cli/console.cfc` | CommandBox command for `wheels console` |
| **Evaluator** | `wheels/console/Evaluator.cfc` | CFML expression evaluation with app context |
| **Formatter** | `wheels/console/Formatter.cfc` | Query/object pretty-printing |
| **History** | `wheels/console/History.cfc` | Command history persistence |
| **Sandbox** | `wheels/console/Sandbox.cfc` | Transaction-wrapped sandbox mode |

## Impact Assessment

- **Developer productivity:** Instant feedback loop for queries, validations, and debugging
- **Learning curve:** New developers can explore models and data interactively
- **Debugging speed:** 10x faster data inspection vs. writing throw-away controllers
- **Framework perception:** Seen as a "must-have" by developers coming from Rails/Laravel/Django

## References

- Laravel Tinker: https://laravel.com/docs/artisan#tinker
- Rails Console: https://guides.rubyonrails.org/command_line.html#bin-rails-console
- Django Shell: https://docs.djangoproject.com/en/5.0/ref/django-admin/#shell
- AdonisJS REPL: https://docs.adonisjs.com/guides/repl
