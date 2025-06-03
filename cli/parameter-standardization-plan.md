# CFWheels CLI Parameter Standardization Implementation Plan

## Overview
This plan outlines the concrete steps to standardize parameter names across all CFWheels CLI commands, starting with a phased approach that maintains backward compatibility.

## Phase 1: Foundation (Immediate)

### 1.1 Create Shared Parameter Definitions
Create a new CFC for shared parameter definitions:

```cfc
// cli/models/SharedParameters.cfc
component {
    
    // Common parameter groups
    public struct function getGenerationParams() {
        return {
            "name": {
                "hint": "Name of the item to generate",
                "type": "string",
                "required": true
            },
            "force": {
                "hint": "Overwrite existing files",
                "type": "boolean",
                "default": false
            },
            "dry-run": {
                "hint": "Preview changes without creating files",
                "type": "boolean",
                "default": false
            }
        };
    }
    
    public struct function getDatabaseParams() {
        return {
            "column-name": {
                "hint": "Name of the database column",
                "type": "string",
                "required": true
            },
            "data-type": {
                "hint": "SQL data type (string, integer, datetime, etc.)",
                "type": "string",
                "required": true
            },
            "default": {
                "hint": "Default value for the column",
                "type": "string"
            },
            "null": {
                "hint": "Whether column allows NULL values",
                "type": "boolean",
                "default": true
            }
        };
    }
    
    public struct function getRelationshipParams() {
        return {
            "belongs-to": {
                "hint": "Parent model name(s) for belongsTo relationship",
                "type": "string"
            },
            "has-many": {
                "hint": "Child model name(s) for hasMany relationship",
                "type": "string"
            },
            "has-one": {
                "hint": "Child model name for hasOne relationship",
                "type": "string"
            }
        };
    }
}
```

### 1.2 Parameter Mapping Helper
Create a helper for backward compatibility:

```cfc
// cli/models/ParameterMapper.cfc
component {
    
    // Map old parameter names to new ones
    private struct function parameterMap() {
        return {
            "objectname": "target",
            "columnName": "column-name",
            "columnType": "data-type",
            "primaryKey": "primary-key",
            "servername": "server-name"
        };
    }
    
    // Convert old parameters to new format
    public struct function normalizeParameters(required struct params) {
        var normalized = duplicate(arguments.params);
        var map = parameterMap();
        
        for (var oldName in map) {
            if (structKeyExists(normalized, oldName)) {
                normalized[map[oldName]] = normalized[oldName];
                
                // Log deprecation warning
                if (!structKeyExists(normalized, "suppress-warnings")) {
                    writeOutput("WARNING: Parameter '#oldName#' is deprecated. Use '#map[oldName]#' instead." & chr(10));
                }
            }
        }
        
        return normalized;
    }
}
```

## Phase 2: Update Commands (v3.1)

### 2.1 Model Generation Command
Update the model.cfc file:

```cfc
// cli/commands/wheels/generate/model.cfc
component extends="wheels.cli.models.BaseCommand" {
    
    property name="parameterMapper" inject="ParameterMapper@cfwheels-cli";
    property name="sharedParams" inject="SharedParameters@cfwheels-cli";
    
    function run(
        required string name,
        string description = "",
        boolean force = false,
        string primaryKey = "id", // Deprecated: Use primary-key
        string "primary-key" = "",
        string "belongs-to" = "",
        string "has-many" = "",
        string "has-one" = "",
        boolean api = false,
        boolean rest = false,
        boolean migration = true
    ) {
        // Normalize parameters
        var args = parameterMapper.normalizeParameters(arguments);
        
        // Use new parameter names internally
        args["primary-key"] = args["primary-key"] ?: args.primaryKey;
        
        // Rest of implementation...
    }
}
```

### 2.2 Property Generation Command
```cfc
// cli/commands/wheels/generate/property.cfc
component extends="wheels.cli.models.BaseCommand" {
    
    function run(
        required string name,
        string columnName = "", // Deprecated: Use column-name
        string "column-name" = "",
        string columnType = "", // Deprecated: Use data-type
        string "data-type" = "",
        string default = "",
        boolean null = true,
        numeric limit = 0,
        numeric precision = 0,
        numeric scale = 0
    ) {
        // Normalize parameters
        var args = parameterMapper.normalizeParameters(arguments);
        
        // Use new names internally
        args["column-name"] = args["column-name"] ?: args.columnName;
        args["data-type"] = args["data-type"] ?: args.columnType;
        
        // Implementation...
    }
}
```

## Phase 3: Update Help System

### 3.1 Enhanced Help Display
Update base command to show parameter groups:

```cfc
// cli/models/BaseCommand.cfc
component {
    
    public string function getHelp() {
        var help = "";
        var metadata = getMetadata(this);
        
        // Group parameters by category
        var paramGroups = {
            "required": [],
            "database": [],
            "relationships": [],
            "options": [],
            "deprecated": []
        };
        
        // Categorize parameters
        for (var func in metadata.functions) {
            if (func.name == "run") {
                for (var param in func.parameters) {
                    var category = categorizeParameter(param);
                    paramGroups[category].append(param);
                }
            }
        }
        
        // Display by group
        for (var group in paramGroups) {
            if (paramGroups[group].len()) {
                help &= chr(10) & "### " & group & " Parameters" & chr(10);
                for (var param in paramGroups[group]) {
                    help &= formatParameter(param);
                }
            }
        }
        
        return help;
    }
}
```

## Phase 4: Migration Tools

### 4.1 Migration Script
Create a script to help users update their scripts:

```cfc
// cli/commands/wheels/migrate-params.cfc
component extends="wheels.cli.models.BaseCommand" {
    
    function run(
        string path = "./",
        boolean "dry-run" = false,
        boolean backup = true
    ) {
        print.line("Scanning for CLI commands with old parameter names...");
        
        var files = directoryList(arguments.path, true, "path", "*.cfm,*.cfc");
        var updates = [];
        
        for (var file in files) {
            var content = fileRead(file);
            var hasChanges = false;
            
            // Check for old parameter names
            var patterns = {
                "objectname": "target",
                "columnName": "column-name",
                "columnType": "data-type",
                "primaryKey": "primary-key"
            };
            
            for (var old in patterns) {
                if (findNoCase(old, content)) {
                    updates.append({
                        "file": file,
                        "old": old,
                        "new": patterns[old]
                    });
                    
                    if (!arguments["dry-run"]) {
                        content = replaceNoCase(content, old, patterns[old], "all");
                        hasChanges = true;
                    }
                }
            }
            
            if (hasChanges && !arguments["dry-run"]) {
                if (arguments.backup) {
                    fileCopy(file, file & ".bak");
                }
                fileWrite(file, content);
            }
        }
        
        // Report findings
        if (updates.len()) {
            print.line("Found #updates.len()# instances to update:");
            print.table(updates);
        } else {
            print.line("No old parameter names found.");
        }
    }
}
```

## Phase 5: Testing Strategy

### 5.1 Backward Compatibility Tests
```cfc
// tests/cli/ParameterCompatibilityTest.cfc
component extends="testbox.system.BaseSpec" {
    
    function run() {
        describe("Parameter Backward Compatibility", function() {
            
            it("should accept old parameter names with warning", function() {
                var command = new cli.commands.wheels.generate.model();
                
                // Capture output
                savecontent variable="output" {
                    command.run(
                        name = "User",
                        objectname = "users",
                        columnName = "user_id"
                    );
                }
                
                expect(output).toInclude("WARNING: Parameter 'objectname' is deprecated");
                expect(output).toInclude("WARNING: Parameter 'columnName' is deprecated");
            });
            
            it("should prefer new parameter names over old", function() {
                var mapper = new cli.models.ParameterMapper();
                var params = {
                    "columnName": "old_name",
                    "column-name": "new_name"
                };
                
                var normalized = mapper.normalizeParameters(params);
                expect(normalized["column-name"]).toBe("new_name");
            });
        });
    }
}
```

## Implementation Timeline

### Week 1-2: Foundation
- [ ] Create SharedParameters.cfc
- [ ] Create ParameterMapper.cfc
- [ ] Update BaseCommand help system
- [ ] Write initial tests

### Week 3-4: Core Commands
- [ ] Update generate:model
- [ ] Update generate:controller
- [ ] Update generate:property
- [ ] Update dbmigrate commands

### Week 5-6: All Commands
- [ ] Update remaining commands
- [ ] Create migration script
- [ ] Update documentation

### Week 7-8: Testing & Documentation
- [ ] Complete test coverage
- [ ] Update all documentation
- [ ] Create migration guide
- [ ] Beta testing

## Success Metrics
- All commands support both old and new parameter names
- Zero breaking changes for existing scripts
- Clear deprecation warnings displayed
- Migration path documented and tested
- 100% test coverage for parameter handling

## Next Steps
1. Review and approve this plan
2. Create feature branch for implementation
3. Begin with SharedParameters.cfc creation
4. Implement in small, reviewable PRs