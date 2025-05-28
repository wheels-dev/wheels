# db seed

Populate the database with seed data for development and testing.

## Synopsis

```bash
wheels db seed [options]
```

## Description

The `db seed` command populates your database with predefined data sets. This is essential for development environments, testing scenarios, and demo installations. Seed data provides a consistent starting point for application development and testing.

## Options

### `--env`
- **Type:** String
- **Default:** `development`
- **Description:** Environment to seed (development, testing, staging)

### `--file`
- **Type:** String
- **Default:** `db/seeds.cfm`
- **Description:** Path to seed file or directory

### `--datasource`
- **Type:** String
- **Default:** Application default
- **Description:** Specific datasource to seed

### `--clean`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Clear existing data before seeding

### `--only`
- **Type:** String
- **Default:** All seeds
- **Description:** Run only specific seed files (comma-separated)

### `--except`
- **Type:** String
- **Default:** None
- **Description:** Skip specific seed files (comma-separated)

### `--verbose`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Show detailed output during seeding

### `--dry-run`
- **Type:** Boolean
- **Default:** `false`
- **Description:** Preview seed operations without executing

## Examples

### Basic seeding
```bash
# Run default seeds
wheels db seed

# Seed specific environment
wheels db seed --env=testing
```

### Clean and seed
```bash
# Clear data and reseed
wheels db seed --clean

# Clean seed with confirmation
wheels db seed --clean --verbose
```

### Selective seeding
```bash
# Run specific seeds
wheels db seed --only=users,products

# Skip certain seeds
wheels db seed --except=large_dataset,temporary_data
```

### Custom seed files
```bash
# Use custom seed file
wheels db seed --file=db/seeds/demo_data.cfm

# Use seed directory
wheels db seed --file=db/seeds/development/
```

## Seed File Structure

### Basic Seed File (`db/seeds.cfm`)
```cfm
<cfscript>
// db/seeds.cfm
component extends="wheels.Seeder" {

    function run() {
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

        announce("Seed data created successfully!");
    }

    function clean() {
        // Clean in reverse order of dependencies
        model("product").deleteAll();
        model("category").deleteAll();
        model("user").deleteAll();
        
        announce("Database cleaned!");
    }

}
</cfscript>
```

### Modular Seed Files
```cfm
// db/seeds/users.cfm
component extends="wheels.Seeder" {
    
    function run() {
        // Admin users
        createAdminUsers();
        
        // Regular users
        createSampleUsers(count=50);
        
        // Test users
        createTestUsers();
    }
    
    private function createAdminUsers() {
        admins = [
            {username: "admin", email: "admin@example.com", role: "admin"},
            {username: "moderator", email: "mod@example.com", role: "moderator"}
        ];
        
        for (admin in admins) {
            admin.password = hash("password123");
            model("user").create(admin);
        }
    }
    
    private function createSampleUsers(required numeric count) {
        for (i = 1; i <= arguments.count; i++) {
            model("user").create(
                username = "user#i#",
                email = "user#i#@example.com",
                password = hash("password123"),
                created_at = dateAdd("d", -randRange(1, 365), now())
            );
        }
    }
    
}
```

## Use Cases

### Development Environment Setup
Create consistent development data:
```bash
# Reset and seed development database
wheels dbmigrate reset --remigrate
wheels db seed --clean
```

### Testing Data
Prepare test database:
```bash
# Seed test environment
wheels db seed --env=testing --clean

# Run tests
wheels test run
```

### Demo Data
Create demonstration data:
```bash
# Load demo dataset
wheels db seed --file=db/seeds/demo.cfm --clean
```

### Performance Testing
Generate large datasets:
```bash
# Create performance test data
wheels db seed --file=db/seeds/performance_test.cfm
```

## Advanced Seeding Patterns

### Faker Integration
```cfm
component extends="wheels.Seeder" {
    
    function run() {
        faker = new lib.Faker();
        
        // Generate realistic data
        for (i = 1; i <= 100; i++) {
            model("customer").create(
                first_name = faker.firstName(),
                last_name = faker.lastName(),
                email = faker.email(),
                phone = faker.phoneNumber(),
                address = faker.streetAddress(),
                city = faker.city(),
                state = faker.state(),
                zip = faker.zipCode()
            );
        }
    }
    
}
```

### Relationship Seeding
```cfm
component extends="wheels.Seeder" {
    
    function run() {
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
                    content = generateContent(),
                    published_at = dateAdd("d", -randRange(1, 30), now())
                );
                
                // Add comments
                addCommentsToPost(post, users);
            }
        }
    }
    
    private function addCommentsToPost(post, users) {
        commentCount = randRange(0, 10);
        for (i = 1; i <= commentCount; i++) {
            randomUser = users[randRange(1, arrayLen(users))];
            model("comment").create(
                post_id = post.id,
                user_id = randomUser.id,
                content = "Comment #i# on post",
                created_at = dateAdd("h", i, post.published_at)
            );
        }
    }
    
}
```

### Conditional Seeding
```cfm
component extends="wheels.Seeder" {
    
    function run() {
        // Only seed if empty
        if (model("user").count() == 0) {
            seedUsers();
        }
        
        // Environment-specific seeding
        if (application.environment == "development") {
            seedDevelopmentData();
        } else if (application.environment == "staging") {
            seedStagingData();
        }
    }
    
}
```

## Best Practices

### 1. Idempotent Seeds
Make seeds safe to run multiple times:
```cfm
function run() {
    // Check before creating
    if (!model("user").exists(username="admin")) {
        model("user").create(
            username = "admin",
            email = "admin@example.com"
        );
    }
}
```

### 2. Use Transactions
Wrap seeds in transactions:
```cfm
function run() {
    transaction {
        try {
            seedUsers();
            seedProducts();
            seedOrders();
        } catch (any e) {
            transaction action="rollback";
            throw(e);
        }
    }
}
```

### 3. Organize by Domain
Structure seeds logically:
```
db/seeds/
  ├── 01_users.cfm
  ├── 02_products.cfm
  ├── 03_orders.cfm
  └── 04_analytics.cfm
```

### 4. Document Seeds
Add clear documentation:
```cfm
/**
 * Seeds initial product catalog
 * Creates: 5 categories, 50 products
 * Dependencies: None
 * Runtime: ~2 seconds
 */
function run() {
    // Seed implementation
}
```

## Error Handling

### Validation Errors
```cfm
function run() {
    try {
        user = model("user").create(data);
        if (user.hasErrors()) {
            announce("Failed to create user: #user.allErrors()#");
        }
    } catch (any e) {
        announce("Error: #e.message#", "error");
    }
}
```

### Dependency Handling
```cfm
function run() {
    // Check dependencies
    if (model("category").count() == 0) {
        throw("Categories must be seeded first!");
    }
    
    // Continue with seeding
}
```

## Notes

- Seed files are typically not run in production
- Always use transactions for data integrity
- Consider performance for large seed operations
- Keep seed data realistic and useful

## Related Commands

- [`wheels dbmigrate latest`](dbmigrate-latest.md) - Run migrations before seeding
- [`wheels db schema`](db-schema.md) - Export/import database structure
- [`wheels generate model`](../generate/model.md) - Generate models for seeding
- [`wheels test run`](../testing/test-run.md) - Test with seeded data