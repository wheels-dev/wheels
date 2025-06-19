# wheels console

Start an interactive REPL console with Wheels application context loaded.

## Synopsis

```bash
wheels console [options]
```

## Description

The `wheels console` command starts an interactive Read-Eval-Print Loop (REPL) with your Wheels application context fully loaded. This allows you to interact with your models, run queries, test helper functions, and debug your application in real-time.

The console requires your Wheels server to be running as it connects via HTTP to maintain the proper application context.

## Options

### `environment`
- **Type:** String
- **Default:** `development`
- **Description:** Environment to load (development, testing, production)
- **Example:** `wheels console environment=testing`

### `execute`
- **Type:** String
- **Description:** Execute a single command and exit
- **Example:** `wheels console execute="model('User').count()"`

### `script`
- **Type:** Boolean
- **Default:** `true`
- **Description:** Use CFScript mode (false for tag mode)
- **Example:** `wheels console script=false`

### `directory`
- **Type:** String
- **Default:** Current working directory
- **Description:** Application directory
- **Example:** `wheels console directory=/path/to/app`

## Examples

### Basic Usage
```bash
# Start interactive console
wheels console

# Start in testing environment
wheels console environment=testing

# Execute single command
wheels console execute="model('User').findAll().recordCount"

# Start in tag mode
wheels console script=false
```

### Console Commands

Once in the console, you can use these special commands:

- `help` or `?` - Show help information
- `examples` - Show usage examples
- `script` - Switch to CFScript mode
- `tag` - Switch to tag mode
- `clear` or `cls` - Clear screen
- `history` - Show command history
- `exit`, `quit`, or `q` - Exit console

### Working with Models

```cfscript
// Find a user by ID
user = model("User").findByKey(1)

// Update user properties
user.name = "John Doe"
user.email = "john@example.com"
user.save()

// Create new user
newUser = model("User").create(
    name="Jane Smith",
    email="jane@example.com",
    password="secure123"
)

// Find users with conditions
activeUsers = model("User").findAll(
    where="active=1 AND createdAt >= '#dateAdd('d', -7, now())#'",
    order="createdAt DESC"
)

// Delete a user
model("User").deleteByKey(5)
```

### Using Helper Functions

```cfscript
// Text helpers
pluralize("person")  // Returns: "people"
singularize("users") // Returns: "user"
capitalize("hello world") // Returns: "Hello World"

// Date helpers
timeAgoInWords(dateAdd('h', -2, now())) // Returns: "2 hours ago"
distanceOfTimeInWords(now(), dateAdd('d', 7, now())) // Returns: "7 days"

// URL helpers
urlFor(route="user", key=1) // Generate URL for user route
linkTo(text="Home", route="root") // Generate link HTML
```

### Direct Database Queries

```cfscript
// Run custom SQL query
results = query("
    SELECT u.*, COUNT(p.id) as post_count 
    FROM users u 
    LEFT JOIN posts p ON u.id = p.userId 
    GROUP BY u.id
")

// Simple count query
userCount = query("SELECT COUNT(*) as total FROM users").total
```

### Inspecting Application State

```cfscript
// View application settings
application.wheels.environment
application.wheels.dataSourceName
application.wheels.version

// Check loaded models
structKeyArray(application.wheels.models)

// View routes (if available)
application.wheels.routes
```

## How It Works

1. The console connects to your running Wheels server via HTTP
2. Code is sent to a special console endpoint for execution
3. The code runs in the full application context with access to all models and helpers
4. Results are returned and displayed in the console
5. Variables persist between commands during the session

## Requirements

- Wheels server must be running (`wheels server start`)
- Server must be accessible at the configured URL
- Application must be in development, testing, or maintenance mode

## Troubleshooting

### "Server must be running to use console"
Start your server first:
```bash
wheels server start
wheels console
```

### "Failed to initialize Wheels context"
1. Check that your server is running: `wheels server status`
2. Verify the server URL is correct
3. Ensure your application is not in production mode

### Code execution errors
- Check syntax - console shows line numbers for errors
- Remember you're in CFScript mode by default
- Use `tag` command to switch to tag mode if needed

## Best Practices

1. **Use for debugging**: Test model methods and queries before implementing
2. **Data exploration**: Quickly inspect and modify data during development
3. **Testing helpers**: Verify helper function outputs
4. **Learning tool**: Explore Wheels functionality interactively
5. **Avoid in production**: Console should not be accessible in production mode

## Security Notes

- Console is only available in development, testing, and maintenance modes
- Never expose console access in production environments
- Be cautious when manipulating production data

## Related Commands

- [`wheels runner`](runner.md) - Execute script files
- [`wheels environment`](environment.md) - Manage environment settings
- [`wheels server start`](../server/server-start.md) - Start the server

## See Also

- [Wheels Model Documentation](../../../database-interaction-through-models/)
- [Wheels Helper Functions](../../../displaying-views-to-users/)