I want to test the next untested group of Wheels CLI commands from PR #1591

## Process

1. **Identify Next Group to Test**
   - Fetch PR #1591 comments using `gh pr view 1591 --comments`
   - Parse the testing checklist comments to find groups with unchecked items
   - Select the first group that has unchecked boxes (following the priority order)
   - Extract all commands and test cases for that group

2. **Prepare Testing Environment**
   - Use the `workspace` directory as sandbox
   - Clean any existing test app: `rm -rf workspace/testapp`
   - Set up fresh environment for testing

3. **Test Each Command in the Group**
   For each unchecked command in the selected group:

   a. **Setup Phase**
      - If not testing app generation, create test app: `box wheels g app testapp`
      - Navigate to test app: `cd workspace/testapp`
      - Start server if needed: `box server start`
      - Wait for server to be ready

   b. **Test Execution**
      - Run the command with various parameter combinations
      - Test basic execution (no parameters)
      - Test required parameters
      - Test optional parameters and flags
      - Test error cases (invalid inputs)
      - Test help text: `box wheels [command] --help`

   c. **Verification**
      - Check command output for errors
      - Verify files are created/modified as expected
      - Use Puppeteer to verify web functionality when applicable
      - Test that aliases work (if any)
      - Verify integration with other commands

   d. **Issue Resolution**
      - If errors occur, analyze the root cause
      - Check the command implementation in `cli/commands/wheels/`
      - Fix any issues found
      - Reload CommandBox if changes made: `box reload`
      - Re-test the command

4. **Update PR Progress**
   After successfully testing each command:
   - Use `gh pr comment 1591 --edit-last` to update the checklist
   - Mark completed items with [x]
   - Add notes about any issues found or fixes made

5. **Clean Up After Each Command**
   - Stop server if running: `box server stop`
   - Forget server: `box server forget`
   - Clean up test files created by the command

6. **Group Completion**
   - Once all commands in a group are tested, add a summary comment
   - Move to the next group if time permits

## Special Considerations

- **Core/Info Commands**: Don't require app creation
- **Generation Commands**: Test file creation and content
- **Database Commands**: Ensure database exists and migrations work
- **Server Commands**: Test server lifecycle
- **Testing Commands**: Verify test execution and reporting

## Testing Priority Order

1. Core/Info Commands (fundamental functionality)
2. Generation Commands (most used features)
3. Database & Migration Commands (critical for development)
4. Testing Commands (quality assurance)
5. Server Commands (development workflow)
6. Environment & Configuration
7. Plugin Management
8. Asset & Cache Management
9. Other utility commands

## Example Test Sequence

For testing "Generation Commands" group:
```bash
# Clean workspace
rm -rf workspace/testapp

# Test app generation
cd workspace
box wheels g app testapp
cd testapp

# Test model generation
box wheels g model User --properties="name:string,email:string"
# Verify: models/User.cfc created, migration created

# Test controller generation
box wheels g controller Users index,show,new
# Verify: controllers/Users.cfc created with actions

# Test scaffold
box wheels scaffold Product name:string,price:decimal
# Verify: model, controller, views, migration created

# Run migrations to test integration
box wheels dbmigrate latest

# Start server and verify with Puppeteer
box server start
# Use Puppeteer to check /users and /products routes

# Clean up
box server stop
box server forget
cd ../..
rm -rf workspace/testapp
```

## Progress Tracking

The PR comments serve as persistent state. Each testing session:
1. Checks current progress from PR
2. Picks up where last session ended
3. Updates progress in real-time
4. Allows multiple people to collaborate

Remember:
- Test thoroughly before checking off items
- Document any issues or unexpected behavior
- Ensure all functionality works as documented
- Fix issues before marking as complete