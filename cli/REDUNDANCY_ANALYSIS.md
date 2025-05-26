# Wheels CLI Redundancy Analysis

## Commands with Full Redundancy

### 1. Security Scanning
- **Original**: `wheels analyze security` (Phase 2)
- **New**: `wheels security scan` (Phase 4)
- **Overlap**: 100% - Both scan for vulnerabilities
- **Recommendation**: 
  - Remove `analyze/security.cfc`
  - OR: Make `analyze security` an alias that calls `security scan`

### 2. Test Execution
- **Original**: `wheels test` (basic test runner)
- **New**: `wheels test run` (Phase 1 - advanced runner)
- **Overlap**: 80% - New command has all features plus more
- **Recommendation**: 
  - Deprecate original `test.cfc`
  - Move any unique functionality to `test/run.cfc`
  - Make `wheels test` an alias for `wheels test run`

## Commands with Partial Redundancy

### 1. Performance Analysis
- **Command 1**: `wheels analyze performance` (Phase 2)
- **Command 2**: `wheels optimize performance` (Phase 4)
- **Overlap**: 50% - Different focus but similar domain
- **Recommendation**: 
  - Combine into single command: `wheels performance`
  - Add flags: `--analyze`, `--optimize`, `--report`

### 2. Resource Generation
- **Command 1**: `wheels generate resource` (Phase 1)
- **Command 2**: `wheels scaffold` (Original, refactored)
- **Overlap**: 60% - Both create full CRUD resources
- **Recommendation**: 
  - Keep both but clarify:
  - `generate resource`: Modern REST API resources
  - `scaffold`: Traditional MVC scaffolding
  - Add deprecation notice to scaffold suggesting resource

### 3. Code Analysis
- **Commands**: Multiple analyze subcommands
  - `analyze code` (Phase 2)
  - `analyze security` (Phase 2) 
  - `analyze performance` (Phase 2)
- **Overlap**: Organizational structure
- **Recommendation**:
  - Create unified `wheels analyze` command
  - Subcommands: `--code`, `--security`, `--performance`, `--all`

## Commands to Deprecate

### Priority 1 (Remove/Deprecate Immediately)
1. `analyze/security.cfc` - Fully replaced by `security/scan.cfc`
2. Original `test.cfc` - Replaced by `test/run.cfc`

### Priority 2 (Deprecate with Migration Path)
1. `analyze/performance.cfc` - Merge with `optimize/performance.cfc`
2. Traditional `scaffold.cfc` - Guide users to `generate resource`

### Priority 3 (Consider Consolidation)
1. All `analyze/*` commands - Consolidate under single analyze command
2. `deps.cfc` - Overlap with `plugins` commands

## Migration Strategy

### 1. Add Deprecation Notices
```cfscript
// In deprecated commands
function run() {
    print.yellowLine("⚠️  This command is deprecated and will be removed in v3.0")
         .line("Please use 'wheels security scan' instead")
         .line();
    
    // Call new command
    command("wheels security scan").run();
}
```

### 2. Create Aliases
```cfscript
// In ModuleConfig.cfc
commandAliases = {
    "wheels test": "wheels test run",
    "wheels analyze security": "wheels security scan"
};
```

### 3. Update Documentation
- Remove deprecated commands from help
- Add migration guide
- Update examples to use new commands

## Benefits of Consolidation

1. **Reduced Confusion**: One clear way to do each task
2. **Smaller API Surface**: Fewer commands to learn
3. **Better Maintenance**: Less code duplication
4. **Consistent Experience**: All commands follow new patterns

## Recommended Final Command Structure

```
wheels
├── generate
│   ├── model
│   ├── controller  
│   ├── view
│   ├── resource (REST)
│   └── test
├── test
│   ├── run
│   └── coverage
├── security
│   └── scan
├── performance (combined analyze + optimize)
│   ├── analyze
│   └── optimize
├── docs
│   ├── generate
│   └── serve
├── plugins
│   ├── install
│   ├── remove
│   └── list
├── env
│   ├── setup
│   ├── list
│   └── switch
├── dbmigrate (existing)
│   ├── create
│   ├── up
│   └── down
└── scaffold (deprecated → generate resource)
```