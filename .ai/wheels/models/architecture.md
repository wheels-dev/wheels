# Model Architecture

## Description
CFWheels model architecture, structure patterns, and basic implementation guidelines.

## Key Points
- Models implement the Active Record pattern
- All models extend `wheels.Model` for ORM functionality
- Models represent both data structure and business logic
- Follow naming conventions: singular file names, plural table names

## Model Architecture Overview

### Base Model Structure
All models extend `wheels.Model`, which provides:
- Database interaction methods (CRUD operations)
- Validation framework
- Association management
- Callback system
- Query building and caching
- Transaction support

### Why Use Models
- Implement the Active Record pattern for database interactions
- Define business logic and data validation rules
- Establish relationships between different data entities
- Provide a clean interface for database operations
- Enable automatic query generation and caching
- Support advanced features like callbacks, soft deletes, and dirty tracking

**Key Concept:** Models represent both the structure (database schema) and behavior (business logic) of your data.

## Basic Model Structure

### Simple Model Template
```cfm
/**
 * User Model - Represents application users
 * Table: users
 * Primary Key: id
 */
component extends="Model" {

    /**
     * Model configuration - associations, validations, properties
     */
    function config() {
        // Table configuration (if different from convention)
        // table("custom_users_table");

        // Associations
        hasMany("posts");
        hasMany("comments");
        hasOne("profile");

        // Validations
        validatesPresenceOf("name,email");
        validatesUniquenessOf("email");
        validatesLengthOf(property="name", minimum=2, maximum=100);
        validatesFormatOf(property="email", with="^[^@]+@[^@]+\.[^@]+$");

        // Custom properties
        property(name="fullName", sql=false); // Virtual property

        // Callbacks
        beforeSave("encryptPassword");
        afterCreate("sendWelcomeEmail");

        // Soft delete enabled automatically if deletedat column exists
    }

    // Custom business logic methods go here

    /**
     * Get user's full display name
     */
    function getFullName() {
        return trim(this.firstname & " " & this.lastname);
    }

    /**
     * Check if user has specific role
     */
    function hasRole(required string roleName) {
        return listFindNoCase(this.roles, arguments.roleName) > 0;
    }

    /**
     * Callback: Encrypt password before saving
     */
    private void function encryptPassword() {
        if (hasChanged("password") && len(this.password)) {
            this.password = hash(this.password, "SHA-256");
        }
    }

    /**
     * Callback: Send welcome email after user creation
     */
    private void function sendWelcomeEmail() {
        // Queue welcome email job
        local.mailer = createObject("component", "mailers.UserMailer");
        local.mailer.welcomeEmail(to=this.email, user=this);
    }
}
```

## Model Generation

### CLI Generator
Use the Wheels CLI to generate model classes and optionally create database migrations:

```bash
# Basic model
wheels g model User

# Model with properties
wheels g model User name:string,email:string,age:integer

# Model with associations
wheels g model Post belongsTo=User hasMany=Comments

# Model with custom table name
wheels g model Product tableName=tbl_products

# Model without migration
wheels g model Category migration=false
```

### Generator Options
- **`name`** - Model name (singular form, becomes class name)
- **`properties`** - Column definitions (name:type,name2:type2)
- **`belongsTo`** - Parent model relationships (comma-separated)
- **`hasMany`** - Child model relationships (comma-separated)
- **`hasOne`** - One-to-one relationships (comma-separated)
- **`primaryKey`** - Primary key column name (default: id)
- **`tableName`** - Custom database table name
- **`migration`** - Generate database migration (default: true)
- **`force`** - Overwrite existing files

## Naming Conventions

- **Model files**: Singular PascalCase (User.cfc, OrderItem.cfc)
- **Database tables**: Plural lowercase (users, orderitems)
- **Primary keys**: id (integer, auto-increment)
- **Foreign keys**: modelname + "id" (userid, postid)
- **Timestamps**: createdat, updatedat, deletedat (lowercase)

## Related Documentation
- [Model Methods Reference](./methods-reference.md)
- [Model Associations](../database/associations/)
- [Model Validations](../database/validations/)
- [Advanced Model Patterns](./advanced-patterns.md)