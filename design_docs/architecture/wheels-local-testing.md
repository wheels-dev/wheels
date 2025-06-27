Plan to Create a Simple Docker Command for Building and Testing Templates/Examples

Based on my analysis of the Wheels monorepo structure, here's my plan to create a simple command that allows contributors to build and test from any template or example directory:

Key Findings:
1. Templates Location: /templates/ directory with base and api subdirectories
2. Examples Location: /examples/ directory with various sample applications
3. Docker Setup: Comprehensive Docker configuration in /tools/docker/ with support for multiple CFML engines (Lucee 5/6/7, Adobe 2018/2021/2023/2025)
4. Main compose.yml: Root-level Docker compose file that mounts /templates/base/src for testing
5. CLI Infrastructure: Existing wheels docker:init and wheels docker:deploy commands in the CLI module

Proposed Solution:

Create a new CLI command wheels docker:test that will:

1. Auto-detect context: Determine if the command is run from a template or example directory
2. Generate local Docker files: Create a lightweight docker-compose.yml that:
	- Uses the existing Docker images from the monorepo
	- Mounts the current directory as the application root
	- Includes necessary database services
	- Exposes appropriate ports for testing
3. Integration with existing infrastructure:
	- Leverage the existing Docker configurations in /tools/docker/
	- Use the same port conventions (60005 for Lucee 5, 62021 for Adobe 2021, etc.)
	- Support the same database options (H2, MySQL, PostgreSQL, SQL Server)
4. Simple usage:
# From any template or example directory:
cd examples/blog-app
wheels docker:test

# With options:
wheels docker:test --engine=lucee@6 --db=postgres
wheels docker:test --engine=adobe@2021 --db=mysql
5. Additional helper commands:
	- wheels docker:test:stop - Stop the test containers
	- wheels docker:test:clean - Remove test containers and volumes
	- wheels docker:test:logs - View container logs

Implementation Details:

1. Create /cli/src/commands/wheels/docker/test.cfc with:
	- Auto-detection logic for template/example context
	- Dynamic docker-compose generation based on current directory
	- Support for all CFML engines and databases
	- Health check integration
2. Update the existing docker structure to:
	- Make Docker images more reusable for local testing
	- Ensure consistent environment variables across all setups
3. Create helper scripts in /tools/docker/:
	- test-template.sh - Shell script for non-CLI users
	- test-cleanup.sh - Cleanup script
4. Documentation updates:
	- Add instructions to /templates/README.md and /examples/README.md
	- Update CLAUDE.md with the new testing workflow
	- Create a quick-start guide for contributors

Benefits:

- Contributors can test any template/example with a single command
- No need to understand the complex monorepo structure
- Consistent testing environment across all contributors
- Integrates seamlessly with existing CI/CD workflows
- Supports all CFML engines for compatibility testing

## Update (2025-06-27): Template Structure Changes

### Flattened Directory Structure
Templates now use a flattened directory structure with all application files at the root level instead of nested in a `src/` subdirectory. This change:
- Simplifies the template structure
- Aligns with standard CFML application layouts
- Reduces confusion from duplicate configuration files

### Docker Dependency Isolation
The Docker test command now uses named volumes for vendor dependencies (WireBox, TestBox) to prevent:
- Host filesystem pollution during testing
- Git tracking of installed dependencies
- Conflicts between host and container environments

The implementation automatically creates named volumes like:
- `wheels-test-vendor-testbox`
- `wheels-test-vendor-wirebox`

These volumes persist dependencies across container restarts while keeping the host repository clean.
