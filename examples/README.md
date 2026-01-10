# Wheels Examples

This directory contains example applications that demonstrate how to use the Wheels framework effectively.

## Available Examples

### Starter App (`starter-app/`)

A complete, production-ready starter application that showcases best practices for building applications with Wheels. This example includes:

- **Modern Architecture**: Clean separation of concerns with MVC pattern
- **Database Integration**: Complete model setup with migrations
- **RESTful API**: Example endpoints following REST conventions
- **Testing Suite**: Comprehensive test coverage with TestBox
- **Deployment Ready**: Docker configuration and deployment scripts

## Installation

### Via CommandBox (Recommended)

In CommandBox, ensure you've got the latest version of the wheels CLI - this is useful for installing plugins and running unit tests from the commandline.

```bash
install wheels-cli
```

Then simply create a directory, and run the install command:

```bash
mkdir myApp
cd myApp
install wheels-starter-app
```

### Manual Installation

Navigate to starter app directory.

```bash
cd starter-app
box install
```

## Getting Started

### Start the Server

```bash
box server start
```

You will get an error when the site initially loads, that's expected. We need to create a database and setup the datasource.

### Creating a Database

Setup a local mySQL database called starterapp and ensure you've got a valid user account for it. Locally that's probably root. The starter app is currently only tested with MySQL. To create a new schema using the MySQL command line, run the following command:

```sql
mysql> CREATE DATABASE starterapp;
```

You could also use a GUI, e.g. MySQL Workbench

### Adding the Datasource

There are two main ways to configure datasources in Lucee:

#### Programmatic Configuration (Code-based)

Configure your MySQL datasource using code-based configuration in `config/app.cfm`. This approach keeps database settings in version control and enables environment-specific configurations.

**Step 1: Environment Variables Setup**
Update .env file in application root:

```bash
# MySQL Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=starterApp
DB_USER=root
DB_PASSWORD=your_secure_password

# MySQL Driver Settings
DB_CLASS=com.mysql.cj.jdbc.Driver
DB_BUNDLENAME=com.mysql.cj
DB_BUNDLEVERSION=8.0.33

# Connection Pool Settings
DB_CONNECTIONLIMIT=50
DB_LIVETIMEOUT=30
DB_ALWAYSSETTIMEOUT=false
DB_VALIDATE=true
```

**Step 2: Configure config/app.cfm**
Update this in config/app.cfm:

```javascript
// Configure MySQL datasource
this.datasources["starterApp"] = {
    class: this.env.DB_CLASS,
    bundleName: this.env.DB_BUNDLENAME, 
    bundleVersion: this.env.DB_BUNDLEVERSION,
    connectionString: "jdbc:mysql://#this.env.DB_HOST#:#this.env.DB_PORT#/#this.env.DB_NAME#?characterEncoding=UTF-8&serverTimezone=UTC&maxReconnects=3&useSSL=false",
    username: this.env.DB_USER,
    password: this.env.DB_PASSWORD,
        
    // Connection pool optimization
    connectionLimit: val(this.env.DB_CONNECTIONLIMIT),
    liveTimeout: val(this.env.DB_LIVETIMEOUT),
    alwaysSetTimeout: this.env.DB_ALWAYSSETTIMEOUT EQ "true",
    validate: this.env.DB_VALIDATE EQ "true"
};
```

**Benefits**
- Version controlled configuration
- Environment-specific settings
- Secure credential management
- Connection pooling optimization
- No manual admin panel setup required

#### Lucee Administrator (Web-based GUI)

Login to the Lucee Administrator at /lucee/admin/server.cfm. As this is your first login, you will need to create a password for the administrator. Note, if you're logging into /CFIDE/administrator, the default password for the admin is commandbox.

1. Login
2. Select Services > Datasource from the left hand column
3. Create a new mySQL datasource called starterapp
4. Fill in the database credentials
5. On saving you should see a green check "OK"

### Database Migrations

Navigate to http://127.0.0.1:8081/wheels/migrator

1. Select the Migrations Tab
2. Click "Migrate to Latest"

Reload the application by visiting http://127.0.0.1:8081/?reload=true&password=changeme

## Key Features Demonstrated

- Database migrations and seeding
- RESTful API endpoints
- Form handling and validation
- Authentication and authorization
- Error handling and logging
- Environment configuration
- Testing patterns and best practices

## Additional Examples

Looking for more examples? Check out our [documentation](https://wheels.dev/docs) for additional tutorials and guides.

## Contributing

Have an example you'd like to share? We welcome contributions! Please see our [contributing guidelines](../CONTRIBUTING.md) for details on how to submit your examples.
