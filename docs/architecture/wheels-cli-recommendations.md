# Wheels CLI Recommendations - Must-Have Features

## Executive Summary

After analyzing the CLI capabilities of Ruby on Rails, Laravel, Django, and ColdBox, this document outlines the absolute must-have features for the Wheels CLI. The recommendations are organized by priority and include implementation strategies leveraging CommandBox's existing capabilities.

## Core CLI Features Analysis

### 1. Ruby on Rails CLI
**Key Commands:**
- `rails generate` (scaffolding)
- `rails db:migrate` (database migrations)
- `rails server` (development server)
- `rails console` (interactive shell)
- `rails test` (testing)

**Strengths:**
- Comprehensive scaffolding with single command
- Convention over configuration
- Integrated testing support

### 2. Laravel Artisan
**Key Commands:**
- `php artisan make:*` (various generators)
- `php artisan migrate` (database migrations)
- `php artisan serve` (development server)
- `php artisan tinker` (interactive shell)

**Strengths:**
- Modular generation commands
- Resource controllers with REST support
- Powerful migration system

### 3. Django manage.py
**Key Commands:**
- `python manage.py startapp` (app creation)
- `python manage.py makemigrations/migrate`
- `python manage.py runserver`
- `python manage.py shell`

**Strengths:**
- Clear separation of apps
- Automatic migration detection
- Built-in admin interface

### 4. ColdBox CLI
**Key Commands:**
- `coldbox create app/handler/model/view`
- Resource and REST support
- Integration with migrations and seeders

**Strengths:**
- HMVC architecture support
- Deep CommandBox integration
- Module-based development

## Absolute Must-Have Features for Wheels CLI

### Priority 1: Essential Core Features

#### 1.1 Application Scaffolding
```bash
wheels create app [name] [options]
  --template=default|api|spa
  --database=sqlite|mysql|postgresql|mssql
  --testing=true|false
  --docker=true|false
  
Example:
wheels create app blog --database=sqlite  # Default for development
```

#### 1.2 Model Generation with Migrations
```bash
wheels create model [name] [properties]
  --migration (creates migration file)
  --seeder (creates seed data)
  --controller (creates matching controller)
  --api (creates API controller)
  
Example:
wheels create model User firstName:string lastName:string email:string:unique age:integer --migration --controller
```

#### 1.3 Controller Generation
```bash
wheels create controller [name] [actions]
  --resource (CRUD actions)
  --api (REST API actions)
  --model=[modelName] (links to model)
  --views (creates view files)
  
Example:
wheels create controller Users --resource --views
```

#### 1.4 Database Migration Management
```bash
wheels db:create              # Create database (SQLite creates file automatically)
wheels db:migrate             # Run pending migrations
wheels db:rollback [steps]    # Rollback migrations
wheels db:seed                # Run seeders
wheels db:reset              # Drop, create, migrate, seed
wheels db:status             # Show migration status
wheels db:setup              # Initial database setup with JDBC drivers
```

**Note:** SQLite is the default database for development, providing zero-configuration setup similar to Rails and Laravel.

#### 1.5 View Generation
```bash
wheels create view [controller]/[action]
  --layout=[layoutName]
  --partial (creates partial)
  
Example:
wheels create view users/index --layout=main
```

### Priority 2: Development Workflow Features

#### 2.1 Server Management
```bash
wheels server:start [options]
  --port=3000
  --host=localhost
  --reloadPassword=password
  --environment=development|testing|production
  
wheels server:stop
wheels server:restart
wheels server:status
```

**Note:** Server start automatically configures the appropriate datasource. For SQLite (default), the database file is created if it doesn't exist.

#### 2.2 Interactive Console (REPL)
```bash
wheels console
  # Access to application context
  # Database queries
  # Model manipulation
  # Testing components
```

#### 2.3 Testing Infrastructure
```bash
wheels test:all              # Run all tests
wheels test:unit [path]      # Run unit tests
wheels test:integration      # Run integration tests
wheels test:create [type] [name]  # Generate test files
```

#### 2.4 Route Management
```bash
wheels routes:list           # Display all routes
wheels routes:test [url]     # Test route matching
wheels create route [pattern] [controller].[action]
```

### Priority 3: Package & Plugin Management

#### 3.1 Plugin Management
```bash
wheels plugin:install [name]
wheels plugin:uninstall [name]
wheels plugin:list
wheels plugin:update [name]
wheels plugin:create [name]
```

#### 3.2 Asset Pipeline
```bash
wheels assets:precompile     # Compile assets for production
wheels assets:clean          # Remove compiled assets
wheels assets:watch          # Watch for changes
```

### Priority 4: Advanced Features

#### 4.1 API Documentation
```bash
wheels api:docs              # Generate API documentation
wheels api:test [endpoint]   # Test API endpoints
```

#### 4.2 Code Quality Tools
```bash
wheels lint                  # Run code linter
wheels format               # Format code
wheels analyze              # Static code analysis
```

## Implementation Strategy with CommandBox

### Leveraging CommandBox's Existing Features

1. **Use CommandBox's Package Management**
   - Leverage `box.json` for Wheels apps
   - Use ForgeBox for plugin distribution
   - Implement semantic versioning
   - Auto-install JDBC drivers (SQLite, MySQL, etc.)

2. **Extend CommandBox's Server Features**
   - Utilize embedded server capabilities
   - Add Wheels-specific reloading
   - Environment configuration
   - Automatic datasource configuration for SQLite

3. **Database Integration**
   - SQLite as default (zero-configuration)
   - Automatic JDBC driver management
   - Easy database switching via CLI
   - Per-environment database files

4. **Build on CommandBox's Command Architecture**
   ```javascript
   component extends="commandbox.system.BaseCommand" {
       function run() {
           // Wheels-specific logic
       }
   }
   ```

4. **Integration Points**
   - Use CommandBox's file operations
   - Leverage interactive prompts
   - Utilize progress bars for long operations

### Recommended Implementation Order

1. **Phase 1: Core Generation** (Weeks 1-2)
   - Model generation with properties
   - Basic controller generation
   - Migration creation

2. **Phase 2: Database Tools** (Weeks 3-4)
   - Migration runner
   - Database commands
   - Seeding functionality

3. **Phase 3: Development Tools** (Weeks 5-6)
   - Interactive console
   - Route visualization
   - Testing infrastructure

4. **Phase 4: Advanced Features** (Weeks 7-8)
   - Plugin management
   - Asset pipeline
   - API tools

## Code Examples

### Example: Project Creation with SQLite
```bash
# Create new app with SQLite (default)
wheels create app blog

# Create with specific database
wheels create app enterprise --database=postgresql

# The SQLite database file is automatically created at:
# db/sqlite/blog_development.db
# db/sqlite/blog_testing.db
# db/sqlite/blog_production.db
```

### Example: Model Generation Template
```javascript
// Command: wheels create model User firstName:string lastName:string email:string:unique
component extends="models.Model" {
    
    function config() {
        table("users");
        
        property(name="firstName", type="string");
        property(name="lastName", type="string");
        property(name="email", type="string");
        
        validatesPresenceOf("firstName,lastName,email");
        validatesUniquenessOf("email");
    }
}
```

### Example: Migration Template
```javascript
component extends="cfwheels.migrator.Migration" {
    
    function up() {
        createTable(name="users") {
            table.increments("id");
            table.string("firstName");
            table.string("lastName");
            table.string("email");
            table.timestamps();
            table.index("email", unique=true);
        };
    }
    
    function down() {
        dropTable("users");
    }
}
```

### Example: Controller Template
```javascript
component extends="Controller" {
    
    function index() {
        users = model("User").findAll();
    }
    
    function show() {
        user = model("User").findByKey(params.id);
    }
    
    function new() {
        user = model("User").new();
    }
    
    function create() {
        user = model("User").create(params.user);
        if (user.save()) {
            redirectTo(route="users", success="User created successfully");
        } else {
            renderView(action="new");
        }
    }
    
    function edit() {
        user = model("User").findByKey(params.id);
    }
    
    function update() {
        user = model("User").findByKey(params.id);
        if (user.update(params.user)) {
            redirectTo(route="users", success="User updated successfully");
        } else {
            renderView(action="edit");
        }
    }
    
    function delete() {
        user = model("User").findByKey(params.id);
        user.delete();
        redirectTo(route="users", success="User deleted successfully");
    }
}
```

## Testing Strategy

### Unit Test Example
```javascript
component extends="wheels.Test" {
    
    function setup() {
        super.setup();
        model("User").deleteAll();
    }
    
    function test_user_creation() {
        user = model("User").new(
            firstName="John",
            lastName="Doe",
            email="john@example.com"
        );
        assert(user.save());
        assert(user.id > 0);
    }
}
```

## Best Practices & Recommendations

1. **Follow Framework Conventions**
   - Maintain Wheels naming conventions
   - Use consistent command syntax
   - Provide helpful error messages

2. **Provide Comprehensive Help**
   ```bash
   wheels help
   wheels create model --help
   wheels db:migrate --help
   ```

3. **Interactive Prompts for Complex Operations**
   - Guide users through scaffolding
   - Confirm destructive operations
   - Suggest next steps

4. **Performance Considerations**
   - Cache command metadata
   - Lazy load dependencies
   - Optimize file operations

5. **Error Handling**
   - Clear error messages
   - Suggest fixes
   - Log errors for debugging

## Conclusion

The Wheels CLI should focus on developer productivity while maintaining the framework's convention-over-configuration philosophy. By leveraging CommandBox's robust foundation and learning from successful CLI implementations in other frameworks, Wheels can provide a world-class command-line experience that accelerates development and reduces boilerplate code.

The recommended features prioritize the most common development tasks while providing a clear path for extending functionality. This approach ensures that both beginners and experienced developers can be productive with the Wheels framework from day one.