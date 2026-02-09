# Wheels Starter Application - Detailed Overview

## What This Is

This repository contains a **user management and authentication web application** built with the [Wheels](https://wheels.dev/) framework (version 3.0), a modern MVC framework inspired by Ruby on Rails. The app demonstrates best practices for Wheels 3.0, including security, conventions, and a modern UI using Bootstrap.

**Important**: This is **not a complete, full-featured app**, but rather a **starter/example app** built with Wheels 3.0. It is designed to help you get started and to showcase best practices in authentication, authorization, auditing, and modern web UI using Wheels.

## Key Features

### User Registration & Verification

- Users can register through a secure registration form
- Email verification system sends verification emails to new users
- Account activation only after email verification is complete

### Authentication

- Secure login and logout functionality
- Password reset system via email
- **Note**: Brute-force protection is marked as TODO in the codebase

### Account Management

- Authenticated users can view their account details
- Users can update their profile information (name, email)
- Password change functionality with current password verification

### Admin Panel

Admin users have access to comprehensive management features:

**User Management:**

- Create new users
- Edit existing user details
- Disable/soft delete users
- Permanently delete users
- Recover disabled users
- Reset user passwords (generates new temp password via email)
- **Assume User Identity**: Login as another user for troubleshooting (high-privilege feature)

**Role & Permission Management:**

- Manage roles (create, edit, delete)
- Manage permissions
- Assign/remove permissions for users and roles
- Role-Based Access Control (RBAC) implementation

**System Administration:**

- View and filter audit logs for security tracking
- Manage application settings
- Monitor user activities

### Security Features

- **CSRF Protection** on all forms using Wheels built-in protection
- **Input validation and sanitization** on all user inputs
- **Role and permission checks** for all admin actions
- **Audit logging** for sensitive actions and changes
- **Secure password handling** with bcrypt hashing

### Email Notifications

- Account verification emails for new registrations
- Password reset emails for forgotten passwords
- Admin password reset notifications when admins reset user passwords

### Modern UI

- **Bootstrap 4** for clean, responsive design
- All forms and navigation use Wheels helpers for consistency and security
- Mobile-responsive interface
- Consistent styling across all pages

## Intended Audience

- **Developers** looking for a reference or starter app for Wheels 3.x
- **Teams** wanting to learn or demonstrate best practices in Wheels MVC development
- **Students** learning modern CFML web development
- **Organizations** evaluating Wheels framework for their projects

## Architecture Overview

### MVC Structure

```
app/
├── controllers/          # Application controllers
│   ├── Controller.cfc   # Base controller with security
│   ├── Main.cfc        # Home page controller
│   ├── Sessions.cfc    # Authentication controller
│   ├── Register.cfc    # User registration
│   ├── PasswordResets.cfc # Password management
│   ├── Accounts.cfc    # User account management
│   └── admin/          # Admin controllers
│   └── functions/          # helper functions
├── models/             # Data models
│   ├── User.cfc        # User model with authentication
│   ├── Role.cfc        # Role model
│   ├── Permission.cfc  # Permission model
│   └── Auditlog.cfc    # Audit logging
|── global/             # application-wide globally accessible functions
├── views/              # Presentation layer
├── mailers/            # Email templates
plugins/            # Third-party plugins
```

### Key Design Principles

- **Convention over Configuration** following Rails-inspired patterns
- **Security by Default** with built-in protections
- **RESTful Design** for clean URLs and API structure
- **Separation of Concerns** with clear MVC boundaries

## Technology Stack

### Backend

- **3.0.0-snapshot** - MVC Framework
- **Lucee 5,6,7, Adobe 2018-2025, Boxlang** - CFML Engine
- **Database** - MySQL, PostgreSQL, Microsoft SQL Server, Oracle, SQLite, H2
- **WireBox** - Dependency injection
- **TestBox** - Testing framework

### Frontend

- **Bootstrap 4** - UI Framework
- **jQuery** - JavaScript utilities
- **Font Awesome** - Icons

### Development Tools

- **CommandBox** - Package management & server
- **ForgeBox** - Package repository

## Quick Start

### Prerequisites

- **CommandBox** - Latest version
- **CFML Engine**: Choose one of the following:
  - Adobe ColdFusion 2018/2021/2023/2025
  - Lucee 5, Lucee 6, Lucee 7
  - Boxlang
- **Database Engine**: Choose one of the following:
  - MySQL
  - PostgreSQL
  - Microsoft SQL Server
  - Oracle Database
  - SQLite Database
  - H2 Database (for development/testing)

### Environment Configuration

1. Copy `.env.example` to `.env`
2. Configure database settings based on your chosen database:

#### MySQL Configuration

```bash
DB_TYPE=mysql
DB_HOST=localhost
DB_PORT=3306
DB_NAME=starterapp
DB_USER=youruser
DB_PASSWORD=yourpassword
```

#### PostgreSQL Configuration

```bash
DB_TYPE=postgresql
DB_HOST=localhost
DB_PORT=5432
DB_NAME=starterapp
DB_USER=youruser
DB_PASSWORD=yourpassword
```

#### Microsoft SQL Server Configuration

```bash
DB_TYPE=mssql
DB_HOST=localhost
DB_PORT=1433
DB_NAME=starterapp
DB_USER=youruser
DB_PASSWORD=yourpassword
```

#### Oracle Configuration

```bash
DB_TYPE=oracle
DB_HOST=localhost
DB_PORT=1521
DB_NAME=starterapp
DB_USER=youruser
DB_PASSWORD=yourpassword
```

#### H2 Configuration (Development)

```bash
DB_TYPE=h2
DB_HOST=localhost
DB_PORT=9092
DB_NAME=starterapp
DB_USER=sa
DB_PASSWORD=
```

## Database Structure

### Core Tables

- **users** - User accounts with authentication fields
- **roles** - User roles for RBAC
- **permissions** - Individual permissions
- **rolepermissions** - Many-to-many between roles and permissions
- **userpermissions** - User-specific permission overrides
- **auditlogs** - Security audit trail
- **settings** - Application configuration

## Authentication Flow

### Registration Process

1. User fills registration form
2. System creates unverified user account
3. Verification email sent with unique token
4. User clicks verification link
5. Account activated and user can login

### Login Process

1. User submits credentials
2. System validates against database
3. Session created with user data
4. Permissions loaded based on role
5. User redirected to appropriate dashboard

## Admin Panel Features

### User Management Interface

- **User List**: Paginated table with search and filtering
- **User Actions**: Edit, delete, reset password, assume identity
- **Bulk Operations**: Role assignment, status changes
- **Audit Trail**: View all user-related activities

### Role Management

- **Role CRUD**: Create, read, update, delete roles
- **Permission Assignment**: Grant/revoke permissions per role
- **User Assignment**: Assign roles to users

## Security Implementation

### Built-in Security Features

- **CSRF Tokens** on all forms
- **SQL Injection Prevention** via parameterized queries
- **XSS Prevention** through output encoding
- **Password Security** with bcrypt hashing
- **Session Management** with secure cookies

### Access Control

- **Authentication Required** for protected routes
- **Role-based Authorization** for admin functions
- **Permission Checks** for sensitive operations
- **Audit Logging** for compliance

## Testing

### Test Structure

```
tests/
├── Test.cfc              # Base test
├── functions/            # Test utilities
├── requests/             # HTTP tests
└── models/               # Model tests
```

### Running Tests

```bash
# Run all tests
box testbox run

# Run specific test suite
box testbox run --directory tests/requests/
```

## Support & Resources

### Documentation

- [Wheels Guides](https://wheels.dev/guides)
- [Wheels Api Reference](https://wheels.dev/api/v3.0.0)

### Community

- [Wheels Web Community](https://wheels.dev/community)
- [Wheels GitHub](https://github.com/wheels-dev/wheels)

## License

This starter application is released under the Apache License 2.0.

---

**Remember**: This is a **skeleton/starter application** designed to showcase Wheels best practices. Use it as a starting point for your own projects and extend it according to your specific requirements.
