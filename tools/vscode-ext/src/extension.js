const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

/**
 * Professional Wheels Hover Provider
 */
class WheelsHoverProvider {
    constructor() {
        this.functionsData = this.loadAllFunctions();
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
                            availableIn: func.availableIn || []
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
            const range = document.getWordRangeAtPosition(position);
            if (!range) return null;
            
            const word = document.getText(range);
            const func = this.functionsData[word];
            
            if (!func) return null;
            
            return this.createProfessionalHover(func);
            
        } catch (error) {
            return null; // Fail silently
        }
    }
    
    /**
     * Create clean, VS Code-style professional hover documentation
     */
    createProfessionalHover(func) {
        const markdown = new vscode.MarkdownString();
        markdown.supportHtml = true;
        markdown.isTrusted = true;

        // 1. Function Signature
        const params = func.parameters.required.concat(func.parameters.optional);
        const signatureParams = params.map(p => {
            const optional = p.required ? '' : '?';
            return `${p.name}${optional}: ${p.type || 'any'}`;
        }).join(', ');
        const signature = `function ${func.name}(${signatureParams}): ${func.returnType}`;
        markdown.appendCodeblock(signature, 'typescript');

        // 2. Clean Description
        if (func.description) {
            markdown.appendMarkdown(`\n${func.description}\n`);
        }

        // 3. Example Usage
        const example = this.buildExample(func);
        if (example) {
            markdown.appendMarkdown(`\n\n**Example:**\n`);
            markdown.appendCodeblock(example, 'cfml');
        }

        // 4. Parameters Table
        const allParams = func.parameters.required.concat(func.parameters.optional);
        if (allParams.length > 0) {
            markdown.appendMarkdown(`\n**Parameters:**\n`);
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

        // 5. Footer - Context Info
        if (func.availableIn.length > 0 || func.category) {
            markdown.appendMarkdown(
                `\n\n---\n*Available in:* \`${func.availableIn.join(', ')}\`` +
                (func.category ? ` • **${func.category}**` : '')
            );
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
 * Activate extension
 */
function activate(context) {
    try {
        // Register hover provider for CFML files
        const hoverProvider = vscode.languages.registerHoverProvider(
            ['cfml', 'cfc'],
            new WheelsHoverProvider()
        );
        
        // Register command to open Wheels documentation
        const showDocCommand = vscode.commands.registerCommand('wheels.showDocumentation', () => {
            vscode.env.openExternal(vscode.Uri.parse('https://wheels.dev/docs'));
        });
        
        context.subscriptions.push(hoverProvider, showDocCommand);
        
        console.log('Wheels VS Code Extension activated successfully!');
        
    } catch (error) {
        // Fail silently to prevent crashes
        console.error('Extension activation failed:', error);
    }
}

function deactivate() {}

module.exports = { activate, deactivate };