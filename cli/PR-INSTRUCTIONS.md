# Pull Request Instructions

## Pull Request Title
Implement CLI improvements from CLI-IMPROVEMENTS.md

## Pull Request Description
### Summary
- Implemented all CLI improvements recommended in CLI-IMPROVEMENTS.md
- Added 10 new command groups with various subcommands to enhance developer workflow
- Added comprehensive documentation for all new and existing commands
- All commands follow existing project structure and patterns

### Changes include
1. **Interactive Development Mode**: Added `wheels watch` command to monitor file changes and automatically reload
2. **Enhanced Testing Tools**: Added `wheels test:coverage` and `wheels test:debug` commands
3. **API Development Support**: Added `wheels generate api-resource` command
4. **Modern Frontend Integration**: Added `wheels generate frontend` command supporting React, Vue, and Alpine.js
5. **Configuration Management**: Added `wheels config:list`, `wheels config:set`, and `wheels config:env` commands
6. **Dependency Management**: Added `wheels deps` command with multiple actions
7. **Performance Analysis**: Added `wheels analyze` command to identify bottlenecks
8. **Database Tools**: Added `wheels db:seed` and `wheels db:schema` commands
9. **CI/CD Templates**: Added `wheels ci:init` command for GitHub Actions, GitLab CI, and Jenkins
10. **Docker Workflow**: Added `wheels docker:init` and `wheels docker:deploy` commands

### Documentation
Added comprehensive documentation in the `docs/` directory covering all CLI commands and best practices.

### Test plan
1. Test each new command individually
2. Verify integration with existing wheels commands
3. Ensure backward compatibility with existing functionality

---

To create this pull request manually:
1. Go to: https://github.com/cfwheels/wheels-cli/pulls
2. Click "New pull request"
3. Select the source branch: "feature/cli-improvements"
4. Select the target branch: "main"
5. Copy and paste the above title and description
6. Click "Create pull request"