# Quick Start Guide

Get up and running with Wheels CLI in minutes.

## Prerequisites

- CommandBox 5.0+
- Java 8+
- Database (MySQL, PostgreSQL, SQL Server, or H2)

## Installation

### Install CommandBox

```bash
# macOS/Linux
curl -fsSl https://downloads.ortussolutions.com/debs/gpg | sudo apt-key add -
echo "deb https://downloads.ortussolutions.com/debs/noarch /" | sudo tee -a /etc/apt/sources.list.d/commandbox.list
sudo apt-get update && sudo apt-get install commandbox

# Windows (PowerShell as Admin)
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install commandbox
```

### Install Wheels CLI

```bash
box install wheels-cli
```

## Creating Your First Application

### 1. Generate Application

```bash
wheels new blog
cd blog
```

This creates a new Wheels application with:
- Complete directory structure
- Configuration files
- Sample code

### 2. Configure Database

Edit `/config/settings.cfm`:

```cfm
<cfset set(dataSourceName="blog_development")>
```

Or use H2 embedded database:

```bash
wheels new blog --setupH2
```

### 3. Start Server

```bash
box server start
```

Visit http://localhost:3000

## Creating Your First Feature

Let's create a blog post feature:

### 1. Generate Scaffold

```bash
wheels scaffold post --properties="title:string,content:text,published:boolean"
```

This generates:
- Model with validations
- Controller with CRUD actions
- Views for all actions
- Database migration
- Test files

### 2. Run Migration

```bash
wheels dbmigrate latest
```

### 3. Add Routes

Edit `/config/routes.cfm`:

```cfm
<cfscript>
    // Add this line
    resources("posts");
</cfscript>
```

### 4. Reload Application

```bash
wheels reload
```

### 5. Test Your Feature

Visit http://localhost:3000/posts

You now have a fully functional blog post management system!

## Development Workflow

### File Watching

In a new terminal:

```bash
wheels watch
```

Now changes to `.cfc` and `.cfm` files trigger automatic reloads.

### Running Tests

```bash
# Run all tests
wheels test run

# Watch mode
wheels test run --watch

# Specific tests
wheels test run tests/models/PostTest.cfc
```

### Adding Relationships

Let's add comments to posts:

```bash
# Generate comment model
wheels generate model comment --properties="author:string,content:text,postId:integer" \
  --belongs-to="post"

# Update post model
wheels generate property post comments --has-many

# Generate comments controller
wheels generate controller comments --rest

# Run migration
wheels dbmigrate latest
```

## Common Tasks

### Adding Authentication

```bash
# Generate user model
wheels scaffold user --properties="email:string,password:string,admin:boolean"

# Generate session controller
wheels generate controller sessions new,create,delete

# Run migrations
wheels dbmigrate latest
```

### Adding API Endpoints

```bash
# Generate API resource
wheels generate api-resource product --properties="name:string,price:decimal"

# Or convert existing to API
wheels generate controller api/posts --api
```

### Working with Views

```bash
# Generate specific views
wheels generate view posts featured
wheels generate view users profile

# Add layouts
echo '<cfoutput><!DOCTYPE html>...</cfoutput>' > views/layout.cfm
```

## Best Practices

### 1. Use Migrations

Always use migrations for database changes:

```bash
# Create tables
wheels dbmigrate create table products

# Add columns
wheels dbmigrate create column products featured

# Create indexes
wheels dbmigrate create blank add_index_to_products
```

### 2. Write Tests

Generate tests for your code:

```bash
# After creating a model
wheels generate test model post

# After creating a controller
wheels generate test controller posts
```

### 3. Use Environment Configuration

```bash
# Development
wheels reload development

# Testing
wheels reload testing

# Production
wheels reload production
```

### 4. Version Control

```bash
git init
git add .
git commit -m "Initial Wheels application"
```

Add to `.gitignore`:
```
/db/sql/
/logs/
/temp/
.env
```

## Debugging

### Check Logs

```bash
tail -f logs/wheels.log
```

### Enable Debug Mode

In `/config/settings.cfm`:

```cfm
<cfset set(showDebugInformation=true)>
```

### Common Issues

**Port already in use:**
```bash
box server start port=3001
```

**Database connection failed:**
```bash
# Check datasource
box server info
box server show
```

**Migration failed:**
```bash
# Check status
wheels dbmigrate info

# Run specific migration
wheels dbmigrate exec 20240120000000
```

## Next Steps

1. **Read the Guides:**
   - [Service Architecture](service-architecture.md)
   - [Testing Guide](testing.md)
   - [Migration Guide](migrations.md)

2. **Explore Commands:**
   - `wheels --help`
   - `wheels generate --help`
   - `wheels dbmigrate --help`

3. **Join the Community:**
   - [Wheels Documentation](https://docs.wheels.dev)
   - [GitHub Discussions](https://github.com/wheels-dev/wheels/discussions)
   - [CFML Slack](https://cfml.slack.com) #wheels channel

## Example: Complete Blog Application

Here's a complete blog setup:

```bash
# Create application
wheels new myblog --setupH2
cd myblog

# Generate blog structure
wheels scaffold post title:string,slug:string,content:text,publishedAt:datetime
wheels scaffold author name:string,email:string,bio:text
wheels generate model comment author:string,email:string,content:text,postId:integer \
  --belongs-to=post

# Update associations
wheels generate property post authorId:integer --belongs-to=author
wheels generate property post comments --has-many
wheels generate property author posts --has-many

# Add routes
echo '<cfset resources("posts")>' >> config/routes.cfm
echo '<cfset resources("authors")>' >> config/routes.cfm

# Run migrations
wheels dbmigrate latest

# Start development
box server start
wheels watch

# Visit http://localhost:3000/posts
```

You now have a working blog with posts, authors, and comments!