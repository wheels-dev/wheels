# Wheels CLI Comprehensive Testing - Claude Code Agent Prompt

## Your Mission
You are tasked with systematically testing all 621 Wheels CLI command variations documented in AI-CLI.md. You'll execute each command, validate results, document findings, and create a comprehensive report identifying what works and what doesn't.

## Initial Setup

1. First, read and analyze the AI-CLI.md file to understand all commands
2. Create a test results file: `CLI-TEST-RESULTS-[YYYYMMDD].md`
3. Ensure you have access to the `workspace` directory for testing
4. Verify CommandBox is installed: `box version`

## Testing Methodology

You'll test commands in categories, following this process for EACH command:

### 1. Environment Preparation
```bash
# For each test, create isolated environment
cd workspace
mkdir test-[category]-[timestamp]
cd test-[category]-[timestamp]

# For commands requiring an app context (skip for 'wheels g app' commands)
box wheels g app testapp
cd testapp
box server start --port=[unique-port]
```

### 2. Command Execution
- Execute the exact command from AI-CLI.md
- Try variations with different parameters
- Capture all output, errors, and exit codes
- Note files created or modified

### 3. Validation
- For generators: Verify files exist and have correct content
- For database commands: Check database state changes
- For server commands: Use puppeteer to verify web functionality
- For config commands: Verify settings changed correctly

### 4. Documentation
Record in your results file:
```markdown
### Command: `[exact command]`
**Category**: [Generator/Database/etc]
**Status**: ✅ Success | ❌ Failure | ⚠️ Partial
**Execution Time**: [time]

**Output**:
```
[console output]
```

**Validation**:
- [What was checked and result]

**Issues**: [Any problems found]
**Notes**: [Observations]
---
```

### 5. Cleanup
```bash
box server stop
box server forget
cd ../..
rm -rf test-[category]-[timestamp]
```

## Testing Order and Categories

Test in this sequence for best results:

### Phase 1: Core Commands (No App Required)
Start with these - they work anywhere:
- `wheels version`
- `wheels info` 
- `wheels about`
- `wheels help`
- `wheels doctor`

### Phase 2: App Generation
Test app creation before other generators:
- `wheels g app myapp` (basic)
- `wheels g app myapp template=wheels-base-template@BE`
- `wheels g app myapp --useBootstrap --setupH2`
- `wheels new` (interactive wizard)

### Phase 3: Generators (Requires App)
For each, test basic and complex variations:
- **Models**: `wheels g model User` and `wheels g model Post title:string,content:text,userId:integer`
- **Controllers**: Basic, with actions, namespaced, REST, API
- **Scaffolds**: Full CRUD generation with all options
- **Views**: Single and multiple
- **Migrations**: All types (create table, add column, etc.)
- **Tests**: Model, controller, integration

### Phase 4: Database Commands
- `wheels db create`, `wheels db setup`
- `wheels dbmigrate latest`, `wheels dbmigrate up/down`
- `wheels db status`, `wheels db rollback`

### Phase 5: Testing Commands
- `wheels test run` with various options
- Coverage commands
- Watch mode

### Phase 6: Server & Environment
- Server lifecycle commands
- Environment switching
- Configuration management

### Phase 7: Advanced Commands
- Plugin management
- Maintenance commands
- Asset compilation
- Cache management
- Deployment commands

## Special Testing Considerations

### Parameter Syntax Variations
Test both styles when applicable:
```bash
# Positional
wheels g model User

# Named
wheels g model name=User

# With properties - test quote handling
wheels g model User properties="name:string,email:string"
```

### Boolean Parameters
Test different boolean syntaxes:
```bash
wheels g model User --force
wheels g model User force=true
```

### Error Scenarios
Deliberately test error cases:
- Missing required parameters
- Invalid parameter values
- Commands run in wrong context
- Conflicting options

### Performance Notes
- Track execution time for each command
- Note any commands that seem unusually slow
- Identify commands that hang or timeout

## Validation Techniques

### For Generator Commands
```javascript
// Use puppeteer to verify scaffolds work
await page.goto(`http://localhost:${port}/users`);
// Check CRUD operations function correctly
```

### For Database Commands
```bash
# Verify migrations
box wheels db status
# Check table creation
box wheels db shell --command="SELECT * FROM schema_info"
```

### For File Generation
- Check file exists at expected path
- Verify file contents match expected template
- Ensure proper naming conventions

## Results Compilation

Your final report should include:

### 1. Executive Summary
- Total commands tested
- Success rate by category
- Critical failures
- Top 5 recommendations

### 2. Detailed Results
- Every command with its result
- Patterns in failures
- Workarounds discovered

### 3. Quick Reference Lists
Create these helpful lists:
- ✅ Commands that work perfectly
- ⚠️ Commands that work with caveats
- ❌ Commands that fail
- 🔧 Commands that need parameter syntax fixes

### 4. Recommendations
Prioritized list of fixes needed:
- Critical (blocks usage)
- Important (degrades experience)
- Nice-to-have (improvements)

## Important Reminders

1. **Test Isolation**: Each command gets a fresh environment
2. **Document Everything**: Even successful tests provide valuable confirmation
3. **Try Variations**: Don't just test the example - try edge cases
4. **Real Validation**: Actually verify the command did what it claims
5. **Cleanup**: Always clean up test environments

## Begin Testing

Start with Phase 1 (Core Commands) and work systematically through all phases. Create your results file now and begin documenting as you test.

Good luck! Your comprehensive testing will greatly improve the Wheels CLI experience for all users.