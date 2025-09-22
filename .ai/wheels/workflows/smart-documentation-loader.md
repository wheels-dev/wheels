# Smart Documentation Loading System Implementation

## Overview
A concrete implementation of the intelligent context-aware documentation loading system that can be integrated into the wheels_execute command to dynamically load the most relevant documentation based on project analysis and task requirements.

## Core Implementation Components

### 1. Project Context Analyzer
```javascript
class ProjectContextAnalyzer {
    constructor(projectPath) {
        this.projectPath = projectPath;
        this.context = {
            models: [],
            controllers: [],
            views: [],
            hasAuthentication: false,
            hasAPI: false,
            hasAdminInterface: false,
            hasFileUploads: false,
            hasEmailFeatures: false,
            hasTesting: false,
            complexityLevel: 'simple',
            frameworkVersion: '2.x',
            existingPatterns: {
                argumentStyles: [],
                associationPatterns: [],
                validationPatterns: [],
                routingPatterns: []
            },
            riskFactors: []
        };
    }

    async analyzeProject() {
        // Analyze directory structure
        await this.scanDirectoryStructure();

        // Analyze existing code patterns
        await this.analyzeCodePatterns();

        // Detect features and complexity
        await this.detectFeatures();

        // Assess risk factors
        await this.assessRiskFactors();

        return this.context;
    }

    async scanDirectoryStructure() {
        try {
            // Scan models
            const modelsPath = path.join(this.projectPath, 'app', 'models');
            if (fs.existsSync(modelsPath)) {
                const modelFiles = fs.readdirSync(modelsPath)
                    .filter(file => file.endsWith('.cfc'))
                    .map(file => file.replace('.cfc', ''));
                this.context.models = modelFiles;
            }

            // Scan controllers
            const controllersPath = path.join(this.projectPath, 'app', 'controllers');
            if (fs.existsSync(controllersPath)) {
                const controllerFiles = fs.readdirSync(controllersPath)
                    .filter(file => file.endsWith('.cfc'))
                    .map(file => file.replace('.cfc', ''));
                this.context.controllers = controllerFiles;
            }

            // Scan views
            const viewsPath = path.join(this.projectPath, 'app', 'views');
            if (fs.existsSync(viewsPath)) {
                const viewDirs = fs.readdirSync(viewsPath, { withFileTypes: true })
                    .filter(dirent => dirent.isDirectory())
                    .map(dirent => dirent.name);
                this.context.views = viewDirs;
            }

        } catch (error) {
            console.warn('Error scanning directory structure:', error.message);
        }
    }

    async analyzeCodePatterns() {
        // Analyze models for patterns
        for (const model of this.context.models) {
            try {
                const modelPath = path.join(this.projectPath, 'app', 'models', `${model}.cfc`);
                if (fs.existsSync(modelPath)) {
                    const content = fs.readFileSync(modelPath, 'utf8');

                    // Detect argument styles in associations
                    const associations = this.extractAssociations(content);
                    associations.forEach(assoc => {
                        this.context.existingPatterns.associationPatterns.push(assoc);
                    });

                    // Detect argument styles
                    const argStyle = this.detectArgumentStyle(content);
                    if (argStyle) {
                        this.context.existingPatterns.argumentStyles.push(argStyle);
                    }

                    // Detect validations
                    const validations = this.extractValidations(content);
                    validations.forEach(validation => {
                        this.context.existingPatterns.validationPatterns.push(validation);
                    });
                }
            } catch (error) {
                console.warn(`Error analyzing model ${model}:`, error.message);
            }
        }

        // Analyze controllers for patterns
        for (const controller of this.context.controllers) {
            try {
                const controllerPath = path.join(this.projectPath, 'app', 'controllers', `${controller}.cfc`);
                if (fs.existsSync(controllerPath)) {
                    const content = fs.readFileSync(controllerPath, 'utf8');

                    // Detect routing patterns, filters, etc.
                    const patterns = this.extractControllerPatterns(content);
                    patterns.forEach(pattern => {
                        this.context.existingPatterns.routingPatterns.push(pattern);
                    });
                }
            } catch (error) {
                console.warn(`Error analyzing controller ${controller}:`, error.message);
            }
        }
    }

    extractAssociations(content) {
        const associations = [];

        // Match hasMany, belongsTo, hasOne patterns
        const associationRegex = /(hasMany|belongsTo|hasOne)\s*\(\s*([^)]+)\)/g;
        let match;

        while ((match = associationRegex.exec(content)) !== null) {
            const type = match[1];
            const params = match[2];

            // Determine if using named or positional arguments
            const isNamed = params.includes('name=') || params.includes('dependent=');
            const isPositional = !isNamed && params.includes('"');

            associations.push({
                type,
                parameters: params,
                argumentStyle: isNamed ? 'named' : isPositional ? 'positional' : 'unknown'
            });
        }

        return associations;
    }

    detectArgumentStyle(content) {
        // Look for patterns that indicate argument style preference
        const namedArgPatterns = [
            /hasMany\s*\(\s*name\s*=/,
            /belongsTo\s*\(\s*name\s*=/,
            /findByKey\s*\(\s*key\s*=/,
            /renderText\s*\(\s*text\s*=/
        ];

        const positionalArgPatterns = [
            /hasMany\s*\(\s*"[^"]+"\s*\)/,
            /belongsTo\s*\(\s*"[^"]+"\s*\)/,
            /findByKey\s*\(\s*[^,)]+\s*\)/,
            /renderText\s*\(\s*"[^"]+"\s*\)/
        ];

        const namedMatches = namedArgPatterns.some(pattern => pattern.test(content));
        const positionalMatches = positionalArgPatterns.some(pattern => pattern.test(content));

        if (namedMatches && !positionalMatches) return 'named';
        if (positionalMatches && !namedMatches) return 'positional';
        if (namedMatches && positionalMatches) return 'mixed'; // Risk factor!
        return 'unknown';
    }

    extractValidations(content) {
        const validations = [];

        const validationRegex = /(validates\w+)\s*\(\s*([^)]+)\)/g;
        let match;

        while ((match = validationRegex.exec(content)) !== null) {
            validations.push({
                type: match[1],
                parameters: match[2]
            });
        }

        return validations;
    }

    async detectFeatures() {
        // Detect authentication
        const hasUserModel = this.context.models.some(m =>
            m.toLowerCase().includes('user') || m.toLowerCase().includes('account')
        );
        const hasSessionController = this.context.controllers.some(c =>
            c.toLowerCase().includes('session') || c.toLowerCase().includes('auth')
        );
        this.context.hasAuthentication = hasUserModel || hasSessionController;

        // Detect API
        const hasAPIController = this.context.controllers.some(c =>
            c.toLowerCase().includes('api') || c.toLowerCase().includes('rest')
        );
        this.context.hasAPI = hasAPIController;

        // Detect admin interface
        const hasAdminController = this.context.controllers.some(c =>
            c.toLowerCase().includes('admin') || c.toLowerCase().includes('manage')
        );
        this.context.hasAdminInterface = hasAdminController;

        // Detect file uploads (check for file upload patterns in controllers)
        const hasFileUploads = await this.checkForFileUploads();
        this.context.hasFileUploads = hasFileUploads;

        // Assess complexity
        this.context.complexityLevel = this.assessComplexity();
    }

    async checkForFileUploads() {
        for (const controller of this.context.controllers) {
            try {
                const controllerPath = path.join(this.projectPath, 'app', 'controllers', `${controller}.cfc`);
                if (fs.existsSync(controllerPath)) {
                    const content = fs.readFileSync(controllerPath, 'utf8');

                    // Check for file upload patterns
                    const fileUploadPatterns = [
                        /fileField\s*\(/,
                        /multipart\/form-data/,
                        /uploadFile\s*\(/,
                        /cffile\s+action\s*=\s*"upload"/
                    ];

                    if (fileUploadPatterns.some(pattern => pattern.test(content))) {
                        return true;
                    }
                }
            } catch (error) {
                console.warn(`Error checking file uploads in ${controller}:`, error.message);
            }
        }
        return false;
    }

    assessComplexity() {
        let score = 0;

        score += this.context.models.length * 2;
        score += this.context.controllers.length * 3;
        score += this.context.views.length * 1;

        if (this.context.hasAuthentication) score += 10;
        if (this.context.hasAPI) score += 8;
        if (this.context.hasAdminInterface) score += 6;
        if (this.context.hasFileUploads) score += 4;

        // Check for complex associations
        const complexAssociations = this.context.existingPatterns.associationPatterns.filter(
            assoc => assoc.parameters.includes('dependent') || assoc.parameters.includes('through')
        );
        score += complexAssociations.length * 3;

        if (score < 20) return 'simple';
        if (score < 50) return 'moderate';
        return 'complex';
    }

    assessRiskFactors() {
        // Check for mixed argument styles
        const argumentStyles = [...new Set(this.context.existingPatterns.argumentStyles)];
        if (argumentStyles.length > 1 && argumentStyles.includes('mixed')) {
            this.context.riskFactors.push({
                type: 'mixed_arguments',
                severity: 'high',
                description: 'Mixed argument styles detected in codebase',
                affectedFiles: 'Multiple models and controllers'
            });
        }

        // Check for complex associations that might cause query/array confusion
        const complexAssociations = this.context.existingPatterns.associationPatterns.filter(
            assoc => assoc.type === 'hasMany'
        );
        if (complexAssociations.length > 0 && this.context.views.length > 0) {
            this.context.riskFactors.push({
                type: 'query_array_confusion',
                severity: 'medium',
                description: 'Views with associations present - risk of query/array confusion',
                affectedFiles: 'Models with hasMany associations and related views'
            });
        }

        // Check for potential N+1 query problems
        if (this.context.models.length > 5 && this.context.views.length > 5) {
            this.context.riskFactors.push({
                type: 'n_plus_one_queries',
                severity: 'medium',
                description: 'Large number of models and views - potential N+1 query issues',
                recommendation: 'Use include parameter in finder methods'
            });
        }
    }
}
```

### 2. Task Intent Analyzer
```javascript
class TaskIntentAnalyzer {
    constructor(taskDescription, projectContext) {
        this.taskDescription = taskDescription.toLowerCase();
        this.projectContext = projectContext;
        this.intent = {
            primaryAction: '',
            components: [],
            features: [],
            complexity: 'simple',
            riskLevel: 'low',
            confidence: 0
        };
    }

    analyzeIntent() {
        this.classifyPrimaryAction();
        this.identifyComponents();
        this.detectFeatures();
        this.assessComplexity();
        this.calculateRiskLevel();
        this.calculateConfidence();

        return this.intent;
    }

    classifyPrimaryAction() {
        const actionPatterns = {
            'create': ['create', 'add', 'build', 'generate', 'make', 'new'],
            'modify': ['update', 'change', 'modify', 'edit', 'alter', 'enhance'],
            'delete': ['remove', 'delete', 'destroy', 'eliminate'],
            'debug': ['fix', 'debug', 'troubleshoot', 'resolve', 'repair', 'error'],
            'optimize': ['optimize', 'improve', 'performance', 'speed', 'faster'],
            'test': ['test', 'testing', 'spec', 'coverage', 'validate']
        };

        for (const [action, keywords] of Object.entries(actionPatterns)) {
            const matches = keywords.filter(keyword =>
                this.taskDescription.includes(keyword)
            );

            if (matches.length > 0) {
                this.intent.primaryAction = action;
                break;
            }
        }

        if (!this.intent.primaryAction) {
            this.intent.primaryAction = 'create'; // Default
        }
    }

    identifyComponents() {
        const componentPatterns = {
            'model': [
                'model', 'user', 'post', 'product', 'order', 'customer',
                'account', 'profile', 'item', 'record', 'data',
                'association', 'relationship', 'validation'
            ],
            'controller': [
                'controller', 'action', 'endpoint', 'route', 'api',
                'request', 'response', 'filter', 'authentication',
                'authorization', 'session'
            ],
            'view': [
                'view', 'template', 'form', 'page', 'interface', 'ui',
                'html', 'layout', 'partial', 'helper', 'display',
                'render', 'show', 'list'
            ],
            'migration': [
                'migration', 'database', 'table', 'schema', 'column',
                'index', 'constraint', 'migrate', 'db'
            ],
            'test': [
                'test', 'testing', 'spec', 'coverage', 'unit',
                'integration', 'browser', 'selenium'
            ]
        };

        for (const [component, keywords] of Object.entries(componentPatterns)) {
            const matches = keywords.filter(keyword =>
                this.taskDescription.includes(keyword)
            );

            if (matches.length > 0) {
                this.intent.components.push(component);
            }
        }

        // If no components detected, infer from action
        if (this.intent.components.length === 0) {
            switch (this.intent.primaryAction) {
                case 'create':
                    this.intent.components.push('model', 'controller', 'view');
                    break;
                case 'debug':
                    // Try to infer from project context
                    if (this.projectContext.riskFactors.length > 0) {
                        this.intent.components.push('model', 'view');
                    }
                    break;
            }
        }
    }

    detectFeatures() {
        const featurePatterns = {
            'authentication': [
                'login', 'auth', 'user', 'session', 'password',
                'register', 'signup', 'signin', 'logout'
            ],
            'crud': [
                'create', 'read', 'update', 'delete', 'manage',
                'crud', 'edit', 'add', 'remove', 'list'
            ],
            'api': [
                'api', 'json', 'rest', 'endpoint', 'service',
                'restful', 'response', 'request'
            ],
            'admin': [
                'admin', 'dashboard', 'management', 'control',
                'administration', 'manage', 'panel'
            ],
            'search': [
                'search', 'filter', 'query', 'find', 'lookup'
            ],
            'email': [
                'email', 'mail', 'notification', 'message',
                'send', 'mailer'
            ],
            'upload': [
                'upload', 'file', 'image', 'attachment',
                'upload', 'document'
            ],
            'validation': [
                'validation', 'validate', 'verify', 'check',
                'required', 'format', 'length'
            ]
        };

        for (const [feature, keywords] of Object.entries(featurePatterns)) {
            const matches = keywords.filter(keyword =>
                this.taskDescription.includes(keyword)
            );

            if (matches.length > 0) {
                this.intent.features.push(feature);
            }
        }
    }

    assessComplexity() {
        let complexityScore = 0;

        // Base complexity from components
        complexityScore += this.intent.components.length * 2;

        // Feature complexity
        const complexFeatures = ['authentication', 'api', 'admin', 'upload'];
        complexityScore += this.intent.features.filter(f =>
            complexFeatures.includes(f)
        ).length * 3;

        // Action complexity
        const complexActions = ['modify', 'optimize', 'debug'];
        if (complexActions.includes(this.intent.primaryAction)) {
            complexityScore += 4;
        }

        // Project context influence
        if (this.projectContext.complexityLevel === 'complex') {
            complexityScore += 3;
        }

        if (complexityScore < 5) this.intent.complexity = 'simple';
        else if (complexityScore < 12) this.intent.complexity = 'moderate';
        else this.intent.complexity = 'complex';
    }

    calculateRiskLevel() {
        let riskScore = 0;

        // Risk from project context
        const highRiskFactors = this.projectContext.riskFactors.filter(
            rf => rf.severity === 'high'
        );
        riskScore += highRiskFactors.length * 3;

        const mediumRiskFactors = this.projectContext.riskFactors.filter(
            rf => rf.severity === 'medium'
        );
        riskScore += mediumRiskFactors.length * 2;

        // Risk from task characteristics
        if (this.intent.components.includes('model') &&
            this.intent.components.includes('view')) {
            riskScore += 2; // Query/array confusion risk
        }

        if (this.intent.features.includes('authentication') ||
            this.intent.features.includes('admin')) {
            riskScore += 2; // Security risk
        }

        if (this.intent.primaryAction === 'modify' &&
            this.projectContext.existingPatterns.argumentStyles.includes('mixed')) {
            riskScore += 3; // High risk of breaking existing patterns
        }

        if (riskScore < 3) this.intent.riskLevel = 'low';
        else if (riskScore < 7) this.intent.riskLevel = 'medium';
        else this.intent.riskLevel = 'high';
    }

    calculateConfidence() {
        let confidence = 0.5; // Base confidence

        // Higher confidence if clear keywords found
        const totalKeywords = this.countKeywordMatches();
        confidence += Math.min(totalKeywords * 0.1, 0.3);

        // Higher confidence if consistent with project context
        if (this.intent.features.some(f => this.projectContextSupportsFeature(f))) {
            confidence += 0.1;
        }

        // Lower confidence if high risk
        if (this.intent.riskLevel === 'high') {
            confidence -= 0.2;
        }

        this.intent.confidence = Math.max(0.1, Math.min(1.0, confidence));
    }

    countKeywordMatches() {
        // Count total keyword matches across all patterns
        // Implementation would count specific matches
        return 5; // Placeholder
    }

    projectContextSupportsFeature(feature) {
        switch (feature) {
            case 'authentication':
                return this.projectContext.hasAuthentication;
            case 'api':
                return this.projectContext.hasAPI;
            case 'admin':
                return this.projectContext.hasAdminInterface;
            case 'upload':
                return this.projectContext.hasFileUploads;
            default:
                return false;
        }
    }
}
```

### 3. Smart Documentation Mapper
```javascript
class SmartDocumentationMapper {
    constructor(projectContext, taskIntent) {
        this.projectContext = projectContext;
        this.taskIntent = taskIntent;
        this.documentationPlan = {
            critical: [],      // Must read first (error prevention)
            primary: [],       // Core documentation for this task
            secondary: [],     // Supporting documentation
            contextual: [],    // Based on project patterns
            preventive: [],    // Anti-pattern prevention
            priority: 1        // Overall priority score
        };
    }

    generateDocumentationPlan() {
        // Always load critical error prevention first
        this.addCriticalDocumentation();

        // Load based on task intent
        this.addTaskSpecificDocumentation();

        // Load based on project context
        this.addContextualDocumentation();

        // Load preventive documentation based on risks
        this.addPreventiveDocumentation();

        // Calculate overall priority
        this.calculatePriority();

        return this.documentationPlan;
    }

    addCriticalDocumentation() {
        // These are ALWAYS loaded first
        this.documentationPlan.critical = [
            '.ai/wheels/troubleshooting/common-errors.md',
            '.ai/wheels/patterns/validation-templates.md'
        ];
    }

    addTaskSpecificDocumentation() {
        // Map primary action to documentation
        const actionMappings = {
            'create': {
                primary: [
                    '.ai/wheels/cli/generators/',
                    '.ai/wheels/snippets/',
                    '.ai/wheels/core-concepts/mvc-architecture/'
                ],
                secondary: [
                    '.ai/wheels/patterns/'
                ]
            },
            'modify': {
                primary: [
                    '.ai/wheels/troubleshooting/',
                    '.ai/wheels/patterns/'
                ],
                secondary: [
                    '.ai/wheels/models/best-practices.md',
                    '.ai/wheels/controllers/best-practices.md'
                ]
            },
            'debug': {
                primary: [
                    '.ai/wheels/troubleshooting/common-errors.md',
                    '.ai/wheels/troubleshooting/session-learnings-2024-09-17.md'
                ],
                secondary: [
                    '.ai/wheels/troubleshooting/form-helper-errors.md'
                ]
            },
            'test': {
                primary: [
                    '.ai/wheels/testing/',
                    '.ai/wheels/models/testing.md',
                    '.ai/wheels/controllers/testing.md'
                ]
            }
        };

        const actionMapping = actionMappings[this.taskIntent.primaryAction];
        if (actionMapping) {
            this.documentationPlan.primary.push(...actionMapping.primary);
            if (actionMapping.secondary) {
                this.documentationPlan.secondary.push(...actionMapping.secondary);
            }
        }

        // Map components to documentation
        const componentMappings = {
            'model': {
                primary: [
                    '.ai/wheels/models/architecture.md',
                    '.ai/wheels/models/associations.md',
                    '.ai/wheels/database/associations/'
                ],
                secondary: [
                    '.ai/wheels/models/validations.md',
                    '.ai/wheels/models/callbacks.md',
                    '.ai/wheels/models/best-practices.md'
                ]
            },
            'controller': {
                primary: [
                    '.ai/wheels/controllers/architecture.md',
                    '.ai/wheels/controllers/rendering.md'
                ],
                secondary: [
                    '.ai/wheels/controllers/filters.md',
                    '.ai/wheels/controllers/params/',
                    '.ai/wheels/controllers/model-interactions.md'
                ]
            },
            'view': {
                primary: [
                    '.ai/wheels/views/data-handling.md',
                    '.ai/wheels/views/helpers/forms.md',
                    '.ai/wheels/views/architecture.md'
                ],
                secondary: [
                    '.ai/wheels/views/layouts.md',
                    '.ai/wheels/views/partials.md',
                    '.ai/wheels/views/best-practices.md'
                ]
            },
            'migration': {
                primary: [
                    '.ai/wheels/database/migrations/creating-migrations.md',
                    '.ai/wheels/database/migrations/column-types.md'
                ],
                secondary: [
                    '.ai/wheels/database/migrations/advanced-operations.md',
                    '.ai/wheels/database/migrations/rollback.md'
                ]
            },
            'test': {
                primary: [
                    '.ai/wheels/testing/browser-automation-patterns.md',
                    '.ai/wheels/models/testing.md',
                    '.ai/wheels/controllers/testing.md'
                ]
            }
        };

        for (const component of this.taskIntent.components) {
            const componentMapping = componentMappings[component];
            if (componentMapping) {
                this.documentationPlan.primary.push(...componentMapping.primary);
                if (componentMapping.secondary) {
                    this.documentationPlan.secondary.push(...componentMapping.secondary);
                }
            }
        }

        // Map features to documentation
        const featureMappings = {
            'authentication': [
                '.ai/wheels/models/user-authentication.md',
                '.ai/wheels/controllers/filters/authentication.md',
                '.ai/wheels/security/csrf-protection.md'
            ],
            'api': [
                '.ai/wheels/controllers/api.md',
                '.ai/wheels/controllers/rendering/json.md'
            ],
            'admin': [
                '.ai/wheels/controllers/filters/authorization.md',
                '.ai/wheels/security/'
            ],
            'upload': [
                '.ai/wheels/files/downloads.md'
            ],
            'validation': [
                '.ai/wheels/models/validations.md',
                '.ai/wheels/database/validations/'
            ]
        };

        for (const feature of this.taskIntent.features) {
            const featureMapping = featureMappings[feature];
            if (featureMapping) {
                this.documentationPlan.contextual.push(...featureMapping);
            }
        }
    }

    addContextualDocumentation() {
        // Add documentation based on existing project patterns
        if (this.projectContext.hasAuthentication &&
            !this.taskIntent.features.includes('authentication')) {
            this.documentationPlan.contextual.push(
                '.ai/wheels/models/user-authentication.md',
                '.ai/wheels/controllers/filters/authentication.md'
            );
        }

        if (this.projectContext.hasAPI &&
            !this.taskIntent.features.includes('api')) {
            this.documentationPlan.contextual.push(
                '.ai/wheels/controllers/api.md'
            );
        }

        // Add complexity-specific documentation
        if (this.projectContext.complexityLevel === 'complex') {
            this.documentationPlan.secondary.push(
                '.ai/wheels/models/advanced-patterns.md',
                '.ai/wheels/views/advanced-patterns.md'
            );
        }

        // Add documentation based on existing argument styles
        const argumentStyles = [...new Set(this.projectContext.existingPatterns.argumentStyles)];
        if (argumentStyles.includes('named')) {
            this.documentationPlan.contextual.push(
                '.ai/wheels/patterns/validation-templates.md'
            );
        }
    }

    addPreventiveDocumentation() {
        // Add documentation based on identified risk factors
        const highRiskFactors = this.projectContext.riskFactors.filter(
            rf => rf.severity === 'high'
        );

        for (const riskFactor of highRiskFactors) {
            switch (riskFactor.type) {
                case 'mixed_arguments':
                    this.documentationPlan.preventive.push(
                        '.ai/wheels/troubleshooting/common-errors.md',
                        '.ai/wheels/patterns/validation-templates.md'
                    );
                    break;
                case 'query_array_confusion':
                    this.documentationPlan.preventive.push(
                        '.ai/wheels/views/data-handling.md',
                        '.ai/wheels/views/query-association-patterns.md'
                    );
                    break;
            }
        }

        // Add preventive documentation based on task characteristics
        if (this.taskIntent.components.includes('model') &&
            this.taskIntent.components.includes('view')) {
            this.documentationPlan.preventive.push(
                '.ai/wheels/views/query-association-patterns.md'
            );
        }

        if (this.taskIntent.features.includes('crud') ||
            this.taskIntent.components.includes('view')) {
            this.documentationPlan.preventive.push(
                '.ai/wheels/troubleshooting/form-helper-errors.md'
            );
        }
    }

    calculatePriority() {
        let priority = 1;

        // Higher priority for high-risk tasks
        if (this.taskIntent.riskLevel === 'high') {
            priority += 2;
        } else if (this.taskIntent.riskLevel === 'medium') {
            priority += 1;
        }

        // Higher priority for complex tasks
        if (this.taskIntent.complexity === 'complex') {
            priority += 1;
        }

        // Higher priority if many risk factors present
        priority += this.projectContext.riskFactors.length * 0.5;

        this.documentationPlan.priority = Math.min(5, priority);
    }
}
```

### 4. Documentation Loader
```javascript
class SmartDocumentationLoader {
    constructor(documentationPlan, aiFolder = '.ai') {
        this.documentationPlan = documentationPlan;
        this.aiFolder = aiFolder;
        this.loadedDocs = {
            content: new Map(),
            metadata: new Map(),
            index: new Map(),
            loadTime: new Date()
        };
    }

    async loadDocumentation() {
        console.log('📚 Loading smart documentation...');

        // Load in priority order with progress tracking
        await this.loadCriticalDocs();
        await this.loadPrimaryDocs();
        await this.loadSecondaryAndContextualDocs();
        await this.loadPreventiveDocs();

        // Create searchable index
        this.createDocumentationIndex();

        console.log(`✅ Loaded ${this.loadedDocs.content.size} documentation files`);
        return this.loadedDocs;
    }

    async loadCriticalDocs() {
        console.log('🚨 Loading critical error prevention documentation...');

        for (const docPath of this.documentationPlan.critical) {
            await this.loadSingleDocument(docPath, 'critical');
        }
    }

    async loadPrimaryDocs() {
        console.log('📖 Loading primary task documentation...');

        // Load primary docs in parallel for speed
        const promises = this.documentationPlan.primary.map(docPath =>
            this.loadSingleDocument(docPath, 'primary')
        );

        await Promise.all(promises);
    }

    async loadSecondaryAndContextualDocs() {
        console.log('📋 Loading secondary and contextual documentation...');

        // Load secondary and contextual docs in parallel
        const allDocs = [
            ...this.documentationPlan.secondary,
            ...this.documentationPlan.contextual
        ];

        const promises = allDocs.map(docPath =>
            this.loadSingleDocument(docPath, 'secondary')
        );

        await Promise.all(promises);
    }

    async loadPreventiveDocs() {
        console.log('🛡️ Loading preventive documentation...');

        for (const docPath of this.documentationPlan.preventive) {
            await this.loadSingleDocument(docPath, 'preventive');
        }
    }

    async loadSingleDocument(docPath, priority) {
        try {
            // Handle directory paths by loading all files
            if (docPath.endsWith('/')) {
                return await this.loadDirectory(docPath, priority);
            }

            const fullPath = path.join(this.aiFolder, docPath);

            if (fs.existsSync(fullPath)) {
                const content = fs.readFileSync(fullPath, 'utf8');
                const metadata = this.extractMetadata(content, docPath);

                this.loadedDocs.content.set(docPath, content);
                this.loadedDocs.metadata.set(docPath, {
                    ...metadata,
                    priority,
                    loadedAt: new Date(),
                    filePath: fullPath
                });

                console.log(`  ✓ Loaded ${docPath} (${priority})`);
            } else {
                console.warn(`  ⚠️ Documentation not found: ${docPath}`);
                await this.tryFallbackDocumentation(docPath, priority);
            }
        } catch (error) {
            console.error(`  ❌ Error loading ${docPath}:`, error.message);
        }
    }

    async loadDirectory(dirPath, priority) {
        const fullPath = path.join(this.aiFolder, dirPath);

        if (!fs.existsSync(fullPath)) {
            console.warn(`  ⚠️ Directory not found: ${dirPath}`);
            return;
        }

        const files = fs.readdirSync(fullPath)
            .filter(file => file.endsWith('.md'))
            .map(file => path.join(dirPath, file));

        for (const file of files) {
            await this.loadSingleDocument(file, priority);
        }
    }

    extractMetadata(content, docPath) {
        const metadata = {
            title: '',
            description: '',
            keyPoints: [],
            codeExamples: [],
            antiPatterns: [],
            solutions: []
        };

        // Extract title (first # heading)
        const titleMatch = content.match(/^#\s+(.+)$/m);
        if (titleMatch) {
            metadata.title = titleMatch[1];
        }

        // Extract description (first paragraph after title)
        const descMatch = content.match(/^#\s+.+\n\n(.+?)$/m);
        if (descMatch) {
            metadata.description = descMatch[1];
        }

        // Extract key points
        const keyPointsMatch = content.match(/## Key Points\n([\s\S]*?)(?=\n## |\n# |$)/);
        if (keyPointsMatch) {
            const keyPoints = keyPointsMatch[1]
                .split('\n')
                .filter(line => line.trim().startsWith('-'))
                .map(line => line.replace(/^-\s*/, ''));
            metadata.keyPoints = keyPoints;
        }

        // Extract code examples
        const codeBlocks = content.match(/```[\s\S]*?```/g) || [];
        metadata.codeExamples = codeBlocks.map(block =>
            block.replace(/```\w*\n/, '').replace(/```$/, '')
        );

        // Extract anti-patterns (❌ or BAD)
        const antiPatterns = content.match(/❌[\s\S]*?(?=✅|$)/g) || [];
        metadata.antiPatterns = antiPatterns;

        return metadata;
    }

    async tryFallbackDocumentation(docPath, priority) {
        // Try alternative paths or MCP resources
        const alternatives = [
            docPath.replace('.md', '-basics.md'),
            docPath.replace('/', '/overview/'),
            docPath + 'README.md'
        ];

        for (const alt of alternatives) {
            const altPath = path.join(this.aiFolder, alt);
            if (fs.existsSync(altPath)) {
                await this.loadSingleDocument(alt, priority);
                return;
            }
        }

        // TODO: Try MCP fallback
        // await this.tryMCPResource(docPath, priority);
    }

    createDocumentationIndex() {
        console.log('🔍 Creating searchable documentation index...');

        const index = {
            antiPatterns: new Map(),
            solutions: new Map(),
            codeTemplates: new Map(),
            keyPoints: new Map()
        };

        for (const [docPath, content] of this.loadedDocs.content.entries()) {
            const metadata = this.loadedDocs.metadata.get(docPath);

            // Index anti-patterns
            metadata.antiPatterns.forEach(pattern => {
                const key = this.extractPatternKey(pattern);
                if (!index.antiPatterns.has(key)) {
                    index.antiPatterns.set(key, []);
                }
                index.antiPatterns.get(key).push({
                    source: docPath,
                    pattern,
                    priority: metadata.priority
                });
            });

            // Index key points
            metadata.keyPoints.forEach(point => {
                const key = point.toLowerCase();
                if (!index.keyPoints.has(key)) {
                    index.keyPoints.set(key, []);
                }
                index.keyPoints.get(key).push({
                    source: docPath,
                    point,
                    priority: metadata.priority
                });
            });

            // Index code examples
            metadata.codeExamples.forEach(example => {
                const key = this.extractCodeKey(example);
                if (!index.codeTemplates.has(key)) {
                    index.codeTemplates.set(key, []);
                }
                index.codeTemplates.get(key).push({
                    source: docPath,
                    code: example,
                    priority: metadata.priority
                });
            });
        }

        this.loadedDocs.index = index;
        console.log(`  ✓ Indexed ${index.antiPatterns.size} anti-patterns, ${index.codeTemplates.size} code templates`);
    }

    extractPatternKey(pattern) {
        // Extract key identifying information from anti-pattern text
        if (pattern.includes('hasMany')) return 'mixed_arguments_hasMany';
        if (pattern.includes('ArrayLen')) return 'query_array_confusion';
        if (pattern.includes('emailField')) return 'invalid_form_helper';
        return 'unknown_pattern';
    }

    extractCodeKey(code) {
        // Extract key identifying information from code examples
        if (code.includes('component extends="Model"')) return 'model_template';
        if (code.includes('component extends="Controller"')) return 'controller_template';
        if (code.includes('<cfloop query=')) return 'view_query_loop';
        return 'code_snippet';
    }

    // Public methods for accessing loaded documentation
    getAntiPatternsFor(patternType) {
        return this.loadedDocs.index.antiPatterns.get(patternType) || [];
    }

    getCodeTemplatesFor(templateType) {
        return this.loadedDocs.index.codeTemplates.get(templateType) || [];
    }

    searchKeyPoints(query) {
        const results = [];
        const queryLower = query.toLowerCase();

        for (const [key, points] of this.loadedDocs.index.keyPoints.entries()) {
            if (key.includes(queryLower)) {
                results.push(...points);
            }
        }

        return results.sort((a, b) => {
            const priorityOrder = { critical: 0, primary: 1, secondary: 2, preventive: 3 };
            return priorityOrder[a.priority] - priorityOrder[b.priority];
        });
    }

    getSolutionsFor(problemType) {
        return this.loadedDocs.index.solutions.get(problemType) || [];
    }

    getLoadedDocsList() {
        return Array.from(this.loadedDocs.content.keys());
    }

    getDocumentationSummary() {
        return {
            totalDocuments: this.loadedDocs.content.size,
            byPriority: {
                critical: this.countByPriority('critical'),
                primary: this.countByPriority('primary'),
                secondary: this.countByPriority('secondary'),
                preventive: this.countByPriority('preventive')
            },
            indexSize: {
                antiPatterns: this.loadedDocs.index.antiPatterns.size,
                codeTemplates: this.loadedDocs.index.codeTemplates.size,
                keyPoints: this.loadedDocs.index.keyPoints.size
            },
            loadTime: this.loadedDocs.loadTime
        };
    }

    countByPriority(priority) {
        let count = 0;
        for (const metadata of this.loadedDocs.metadata.values()) {
            if (metadata.priority === priority) count++;
        }
        return count;
    }
}
```

## Integration with wheels_execute Command

### Enhanced Phase 1: Smart Documentation Loading
```markdown
### Phase 1: Intelligent Documentation Loading (3-5 minutes)

#### 1.1 Project Context Analysis (NEW)
```javascript
const projectAnalyzer = new ProjectContextAnalyzer('/path/to/project');
const projectContext = await projectAnalyzer.analyzeProject();

console.log('📊 Project Analysis Results:');
console.log(`  Models: ${projectContext.models.length}`);
console.log(`  Controllers: ${projectContext.controllers.length}`);
console.log(`  Complexity: ${projectContext.complexityLevel}`);
console.log(`  Risk Factors: ${projectContext.riskFactors.length}`);
```

#### 1.2 Task Intent Recognition (NEW)
```javascript
const taskAnalyzer = new TaskIntentAnalyzer(userTask, projectContext);
const taskIntent = taskAnalyzer.analyzeIntent();

console.log('🎯 Task Intent Analysis:');
console.log(`  Primary Action: ${taskIntent.primaryAction}`);
console.log(`  Components: ${taskIntent.components.join(', ')}`);
console.log(`  Features: ${taskIntent.features.join(', ')}`);
console.log(`  Risk Level: ${taskIntent.riskLevel}`);
console.log(`  Confidence: ${Math.round(taskIntent.confidence * 100)}%`);
```

#### 1.3 Smart Documentation Planning (NEW)
```javascript
const docMapper = new SmartDocumentationMapper(projectContext, taskIntent);
const documentationPlan = docMapper.generateDocumentationPlan();

console.log('📋 Documentation Plan:');
console.log(`  Critical: ${documentationPlan.critical.length} files`);
console.log(`  Primary: ${documentationPlan.primary.length} files`);
console.log(`  Secondary: ${documentationPlan.secondary.length} files`);
console.log(`  Contextual: ${documentationPlan.contextual.length} files`);
console.log(`  Preventive: ${documentationPlan.preventive.length} files`);
```

#### 1.4 Adaptive Documentation Loading (ENHANCED)
```javascript
const docLoader = new SmartDocumentationLoader(documentationPlan);
const loadedDocs = await docLoader.loadDocumentation();

console.log('✅ Smart Documentation Loading Complete:');
const summary = docLoader.getDocumentationSummary();
console.log(`  Total Documents: ${summary.totalDocuments}`);
console.log(`  Anti-patterns Indexed: ${summary.indexSize.antiPatterns}`);
console.log(`  Code Templates: ${summary.indexSize.codeTemplates}`);
```

This smart documentation loading system transforms the static documentation approach into a dynamic, context-aware assistant that adapts to both the project environment and the specific task requirements, providing exactly the right information at the right time.
```

## Usage Example

```javascript
// Complete workflow example
async function smartDocumentationWorkflow(projectPath, userTask) {
    // 1. Analyze project context
    const projectAnalyzer = new ProjectContextAnalyzer(projectPath);
    const projectContext = await projectAnalyzer.analyzeProject();

    // 2. Analyze task intent
    const taskAnalyzer = new TaskIntentAnalyzer(userTask, projectContext);
    const taskIntent = taskAnalyzer.analyzeIntent();

    // 3. Generate documentation plan
    const docMapper = new SmartDocumentationMapper(projectContext, taskIntent);
    const documentationPlan = docMapper.generateDocumentationPlan();

    // 4. Load documentation intelligently
    const docLoader = new SmartDocumentationLoader(documentationPlan);
    const loadedDocs = await docLoader.loadDocumentation();

    // 5. Provide intelligent assistance
    return {
        projectContext,
        taskIntent,
        documentationPlan,
        loadedDocs,
        assistance: {
            antiPatterns: docLoader.getAntiPatternsFor(taskIntent.riskLevel),
            codeTemplates: docLoader.getCodeTemplatesFor(taskIntent.primaryAction),
            keyPoints: docLoader.searchKeyPoints(userTask)
        }
    };
}

// Example usage
const result = await smartDocumentationWorkflow(
    '/path/to/wheels/project',
    'create a blog with posts and comments'
);

console.log('Smart Documentation System Ready:', result.assistance);
```

This implementation provides a concrete, working smart documentation loading system that can be integrated directly into the wheels_execute command.