# CLAUDE.md - Application Directory Dispatcher

⚠️ **CRITICAL: All detailed documentation has been moved to the .ai folder!**

## 🚨 MANDATORY: Before Working in /app Directory

**The `/app` directory contains the core MVC components of your Wheels application.**

### 📖 Component-Specific Documentation

**ALWAYS read the appropriate documentation before working on any component:**

#### 🏗️ Models (`/app/models/`)
**See:** `.ai/wheels/models/` for complete model documentation
- Data layer, ORM, associations, validations
- **Quick dispatcher:** `app/models/CLAUDE.md`

#### 🎮 Controllers (`/app/controllers/`)
**See:** `.ai/wheels/controllers/` for complete controller documentation
- Request handling, filters, rendering, API development
- **Quick dispatcher:** `app/controllers/CLAUDE.md`

#### 📄 Views (`/app/views/`)
**See:** `.ai/wheels/views/` for complete view documentation
- Templates, layouts, forms, partials, helpers
- **Quick dispatcher:** `app/views/CLAUDE.md`

#### 🗄️ Database Migrations (`/app/migrator/`)
**See:** `.ai/wheels/database/migrations/` for migration documentation
- Schema changes, column types, indexes

#### ⚙️ Other Components
- **Events** (`/app/events/`): Application lifecycle events
- **Global** (`/app/global/`): Globally accessible functions
- **Mailers** (`/app/mailers/`): Email components
- **Jobs** (`/app/jobs/`): Background job processing
- **Libraries** (`/app/lib/`): Custom libraries and utilities

## 🔍 Critical Anti-Pattern Prevention

**Before writing ANY code in the app directory:**
- [ ] ❌ **NO** mixed argument styles in Wheels functions
- [ ] ❌ **NO** ArrayLen() on model associations
- [ ] ❌ **NO** array loops on query objects
- [ ] ❌ **NO** Rails-style nested resource routing
- [ ] ✅ **YES** read component-specific .ai documentation
- [ ] ✅ **YES** follow established patterns from .ai documentation

## 🚀 Quick Development Workflow

1. **Generate component**: Use `wheels g` commands
2. **Read documentation**: Check appropriate `.ai/wheels/` folder
3. **Implement code**: Follow patterns from documentation
4. **Validate**: Check against anti-patterns
5. **Test**: Ensure functionality works correctly

🚨 **DO NOT copy code examples from old CLAUDE.md files - read the complete .ai documentation!**