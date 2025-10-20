# Systematic Documentation Loading Strategy

## Overview

This strategy defines how the enhanced `mcp__wheels__develop` workflow automatically loads relevant documentation from the `.ai` folder based on task analysis. The goal is to ensure AI assistants always have the correct patterns, anti-patterns, and best practices loaded before beginning any implementation work.

## Core Principles

1. **Context-Aware Loading**: Load documentation based on task type detection
2. **Priority-Based Access**: Critical error prevention documentation always loads first
3. **Progressive Enhancement**: Load basic patterns first, then advanced features
4. **Consistency Enforcement**: Ensure same patterns are applied across similar components
5. **Error Prevention**: Always prioritize anti-pattern documentation

## Documentation Loading Architecture

### Phase 1: Universal Critical Documentation (ALWAYS FIRST)

**Mandatory files loaded for EVERY task:**
```
1. .ai/wheels/troubleshooting/common-errors.md         [CRITICAL - Error Prevention]
2. .ai/wheels/patterns/validation-templates.md         [CRITICAL - Anti-Pattern Checklists]
3. .ai/wheels/workflows/pre-implementation.md          [WORKFLOW - Process Validation]
```

**Purpose**: Prevent the two most common Wheels errors:
- Mixed argument styles in function calls
- Query/Array confusion in loops and counts

### Phase 2: Task Type Detection Engine

#### Natural Language Analysis Patterns
```
Task Analysis Keywords → Component Type Detection:

Model Indicators:
- "model", "User", "Post", "Comment", "Product", "Order"
- "association", "hasMany", "belongsTo", "validation"
- "database", "table", "record", "ActiveRecord"
- "save", "create", "update", "delete", "find"

Controller Indicators:
- "controller", "action", "CRUD", "REST", "API"
- "filter", "authentication", "authorization"
- "render", "redirect", "session", "flash"
- "index", "show", "new", "create", "edit", "update", "destroy"

View Indicators:
- "view", "template", "form", "layout", "partial"
- "helper", "display", "render", "output"
- "HTML", "CSS", "JavaScript", "Alpine.js", "HTMX"
- "responsive", "mobile", "desktop"

Migration Indicators:
- "migration", "migrate", "schema", "column", "table"
- "database", "create table", "alter table", "index"
- "rollback", "up", "down", "version"

Configuration Indicators:
- "route", "routing", "URL", "endpoint"
- "config", "settings", "environment"
- "security", "CSRF", "authentication"
```

#### Task Complexity Assessment
```
Simple Task (1-2 components):
- "create a User model"
- "add validation to Post"
- "create contact form"

Moderate Task (3-5 components):
- "create blog with posts and comments"
- "add user authentication"
- "create product catalog"

Complex Task (6+ components):
- "create e-commerce site with users, products, orders, payments"
- "build admin dashboard with user management"
- "create multi-tenant blog platform"
```

### Phase 3: Component-Specific Documentation Loading

#### Model Development Documentation Stack
```
Primary Load Order:
1. .ai/wheels/models/architecture.md                   [Foundation patterns]
2. .ai/wheels/models/associations.md                   [Relationship handling]
3. .ai/wheels/models/validations.md                    [Validation patterns]
4. .ai/wheels/models/best-practices.md                 [Development guidelines]
5. .ai/wheels/snippets/model-snippets.md               [Code templates]

Secondary Load (Task-Specific):
IF associations detected:
  → .ai/wheels/database/associations/has-many.md
  → .ai/wheels/database/associations/belongs-to.md
  → .ai/wheels/database/associations/has-one.md

IF validation requirements:
  → .ai/wheels/database/validations/presence.md
  → .ai/wheels/database/validations/uniqueness.md
  → .ai/wheels/database/validations/format.md
  → .ai/wheels/database/validations/custom.md

IF authentication model:
  → .ai/wheels/models/user-authentication.md
  → .ai/wheels/security/csrf-protection.md

IF performance concerns:
  → .ai/wheels/models/performance.md
  → .ai/wheels/database/queries/finding-records.md
```

#### Controller Development Documentation Stack
```
Primary Load Order:
1. .ai/wheels/controllers/architecture.md              [Foundation patterns]
2. .ai/wheels/controllers/rendering.md                 [View handling]
3. .ai/wheels/controllers/model-interactions.md        [Data layer patterns]
4. .ai/wheels/controllers/filters.md                   [Request processing]
5. .ai/wheels/snippets/controller-snippets.md          [Code templates]

Secondary Load (Task-Specific):
IF authentication required:
  → .ai/wheels/controllers/security.md
  → .ai/wheels/patterns/authentication.md

IF API development:
  → .ai/wheels/controllers/api.md
  → .ai/wheels/controllers/http-detection.md

IF admin functionality:
  → .ai/wheels/controllers/filters.md (authorization)
  → .ai/wheels/controllers/security.md

IF CRUD operations:
  → .ai/wheels/patterns/crud.md
  → .ai/wheels/controllers/model-interactions.md
```

#### View Development Documentation Stack
```
Primary Load Order:
1. .ai/wheels/views/data-handling.md                   [CRITICAL - Query patterns]
2. .ai/wheels/views/architecture.md                    [Structure patterns]
3. .ai/wheels/views/forms.md                          [Form helper patterns]
4. .ai/wheels/views/layouts.md                        [Layout patterns]
5. .ai/wheels/snippets/view-snippets.md               [Code templates]

Secondary Load (Task-Specific):
IF forms detected:
  → .ai/wheels/views/forms.md
  → .ai/wheels/views/helpers/forms.md
  → .ai/wheels/security/csrf-protection.md

IF layout work:
  → .ai/wheels/views/layouts/structure.md
  → .ai/wheels/views/layouts/partials.md
  → .ai/wheels/views/layouts/content-for.md

IF helpers needed:
  → .ai/wheels/views/helpers/links.md
  → .ai/wheels/views/helpers/dates.md
  → .ai/wheels/views/helpers/custom.md

IF responsive design:
  → .ai/wheels/views/advanced-patterns.md
  → .ai/cfml/syntax/cfscript-vs-tags.md
```

#### Migration Development Documentation Stack
```
Primary Load Order:
1. .ai/wheels/database/migrations/creating-migrations.md
2. .ai/wheels/database/migrations/column-types.md
3. .ai/wheels/database/migrations/advanced-operations.md
4. .ai/wheels/database/migrations/running-migrations.md

Secondary Load (Task-Specific):
IF complex schema changes:
  → .ai/wheels/database/migrations/rollback.md

IF data seeding required:
  → .ai/wheels/troubleshooting/common-errors.md (parameter binding issues)

IF indexes needed:
  → .ai/wheels/database/migrations/advanced-operations.md
```

### Phase 4: Cross-Component Documentation Loading

#### Multi-Component Project Documentation
```
For projects requiring multiple components:

1. Load all primary stacks for detected components
2. Load integration documentation:
   → .ai/wheels/core-concepts/routing/patterns.md
   → .ai/wheels/configuration/routing.md
   → .ai/wheels/patterns/crud.md

3. Load security documentation:
   → .ai/wheels/security/csrf-protection.md
   → .ai/wheels/controllers/security.md

4. Load testing documentation:
   → .ai/wheels/models/testing.md
   → .ai/wheels/controllers/testing.md
   → .ai/wheels/views/testing.md
```

### Phase 5: CFML Language Documentation Loading

#### Syntax-Specific Documentation
```
Load based on syntax patterns needed:

IF CFScript detected/preferred:
  → .ai/cfml/syntax/cfscript-vs-tags.md
  → .ai/cfml/syntax/basic-syntax.md
  → .ai/cfml/components/component-basics.md

IF complex data handling:
  → .ai/cfml/data-types/variables.md
  → .ai/cfml/data-types/variable-scopes.md
  → .ai/cfml/control-flow/loops.md

IF query operations:
  → .ai/cfml/database/query-basics.md
  → .ai/cfml/control-flow/loops.md

IF error handling needed:
  → .ai/cfml/control-flow/exception-handling.md
  → .ai/cfml/control-flow/conditionals.md
```

## Documentation Loading Implementation

### Smart Loading Algorithm
```javascript
function loadDocumentationForTask(taskDescription, taskComplexity) {
    const documentationQueue = [];

    // Phase 1: Always load critical documentation first
    documentationQueue.push(...CRITICAL_DOCUMENTATION);

    // Phase 2: Analyze task and determine component types
    const components = analyzeTaskComponents(taskDescription);

    // Phase 3: Load component-specific documentation
    for (const component of components) {
        documentationQueue.push(...getComponentDocumentation(component));
    }

    // Phase 4: Load cross-component documentation if needed
    if (components.length > 1) {
        documentationQueue.push(...INTEGRATION_DOCUMENTATION);
    }

    // Phase 5: Load CFML documentation as needed
    const syntaxNeeds = analyzeSyntaxRequirements(taskDescription, components);
    documentationQueue.push(...getCFMLDocumentation(syntaxNeeds));

    // Phase 6: Load advanced features based on complexity
    if (taskComplexity === 'complex') {
        documentationQueue.push(...ADVANCED_DOCUMENTATION);
    }

    return documentationQueue;
}
```

### Component Detection Patterns
```javascript
function analyzeTaskComponents(taskDescription) {
    const components = [];
    const text = taskDescription.toLowerCase();

    // Model detection
    if (hasModelIndicators(text)) {
        components.push('model');

        // Specific model features
        if (text.includes('association') || text.includes('relationship')) {
            components.push('model_associations');
        }
        if (text.includes('validation') || text.includes('validate')) {
            components.push('model_validations');
        }
        if (text.includes('user') || text.includes('auth')) {
            components.push('model_authentication');
        }
    }

    // Controller detection
    if (hasControllerIndicators(text)) {
        components.push('controller');

        // Specific controller features
        if (text.includes('api') || text.includes('json')) {
            components.push('controller_api');
        }
        if (text.includes('admin') || text.includes('auth')) {
            components.push('controller_security');
        }
        if (text.includes('crud') || text.includes('rest')) {
            components.push('controller_crud');
        }
    }

    // View detection
    if (hasViewIndicators(text)) {
        components.push('view');

        // Specific view features
        if (text.includes('form') || text.includes('input')) {
            components.push('view_forms');
        }
        if (text.includes('layout') || text.includes('template')) {
            components.push('view_layouts');
        }
        if (text.includes('responsive') || text.includes('mobile')) {
            components.push('view_responsive');
        }
    }

    // Migration detection
    if (hasMigrationIndicators(text)) {
        components.push('migration');

        if (text.includes('seed') || text.includes('data')) {
            components.push('migration_seeding');
        }
    }

    return components;
}
```

### Documentation Priority Matrix
```
Priority 1 (Critical - Always Load):
- common-errors.md
- validation-templates.md
- pre-implementation.md

Priority 2 (Foundation - Load for Component Type):
- architecture.md files
- basic patterns

Priority 3 (Feature-Specific - Load as Needed):
- associations.md
- validations.md
- forms.md
- security.md

Priority 4 (Advanced - Load for Complex Tasks):
- performance.md
- advanced-patterns.md
- testing.md

Priority 5 (Reference - Load on Demand):
- methods-reference.md
- snippets.md
- troubleshooting files
```

### Documentation Validation
```javascript
function validateDocumentationLoaded(components, taskComplexity) {
    const requiredDocs = [];

    // Always required
    requiredDocs.push('common-errors.md', 'validation-templates.md');

    // Component-specific requirements
    if (components.includes('model')) {
        requiredDocs.push('models/architecture.md', 'models/best-practices.md');
    }
    if (components.includes('controller')) {
        requiredDocs.push('controllers/architecture.md', 'controllers/rendering.md');
    }
    if (components.includes('view')) {
        requiredDocs.push('views/data-handling.md', 'views/architecture.md');
    }

    // Verify all required documentation is loaded
    for (const doc of requiredDocs) {
        if (!isDocumentationLoaded(doc)) {
            throw new Error(`Required documentation not loaded: ${doc}`);
        }
    }

    return true;
}
```

## Documentation Context Management

### Context Preservation
```javascript
function preserveDocumentationContext(loadedDocs) {
    // Store loaded documentation in context for reference during implementation
    const context = {
        antiPatterns: extractAntiPatterns(loadedDocs),
        codeTemplates: extractTemplates(loadedDocs),
        bestPractices: extractBestPractices(loadedDocs),
        securityRules: extractSecurityRules(loadedDocs),
        argumentStyles: detectArgumentStyles(loadedDocs)
    };

    return context;
}
```

### Pattern Extraction
```javascript
function extractAntiPatterns(documentation) {
    // Extract ❌ marked patterns from documentation
    const antiPatterns = [];

    documentation.forEach(doc => {
        const patterns = doc.content.match(/❌.*$/gm);
        if (patterns) {
            antiPatterns.push(...patterns);
        }
    });

    return antiPatterns;
}

function extractTemplates(documentation) {
    // Extract code blocks marked as templates
    const templates = {};

    documentation.forEach(doc => {
        if (doc.path.includes('snippets')) {
            const codeBlocks = doc.content.match(/```cfm(.*?)```/gs);
            if (codeBlocks) {
                templates[doc.component] = codeBlocks;
            }
        }
    });

    return templates;
}
```

## Error Recovery Documentation Loading

### Documentation Re-consultation on Errors
```javascript
function loadErrorRecoveryDocumentation(errorType, originalComponents) {
    const recoveryDocs = [];

    switch (errorType) {
        case 'mixed_arguments':
            recoveryDocs.push('.ai/wheels/troubleshooting/common-errors.md');
            recoveryDocs.push('.ai/wheels/patterns/validation-templates.md');
            break;

        case 'query_array_confusion':
            recoveryDocs.push('.ai/wheels/models/data-handling.md');
            recoveryDocs.push('.ai/wheels/views/data-handling.md');
            recoveryDocs.push('.ai/cfml/control-flow/loops.md');
            break;

        case 'route_conflicts':
            recoveryDocs.push('.ai/wheels/configuration/routing.md');
            recoveryDocs.push('.ai/wheels/core-concepts/routing/patterns.md');
            break;

        case 'validation_failures':
            recoveryDocs.push('.ai/wheels/models/validations.md');
            recoveryDocs.push('.ai/wheels/database/validations/');
            break;
    }

    // Load original component documentation as backup
    recoveryDocs.push(...getComponentDocumentation(originalComponents));

    return recoveryDocs;
}
```

## Usage Guidelines

### When to Trigger Documentation Loading

1. **Before any code generation**: Always load documentation first
2. **On error encounters**: Load error-specific documentation
3. **When switching component types**: Load new component documentation
4. **For complex tasks**: Load additional advanced documentation

### Documentation Loading Optimization

1. **Cache frequently used documentation**: Keep anti-pattern docs in memory
2. **Progressive loading**: Load basic docs first, advanced docs as needed
3. **Context-aware caching**: Remember documentation preferences per project
4. **Lazy loading**: Load reference documentation only when specific features are used

### Integration with Development Workflow

1. **Pre-implementation phase**: Load all relevant documentation before planning
2. **Implementation phase**: Have documentation context available for reference
3. **Error recovery phase**: Automatically load error-specific documentation
4. **Validation phase**: Use documentation for anti-pattern checking

This systematic documentation loading strategy ensures that AI assistants always have the right knowledge available at the right time, preventing common errors and ensuring consistent, high-quality implementations that follow established Wheels patterns and best practices.