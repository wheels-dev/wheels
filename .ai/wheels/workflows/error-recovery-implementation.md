# Enhanced Error Recovery Implementation

## Progressive Error Recovery System

This file provides the concrete implementation patterns for the enhanced error recovery system that can be integrated into the wheels_execute command.

## Level 1: Documentation-Based Recovery

### Error Pattern Database
```javascript
const ERROR_PATTERNS = {
    "Missing argument name": {
        type: "mixed_arguments",
        severity: "high",
        documentation: [
            ".ai/wheels/troubleshooting/common-errors.md",
            ".ai/wheels/patterns/validation-templates.md"
        ],
        solutions: [
            {
                name: "Convert to named arguments",
                pattern: /(\w+)\(\"([^\"]*)\",\s*(\w+)=/g,
                replacement: '$1(name="$2", $3=',
                confidence: 0.9
            },
            {
                name: "Convert to positional arguments",
                pattern: /(\w+)\(name=\"([^\"]*)\",\s*(\w+)=([^,)]+)/g,
                replacement: '$1("$2")',
                confidence: 0.8
            }
        ],
        prevention: "Use consistent argument style throughout component"
    },

    "Can't cast Object type [Query] to Array": {
        type: "query_array_confusion",
        severity: "high",
        documentation: [
            ".ai/wheels/views/data-handling.md",
            ".ai/wheels/models/associations.md",
            ".ai/wheels/views/query-association-patterns.md"
        ],
        solutions: [
            {
                name: "Replace ArrayLen with recordCount",
                pattern: /ArrayLen\(([^)]+)\)/g,
                replacement: '$1.recordCount',
                confidence: 0.95
            },
            {
                name: "Fix query loop syntax",
                pattern: /<cfloop array="#([^"]+)#" index="(\w+)">/g,
                replacement: '<cfloop query="$1">',
                confidence: 0.9
            },
            {
                name: "Store association result before looping",
                pattern: /<cfloop query="([^"]+\(\))">/,
                replacement: '<cfset queryResult = $1><cfloop query="queryResult">',
                confidence: 0.85
            }
        ],
        prevention: "Always use .recordCount for query counts and proper loop syntax"
    },

    "No matching function [EMAILFIELD] found": {
        type: "invalid_helper",
        severity: "medium",
        documentation: [
            ".ai/wheels/views/helpers/forms.md",
            ".ai/wheels/troubleshooting/form-helper-errors.md"
        ],
        solutions: [
            {
                name: "Replace with textField and type",
                pattern: /#emailField\(([^)]+)\)#/g,
                replacement: '#textField($1, type="email")#',
                confidence: 0.95
            },
            {
                name: "Replace passwordField with textField",
                pattern: /#passwordField\(([^)]+)\)#/g,
                replacement: '#passwordField($1)#', // This actually exists
                confidence: 0.9
            }
        ],
        prevention: "Use available CFWheels form helpers or textField with type attribute"
    }
};
```

### Automatic Error Recovery
```javascript
class AutomaticErrorRecovery {
    async recoverFromError(error, context, codeContent) {
        const errorPattern = this.identifyErrorPattern(error);

        if (!errorPattern) {
            return this.escalateToLevel2(error, context);
        }

        // Load relevant documentation
        await this.loadRecoveryDocumentation(errorPattern.documentation);

        // Apply solutions in order of confidence
        for (const solution of errorPattern.solutions.sort((a, b) => b.confidence - a.confidence)) {
            try {
                const recoveredCode = this.applySolution(codeContent, solution);
                const validation = await this.validateRecoveredCode(recoveredCode);

                if (validation.success) {
                    this.logSuccessfulRecovery(error, solution);
                    return {
                        success: true,
                        code: recoveredCode,
                        solution: solution.name,
                        confidence: solution.confidence
                    };
                }
            } catch (solutionError) {
                this.logFailedSolution(error, solution, solutionError);
                continue;
            }
        }

        return this.escalateToLevel2(error, context);
    }

    identifyErrorPattern(error) {
        for (const [pattern, config] of Object.entries(ERROR_PATTERNS)) {
            if (error.message && error.message.includes(pattern)) {
                return config;
            }
        }
        return null;
    }

    applySolution(codeContent, solution) {
        return codeContent.replace(solution.pattern, solution.replacement);
    }
}
```

## Level 2: Pattern Simplification Recovery

### Simplification Strategies
```javascript
class PatternSimplifier {
    async simplifyImplementation(originalPlan, error) {
        const simplificationStrategies = [
            this.removeComplexAssociations,
            this.simplifyValidations,
            this.removeAdvancedFeatures,
            this.useBasicCRUD,
            this.splitIntoSmallerComponents
        ];

        for (const strategy of simplificationStrategies) {
            try {
                const simplifiedPlan = await strategy(originalPlan, error);
                const result = await this.testSimplifiedImplementation(simplifiedPlan);

                if (result.success) {
                    return {
                        success: true,
                        plan: simplifiedPlan,
                        strategy: strategy.name,
                        message: `Recovered using ${strategy.name} simplification`
                    };
                }
            } catch (strategyError) {
                console.log(`Simplification strategy ${strategy.name} failed:`, strategyError);
                continue;
            }
        }

        return this.escalateToLevel3(originalPlan, error);
    }

    removeComplexAssociations(plan, error) {
        // Remove dependent associations and complex options
        const simplifiedPlan = JSON.parse(JSON.stringify(plan));

        if (simplifiedPlan.models) {
            simplifiedPlan.models.forEach(model => {
                if (model.associations) {
                    model.associations = model.associations.map(assoc => ({
                        type: assoc.type,
                        name: assoc.name
                        // Remove complex options like dependent: "delete"
                    }));
                }
            });
        }

        return simplifiedPlan;
    }

    simplifyValidations(plan, error) {
        // Keep only basic validations
        const simplifiedPlan = JSON.parse(JSON.stringify(plan));

        if (simplifiedPlan.models) {
            simplifiedPlan.models.forEach(model => {
                if (model.validations) {
                    model.validations = model.validations.filter(validation =>
                        ['presence', 'uniqueness', 'length'].includes(validation.type)
                    );
                }
            });
        }

        return simplifiedPlan;
    }

    useBasicCRUD(plan, error) {
        // Generate only basic CRUD operations
        const simplifiedPlan = JSON.parse(JSON.stringify(plan));

        if (simplifiedPlan.controllers) {
            simplifiedPlan.controllers.forEach(controller => {
                controller.actions = ['index', 'show', 'new', 'create', 'edit', 'update', 'delete'];
                // Remove custom actions and filters
                delete controller.customActions;
                delete controller.filters;
            });
        }

        return simplifiedPlan;
    }
}
```

## Level 3: Community Pattern Integration

### Community Solutions Database
```javascript
class CommunityPatternMatcher {
    async findSimilarSolutions(error, context) {
        // Simulate community pattern database lookup
        const communityPatterns = await this.queryCommunityDatabase({
            errorType: error.type,
            wheelsVersion: context.wheelsVersion,
            componentType: context.componentType,
            similarityThreshold: 0.8
        });

        for (const pattern of communityPatterns) {
            try {
                const result = await this.applyCommunityPattern(pattern, context);
                if (result.success) {
                    // Contribute back to community knowledge
                    await this.contributeSolution(error, pattern, result);
                    return result;
                }
            } catch (patternError) {
                console.log(`Community pattern failed:`, patternError);
                continue;
            }
        }

        return this.escalateToHuman(error, context);
    }

    async queryCommunityDatabase(criteria) {
        // This would integrate with a real community database
        // For now, return mock patterns based on common solutions
        const mockPatterns = [
            {
                id: "mixed-args-solution-1",
                errorType: "mixed_arguments",
                solution: "Convert all association calls to named arguments",
                code: `
                    // Before: hasMany("comments", dependent="delete")
                    // After: hasMany(name="comments", dependent="delete")
                `,
                successRate: 0.92,
                votes: 45,
                wheelsVersions: ["2.x", "1.4.x"]
            },
            {
                id: "query-array-solution-1",
                errorType: "query_array_confusion",
                solution: "Store association result before looping",
                code: `
                    // Before: <cfloop array="#post.comments()#">
                    // After:
                    <cfset comments = post.comments()>
                    <cfloop query="comments">
                `,
                successRate: 0.88,
                votes: 38,
                wheelsVersions: ["2.x", "1.4.x"]
            }
        ];

        return mockPatterns.filter(p =>
            p.errorType === criteria.errorType &&
            p.wheelsVersions.includes(criteria.wheelsVersion)
        );
    }
}
```

## Error Prediction System

### Pre-Implementation Error Scanning
```javascript
class ErrorPredictor {
    async predictPotentialErrors(implementationPlan, projectContext) {
        const predictions = [];

        // Check for mixed argument risks
        const mixedArgRisk = this.assessMixedArgumentRisk(implementationPlan);
        if (mixedArgRisk.risk > 0.7) {
            predictions.push({
                type: "mixed_arguments",
                severity: "high",
                confidence: mixedArgRisk.risk,
                prevention: "Establish consistent argument style before implementation",
                suggestedAction: "Review existing code patterns and choose named or positional style"
            });
        }

        // Check for query/array confusion risks
        const queryArrayRisk = this.assessQueryArrayRisk(implementationPlan);
        if (queryArrayRisk.risk > 0.6) {
            predictions.push({
                type: "query_array_confusion",
                severity: "high",
                confidence: queryArrayRisk.risk,
                prevention: "Load data handling documentation and use proper query syntax",
                suggestedAction: "Review .ai/wheels/views/data-handling.md before implementation"
            });
        }

        // Check for form helper risks
        if (this.hasFormComponents(implementationPlan)) {
            const formRisk = this.assessFormHelperRisk(implementationPlan);
            if (formRisk.risk > 0.5) {
                predictions.push({
                    type: "invalid_helper",
                    severity: "medium",
                    confidence: formRisk.risk,
                    prevention: "Use available CFWheels form helpers only",
                    suggestedAction: "Review .ai/wheels/views/helpers/forms.md"
                });
            }
        }

        return predictions;
    }

    assessMixedArgumentRisk(plan) {
        let riskScore = 0;
        let riskFactors = [];

        // Check if plan involves associations
        if (plan.models && plan.models.some(m => m.associations && m.associations.length > 0)) {
            riskScore += 0.3;
            riskFactors.push("Has model associations");
        }

        // Check if working with existing code that might have inconsistent patterns
        if (plan.modifyExisting) {
            riskScore += 0.4;
            riskFactors.push("Modifying existing code");
        }

        // Check if complex associations are planned
        if (plan.models && plan.models.some(m =>
            m.associations && m.associations.some(a => a.options && Object.keys(a.options).length > 0))) {
            riskScore += 0.4;
            riskFactors.push("Complex associations with options");
        }

        return { risk: riskScore, factors: riskFactors };
    }

    assessQueryArrayRisk(plan) {
        let riskScore = 0;
        let riskFactors = [];

        // Check if views will display association data
        if (plan.views && plan.models && plan.models.some(m => m.associations)) {
            riskScore += 0.5;
            riskFactors.push("Views displaying association data");
        }

        // Check if looping over model results
        if (plan.views && plan.views.some(v => v.hasLoops)) {
            riskScore += 0.3;
            riskFactors.push("Views with data loops");
        }

        // Check if counting association records
        if (plan.views && plan.views.some(v => v.showsCounts)) {
            riskScore += 0.2;
            riskFactors.push("Views showing record counts");
        }

        return { risk: riskScore, factors: riskFactors };
    }
}
```

## Integration with wheels_execute Command

### Enhanced Error Handling Workflow
```markdown
## Enhanced wheels_execute Error Handling

### Phase 0: Pre-Implementation Error Prediction (NEW)
1. Analyze implementation plan for error risks
2. Run error prediction algorithms
3. Load preventive documentation based on predictions
4. Suggest alternative approaches for high-risk patterns

### During Implementation: Real-Time Error Monitoring (NEW)
1. Monitor for predicted error patterns during code generation
2. Apply automatic corrections for known anti-patterns
3. Validate each component against error patterns
4. Escalate to recovery system if errors detected

### Phase 8: Post-Implementation Error Recovery (NEW)
1. If any errors detected, engage progressive recovery:
   - Level 1: Apply documented solutions automatically
   - Level 2: Simplify implementation approach
   - Level 3: Search community patterns
   - Level 4: Request human intervention

2. Learn from successful recoveries:
   - Update error pattern database
   - Improve prediction algorithms
   - Contribute to community knowledge

3. Update documentation with new patterns:
   - Add successful solutions to .ai documentation
   - Update anti-pattern detection rules
   - Enhance prevention strategies
```

## Implementation Files Structure
```
.ai/wheels/workflows/
├── error-recovery-implementation.md (this file)
├── error-patterns-database.js (error pattern definitions)
├── automatic-recovery.js (Level 1 recovery implementation)
├── pattern-simplifier.js (Level 2 simplification strategies)
├── community-matcher.js (Level 3 community integration)
├── error-predictor.js (pre-implementation prediction)
└── recovery-integration.md (wheels_execute integration guide)
```

This implementation provides a robust, multi-level error recovery system that learns and improves over time while maintaining the high-quality standards of the wheels_execute command.