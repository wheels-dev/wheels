const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

/**
 * Wheels Completion Provider for auto-language detection
 */
class WheelsCompletionProvider {
    constructor() {
        // Cache templates to avoid repeated file reads
        this.templateCache = new Map();
        this.workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    }

    provideCompletionItems(document, position) {
        // Only provide completions for plaintext or unsupported files
        if (document.languageId !== 'plaintext' && document.languageId !== 'cfml') {
            return [];
        }

        const line = document.lineAt(position.line);
        const linePrefix = line.text.substring(0, position.character);

        // Check if we're typing a Wheels template snippet
        const wheelsSnippets = ['wcontroller', 'wmodel'];

        const completions = [];

        for (const snippet of wheelsSnippets) {
            if (snippet.startsWith(linePrefix.toLowerCase().trim())) {
                const completion = new vscode.CompletionItem(snippet, vscode.CompletionItemKind.Snippet);
                completion.insertText = new vscode.SnippetString(this.getSnippetContent(snippet));
                completion.detail = this.getDetailedDescription(snippet);
                completion.documentation = this.getComprehensiveDocumentation(snippet);

                // Add command to set language after insertion
                completion.command = {
                    command: 'wheels.setLanguageToCFML',
                    title: 'Set Language to CFML'
                };

                completions.push(completion);
            }
        }

        return completions;
    }

    getSnippetContent(snippetName) {
        try {
            // Check cache first
            if (this.templateCache.has(snippetName)) {
                return this.templateCache.get(snippetName);
            }

            // Map snippet names to template files
            const templateType = snippetName === 'wcontroller' ? 'controller' :
                                snippetName === 'wmodel' ? 'model' :
                                null;

            if (!templateType) return '// Template not found';

            // Get template file path
            const templateFileName = `${templateType}.cfc`;
            const templatePath = path.join(__dirname, '..', 'assets', 'templates', templateFileName);

            // Read template file
            let template = fs.readFileSync(templatePath, 'utf8');

            // Replace placeholders with default values for snippets
            const defaultData = getDefaultTemplateData(templateType);
            template = replacePlaceholders(template, defaultData);

            // Cache the processed template
            this.templateCache.set(snippetName, template);

            return template;

        } catch (error) {
            console.error('Failed to load template file:', error);
            return '// Template not found';
        }
    }

    /**
     * Get detailed description for completion items
     */
    getDetailedDescription(snippetName) {
        const descriptions = {
            'wcontroller': 'Complete Wheels Controller with CRUD Actions',
            'wmodel': 'Complete Wheels Model with Validations & Associations'
        };
        return descriptions[snippetName] || 'Wheels Template';
    }

    /**
     * Get comprehensive documentation for completion items
     */
    getComprehensiveDocumentation(snippetName) {
        const docs = {
            'wcontroller': new vscode.MarkdownString(`
**Wheels Controller Template**

Creates a complete CRUD controller with:
- config() - Filters, verification, formats
- index() - List all records with sorting
- show() - Display single record
- new() - Form for new record
- create() - Create new record with validation
- edit() - Form for editing existing record
- update() - Update existing record with validation
- delete() - Delete record with confirmation

**Features:**
- Proper error handling with flashInsert()
- Route-based redirects
- Model validation support
- RESTful action structure
- Best practice comments and examples

**Language:** Automatically sets file to CFML
            `),
            'wmodel': new vscode.MarkdownString(`
**Wheels Model Template**

Creates a complete model with:
- config() - Associations, validations, callbacks
- hasMany/belongsTo/hasOne examples
- Validation examples (presence, uniqueness, format, length)
- Callback examples (beforeSave, afterCreate, afterUpdate)
- Custom finder methods
- Property methods for computed values

**Features:**
- Complete association examples
- Common validation patterns
- Callback method templates
- Custom business logic methods
- Best practice comments

**Language:** Automatically sets file to CFML
            `)
        };

        const doc = docs[snippetName] || new vscode.MarkdownString('Wheels framework template');
        doc.isTrusted = true;
        doc.supportHtml = false;
        return doc;
    }
}

/**
 * Wheels Parameter Validator
 * Validates parameter names in Wheels API function calls when using named parameter syntax
 */
class WheelsParameterValidator {
    constructor() {
        this.diagnosticCollection = vscode.languages.createDiagnosticCollection('wheels-parameters');
        this.wheelsParameters = {};
        this.loadWheelsParameters();
    }

    validateDocument(document) {
        const diagnostics = [];
        const text = document.getText();

        // Only validate if we have parameter data loaded
        if (Object.keys(this.wheelsParameters).length > 0) {
            this.checkParameterNames(text, document, diagnostics);
        }

        this.diagnosticCollection.set(document.uri, diagnostics);
    }

    checkParameterNames(text, document, diagnostics) {
        // Find all function calls with named parameters
        const functionCallPattern = /(\w+)\s*\(([^)]+)\)/g;
        let match;

        while ((match = functionCallPattern.exec(text)) !== null) {
            const functionName = match[1];
            const parametersString = match[2];
            const functionStart = match.index;
            const parametersStart = functionStart + match[0].indexOf('(') + 1;

            // Skip if this function is not in our Wheels API
            if (!this.wheelsParameters[functionName]) {
                continue;
            }

            // Parse named parameters only (skip positional parameters)
            const namedParams = this.parseNamedParameters(parametersString);

            // Validate each named parameter
            namedParams.forEach(param => {
                const paramStart = parametersStart + param.startIndex;
                const paramEnd = paramStart + param.name.length;
                const startPos = document.positionAt(paramStart);
                const endPos = document.positionAt(paramEnd);
                const range = new vscode.Range(startPos, endPos);

                if (!this.isValidParameter(functionName, param.name)) {
                    const suggestion = this.suggestParameter(functionName, param.name);
                    const message = suggestion ?
                        `Invalid parameter '${param.name}'. Did you mean '${suggestion}'?` :
                        `Invalid parameter '${param.name}' for function '${functionName}'`;

                    diagnostics.push(new vscode.Diagnostic(
                        range,
                        message,
                        vscode.DiagnosticSeverity.Warning
                    ));
                }
            });
        }
    }

    parseNamedParameters(parametersString) {
        const namedParams = [];
        let inString = false;
        let stringChar = '';
        let depth = 0;
        let currentParam = '';
        let paramStart = -1;
        let i = 0;

        while (i < parametersString.length) {
            const char = parametersString[i];

            if (!inString) {
                if (char === '"' || char === "'") {
                    inString = true;
                    stringChar = char;
                } else if (char === '(') {
                    depth++;
                } else if (char === ')') {
                    depth--;
                } else if (char === '=' && depth === 0) {
                    // Found a named parameter assignment at top level
                    if (currentParam.trim()) {
                        namedParams.push({
                            name: currentParam.trim(),
                            startIndex: paramStart
                        });
                    }
                    // Skip to after the equals sign and find the value
                    i = this.skipParameterValue(parametersString, i + 1);
                    currentParam = '';
                    paramStart = -1;
                    continue;
                } else if (char === ',' && depth === 0) {
                    // Reset for next parameter
                    currentParam = '';
                    paramStart = -1;
                } else if (/[a-zA-Z_]/.test(char) && currentParam === '' && paramStart === -1) {
                    // Start of a potential parameter name
                    currentParam = char;
                    paramStart = i;
                } else if (/\w/.test(char) && currentParam !== '') {
                    // Continue building parameter name
                    currentParam += char;
                } else if (char === ' ' && currentParam !== '') {
                    // Space after word - check if it's a CFML type declaration
                    const currentWord = currentParam.trim();
                    const cfmlTypes = ['required', 'string', 'numeric', 'boolean', 'date', 'struct', 'array', 'query', 'any'];

                    if (cfmlTypes.includes(currentWord.toLowerCase())) {
                        // This is a type declaration, reset and look for actual parameter name
                        currentParam = '';
                        paramStart = -1;
                    }
                } else if (!/\s/.test(char) && currentParam !== '') {
                    // Non-whitespace, non-word character - not a parameter name
                    currentParam = '';
                    paramStart = -1;
                }
            } else {
                // We're inside a string
                if (char === stringChar && (i === 0 || parametersString[i-1] !== '\\')) {
                    inString = false;
                    stringChar = '';
                }
            }

            i++;
        }

        return namedParams;
    }

    skipParameterValue(parametersString, startIndex) {
        let i = startIndex;
        let inString = false;
        let stringChar = '';
        let depth = 0;

        // Skip whitespace
        while (i < parametersString.length && /\s/.test(parametersString[i])) {
            i++;
        }

        while (i < parametersString.length) {
            const char = parametersString[i];

            if (!inString) {
                if (char === '"' || char === "'") {
                    inString = true;
                    stringChar = char;
                } else if (char === '(') {
                    depth++;
                } else if (char === ')') {
                    depth--;
                } else if (char === ',' && depth === 0) {
                    // Found the end of this parameter value
                    return i;
                }
            } else {
                if (char === stringChar && (i === 0 || parametersString[i-1] !== '\\')) {
                    inString = false;
                    stringChar = '';
                }
            }

            i++;
        }

        return i;
    }

    isValidParameter(functionName, parameterName) {
        const validParams = this.wheelsParameters[functionName];
        if (!validParams) return true; // Function not found, assume valid

        return validParams.includes(parameterName.toLowerCase());
    }

    suggestParameter(functionName, parameterName) {
        const validParams = this.wheelsParameters[functionName];
        if (!validParams) return null;

        const lowerParam = parameterName.toLowerCase();

        // Find best match using simple string similarity
        let bestMatch = null;
        let bestScore = 0;

        validParams.forEach(validParam => {
            const score = this.calculateSimilarity(lowerParam, validParam);
            if (score > bestScore && score > 0.5) { // Threshold for suggestions
                bestScore = score;
                bestMatch = validParam;
            }
        });

        return bestMatch;
    }

    calculateSimilarity(str1, str2) {
        // Simple similarity calculation
        if (str1 === str2) return 1;
        if (str2.startsWith(str1) || str1.startsWith(str2)) return 0.8;

        // Levenshtein distance-based similarity
        const maxLength = Math.max(str1.length, str2.length);
        const distance = this.levenshteinDistance(str1, str2);
        return (maxLength - distance) / maxLength;
    }

    levenshteinDistance(str1, str2) {
        const matrix = [];

        for (let i = 0; i <= str2.length; i++) {
            matrix[i] = [i];
        }

        for (let j = 0; j <= str1.length; j++) {
            matrix[0][j] = j;
        }

        for (let i = 1; i <= str2.length; i++) {
            for (let j = 1; j <= str1.length; j++) {
                if (str2.charAt(i - 1) === str1.charAt(j - 1)) {
                    matrix[i][j] = matrix[i - 1][j - 1];
                } else {
                    matrix[i][j] = Math.min(
                        matrix[i - 1][j - 1] + 1,
                        matrix[i][j - 1] + 1,
                        matrix[i - 1][j] + 1
                    );
                }
            }
        }

        return matrix[str2.length][str1.length];
    }

    loadWheelsParameters() {
        try {
            const jsonPath = path.join(__dirname, '..', 'snippets', 'wheels-api.json');
            const rawData = fs.readFileSync(jsonPath, 'utf8');
            const jsonData = JSON.parse(rawData);

            const parameters = {};
            let count = 0;

            if (jsonData.functions && Array.isArray(jsonData.functions)) {
                jsonData.functions.forEach(func => {
                    if (func.name && func.parameters && Array.isArray(func.parameters)) {
                        parameters[func.name] = func.parameters.map(p => p.name.toLowerCase());
                        count++;
                    }
                });
            }

            console.log(`Loaded ${count} Wheels functions for parameter validation`);
            this.wheelsParameters = parameters;

        } catch (error) {
            console.error('Failed to load Wheels parameters:', error);
            this.wheelsParameters = {};
        }
    }

    dispose() {
        this.diagnosticCollection.dispose();
    }
}

/**
 * Wheels Parameter Completion Provider
 * Provides auto-completion for Wheels function parameters when typing partial parameter names
 */
class WheelsParameterCompletionProvider {
    constructor() {
        this.wheelsParameters = {};
        this.loadWheelsParameters();
    }

    provideCompletionItems(document, position, token, context) {
        try {
            // Only provide completions for CFML files
            if (document.languageId !== 'cfml') {
                return [];
            }

            const line = document.lineAt(position.line);
            const lineText = line.text;
            const beforeCursor = lineText.substring(0, position.character);

            // Check if we're inside a function call with parameters
            const functionMatch = this.findCurrentFunctionCall(beforeCursor);
            if (!functionMatch) {
                return [];
            }

            const functionName = functionMatch.functionName;
            const validParams = this.wheelsParameters[functionName];
            if (!validParams || validParams.length === 0) {
                return [];
            }

            // Get the current partial parameter being typed
            const partialParam = this.getCurrentPartialParameter(beforeCursor, functionMatch.paramStart);
            if (!partialParam || partialParam.length === 0) {
                return [];
            }

            // Find matching parameters
            const completions = [];
            validParams.forEach(paramName => {
                if (paramName.toLowerCase().startsWith(partialParam.toLowerCase())) {
                    const completion = new vscode.CompletionItem(
                        `${paramName} = `,
                        vscode.CompletionItemKind.Property
                    );

                    // Set the text to insert (replace the partial text)
                    completion.insertText = `${paramName} = `;

                    // Set the range to replace the partial parameter text
                    const startPos = new vscode.Position(position.line, position.character - partialParam.length);
                    const endPos = position;
                    completion.range = new vscode.Range(startPos, endPos);

                    // Set sort order to prioritize exact matches
                    if (paramName.toLowerCase() === partialParam.toLowerCase()) {
                        completion.sortText = '0' + paramName;
                    } else {
                        completion.sortText = '1' + paramName;
                    }

                    // Add documentation
                    completion.detail = `${functionName} parameter`;
                    completion.documentation = `Auto-complete parameter name for ${functionName}()`;

                    completions.push(completion);
                }
            });

            return completions;

        } catch (error) {
            return [];
        }
    }

    findCurrentFunctionCall(lineText) {
        // Find the most recent function call that hasn't been closed
        const functionPattern = /(\w+)\s*\(/g;
        let lastMatch = null;
        let match;
        let openParens = 0;

        // Find all function calls and track parentheses
        const matches = [];
        while ((match = functionPattern.exec(lineText)) !== null) {
            matches.push({
                functionName: match[1],
                start: match.index,
                paramStart: match.index + match[0].length
            });
        }

        if (matches.length === 0) return null;

        // Check which function call we're currently inside
        for (let i = matches.length - 1; i >= 0; i--) {
            const funcMatch = matches[i];
            const afterFunction = lineText.substring(funcMatch.paramStart);

            // Count parentheses to see if this function is still open
            openParens = 0;
            for (let j = 0; j < afterFunction.length; j++) {
                if (afterFunction[j] === '(') openParens++;
                else if (afterFunction[j] === ')') openParens--;
            }

            // If we have more opening than closing parens, we're inside this function
            if (openParens > 0) {
                return funcMatch;
            }
        }

        // Default to the last function found
        return matches[matches.length - 1];
    }

    getCurrentPartialParameter(lineText, paramStart) {
        // Get the text after the opening parenthesis
        const paramText = lineText.substring(paramStart);

        // Find the current parameter being typed
        // Look for the last word that could be a parameter name
        const lastWordMatch = paramText.match(/(?:^|[,\s])([a-zA-Z]\w*)$/);

        if (lastWordMatch) {
            return lastWordMatch[1];
        }

        return '';
    }

    loadWheelsParameters() {
        try {
            const jsonPath = path.join(__dirname, '..', 'snippets', 'wheels-api.json');
            const rawData = fs.readFileSync(jsonPath, 'utf8');
            const jsonData = JSON.parse(rawData);

            const parameters = {};
            let count = 0;

            if (jsonData.functions && Array.isArray(jsonData.functions)) {
                jsonData.functions.forEach(func => {
                    if (func.name && func.parameters && Array.isArray(func.parameters)) {
                        parameters[func.name] = func.parameters.map(p => p.name);
                        count++;
                    }
                });
            }

            console.log(`Loaded ${count} Wheels functions for parameter completion`);
            this.wheelsParameters = parameters;

        } catch (error) {
            console.error('Failed to load Wheels parameters for completion:', error);
            this.wheelsParameters = {};
        }
    }
}

/**
 * Wheels Definition Provider - Go to Definition functionality
 */
class WheelsDefinitionProvider {
    constructor() {
        this.workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    }

    provideDefinition(document, position, token) {
        try {
            const wordRange = document.getWordRangeAtPosition(position);
            if (!wordRange) return null;

            const word = document.getText(wordRange);
            const line = document.lineAt(position.line).text;

        // Check what kind of definition we're looking for
        const modelMatch = this.findModelDefinition(line, word, position, document);
        if (modelMatch) return modelMatch;

        const controllerMatch = this.findControllerDefinition(line, word, position, document);
        if (controllerMatch) return controllerMatch;

            const viewMatch = this.findViewDefinition(line, word, position, document);
            if (viewMatch) return viewMatch;

            return null;
        } catch (error) {
            // Silently fail for better user experience
            return null;
        }
    }

    /**
     * Find model file definitions from model("ModelName") calls
     */
    findModelDefinition(line, word, position, document) {
        // Match patterns like: model("User"), model('User'), model("User")
        const modelPattern = /model\s*\(\s*["']([^"']+)["']\s*\)/g;
        const matches = [...line.matchAll(modelPattern)];

        for (const match of matches) {
            const modelName = match[1];
            const startIndex = match.index + match[0].indexOf(modelName);
            const endIndex = startIndex + modelName.length;

            // Check if cursor is on the model name
            if (position.character >= startIndex && position.character <= endIndex) {
                return this.createModelLocation(modelName);
            }
        }
        return null;
    }

    /**
     * Find controller definitions from redirectTo, linkTo calls
     */
    findControllerDefinition(line, word, position, document) {
        // Match patterns like: redirectTo(controller="users"), linkTo(controller="posts")
        const controllerPattern = /(?:redirectTo|linkTo|startFormTag)\s*\([^)]*controller\s*=\s*["']([^"']+)["'][^)]*/g;
        const matches = [...line.matchAll(controllerPattern)];

        for (const match of matches) {
            const controllerName = match[1];
            const startIndex = match.index + match[0].indexOf(controllerName);
            const endIndex = startIndex + controllerName.length;

            if (position.character >= startIndex && position.character <= endIndex) {
                // Check if there's also an action parameter
                const actionMatch = line.match(/action\s*=\s*["']([^"']+)["']/);
                const actionName = actionMatch ? actionMatch[1] : null;

                return this.createControllerLocation(controllerName, actionName);
            }
        }

        // Also check for route-based navigation
        return this.findRouteDefinition(line, word, position, document);
    }

    /**
     * Find definitions from route names (linkTo(route="user"), redirectTo(route="users"))
     */
    findRouteDefinition(line, word, position, document) {
        const routePattern = /(?:redirectTo|linkTo|startFormTag)\s*\([^)]*route\s*=\s*["']([^"']+)["'][^)]*/g;
        const matches = [...line.matchAll(routePattern)];

        for (const match of matches) {
            const routeName = match[1];
            const startIndex = match.index + match[0].indexOf(routeName);
            const endIndex = startIndex + routeName.length;

            if (position.character >= startIndex && position.character <= endIndex) {
                return this.createRouteLocation(routeName);
            }
        }
        return null;
    }

    /**
     * Find view definitions from renderView, includePartial calls
     */
    findViewDefinition(line, word, position, document) {
        // Match patterns like: renderView("users/show"), includePartial("shared/header")
        const viewPattern = /(?:renderView|includePartial|include)\s*\(\s*["']([^"']+)["']\s*\)/g;
        const matches = [...line.matchAll(viewPattern)];

        for (const match of matches) {
            const viewPath = match[1];
            const startIndex = match.index + match[0].indexOf(viewPath);
            const endIndex = startIndex + viewPath.length;

            if (position.character >= startIndex && position.character <= endIndex) {
                return this.createViewLocation(viewPath);
            }
        }
        return null;
    }

    /**
     * Create location for model file
     */
    createModelLocation(modelName) {
        if (!this.workspaceRoot) return null;

        // Handle namespaced models: Api.User -> Api/User.cfc
        const modelPath = modelName.includes('.') ? modelName.replace(/\./g, '/') : modelName;

        // Support both Wheels project structures
        const possiblePaths = [
            // Normal user structure
            path.join(this.workspaceRoot, 'app', 'models', `${modelPath}.cfc`),
            // Core/Base template structure
            path.join(this.workspaceRoot, 'templates', 'base', 'src', 'app', 'models', `${modelPath}.cfc`),
            // Alternative structures
            path.join(this.workspaceRoot, 'src', 'app', 'models', `${modelPath}.cfc`),
            path.join(this.workspaceRoot, 'models', `${modelPath}.cfc`)
        ];

        for (const fullPath of possiblePaths) {
            if (fs.existsSync(fullPath)) {
                const uri = vscode.Uri.file(fullPath);
                return new vscode.Location(uri, new vscode.Position(0, 0));
            }
        }
        return null;
    }

    /**
     * Create location for controller file, optionally jump to specific action
     */
    createControllerLocation(controllerName, actionName = null) {
        if (!this.workspaceRoot) return null;

        // Handle both plural and singular controller names
        const possibleNames = [
            controllerName,
            controllerName.endsWith('s') ? controllerName : controllerName + 's',
            controllerName.endsWith('s') ? controllerName.slice(0, -1) : controllerName
        ];

        for (const name of possibleNames) {
            // Support both Wheels project structures
            const possiblePaths = [
                // Normal user structure
                path.join(this.workspaceRoot, 'app', 'controllers', `${this.capitalize(name)}.cfc`),
                // Core/Base template structure
                path.join(this.workspaceRoot, 'templates', 'base', 'src', 'app', 'controllers', `${this.capitalize(name)}.cfc`),
                // Alternative structures
                path.join(this.workspaceRoot, 'src', 'app', 'controllers', `${this.capitalize(name)}.cfc`),
                path.join(this.workspaceRoot, 'controllers', `${this.capitalize(name)}.cfc`)
            ];

            for (const controllerPath of possiblePaths) {
                if (fs.existsSync(controllerPath)) {
                    const uri = vscode.Uri.file(controllerPath);

                    // If action name is provided, try to find the specific function
                    if (actionName) {
                        const position = this.findFunctionInFile(controllerPath, actionName);
                        if (position) {
                            return new vscode.Location(uri, position);
                        }
                    }

                    return new vscode.Location(uri, new vscode.Position(0, 0));
                }
            }
        }
        return null;
    }

    /**
     * Create location based on route name (maps to controller/action)
     */
    createRouteLocation(routeName) {
        if (!this.workspaceRoot) return null;

        // Common route patterns in Wheels
        const routeToController = {
            // Singular routes usually map to show action
            'user': { controller: 'users', action: 'show' },
            'post': { controller: 'posts', action: 'show' },
            'product': { controller: 'products', action: 'show' },

            // Plural routes usually map to index action
            'users': { controller: 'users', action: 'index' },
            'posts': { controller: 'posts', action: 'index' },
            'products': { controller: 'products', action: 'index' },

            // Edit routes
            'editUser': { controller: 'users', action: 'edit' },
            'editPost': { controller: 'posts', action: 'edit' },
            'editProduct': { controller: 'products', action: 'edit' },

            // New routes
            'newUser': { controller: 'users', action: 'new' },
            'newPost': { controller: 'posts', action: 'new' },
            'newProduct': { controller: 'products', action: 'new' }
        };

        // Check exact match first
        if (routeToController[routeName]) {
            const route = routeToController[routeName];
            return this.createControllerLocation(route.controller, route.action);
        }

        // Try to infer from route name
        if (routeName.startsWith('edit')) {
            const modelName = routeName.slice(4).toLowerCase();
            return this.createControllerLocation(modelName + 's', 'edit');
        }

        if (routeName.startsWith('new')) {
            const modelName = routeName.slice(3).toLowerCase();
            return this.createControllerLocation(modelName + 's', 'new');
        }

        // Default: assume route name is controller name
        return this.createControllerLocation(routeName);
    }

    /**
     * Create location for view file
     */
    createViewLocation(viewPath) {
        if (!this.workspaceRoot) return null;

        // Support both Wheels project structures and different view path formats
        const possiblePaths = [
            // Normal user structure
            path.join(this.workspaceRoot, 'app', 'views', `${viewPath}.cfm`),
            path.join(this.workspaceRoot, 'app', 'views', viewPath, 'index.cfm'),
            // Core/Base template structure
            path.join(this.workspaceRoot, 'templates', 'base', 'src', 'app', 'views', `${viewPath}.cfm`),
            path.join(this.workspaceRoot, 'templates', 'base', 'src', 'app', 'views', viewPath, 'index.cfm'),
            // Alternative structures
            path.join(this.workspaceRoot, 'src', 'app', 'views', `${viewPath}.cfm`),
            path.join(this.workspaceRoot, 'src', 'app', 'views', viewPath, 'index.cfm'),
            path.join(this.workspaceRoot, 'views', `${viewPath}.cfm`),
            path.join(this.workspaceRoot, 'views', viewPath, 'index.cfm')
        ];

        for (const viewFilePath of possiblePaths) {
            if (fs.existsSync(viewFilePath)) {
                const uri = vscode.Uri.file(viewFilePath);
                return new vscode.Location(uri, new vscode.Position(0, 0));
            }
        }
        return null;
    }

    /**
     * Find specific function within a file
     */
    findFunctionInFile(filePath, functionName) {
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            const lines = content.split('\n');

            // Look for function definition patterns
            const functionPatterns = [
                new RegExp(`^\\s*function\\s+${functionName}\\s*\\(`, 'i'),
                new RegExp(`^\\s*public\\s+function\\s+${functionName}\\s*\\(`, 'i'),
                new RegExp(`^\\s*private\\s+function\\s+${functionName}\\s*\\(`, 'i'),
                new RegExp(`^\\s*remote\\s+function\\s+${functionName}\\s*\\(`, 'i')
            ];

            for (let i = 0; i < lines.length; i++) {
                for (const pattern of functionPatterns) {
                    if (pattern.test(lines[i])) {
                        return new vscode.Position(i, 0);
                    }
                }
            }
        } catch (error) {
            // File doesn't exist or can't be read
        }
        return null;
    }

    /**
     * Capitalize first letter of string
     */
    capitalize(str) {
        return str.charAt(0).toUpperCase() + str.slice(1);
    }
}

/**
 * Wheels Signature Help Provider - IntelliSense parameter hints
 * Provides intelligent parameter highlighting that only highlights when user types partial matches
 * - Shows parameter list on '(' and ',' triggers
 * - Highlights parameters only when user starts typing (e.g., "findAll(g" highlights "group")
 * - No highlighting for empty positions (e.g., "findAll(" shows list but no highlight)
 */
class WheelsSignatureHelpProvider {
    constructor() {
        this.wheelsSignatures = {};
        this.loadWheelsSignatures(); // Load immediately
    }

    provideSignatureHelp(document, position, token, context) {
        try {
            if (!this.wheelsSignatures) return null;

            const line = document.lineAt(position.line);
            const linePrefix = line.text.substring(0, position.character);

            // Find the function being called
            const functionMatch = this.findFunctionCall(linePrefix);
            if (!functionMatch) return null;

            const functionName = functionMatch.name;
            const signature = this.wheelsSignatures[functionName];
            if (!signature) return null;

            // Create signature help
            const sigHelp = new vscode.SignatureHelp();
            const sigInfo = new vscode.SignatureInformation(signature.signature, signature.documentation);

            // Add parameter information
            signature.parameters.forEach(param => {
                const paramInfo = new vscode.ParameterInformation(
                    param.label,
                    param.documentation
                );
                sigInfo.parameters.push(paramInfo);
            });

            sigHelp.signatures.push(sigInfo);
            sigHelp.activeSignature = 0;

            // Determine active parameter based on named parameters or position
            const activeParamIndex = this.findActiveParameter(linePrefix, functionMatch.startIndex, signature.parameters);
            sigHelp.activeParameter = activeParamIndex;

            return sigHelp;

        } catch (error) {
            return null;
        }
    }

    /**
     * Find the function call at the current position
     */
    findFunctionCall(linePrefix) {
        // Match function calls including method chaining: obj.method( or functionName(
        const functionPattern = /(?:(\w+)\.)?(\w+)\s*\(\s*[^)]*$/;
        const match = linePrefix.match(functionPattern);

        if (match) {
            const objectName = match[1]; // Could be null for standalone functions
            const functionName = match[2];

            return {
                name: functionName,
                objectName: objectName,
                startIndex: match.index + match[0].indexOf('(') + 1
            };
        }
        return null;
    }

    /**
     * Count commas to determine active parameter
     */
    countCommasInCall(linePrefix, startIndex) {
        const callContent = linePrefix.substring(startIndex);
        let commaCount = 0;
        let depth = 0;
        let inString = false;
        let stringChar = '';

        for (let i = 0; i < callContent.length; i++) {
            const char = callContent[i];

            if (!inString) {
                if (char === '"' || char === "'") {
                    inString = true;
                    stringChar = char;
                } else if (char === '(') {
                    depth++;
                } else if (char === ')') {
                    depth--;
                } else if (char === ',' && depth === 0) {
                    commaCount++;
                }
            } else {
                if (char === stringChar && (i === 0 || callContent[i-1] !== '\\')) {
                    inString = false;
                }
            }
        }

        return commaCount;
    }

    /**
     * Find active parameter based on user input and cursor position
     * Returns the parameter index that should be highlighted, or -1 for no highlighting
     *
     * Behavior:
     * - "findAll(" -> -1 (no highlight)
     * - "findAll(g" -> highlights "group"
     * - "findAll(group, " -> -1 (no highlight)
     * - "findAll(group, o" -> highlights "order"
     * - "findAll(where='test', ord" -> highlights "order"
     */
    findActiveParameter(linePrefix, startIndex, parameters) {
        const callContent = linePrefix.substring(startIndex);

        // Parse parameters in the function call
        const parsedParams = this.parseParameters(callContent);
        const providedParamNames = parsedParams.filter(p => p.completed).map(p => p.name);

        // Find cursor position within the call
        const cursorPos = callContent.length;

        // Check if we're currently typing a named parameter
        const currentParam = this.findParameterAtPosition(callContent, cursorPos);

        if (currentParam && currentParam.name) {
            // Find the parameter index by name (exact match first)
            const paramIndex = parameters.findIndex(p => p.label === currentParam.name);
            if (paramIndex !== -1) {
                return paramIndex;
            }

            // Handle partial parameter names (e.g., "orde" should match "order")
            const partialMatch = parameters.findIndex(p =>
                p.label.toLowerCase().startsWith(currentParam.name.toLowerCase())
            );
            if (partialMatch !== -1) {
                return partialMatch;
            }
        }

        // Check if user is typing a partial parameter name
        // Examples: "findAll(g" -> "g", "findAll(where='test', ord" -> "ord"
        const paramNameMatch = callContent.match(/(?:^|\s*,\s*)([a-zA-Z]\w*)$/);
        if (paramNameMatch) {
            const partialParamName = paramNameMatch[1];
            // Find parameter that starts with this partial name
            const matchIndex = parameters.findIndex(p =>
                p.label.toLowerCase().startsWith(partialParamName.toLowerCase())
            );
            if (matchIndex !== -1) {
                return matchIndex;
            }
        }

        // Don't highlight anything if user hasn't started typing a parameter name
        // Examples: "findAll(" or "findAll(where='test', )" or "findAll(group, )"
        if (callContent.match(/[,(]\s*$/) || callContent.trim() === '') {
            return -1; // No parameter highlighting - shows list but no highlight
        }

        // Fallback to position-based detection only if we have some content
        const commaCount = this.countCommasInCall(linePrefix, startIndex);
        return Math.min(commaCount, parameters.length - 1);
    }

    /**
     * Find the next parameter that hasn't been provided yet
     */
    findNextAvailableParameter(parameters, providedParamNames) {
        for (let i = 0; i < parameters.length; i++) {
            const paramName = parameters[i].label;
            if (!providedParamNames.includes(paramName)) {
                return i;
            }
        }
        // All parameters provided, highlight the last one
        return Math.max(0, parameters.length - 1);
    }

    /**
     * Parse parameters from function call content
     */
    parseParameters(callContent) {
        const params = [];
        let inString = false;
        let stringChar = '';
        let depth = 0;
        let paramName = '';
        let paramValue = '';
        let inValue = false;

        for (let i = 0; i < callContent.length; i++) {
            const char = callContent[i];

            if (!inString) {
                if (char === '"' || char === "'") {
                    inString = true;
                    stringChar = char;
                    if (inValue) paramValue += char;
                } else if (char === '(') {
                    depth++;
                } else if (char === ')') {
                    depth--;
                    if (depth === 0) {
                        // End of function call
                        if (paramName.trim()) {
                            params.push({
                                name: paramName.trim(),
                                value: paramValue.trim(),
                                completed: paramValue.trim().length > 0
                            });
                        }
                        break;
                    }
                } else if (char === '=' && depth <= 1 && !inValue) {
                    inValue = true;
                } else if (char === ',' && depth <= 1) {
                    if (paramName.trim()) {
                        params.push({
                            name: paramName.trim(),
                            value: paramValue.trim(),
                            completed: paramValue.trim().length > 0
                        });
                    }
                    paramName = '';
                    paramValue = '';
                    inValue = false;
                } else if (char === ' ' && !inValue) {
                    // Skip spaces in parameter names unless we're building a name
                    if (paramName.trim().length > 0 && !/^\s*$/.test(paramName)) {
                        // Don't add spaces at the end of param names
                    }
                } else {
                    if (inValue) {
                        paramValue += char;
                    } else {
                        // Only add non-whitespace characters to parameter names
                        if (!/\s/.test(char)) {
                            paramName += char;
                        }
                    }
                }
            } else {
                if (char === stringChar && (i === 0 || callContent[i-1] !== '\\')) {
                    inString = false;
                }
                if (inValue) paramValue += char;
            }
        }

        // Handle case where we're still typing the last parameter
        if (paramName.trim()) {
            params.push({
                name: paramName.trim(),
                value: paramValue.trim(),
                completed: paramValue.trim().length > 0
            });
        }

        return params;
    }

    /**
     * Find which parameter the cursor is currently positioned in
     * Returns the parameter name that should be highlighted based on cursor position
     */
    findParameterAtPosition(callContent, cursorPos) {
        let inString = false;
        let stringChar = '';
        let depth = 0;
        let currentParamName = '';
        let inValue = false;
        let paramStart = 0;

        for (let i = 0; i < Math.min(cursorPos, callContent.length); i++) {
            const char = callContent[i];

            if (!inString) {
                if (char === '"' || char === "'") {
                    inString = true;
                    stringChar = char;
                } else if (char === '(') {
                    depth++;
                    if (depth === 1) paramStart = i + 1;
                } else if (char === ')') {
                    depth--;
                } else if (char === '=' && depth === 0 && !inValue) {
                    // Found equals sign - now we're in the parameter value
                    inValue = true;
                } else if (char === ',' && depth === 0) {
                    // Found comma - reset for next parameter
                    currentParamName = '';
                    inValue = false;
                    paramStart = i + 1;
                } else if (!inValue && depth === 0 && !/\s/.test(char)) {
                    // Building parameter name (not in value, not whitespace)
                    currentParamName += char;
                }
            } else {
                if (char === stringChar && (i === 0 || callContent[i-1] !== '\\')) {
                    inString = false;
                }
            }
        }

        // Return the current parameter name if we have one
        // This handles cases like:
        // - "findAll(where" -> "where"
        // - "findAll(where=" -> "where" (still in where parameter)
        // - "findAll(where=\"id=1\"" -> "where" (still in where parameter until comma)
        if (currentParamName.trim()) {
            return {
                name: currentParamName.trim(),
                position: paramStart
            };
        }

        return null;
    }

    /**
     * Load Wheels function signatures from wheels-api.json
     */
    loadWheelsSignatures() {
        try {
            const jsonPath = path.join(__dirname, '..', 'snippets', 'wheels-api.json');
            const rawData = fs.readFileSync(jsonPath, 'utf8');
            const jsonData = JSON.parse(rawData);

            const signatures = {};
            let count = 0;

            if (jsonData.functions && Array.isArray(jsonData.functions)) {
                jsonData.functions.forEach(func => {
                    if (func.name && func.parameters) {
                        // Build signature from parameters
                        const params = func.parameters.map(p => {
                            const optional = p.required === false ? '?' : '';
                            const type = p.type || 'any';
                            return `${p.name}${optional}: ${type}`;
                        }).join(', ');

                        const signature = `${func.name}(${params})${func.returntype ? ': ' + func.returntype : ''}`;

                        // Convert parameters for VS Code
                        const parameters = func.parameters.map(p => ({
                            label: p.name,
                            documentation: this.cleanParameterDescription(p.hint) || `${p.name} parameter`
                        }));

                        signatures[func.name] = {
                            signature: signature,
                            documentation: this.cleanDescription(func.hint) || `Wheels ${func.name} function`,
                            parameters: parameters
                        };
                        count++;
                    }
                });
            }

            console.log(`Loaded ${count} Wheels function signatures`);
            this.wheelsSignatures = signatures;

        } catch (error) {
            console.error('Failed to load Wheels signatures:', error);
            this.wheelsSignatures = {};
        }
    }

    /**
     * Clean and format parameter description
     */
    cleanParameterDescription(hint) {
        if (!hint) return null;

        return hint
            .replace(/<[^>]*>/g, '')
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/&amp;/g, '&')
            .replace(/&quot;/g, '"')
            .replace(/\n/g, ' ')
            .replace(/\s+/g, ' ')
            .trim();
    }

    /**
     * Clean and format function description
     */
    cleanDescription(hint) {
        if (!hint) return null;

        let clean = hint
            .replace(/<[^>]*>/g, '')
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/&amp;/g, '&')
            .replace(/&quot;/g, '"')
            .replace(/\n/g, ' ')
            .replace(/\s+/g, ' ')
            .trim();

        // Get first sentence, max 100 characters for signature help
        const sentences = clean.split(/[.!?]/);
        let description = sentences[0].trim();

        if (description.length > 100) {
            description = description.substring(0, 97) + '...';
        }

        return description + (description.endsWith('.') ? '' : '.');
    }
}

/**
 * Professional Wheels Hover Provider
 */
class WheelsHoverProvider {
    constructor() {
        this.functionsData = this.loadAllFunctions(); // Load immediately
    }
    
    /**
     * Load all functions from wheels-api.json with robust error handling
     */
    loadAllFunctions() {
        try {
            const jsonPath = path.join(__dirname, '..', 'snippets', 'wheels-api.json');
            const rawData = fs.readFileSync(jsonPath, 'utf8');
            const jsonData = JSON.parse(rawData);
            const functions = {};
            let count = 0;
            
            // Parse functions array from root level
            if (jsonData.functions && Array.isArray(jsonData.functions)) {
                jsonData.functions.forEach(func => {
                    if (func.name) {
                        functions[func.name] = {
                            name: func.name,
                            description: this.cleanDescription(func.hint),
                            returnType: func.returntype || 'any',
                            parameters: this.parseParameters(func.parameters),
                            category: this.getCategory(func),
                            availableIn: func.availableIn || [],
                            tags: func.tags || {}
                        };
                        count++;
                    }
                });
            }
            
            console.log(`Loaded ${count} Wheels functions for hover`);
            return functions;
            
        } catch (error) {
            console.error('Failed to load functions:', error);
            return {};
        }
    }
    
    /**
     * Clean and format function description
     */
    cleanDescription(hint) {
        if (!hint) return 'Wheels framework function';
        
        // Remove HTML tags and clean up
        let clean = hint
            .replace(/<[^>]*>/g, '')
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/&amp;/g, '&')
            .replace(/&quot;/g, '"')
            .replace(/\n/g, ' ')
            .replace(/\s+/g, ' ')
            .trim();
        
        // Get first sentence, max 120 characters
        const sentences = clean.split(/[.!?]/);
        let description = sentences[0].trim();
        
        if (description.length > 120) {
            description = description.substring(0, 117) + '...';
        }
        
        return description + (description.endsWith('.') ? '' : '.');
    }
    
    /**
     * Parse and organize parameters
     */
    parseParameters(params) {
        if (!Array.isArray(params)) return { required: [], optional: [] };
        
        const required = params.filter(p => p.required === true);
        const optional = params.filter(p => p.required === false);
        
        return { required, optional };
    }
    
    /**
     * Get function category
     */
    getCategory(func) {
        if (func.tags?.category) return func.tags.category;
        if (func.availableIn && func.availableIn.length > 0) {
            return func.availableIn[0] + ' function';
        }
        return 'Wheels function';
    }
    
    /**
     * Generate professional hover documentation
     */
    provideHover(document, position, token) {
        try {
            if (!this.functionsData) return null;

            const range = document.getWordRangeAtPosition(position);
            if (!range) return null;

            const word = document.getText(range);
            const func = this.functionsData[word];

            if (!func) return null;

            // Only show hover if this looks like a function call
            if (!this.isFunctionCall(document, range)) {
                return null;
            }

            return this.createProfessionalHover(func);

        } catch (error) {
            return null; // Fail silently
        }
    }

    /**
     * Check if the word at the given range is being used as a function call
     * Handles multi-line function calls and various edge cases
     */
    isFunctionCall(document, range) {
        try {
            // Check if we're inside a string literal or comment
            if (this.isInStringOrComment(document, range.start)) {
                return false;
            }

            // First check the current line for immediate parenthesis
            const currentLine = document.lineAt(range.start.line);
            const lineText = currentLine.text;
            const wordEndIndex = range.end.character;

            // Look for opening parenthesis on the same line (most common case)
            for (let i = wordEndIndex; i < lineText.length; i++) {
                const char = lineText[i];

                if (char === '(') {
                    return true; // Found opening parenthesis - this is a function call
                } else if (char !== ' ' && char !== '\t') {
                    // Found non-whitespace that's not '(' - check if it's assignment or other operators
                    if (char === '=' || char === ';' || char === ',' || char === ')' || char === '}') {
                        return false; // This is variable assignment or other non-function usage
                    }
                    break; // Other non-whitespace - stop looking on this line
                }
            }

            // Check next few lines for opening parenthesis (multi-line function calls)
            const maxLinesToCheck = 5; // Reasonable limit to avoid performance issues
            for (let lineNum = range.start.line + 1;
                 lineNum <= range.start.line + maxLinesToCheck && lineNum < document.lineCount;
                 lineNum++) {

                const nextLineText = document.lineAt(lineNum).text;
                const trimmedLine = nextLineText.trim();

                // Skip empty lines and comment lines
                if (trimmedLine === '' || this.isCommentLine(trimmedLine)) {
                    continue;
                }

                // Check if line starts with opening parenthesis
                if (trimmedLine.startsWith('(')) {
                    return true; // Found opening paren on subsequent line
                }

                // If we find non-empty, non-comment content that doesn't start with '(',
                // this is likely not a function call
                break;
            }

            return false;

        } catch (error) {
            return false; // Fail safely
        }
    }

    /**
     * Check if the position is inside a string literal or comment
     */
    isInStringOrComment(document, position) {
        try {
            const line = document.lineAt(position.line);
            const lineText = line.text;
            const charIndex = position.character;

            let inSingleQuote = false;
            let inDoubleQuote = false;

            for (let i = 0; i < charIndex; i++) {
                const char = lineText[i];
                const prevChar = i > 0 ? lineText[i - 1] : '';

                // Check for single-line comment (// or <!--- style)
                if (!inSingleQuote && !inDoubleQuote) {
                    // JavaScript/CFML style comment
                    if (char === '/' && i + 1 < lineText.length && lineText[i + 1] === '/') {
                        return true;
                    }
                    // CFML comment
                    if (char === '<' && lineText.substring(i, i + 4) === '<!-') {
                        return true;
                    }
                    // Hash comment (CFScript)
                    if (char === '/' && i + 1 < lineText.length && lineText[i + 1] === '*') {
                        return true;
                    }
                }

                // Skip escaped quotes
                if (prevChar === '\\') continue;

                // Toggle quote states
                if (char === '"' && !inSingleQuote) {
                    inDoubleQuote = !inDoubleQuote;
                } else if (char === "'" && !inDoubleQuote) {
                    inSingleQuote = !inSingleQuote;
                }
            }

            return inSingleQuote || inDoubleQuote;

        } catch (error) {
            return false; // Fail safely
        }
    }

    /**
     * Check if a line is a comment line
     */
    isCommentLine(lineText) {
        const trimmed = lineText.trim();
        return trimmed.startsWith('//') ||
               trimmed.startsWith('<!-') ||
               trimmed.startsWith('/*') ||
               trimmed.startsWith('*') ||
               trimmed.toLowerCase().startsWith('<cfcomment');
    }
    
    /**
     * Create clean, VS Code-style professional hover documentation
     */
    createProfessionalHover(func) {
        const markdown = new vscode.MarkdownString();
        markdown.supportHtml = true;
        markdown.isTrusted = true;

        // 1. Wheels Version and Core Function Badge
        markdown.appendMarkdown(`**Wheels 3.0.0** • Core Function\n\n`);

        // 2. Function Signature
        const params = func.parameters.required.concat(func.parameters.optional);
        const signatureParams = params.map(p => {
            const optional = p.required ? '' : '?';
            return `${p.name}${optional}: ${p.type || 'any'}`;
        }).join(', ');
        const signature = `function ${func.name}(${signatureParams}): ${func.returnType}`;
        markdown.appendCodeblock(signature, 'typescript');

        // 3. Framework Context (Section & Category)
        if (func.tags?.section && func.tags?.category) {
            markdown.appendMarkdown(`**Framework Area:** ${func.tags.section}\n\n`);
        }

        // 4. Scope Information
        if (func.availableIn.length > 0) {
            const scopeBadges = func.availableIn.map(scope => `\`${scope}\``).join(' ');
            markdown.appendMarkdown(`**Available in:** ${scopeBadges}\n\n`);
        }

        // 5. Clean Description
        if (func.description) {
            markdown.appendMarkdown(`${func.description}\n\n`);
        }

        // 6. Parameters Table
        const allParams = func.parameters.required.concat(func.parameters.optional);
        if (allParams.length > 0) {
            markdown.appendMarkdown(`**Parameters:**\n`);
            markdown.appendMarkdown(`| **Parameter** | **Type** | **Required** | **Default** | **Description** |\n`);
            markdown.appendMarkdown(`|--------------|----------|--------------|-------------|------------------|\n`);

            allParams.forEach(param => {
                const type = param.type || 'any';
                const required = param.required ? '✅ Yes' : '❌ No';
                const defaultVal = param.default !== undefined && param.default !== '' ? `\`${param.default}\`` : '—';
                const description = this.getParameterDescription(param);
                markdown.appendMarkdown(
                    `| \`${param.name}\` | \`${type}\` | ${required} | ${defaultVal} | ${description} |\n`
                );
            });
        }

        return new vscode.Hover(markdown);
    }
    
    /**
     * Build function signature
     */
    buildSignature(func) {
        const params = this.getKeyParameters(func, 3); // Max 3 for signature
        const paramStr = params.map(p => {
            const optional = p.required ? '' : '?';
            return `${p.name}${optional}: ${p.type || 'any'}`;
        }).join(', ');
        
        return `function ${func.name}(${paramStr}): ${func.returnType}`;
    }
    
    /**
     * Build usage example
     */
    buildExample(func) {
        const keyParams = this.getKeyParameters(func, 2); // Max 2 for example
        
        if (keyParams.length === 0) {
            return `${func.name}()`;
        }
        
        const exampleParams = keyParams.map(param => {
            const value = this.getExampleValue(param);
            return `${param.name} = ${value}`;
        }).join(', ');
        
        return `${func.name}(${exampleParams})`;
    }
    
    /**
     * Get example value for parameter
     */
    getExampleValue(param) {
        // Common parameter examples
        const examples = {
            'where': '"active = 1"',
            'order': '"name ASC"',
            'include': '"posts"',
            'page': '1',
            'perPage': '10',
            'returnAs': '"objects"'
        };
        
        if (examples[param.name]) return examples[param.name];
        
        // Default by type
        switch (param.type) {
            case 'string': return '""';
            case 'boolean': return 'true';
            case 'numeric': return '1';
            case 'array': return '[]';
            default: return '""';
        }
    }
    
    /**
     * Get most important parameters to show
     */
    getKeyParameters(func, limit = 4) {
        const { required, optional } = func.parameters;
        const priority = ['where', 'order', 'include', 'page', 'returnAs', 'properties'];
        
        let keyParams = [];
        
        // Add required params first
        keyParams.push(...required.slice(0, Math.min(2, limit)));
        
        // Add important optional params
        const remaining = limit - keyParams.length;
        if (remaining > 0) {
            const importantOptional = optional
                .filter(p => priority.includes(p.name))
                .slice(0, remaining);
            keyParams.push(...importantOptional);
        }
        
        return keyParams;
    }
    
    /**
     * Get clean parameter description
     */
    getParameterDescription(param) {
        // Common parameter descriptions
        const commonDescriptions = {
            'where': 'SQL WHERE clause to filter records',
            'order': 'SQL ORDER BY clause for sorting',
            'group': 'SQL GROUP BY clause for grouping',
            'select': 'Columns to select from database',
            'include': 'Associated models to include via JOIN',
            'page': 'Page number for pagination',
            'perPage': 'Number of records per page',
            'cache': 'Cache duration in minutes',
            'reload': 'Force database query refresh',
            'returnAs': 'Return format (query, objects, structs)',
            'properties': 'Object properties to set',
            'key': 'Primary key value',
            'name': 'Name or identifier',
            'value': 'Value to assign',
            'message': 'Error or flash message',
            'type': 'Type specification'
        };
        
        if (commonDescriptions[param.name]) {
            return commonDescriptions[param.name];
        }
        
        // Clean original hint if available
        if (param.hint) {
            let hint = param.hint
                .replace(/<[^>]*>/g, '')
                .replace(/&lt;/g, '<')
                .replace(/&gt;/g, '>')
                .replace(/&amp;/g, '&')
                .trim();
            
            // Get first sentence, max 60 chars
            const sentence = hint.split(/[.!?]/)[0];
            return sentence.length > 60 ? sentence.substring(0, 57) + '...' : sentence;
        }
        
        // Fallback based on type
        const typeDescriptions = {
            'string': 'String value',
            'boolean': 'True or false',
            'numeric': 'Numeric value',
            'array': 'Array of values',
            'struct': 'Structure/object'
        };
        
        return typeDescriptions[param.type] || 'Parameter value';
    }
}

/**
 * Create a new file and insert template snippet
 */
async function createNewFileWithTemplate() {
    try {
        // Ask user what type of template they want
        const templateType = await vscode.window.showQuickPick([
            { label: 'Controller (wcontroller)', value: 'controller' },
            { label: 'Model (wmodel)', value: 'model' },
            { label: 'View', value: 'view' }
        ], {
            placeHolder: 'Select template type'
        });

        if (!templateType) return;

        // Create a new untitled file
        const document = await vscode.workspace.openTextDocument({
            language: 'cfml',
            content: ''
        });

        const editor = await vscode.window.showTextDocument(document);

        // Insert the template content
        if (templateType.value === 'view') {
            // For views, create basic template
            const viewTemplate = `<cfparam name="items">
<cfoutput>

#contentFor("title", "Page Title")#

<div class="container">
    <div class="row">
        <div class="col-md-12">
            <h1>Page Heading</h1>

            <!-- Content goes here -->

        </div>
    </div>
</div>

</cfoutput>`;
            await editor.edit(editBuilder => {
                editBuilder.insert(new vscode.Position(0, 0), viewTemplate);
            });
        } else {
            // For controllers and models, use template file
            const templateContent = getTemplateContentForSnippet(templateType.value);
            await editor.edit(editBuilder => {
                editBuilder.insert(new vscode.Position(0, 0), templateContent);
            });
        }

        vscode.window.showInformationMessage(`Inserted ${templateType.label} template`);

    } catch (error) {
        vscode.window.showErrorMessage(`Failed to create template: ${error.message}`);
    }
}

/**
 * Get template content for snippet usage
 */
function getTemplateContentForSnippet(templateType) {
    try {
        // Get template file path
        const templateFileName = `${templateType}.cfc`;
        const templatePath = path.join(__dirname, '..', 'assets', 'templates', templateFileName);

        // Read template file
        let template = fs.readFileSync(templatePath, 'utf8');

        // Replace placeholders with default values
        const defaultData = getDefaultTemplateData(templateType);
        template = replacePlaceholders(template, defaultData);

        return template;

    } catch (error) {
        console.error('Failed to load template file:', error);
        return '// Template not found';
    }
}

/**
 * Get default template data for snippets
 */
function getDefaultTemplateData(templateType) {
    if (templateType === 'controller') {
        return {
            modelName: 'Item',
            modelNameLower: 'item',
            modelNamePlural: 'items',
            defaultSortColumn: 'name',
            routeName: 'item',
            routeNamePlural: 'items'
        };
    } else if (templateType === 'model') {
        return {
            modelName: 'Item',
            modelNameLower: 'item',
            tableName: 'items',
            hasManySample: 'orders',
            belongsToSample: 'category',
            hasOneSample: 'profile',
            requiredFields: 'name',
            uniqueFields: 'email',
            lengthField: 'name',
            minLength: '2',
            maxLength: '50',
            emailField: 'email',
            beforeSaveMethod: 'normalizeData',
            afterCreateMethod: 'sendWelcomeEmail',
            afterUpdateMethod: 'clearCache',
            propertyName: 'fullName',
            primaryKeyColumn: 'id',
            dateProperty: 'birthDate'
        };
    }

    return {};
}

/**
 * Create a new Wheels file from template
 */
async function createWheelsFile(type, uri) {
    try {
        // Get the target directory
        const targetDir = uri ? uri.fsPath : vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
        if (!targetDir) {
            vscode.window.showErrorMessage('No workspace folder found');
            return;
        }

        // Prompt for file name with detailed instructions
        const prompts = {
            controller: {
                prompt: 'Enter controller name (will create complete CRUD controller)',
                placeHolder: 'Users (creates Users.cfc controller with index, show, create, etc.)',
                validateInput: (value) => {
                    if (!value || value.trim().length === 0) {
                        return 'Controller name is required';
                    }
                    const trimmed = value.trim();
                    if (trimmed !== value) {
                        return 'Controller name cannot have leading or trailing spaces';
                    }
                    if (!/^[A-Za-z][A-Za-z0-9]*$/.test(trimmed)) {
                        return 'Controller name must start with a letter and contain only letters and numbers (no spaces or special characters)';
                    }
                    return null;
                }
            },
            model: {
                prompt: 'Enter model name (will create model with validations and associations)',
                placeHolder: 'User (creates User.cfc with common patterns)',
                validateInput: (value) => {
                    if (!value || value.trim().length === 0) {
                        return 'Model name is required';
                    }
                    const trimmed = value.trim();
                    if (trimmed !== value) {
                        return 'Model name cannot have leading or trailing spaces';
                    }
                    if (!/^[A-Za-z][A-Za-z0-9]*$/.test(trimmed)) {
                        return 'Model name must start with a letter and contain only letters and numbers (no spaces or special characters)';
                    }
                    return null;
                }
            },
            view: {
                prompt: 'Enter view path (will create view template with layout)',
                placeHolder: 'users/index (creates users/index.cfm)',
                validateInput: (value) => {
                    if (!value || value.trim().length === 0) {
                        return 'View path is required';
                    }
                    const trimmed = value.trim();
                    if (trimmed !== value) {
                        return 'View path cannot have leading or trailing spaces';
                    }
                    if (!/^[A-Za-z0-9\/\_\-]+$/.test(trimmed)) {
                        return 'View path can only contain letters, numbers, slashes, hyphens, and underscores';
                    }
                    return null;
                }
            }
        };

        const fileName = await vscode.window.showInputBox(prompts[type]);

        if (!fileName) return;

        // For Command Palette (no uri), ask for target directory
        let finalTargetDir = targetDir;
        if (!uri) {
            const targetPath = await vscode.window.showInputBox({
                prompt: `Enter target directory for ${type}`,
                placeHolder: `Enter path (e.g., templates, custom/folder, src/components)`,
                value: ``,
                validateInput: (value) => {
                    if (!value || value.trim().length === 0) {
                        return 'Target directory is required';
                    }
                    return null;
                }
            });
            if (!targetPath) return;
            finalTargetDir = path.join(vscode.workspace.workspaceFolders[0].uri.fsPath, targetPath.trim());
        }

        // Determine file paths and template data
        const templateData = getTemplateData(type, fileName, finalTargetDir);

        // Get template content from template files
        const fileContent = getTemplateContentFromFiles(type, templateData);

        // Create target file
        const targetPath = path.join(templateData.targetDir, templateData.fileName);

        // Check if file already exists
        if (fs.existsSync(targetPath)) {
            const relativePath = vscode.workspace.asRelativePath(targetPath);
            const overwrite = await vscode.window.showWarningMessage(
                `Component Already Exists\n\nThe file "${relativePath}" already exists and will be overwritten.\n\nDo you want to continue?`,
                { modal: true },
                'Yes, Overwrite',
                'No, Cancel'
            );

            if (overwrite !== 'Yes, Overwrite') {
                vscode.window.showInformationMessage(`File creation cancelled. Your existing "${templateData.fileName}" was not modified.`);
                return;
            }
        }

        // Ensure directory exists
        const dir = path.dirname(targetPath);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }

        // Write file
        fs.writeFileSync(targetPath, fileContent);

        // Open the created file and set language to CFML
        const document = await vscode.workspace.openTextDocument(targetPath);
        const editor = await vscode.window.showTextDocument(document);

        // Set language to CFML for .cfc and .cfm files
        if (templateData.fileName.endsWith('.cfc') || templateData.fileName.endsWith('.cfm')) {
            await vscode.languages.setTextDocumentLanguage(document, 'cfml');
        }

        const successMessages = {
            controller: `Created controller: ${templateData.fileName}`,
            model: `Created model: ${templateData.fileName}`,
            view: `Created view: ${templateData.fileName}`
        };

        vscode.window.showInformationMessage(successMessages[type] || `Created ${type}: ${templateData.fileName}`);

    } catch (error) {
        vscode.window.showErrorMessage(`Failed to create ${type}: ${error.message}`);
    }
}


/**
 * Get template data for file creation
 */
function getTemplateData(type, fileName, targetDir) {
    const data = {};

    if (type === 'controller') {
        const cleanName = fileName.trim();

        data.fileName = `${cleanName}.cfc`;
        data.targetDir = targetDir;
        data.modelName = cleanName;
        data.modelNameLower = cleanName.toLowerCase();
        data.modelNamePlural = cleanName.toLowerCase();
        data.defaultSortColumn = 'name';
        data.routeName = cleanName.toLowerCase();
        data.routeNamePlural = cleanName.toLowerCase();

    } else if (type === 'model') {
        const cleanName = fileName.trim();

        data.fileName = `${cleanName}.cfc`;
        data.targetDir = targetDir;
        data.modelName = cleanName;
        data.modelNameLower = cleanName.toLowerCase();
        data.tableName = data.modelNameLower;

    } else if (type === 'view') {
        const cleanName = fileName.trim();
        const viewPath = cleanName.includes('/') ? cleanName : `${cleanName}/index`;

        data.fileName = `${viewPath}.cfm`;
        data.targetDir = targetDir;

        // Extract model name and action from path
        const pathParts = viewPath.split('/');
        const modelNamePlural = pathParts[0]; // e.g., "customers"
        const action = pathParts[1] || 'index'; // e.g., "new", "show", "edit", "index"

        // Generate model names
        const modelName = modelNamePlural.charAt(0).toUpperCase() + modelNamePlural.slice(1, -1); // "customers" -> "Customer"
        const modelNameSingular = modelName.toLowerCase(); // "customer"

        data.modelName = modelName; // "Customer"
        data.modelNamePlural = modelNamePlural; // "customers"
        data.itemVar = modelNameSingular; // "customer"
        data.itemVarLower = modelNameSingular; // "customer"
        data.itemsVar = modelNamePlural; // "customers"
        data.viewTitle = capitalize(cleanName);
        data.pageHeading = data.viewTitle;
        data.action = action;
    }

    return data;
}


/**
 * Detect action from view path (e.g., "users/index.cfm" -> "index", "customers/new.cfm" -> "new")
 */
function detectActionFromViewPath(fileName) {
    // Remove .cfm extension
    const pathWithoutExt = fileName.replace(/\.cfm$/, '');

    // Split by forward slash to get parts
    const parts = pathWithoutExt.split('/');

    // Get the last part (the action)
    const lastPart = parts[parts.length - 1];

    // Check if it's a known action
    const knownActions = ['index', 'show', 'new', 'edit'];
    if (knownActions.includes(lastPart)) {
        return lastPart;
    }

    return null;
}

/**
 * Get template content from template files
 */
function getTemplateContentFromFiles(type, templateData) {
    try {
        let templateFileName;

        if (type === 'view') {
            // Detect action from view path for action-specific templates
            const action = detectActionFromViewPath(templateData.fileName);
            if (action) {
                templateFileName = `view-${action}.cfm`;
            } else {
                templateFileName = `view.cfm`;
            }
        } else {
            templateFileName = `${type}.cfc`;
        }

        const templatePath = path.join(__dirname, '..', 'assets', 'templates', templateFileName);

        // Read template file
        let template = fs.readFileSync(templatePath, 'utf8');

        // Replace placeholders with actual data
        template = replacePlaceholders(template, templateData);

        return template;

    } catch (error) {
        console.error(`Failed to load template file for ${type}:`, error);

        // Fallback to basic template
        return createBasicTemplate(type, templateData);
    }
}


/**
 * Create basic template fallback
 */
function createBasicTemplate(type, templateData) {
    if (type === 'controller') {
        return `component extends="Controller" {
    function config() {
        // Configuration here
    }

    function index() {
        // Controller logic here
    }
}`;
    } else if (type === 'model') {
        return `component extends="Model" {
    function config() {
        validatesPresenceOf("name");
    }
}`;
    } else if (type === 'view') {
        return `<cfoutput>
<h1>${templateData.pageHeading}</h1>
<p>View content here.</p>
</cfoutput>`;
    }

    return '';
}

/**
 * Replace template placeholders with actual values
 */
function replacePlaceholders(template, data) {
    let result = template;
    for (const [key, value] of Object.entries(data)) {
        if (typeof value === 'string') {
            const placeholder = '${' + key + '}';
            result = result.replace(new RegExp(escapeRegExp(placeholder), 'g'), value);
        }
    }
    return result;
}

/**
 * Escape special regex characters
 */
function escapeRegExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * Capitalize first letter
 */
function capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}

/**
 * Activate extension
 */
function activate(context) {
    try {
        // Register hover provider for CFML files
        const hoverProvider = vscode.languages.registerHoverProvider(
            ['cfml', 'cfc'],
            new WheelsHoverProvider()
        );

        // Register definition provider for CFML files (Go to Definition)
        const definitionProvider = vscode.languages.registerDefinitionProvider(
            ['cfml', 'cfc'],
            new WheelsDefinitionProvider()
        );

        // Register signature help provider for CFML files (IntelliSense parameter hints)
        // Provides smart parameter highlighting that only highlights when user types partial matches
        const signatureHelpProvider = vscode.languages.registerSignatureHelpProvider(
            ['cfml', 'cfc'],
            new WheelsSignatureHelpProvider(),
            '(', ',', ' '  // Trigger characters: opening parenthesis, comma, space
        );

        // Register parameter validator
        const parameterValidator = new WheelsParameterValidator();

        // Validate open documents
        vscode.workspace.textDocuments.forEach(document => {
            if (document.languageId === 'cfml') {
                parameterValidator.validateDocument(document);
            }
        });

        // Validate documents when opened
        const onDidOpenTextDocument = vscode.workspace.onDidOpenTextDocument(document => {
            if (document.languageId === 'cfml') {
                parameterValidator.validateDocument(document);
            }
        });

        // Validate documents when changed and auto-detect CFML
        const onDidChangeTextDocument = vscode.workspace.onDidChangeTextDocument(event => {
            if (event.document.languageId === 'cfml') {
                parameterValidator.validateDocument(event.document);
            }

            // Auto-detect CFML for Wheels templates
            if (event.document.languageId === 'plaintext') {
                const text = event.document.getText();
                if (text.includes('component extends=') ||
                    text.includes('<cfcomponent') ||
                    text.includes('function config()') ||
                    text.includes('<cfoutput>')) {
                    // This looks like CFML, set the language
                    setTimeout(async () => {
                        try {
                            await vscode.languages.setTextDocumentLanguage(event.document, 'cfml');
                        } catch (error) {
                            // Ignore errors (document might be closed)
                        }
                    }, 200);
                }
            }
        });

        // Clear diagnostics when document is closed
        const onDidCloseTextDocument = vscode.workspace.onDidCloseTextDocument(document => {
            parameterValidator.diagnosticCollection.delete(document.uri);
        });
        
        // Register command to open Wheels documentation
        const showDocCommand = vscode.commands.registerCommand('wheels.showDocumentation', () => {
            vscode.env.openExternal(vscode.Uri.parse('https://wheels.dev/docs'));
        });

        // Register file creation commands
        const createController = vscode.commands.registerCommand('wheels.createController', (uri) => {
            createWheelsFile('controller', uri);
        });

        const createModel = vscode.commands.registerCommand('wheels.createModel', (uri) => {
            createWheelsFile('model', uri);
        });

        const createView = vscode.commands.registerCommand('wheels.createView', (uri) => {
            createWheelsFile('view', uri);
        });

        const newFileWithTemplate = vscode.commands.registerCommand('wheels.newFileWithTemplate', async () => {
            await createNewFileWithTemplate();
        });

        // Command to set language to CFML
        const setLanguageToCFML = vscode.commands.registerCommand('wheels.setLanguageToCFML', async () => {
            // Add a small delay to ensure the content is inserted first
            setTimeout(async () => {
                const editor = vscode.window.activeTextEditor;
                if (editor && editor.document.languageId !== 'cfml') {
                    try {
                        await vscode.languages.setTextDocumentLanguage(editor.document, 'cfml');
                        console.log('Language set to CFML automatically');
                    } catch (error) {
                        console.error('Failed to set language to CFML:', error);
                    }
                }
            }, 100); // 100ms delay
        });

        // Register completion provider for auto-language detection
        const completionProvider = vscode.languages.registerCompletionItemProvider(
            ['plaintext', 'cfml'],
            new WheelsCompletionProvider(),
            'w' // Trigger on 'w' for wcontroller, wmodel
        );

        // Register parameter completion provider for Tab auto-completion
        const parameterCompletionProvider = vscode.languages.registerCompletionItemProvider(
            ['cfml'],
            new WheelsParameterCompletionProvider(),
            'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
            'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'  // Trigger on any letter
        );

        context.subscriptions.push(
            hoverProvider,
            definitionProvider,
            signatureHelpProvider,
            parameterValidator,
            onDidOpenTextDocument,
            onDidChangeTextDocument,
            onDidCloseTextDocument,
            showDocCommand,
            createController,
            createModel,
            createView,
            newFileWithTemplate,
            setLanguageToCFML,
            completionProvider,
            parameterCompletionProvider
        );
        
        console.log('Wheels VS Code Extension activated successfully!');
        
    } catch (error) {
        // Fail silently to prevent crashes
        console.error('Extension activation failed:', error);
    }
}

function deactivate() {}

module.exports = { activate, deactivate };