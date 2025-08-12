# db seed (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Generate and populate test data.

## Synopsis

```bash
wheels db seed [options]
```

## Description

The `db seed` command populates your database with test data. This is useful for development environments, testing scenarios, and demo installations. The command will generate sample data based on your models.

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `file` | string | No | "seed" | Path to seed file (without .cfm extension) |
| `environment` | string | No | current | Environment to seed |

## Examples

### Basic seeding (uses default seed file)
```bash
wheels db seed
```

### Use custom seed file
```bash
wheels db seed file=demo
```

### Seed specific environment
```bash
wheels db seed environment=testing
```

### Use seed file from subdirectory
```bash
wheels db seed file=development/users
```

## Seed File Location

Seed files should be placed in the `db/` directory of your application:

```
app/
  db/
    seed.cfm         # Default seed file
    demo.cfm         # Custom seed file
    development/     # Environment-specific seeds
      users.cfm
      products.cfm
```

## Seed File Structure

### Basic Seed File (`db/seed.cfm`)
```cfm
<cfscript>
// db/seed.cfm

// Create admin user
user = model("user").create(
    username = "admin",
    email = "admin@example.com",
    password = "password123",
    role = "admin"
);

// Create sample categories  
categories = [
    {name: "Electronics", slug: "electronics"},
    {name: "Books", slug: "books"},
    {name: "Clothing", slug: "clothing"}
];

for (category in categories) {
    model("category").create(category);
}

// Create sample products
electronicsCategory = model("category").findOne(where="slug='electronics'");

products = [
    {
        name: "Laptop",
        price: 999.99,
        category_id: electronicsCategory.id,
        in_stock: true
    },
    {
        name: "Smartphone", 
        price: 699.99,
        category_id: electronicsCategory.id,
        in_stock: true
    }
];

for (product in products) {
    model("product").create(product);
}

writeOutput("Seed data created successfully!");
</cfscript>
```

### Function-Based Seed Files
```cfm
// db/development/users.cfm
<cfscript>
// Admin users
admins = [
    {username: "admin", email: "admin@example.com", role: "admin"},
    {username: "moderator", email: "mod@example.com", role: "moderator"}
];

for (admin in admins) {
    admin.password = hash("password123");
    model("user").create(admin);
}

// Regular users
for (i = 1; i <= 50; i++) {
    model("user").create(
        username = "user#i#",
        email = "user#i#@example.com",
        password = hash("password123"),
        created_at = dateAdd("d", -randRange(1, 365), now())
    );
}

writeOutput("Created admin and sample users");
</cfscript>
```

## Use Cases

### Development Environment Setup
Create consistent development data:
```bash
# Reset and seed development database
wheels dbmigrate reset
wheels dbmigrate latest
wheels db seed
```

### Testing Data
Prepare test database:
```bash
# Seed test environment
wheels db seed environment=testing

# Run tests
wheels test run
```

### Demo Data
Create demonstration data:
```bash
# Load demo dataset
wheels db seed file=demo
```

### Multiple Seed Files
Organize seeds by purpose:
```bash
# Seed users
wheels db seed file=development/users

# Seed products
wheels db seed file=development/products
```

## Advanced Seeding Patterns

### Using Random Data
```cfm
<cfscript>
// Generate random users
firstNames = ["John", "Jane", "Bob", "Alice", "Charlie", "Diana"];
lastNames = ["Smith", "Johnson", "Williams", "Brown", "Jones"];
cities = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix"];

for (i = 1; i <= 100; i++) {
    model("customer").create(
        first_name = firstNames[randRange(1, arrayLen(firstNames))],
        last_name = lastNames[randRange(1, arrayLen(lastNames))],
        email = "customer#i#@example.com",
        city = cities[randRange(1, arrayLen(cities))],
        created_at = dateAdd("d", -randRange(1, 365), now())
    );
}
</cfscript>
```

### Relationship Seeding
```cfm
<cfscript>
// Create users
users = [];
for (i = 1; i <= 10; i++) {
    users.append(model("user").create(
        username = "user#i#",
        email = "user#i#@example.com"
    ));
}

// Create posts for each user
for (user in users) {
    postCount = randRange(5, 15);
    for (j = 1; j <= postCount; j++) {
        post = model("post").create(
            user_id = user.id,
            title = "Post #j# by #user.username#",
            content = "This is sample content for the post.",
            published_at = dateAdd("d", -randRange(1, 30), now())
        );
        
        // Add comments
        commentCount = randRange(0, 10);
        for (k = 1; k <= commentCount; k++) {
            randomUser = users[randRange(1, arrayLen(users))];
            model("comment").create(
                post_id = post.id,
                user_id = randomUser.id,
                content = "Comment #k# on post",
                created_at = dateAdd("h", k, post.published_at)
            );
        }
    }
}
</cfscript>
```

### Conditional Seeding
```cfm
<cfscript>
// Only seed if empty
if (model("user").count() == 0) {
    // Create initial users
    model("user").create(
        username = "admin",
        email = "admin@example.com",
        password = "password123"
    );
    writeOutput("Created initial users<br>");
} else {
    writeOutput("Users already exist, skipping<br>");
}

// Environment-specific seeding
if (get("environment") == "development") {
    // Add development-specific data
    for (i = 1; i <= 10; i++) {
        model("user").create(
            username = "testuser#i#",
            email = "test#i#@example.com"
        );
    }
    writeOutput("Added development test users<br>");
}
</cfscript>
```

## Best Practices

### 1. Idempotent Seeds
Make seeds safe to run multiple times:
```cfm
<cfscript>
// Check before creating
if (!model("user").exists(where="username='admin'")) {
    model("user").create(
        username = "admin",
        email = "admin@example.com",
        password = "password123"
    );
    writeOutput("Created admin user<br>");
} else {
    writeOutput("Admin user already exists<br>");
}
</cfscript>
```

### 2. Use Transactions
Wrap seeds in transactions:
```cfm
<cfscript>
transaction {
    try {
        // Create users
        for (i = 1; i <= 10; i++) {
            model("user").create(
                username = "user#i#",
                email = "user#i#@example.com"
            );
        }
        
        // Create related data
        // ...
        
        writeOutput("Seed completed successfully<br>");
    } catch (any e) {
        transaction action="rollback";
        writeOutput("Error: #e.message#<br>");
        rethrow;
    }
}
</cfscript>
```

### 3. Organize by Domain
Structure seeds logically:
```
app/db/
  ├── seed.cfm              # Default seed file
  ├── demo.cfm              # Demo data
  ├── development/          # Development seeds
  │   ├── users.cfm
  │   ├── products.cfm
  │   └── orders.cfm
  └── testing/              # Test-specific seeds
      └── test_data.cfm
```

### 4. Document Seeds
Add clear documentation:
```cfm
<cfscript>
/**
 * Seed file: products.cfm
 * Creates: 5 categories, 50 products
 * Dependencies: None
 * Runtime: ~2 seconds
 */

// Create categories first
categories = [...]; 

// Then create products
// ...
</cfscript>
```

## Error Handling

### Validation Errors
```cfm
<cfscript>
try {
    user = model("user").create(
        username = "testuser",
        email = "invalid-email" // Will fail validation
    );
    
    if (user.hasErrors()) {
        writeOutput("Failed to create user:<br>");
        for (error in user.allErrors()) {
            writeOutput("- #error.message#<br>");
        }
    }
} catch (any e) {
    writeOutput("Error: #e.message#<br>");
}
</cfscript>
```

### Dependency Handling
```cfm
<cfscript>
// Check dependencies
if (model("category").count() == 0) {
    writeOutput("ERROR: Categories must be seeded first!<br>");
    abort;
}

// Continue with product seeding
// ...
</cfscript>
```

## Notes

- Seed files must be placed in the `app/db/` directory
- The file parameter should not include the .cfm extension
- Seed files are executed in the application context with access to all models
- Output from seed files is displayed to the user
- Consider performance when seeding large amounts of data

## Related Commands

- [`wheels dbmigrate latest`](dbmigrate-latest.md) - Run migrations before seeding
- [`wheels db schema`](db-schema.md) - Export/import database structure
- [`wheels generate model`](../generate/model.md) - Generate models for seeding
- [`wheels test run`](../testing/test-run.md) - Test with seeded data