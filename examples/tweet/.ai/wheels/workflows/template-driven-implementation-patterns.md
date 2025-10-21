# Template-Driven Implementation with Error Recovery Patterns

## Overview

This document defines the template-driven implementation system for the `/wheels_execute` workflow. It provides code generation patterns, error recovery mechanisms, and quality assurance integration to ensure consistent, high-quality Wheels implementations.

## Core Implementation Principles

1. **Template-First Approach**: Always start with proven patterns from `.ai/wheels/snippets/`
2. **Consistency Enforcement**: Maintain argument styles and naming conventions
3. **Progressive Enhancement**: Build complexity incrementally with validation at each step
4. **Error Recovery**: Intelligent fallbacks when generation fails
5. **Quality Validation**: Continuous validation against anti-patterns

## Template Selection Engine

### Template Repository Structure
```
.ai/wheels/snippets/
├── models/
│   ├── basic-model-template.cfm
│   ├── user-authentication-template.cfm
│   ├── association-heavy-template.cfm
│   └── validation-intensive-template.cfm
├── controllers/
│   ├── basic-crud-controller.cfm
│   ├── api-controller-template.cfm
│   ├── admin-controller-template.cfm
│   └── authentication-controller.cfm
├── views/
│   ├── index-view-template.cfm
│   ├── form-view-template.cfm
│   ├── show-view-template.cfm
│   └── layout-template.cfm
├── migrations/
│   ├── create-table-migration.cfm
│   ├── add-column-migration.cfm
│   └── create-join-table-migration.cfm
└── tests/
    ├── model-test-template.cfm
    ├── controller-test-template.cfm
    └── integration-test-template.cfm
```

### Template Selection Algorithm
```javascript
class TemplateSelector {
    selectTemplate(componentType, features, complexity, existingPatterns) {
        const templateMap = {
            model: this.selectModelTemplate(features, complexity),
            controller: this.selectControllerTemplate(features, complexity),
            view: this.selectViewTemplate(features, complexity),
            migration: this.selectMigrationTemplate(features, complexity)
        };

        let selectedTemplate = templateMap[componentType];

        // Adapt template to existing patterns
        selectedTemplate = this.adaptToExistingPatterns(selectedTemplate, existingPatterns);

        return selectedTemplate;
    }

    selectModelTemplate(features, complexity) {
        // Authentication model
        if (features.includes('authentication')) {
            return 'user-authentication-template.cfm';
        }

        // Complex associations
        if (complexity === 'complex' || features.includes('many_associations')) {
            return 'association-heavy-template.cfm';
        }

        // Heavy validation requirements
        if (features.includes('validation_intensive')) {
            return 'validation-intensive-template.cfm';
        }

        // Default basic model
        return 'basic-model-template.cfm';
    }

    selectControllerTemplate(features, complexity) {
        // API controller
        if (features.includes('api')) {
            return 'api-controller-template.cfm';
        }

        // Admin controller
        if (features.includes('admin')) {
            return 'admin-controller-template.cfm';
        }

        // Authentication controller
        if (features.includes('authentication')) {
            return 'authentication-controller.cfm';
        }

        // Default CRUD controller
        return 'basic-crud-controller.cfm';
    }
}
```

## Code Generation Patterns

### Model Generation Template
```cfm
<!-- Basic Model Template -->
component extends="Model" {

    function config() {
        // Associations - CONSISTENT ARGUMENT STYLE ENFORCED
        {{#associations}}
        {{#if (eq type "hasMany")}}
        hasMany(name="{{target}}"{{#if dependent}}, dependent="{{dependent}}"{{/if}});
        {{/if}}
        {{#if (eq type "belongsTo")}}
        belongsTo(name="{{target}}"{{#if foreignKey}}, foreignKey="{{foreignKey}}"{{/if}});
        {{/if}}
        {{#if (eq type "hasOne")}}
        hasOne(name="{{target}}"{{#if dependent}}, dependent="{{dependent}}"{{/if}});
        {{/if}}
        {{/associations}}

        // Validations - ANTI-PATTERN PREVENTION
        {{#validations}}
        {{#if (eq type "presence")}}
        validatesPresenceOf(properties="{{properties}}");
        {{/if}}
        {{#if (eq type "uniqueness")}}
        validatesUniquenessOf(property="{{property}}"{{#if scope}}, scope="{{scope}}"{{/if}});
        {{/if}}
        {{#if (eq type "format")}}
        validatesFormatOf(property="{{property}}", regEx="{{regex}}");
        {{/if}}
        {{#if (eq type "length")}}
        validatesLengthOf(property="{{property}}"{{#if minimum}}, minimum={{minimum}}{{/if}}{{#if maximum}}, maximum={{maximum}}{{/if}});
        {{/if}}
        {{/validations}}

        // Callbacks
        {{#callbacks}}
        {{callback}}("{{method}}");
        {{/callbacks}}

        // Security - Always include timestamps for audit trail
        timestamps();
    }

    {{#customMethods}}
    // Custom finder methods
    function findBy{{pascalCase property}}(required {{dataType}} {{property}}) {
        return findOne(where="{{snakeCase property}} = :{{property}}", {{property}}=arguments.{{property}});
    }
    {{/customMethods}}

    {{#if isUserModel}}
    // Authentication methods
    function authenticate(required string password) {
        return hashPassword(arguments.password) == this.password;
    }

    private function hashPassword(required string password) {
        return hash(arguments.password & this.salt, "SHA-256");
    }
    {{/if}}

    {{#businessMethods}}
    // Business logic methods
    function {{methodName}}({{#parameters}}{{#unless @first}}, {{/unless}}{{type}} {{name}}{{/parameters}}) {
        {{methodBody}}
    }
    {{/businessMethods}}
}
```

### Controller Generation Template
```cfm
<!-- Basic CRUD Controller Template -->
component extends="Controller" {

    function config() {
        // Filters - SECURITY FIRST
        {{#filters}}
        filters(through="{{name}}"{{#if except}}, except="{{except}}"{{/if}}{{#if only}}, only="{{only}}"{{/if}});
        {{/filters}}

        // Parameter verification - INPUT VALIDATION
        {{#paramVerifications}}
        verifies({{#if only}}only="{{only}}", {{/if}}{{#if except}}except="{{except}}", {{/if}}params="{{params}}", paramsTypes="{{paramsTypes}}");
        {{/paramVerifications}}

        // Content type support
        provides("{{contentTypes}}");

        {{#if csrfProtection}}
        // CSRF Protection - SECURITY REQUIREMENT
        protectsFromForgery();
        {{/if}}
    }

    // Index action - LIST VIEW
    function index() {
        {{modelVariable}} = model("{{modelName}}").findAll({{#if defaultOrder}}order="{{defaultOrder}}"{{/if}}{{#if includes}}, include="{{includes}}"{{/if}}{{#if pagination}}, page=params.page, perPage={{perPage}}{{/if}});

        {{#if hasSearch}}
        // Search functionality
        if (structKeyExists(params, "search") && len(trim(params.search))) {
            {{modelVariable}} = model("{{modelName}}").findAll(
                where="{{searchFields}} LIKE :search",
                search="%#params.search#%"{{#if defaultOrder}},
                order="{{defaultOrder}}"{{/if}}
            );
        }
        {{/if}}
    }

    // Show action - DETAIL VIEW
    function show() {
        {{singularVariable}} = model("{{modelName}}").findByKey(key=params.key{{#if includes}}, include="{{includes}}"{{/if}});

        if (!isObject({{singularVariable}})) {
            renderText(text="{{modelName}} not found", status=404);
            return;
        }
    }

    // New action - FORM DISPLAY
    function new() {
        {{singularVariable}} = model("{{modelName}}").new();
        {{#relatedModels}}
        {{variable}} = model("{{model}}").findAll({{#if order}}order="{{order}}"{{/if}});
        {{/relatedModels}}
    }

    // Create action - FORM PROCESSING
    function create() {
        {{singularVariable}} = model("{{modelName}}").new({{#if nestedParams}}params.{{nestedParams}}{{else}}params{{/if}});

        if ({{singularVariable}}.save()) {
            redirectTo({{#if redirectRoute}}route="{{redirectRoute}}", key={{singularVariable}}.id{{else}}action="index"{{/if}}, success="{{modelName}} created successfully!");
        } else {
            {{#relatedModels}}
            {{variable}} = model("{{model}}").findAll({{#if order}}order="{{order}}"{{/if}});
            {{/relatedModels}}
            renderView(action="new");
        }
    }

    // Edit action - EDIT FORM DISPLAY
    function edit() {
        {{singularVariable}} = model("{{modelName}}").findByKey(key=params.key);

        if (!isObject({{singularVariable}})) {
            redirectTo(action="index", error="{{modelName}} not found");
            return;
        }

        {{#relatedModels}}
        {{variable}} = model("{{model}}").findAll({{#if order}}order="{{order}}"{{/if}});
        {{/relatedModels}}
    }

    // Update action - UPDATE PROCESSING
    function update() {
        {{singularVariable}} = model("{{modelName}}").findByKey(key=params.key);

        if (!isObject({{singularVariable}})) {
            redirectTo(action="index", error="{{modelName}} not found");
            return;
        }

        if ({{singularVariable}}.update({{#if nestedParams}}params.{{nestedParams}}{{else}}params{{/if}})) {
            redirectTo({{#if redirectRoute}}route="{{redirectRoute}}", key={{singularVariable}}.id{{else}}action="show", key={{singularVariable}}.id{{/if}}, success="{{modelName}} updated successfully!");
        } else {
            {{#relatedModels}}
            {{variable}} = model("{{model}}").findAll({{#if order}}order="{{order}}"{{/if}});
            {{/relatedModels}}
            renderView(action="edit");
        }
    }

    {{#if hasDelete}}
    // Delete action - DELETION PROCESSING
    function delete() {
        {{singularVariable}} = model("{{modelName}}").findByKey(key=params.key);

        if (!isObject({{singularVariable}})) {
            redirectTo(action="index", error="{{modelName}} not found");
            return;
        }

        if ({{singularVariable}}.delete()) {
            redirectTo(action="index", success="{{modelName}} deleted successfully!");
        } else {
            redirectTo(action="index", error="Unable to delete {{modelName}}");
        }
    }
    {{/if}}

    {{#authenticationRequired}}
    // Authentication filter
    private function authenticate() {
        if (!session.authenticated) {
            redirectTo(route="login", error="Please log in to continue");
        }
    }
    {{/authenticationRequired}}

    {{#authorizationRequired}}
    // Authorization filter
    private function authorize() {
        if (!session.user.hasRole("{{requiredRole}}")) {
            renderText(text="Access denied", status=403);
        }
    }
    {{/authorizationRequired}}

    {{#findFilter}}
    // Find resource filter
    private function find{{modelName}}() {
        {{singularVariable}} = model("{{modelName}}").findByKey(key=params.key);
        if (!isObject({{singularVariable}})) {
            renderText(text="{{modelName}} not found", status=404);
        }
    }
    {{/findFilter}}
}
```

### View Generation Template
```cfm
<!-- Index View Template -->
<cfparam name="{{modelVariable}}">
{{#if layoutSpecific}}
<cfparam name="pageTitle" default="{{pageTitle}}">
{{/if}}

<cfoutput>
{{#if contentFor}}
#contentFor("title", "{{pageTitle}}")#
{{/if}}

<div class="{{containerClass}}">
    <div class="row">
        <div class="col-md-12">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h1>{{pageTitle}}</h1>
                {{#if hasCreateButton}}
                #linkTo(route="new{{modelName}}", text="New {{singularDisplayName}}", class="btn btn-primary")#
                {{/if}}
            </div>

            {{#if hasSearch}}
            <!-- Search Form -->
            <div class="mb-4">
                #startFormTag(route="{{indexRoute}}", method="get", class="d-flex")#
                    <div class="flex-grow-1 me-2">
                        #textField(name="search", value=params.search, placeholder="Search {{pluralDisplayName}}...", class="form-control")#
                    </div>
                    <button type="submit" class="btn btn-outline-secondary">Search</button>
                #endFormTag()#
            </div>
            {{/if}}

            <!-- Results -->
            <cfif {{modelVariable}}.recordCount gt 0>
                {{#if displayType eq "table"}}
                <!-- Table View -->
                <div class="table-responsive">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                {{#tableColumns}}
                                <th>{{displayName}}</th>
                                {{/tableColumns}}
                                <th width="200">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <!-- CRITICAL: Proper query loop syntax - ANTI-PATTERN PREVENTION -->
                            <cfloop query="{{modelVariable}}">
                                <tr>
                                    {{#tableColumns}}
                                    <td>
                                        {{#if isLink}}
                                        #linkTo(route="{{linkRoute}}", key={{modelVariable}}.id, text={{modelVariable}}.{{field}})#
                                        {{else}}
                                        #{{modelVariable}}.{{field}}#
                                        {{/if}}
                                    </td>
                                    {{/tableColumns}}
                                    <td>
                                        <div class="btn-group btn-group-sm">
                                            #linkTo(route="{{showRoute}}", key={{modelVariable}}.id, text="View", class="btn btn-outline-primary btn-sm")#
                                            #linkTo(route="{{editRoute}}", key={{modelVariable}}.id, text="Edit", class="btn btn-outline-secondary btn-sm")#
                                            {{#if hasDelete}}
                                            #linkTo(route="{{deleteRoute}}", key={{modelVariable}}.id, method="delete", confirm="Are you sure?", text="Delete", class="btn btn-outline-danger btn-sm")#
                                            {{/if}}
                                        </div>
                                    </td>
                                </tr>
                            </cfloop>
                        </tbody>
                    </table>
                </div>
                {{else}}
                <!-- Card View -->
                <div class="row">
                    <!-- CRITICAL: Proper query loop syntax - ANTI-PATTERN PREVENTION -->
                    <cfloop query="{{modelVariable}}">
                        <div class="col-md-4 mb-4">
                            <div class="card">
                                {{#if hasImage}}
                                <div class="card-img-top">
                                    <!-- Image placeholder or actual image -->
                                </div>
                                {{/if}}
                                <div class="card-body">
                                    <h5 class="card-title">
                                        #linkTo(route="{{showRoute}}", key={{modelVariable}}.id, text={{modelVariable}}.{{titleField}})#
                                    </h5>
                                    {{#cardFields}}
                                    <p class="card-text">
                                        <strong>{{label}}:</strong> #{{modelVariable}}.{{field}}#
                                    </p>
                                    {{/cardFields}}
                                    <div class="btn-group">
                                        #linkTo(route="{{showRoute}}", key={{modelVariable}}.id, text="View", class="btn btn-primary btn-sm")#
                                        #linkTo(route="{{editRoute}}", key={{modelVariable}}.id, text="Edit", class="btn btn-secondary btn-sm")#
                                    </div>
                                </div>
                            </div>
                        </div>
                    </cfloop>
                </div>
                {{/if}}

                {{#if hasPagination}}
                <!-- Pagination -->
                <div class="d-flex justify-content-center">
                    #paginationLinks({{modelVariable}})#
                </div>
                {{/if}}
            <cfelse>
                <!-- Empty State -->
                <div class="text-center py-5">
                    <h3 class="text-muted">No {{pluralDisplayName}} found</h3>
                    <p class="text-muted">{{emptyStateMessage}}</p>
                    {{#if hasCreateButton}}
                    #linkTo(route="new{{modelName}}", text="Create {{singularDisplayName}}", class="btn btn-primary")#
                    {{/if}}
                </div>
            </cfif>
        </div>
    </div>
</div>
</cfoutput>
```

## Error Recovery Framework

### Error Detection Patterns
```javascript
class ErrorDetector {
    detectErrors(generatedCode, componentType) {
        const errors = [];

        // Mixed argument detection
        const mixedArgErrors = this.detectMixedArguments(generatedCode);
        if (mixedArgErrors.length > 0) {
            errors.push({
                type: 'mixed_arguments',
                severity: 'critical',
                locations: mixedArgErrors,
                description: 'Mixed positional and named arguments detected',
                recovery: 'convert_to_consistent_style'
            });
        }

        // Query/Array confusion detection
        const queryArrayErrors = this.detectQueryArrayConfusion(generatedCode);
        if (queryArrayErrors.length > 0) {
            errors.push({
                type: 'query_array_confusion',
                severity: 'critical',
                locations: queryArrayErrors,
                description: 'ArrayLen() or array loops used on query objects',
                recovery: 'use_proper_query_methods'
            });
        }

        // Naming convention errors
        const namingErrors = this.detectNamingErrors(generatedCode, componentType);
        if (namingErrors.length > 0) {
            errors.push({
                type: 'naming_convention',
                severity: 'medium',
                locations: namingErrors,
                description: 'Incorrect naming conventions detected',
                recovery: 'fix_naming_conventions'
            });
        }

        return errors;
    }

    detectMixedArguments(code) {
        const mixedArgPatterns = [
            /hasMany\s*\(\s*"[^"]*"\s*,\s*\w+\s*=/g,
            /belongsTo\s*\(\s*"[^"]*"\s*,\s*\w+\s*=/g,
            /findByKey\s*\(\s*[^,]*,\s*\w+\s*=/g,
            /validatesPresenceOf\s*\(\s*"[^"]*"\s*,\s*\w+\s*=/g
        ];

        const errors = [];
        mixedArgPatterns.forEach(pattern => {
            const matches = [...code.matchAll(pattern)];
            matches.forEach(match => {
                errors.push({
                    line: this.getLineNumber(code, match.index),
                    column: match.index,
                    text: match[0],
                    suggestion: this.suggestConsistentArgs(match[0])
                });
            });
        });

        return errors;
    }

    detectQueryArrayConfusion(code) {
        const queryArrayPatterns = [
            /ArrayLen\s*\(\s*\w+\s*\.\s*\w+\s*\(\s*\)\s*\)/g,
            /<cfloop\s+array\s*=\s*"#\w+#"/g,
            /for\s*\(\s*\w+\s+in\s+\w+\.\w+\(\)\s*\)/g
        ];

        const errors = [];
        queryArrayPatterns.forEach(pattern => {
            const matches = [...code.matchAll(pattern)];
            matches.forEach(match => {
                errors.push({
                    line: this.getLineNumber(code, match.index),
                    column: match.index,
                    text: match[0],
                    suggestion: this.suggestQueryMethod(match[0])
                });
            });
        });

        return errors;
    }
}
```

### Recovery Action System
```javascript
class ErrorRecoverySystem {
    recoverFromError(error, originalCode, context) {
        switch (error.type) {
            case 'mixed_arguments':
                return this.fixMixedArguments(originalCode, error, context);
            case 'query_array_confusion':
                return this.fixQueryArrayConfusion(originalCode, error, context);
            case 'naming_convention':
                return this.fixNamingConventions(originalCode, error, context);
            case 'validation_failure':
                return this.fixValidationFailure(originalCode, error, context);
            default:
                return this.genericErrorRecovery(originalCode, error, context);
        }
    }

    fixMixedArguments(code, error, context) {
        // Determine dominant argument style in existing codebase
        const argumentStyle = this.detectDominantArgumentStyle(context.existingCode);

        // Convert all function calls to consistent style
        let fixedCode = code;

        if (argumentStyle === 'named') {
            // Convert to all named arguments
            fixedCode = fixedCode.replace(
                /hasMany\s*\(\s*"([^"]*)"\s*,\s*(\w+)\s*=\s*"([^"]*)"/g,
                'hasMany(name="$1", $2="$3")'
            );
            fixedCode = fixedCode.replace(
                /belongsTo\s*\(\s*"([^"]*)"\s*,\s*(\w+)\s*=\s*"([^"]*)"/g,
                'belongsTo(name="$1", $2="$3")'
            );
        } else {
            // Convert to all positional arguments
            fixedCode = fixedCode.replace(
                /hasMany\s*\(\s*name\s*=\s*"([^"]*)"\s*,\s*\w+\s*=\s*"[^"]*"/g,
                'hasMany("$1")'
            );
            fixedCode = fixedCode.replace(
                /belongsTo\s*\(\s*name\s*=\s*"([^"]*)"\s*,\s*\w+\s*=\s*"[^"]*"/g,
                'belongsTo("$1")'
            );
        }

        return {
            fixedCode: fixedCode,
            changes: this.getChanges(code, fixedCode),
            validationRequired: true
        };
    }

    fixQueryArrayConfusion(code, error, context) {
        let fixedCode = code;

        // Fix ArrayLen() on queries
        fixedCode = fixedCode.replace(
            /ArrayLen\s*\(\s*(\w+)\s*\.\s*(\w+)\s*\(\s*\)\s*\)/g,
            '$1.$2().recordCount'
        );

        // Fix array loops on queries
        fixedCode = fixedCode.replace(
            /<cfloop\s+array\s*=\s*"#(\w+)#"\s+index\s*=\s*"(\w+)">/g,
            '<cfloop query="$1">'
        );

        // Fix for-in loops on queries
        fixedCode = fixedCode.replace(
            /for\s*\(\s*(\w+)\s+in\s+(\w+)\.(\w+)\(\)\s*\)/g,
            '/* Use <cfloop query="$2.$3()"> instead of for-in loop */'
        );

        return {
            fixedCode: fixedCode,
            changes: this.getChanges(code, fixedCode),
            validationRequired: true
        };
    }

    fixNamingConventions(code, error, context) {
        let fixedCode = code;

        // Fix model naming (should be singular)
        const modelNameFixes = {
            'Users.cfc': 'User.cfc',
            'Posts.cfc': 'Post.cfc',
            'Comments.cfc': 'Comment.cfc',
            'Products.cfc': 'Product.cfc'
        };

        // Fix controller naming (should be plural)
        const controllerNameFixes = {
            'UserController.cfc': 'UsersController.cfc',
            'PostController.cfc': 'PostsController.cfc',
            'CommentController.cfc': 'CommentsController.cfc'
        };

        // Apply naming fixes
        Object.entries(modelNameFixes).forEach(([wrong, correct]) => {
            if (code.includes(wrong)) {
                fixedCode = fixedCode.replace(new RegExp(wrong, 'g'), correct);
            }
        });

        Object.entries(controllerNameFixes).forEach(([wrong, correct]) => {
            if (code.includes(wrong)) {
                fixedCode = fixedCode.replace(new RegExp(wrong, 'g'), correct);
            }
        });

        return {
            fixedCode: fixedCode,
            changes: this.getChanges(code, fixedCode),
            validationRequired: true
        };
    }
}
```

### Progressive Recovery Strategy
```javascript
class ProgressiveRecoveryStrategy {
    attemptRecovery(error, originalCode, context, attemptNumber = 1) {
        const maxAttempts = 3;

        if (attemptNumber > maxAttempts) {
            return {
                success: false,
                reason: 'Maximum recovery attempts exceeded',
                fallbackAction: 'request_human_intervention'
            };
        }

        // Progressive recovery strategies
        const strategies = [
            'template_substitution',      // Attempt 1: Try different template
            'pattern_simplification',     // Attempt 2: Simplify the pattern
            'manual_intervention'         // Attempt 3: Request human help
        ];

        const strategy = strategies[attemptNumber - 1];

        switch (strategy) {
            case 'template_substitution':
                return this.tryAlternativeTemplate(error, originalCode, context);
            case 'pattern_simplification':
                return this.simplifyPattern(error, originalCode, context);
            case 'manual_intervention':
                return this.requestManualIntervention(error, originalCode, context);
        }
    }

    tryAlternativeTemplate(error, originalCode, context) {
        // Load alternative template from .ai documentation
        const alternativeTemplate = this.loadAlternativeTemplate(context.componentType, error.type);

        if (alternativeTemplate) {
            const regeneratedCode = this.generateFromTemplate(alternativeTemplate, context.data);
            const errors = this.validateCode(regeneratedCode);

            if (errors.length === 0) {
                return {
                    success: true,
                    fixedCode: regeneratedCode,
                    strategy: 'alternative_template',
                    template: alternativeTemplate.name
                };
            }
        }

        return { success: false, reason: 'No suitable alternative template found' };
    }

    simplifyPattern(error, originalCode, context) {
        // Remove complex features and use basic patterns
        const simplifiedContext = this.simplifyContext(context);
        const basicTemplate = this.loadBasicTemplate(context.componentType);

        const simplifiedCode = this.generateFromTemplate(basicTemplate, simplifiedContext);
        const errors = this.validateCode(simplifiedCode);

        if (errors.length === 0) {
            return {
                success: true,
                fixedCode: simplifiedCode,
                strategy: 'simplified_pattern',
                removedFeatures: this.getRemovedFeatures(context, simplifiedContext)
            };
        }

        return { success: false, reason: 'Simplified pattern still contains errors' };
    }
}
```

## Quality Assurance Integration

### Continuous Validation System
```javascript
class ContinuousValidator {
    validateDuringGeneration(code, phase, context) {
        const validations = {
            syntax: this.validateSyntax(code),
            patterns: this.validatePatterns(code, context),
            security: this.validateSecurity(code, context),
            performance: this.validatePerformance(code, context),
            consistency: this.validateConsistency(code, context)
        };

        const errors = [];
        const warnings = [];

        Object.entries(validations).forEach(([type, results]) => {
            errors.push(...results.errors);
            warnings.push(...results.warnings);
        });

        return {
            valid: errors.length === 0,
            errors: errors,
            warnings: warnings,
            phase: phase,
            timestamp: new Date().toISOString()
        };
    }

    validatePatterns(code, context) {
        const errors = [];
        const warnings = [];

        // Check against known anti-patterns from .ai documentation
        const antiPatterns = this.loadAntiPatterns();

        antiPatterns.forEach(pattern => {
            if (this.matchesAntiPattern(code, pattern)) {
                errors.push({
                    type: 'anti_pattern',
                    pattern: pattern.name,
                    description: pattern.description,
                    suggestion: pattern.solution
                });
            }
        });

        // Check consistency with existing codebase
        const consistencyIssues = this.checkConsistency(code, context.existingCode);
        warnings.push(...consistencyIssues);

        return { errors, warnings };
    }

    validateSecurity(code, context) {
        const errors = [];
        const warnings = [];

        // Check for CSRF protection in forms
        if (code.includes('<form') || code.includes('startFormTag')) {
            if (!code.includes('authenticityToken') && !code.includes('csrfToken')) {
                warnings.push({
                    type: 'security',
                    issue: 'missing_csrf_protection',
                    description: 'Forms should include CSRF protection'
                });
            }
        }

        // Check for SQL injection protection
        const sqlPatterns = [
            /where\s*=\s*"[^"]*#[^#]*#[^"]*"/gi,
            /query\s*=\s*"[^"]*#[^#]*#[^"]*"/gi
        ];

        sqlPatterns.forEach(pattern => {
            if (pattern.test(code)) {
                errors.push({
                    type: 'security',
                    issue: 'potential_sql_injection',
                    description: 'Direct variable interpolation in SQL may be vulnerable to injection'
                });
            }
        });

        return { errors, warnings };
    }
}
```

This template-driven implementation system ensures consistent, high-quality code generation with comprehensive error recovery and continuous quality validation, making the `/wheels_execute` workflow robust and reliable.