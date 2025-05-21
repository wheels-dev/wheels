# Submitting Pull Requests to CFWheels

This guide provides a step-by-step process for contributing code to CFWheels through pull requests (PRs). It covers the entire workflow from setting up your development environment to getting your PR merged into the project.

## Prerequisites

Before you start contributing, make sure you have:

1. A GitHub account
2. Git installed on your local machine
3. Docker installed (for running the test environment)
4. Basic knowledge of Git commands and GitHub workflows
5. Familiarity with CFWheels and CFML

## Setting Up Your Development Environment

### 1. Fork the CFWheels Repository

Start by forking the CFWheels repository to your own GitHub account:

1. Visit [https://github.com/cfwheels/cfwheels](https://github.com/cfwheels/cfwheels)
2. Click the "Fork" button in the upper right corner
3. Select your GitHub account as the destination

### 2. Clone Your Fork Locally

Clone your fork to your local machine:

```bash
git clone https://github.com/YOUR-USERNAME/cfwheels.git
cd cfwheels
```

### 3. Add the Upstream Repository

Add the main CFWheels repository as an "upstream" remote to keep your fork in sync:

```bash
git remote add upstream https://github.com/cfwheels/cfwheels.git
```

### 4. Set Up Docker Test Environment

Set up the Docker-based test environment to ensure your changes work across all supported platforms:

```bash
# Start the minimal test environment
docker compose --profile quick-test up -d
```

See [Using the Test Environment](using-the-test-environment.md) for more detailed instructions.

## Contribution Workflow

### 1. Find or Create an Issue

Before writing any code, make sure there's an issue in the GitHub issue tracker:

1. Check if an issue already exists for the bug or feature you want to work on
2. If not, create a new issue describing the bug or feature
3. Wait for feedback from the core team before proceeding

### 2. Create a Feature Branch

Once your issue is approved, create a feature branch in your local repository:

```bash
# First, sync your fork with upstream
git fetch upstream
git checkout develop
git merge upstream/develop

# Create a new branch
git checkout -b feature/issue-NUMBER
```

Replace `NUMBER` with the issue number from GitHub. Use descriptive branch names:
- `feature/issue-123` for new features
- `fix/issue-123` for bug fixes
- `docs/issue-123` for documentation updates

### 3. Make Your Changes

Now you can start coding! Remember to:

- Follow the [Code Style Guide](https://github.com/cfwheels/cfwheels/wiki/Code-Style-Guide)
- Add comments where appropriate
- Write tests for your changes
- Keep your changes focused on addressing the specific issue

### 4. Test Your Changes

#### Using the Docker Test Environment

The Docker test environment allows you to test your changes against multiple CFML engines and databases:

```bash
# Start the test environment with specific components
docker compose --profile lucee --profile mysql --profile ui up -d

# Access the TestUI at http://localhost:3001
```

#### Running Tests

Use the TestUI or run tests directly:

```bash
# Run all tests across all engines (from TestUI)
# or run specific tests via command line:
docker exec -it cfwheels-test-lucee5 sh -c "cd /cfwheels-test-suite && box wheels test app"

# Run a specific test
docker exec -it cfwheels-test-lucee5 sh -c "cd /cfwheels-test-suite && box wheels test app TestName"
```

Make sure your changes:
1. Pass all existing tests
2. Include new tests for new functionality
3. Work across all supported CFML engines

### 5. Commit Your Changes

Once your changes are ready and tested:

```bash
git add .
git commit -m "fix: description of your changes (fixes #123)"
```

Follow these commit message guidelines:
- Start with a type: `fix:`, `feat:`, `docs:`, `refactor:`, etc.
- Include a concise description of the changes
- Reference the issue number with `(fixes #123)` or `(refs #123)`
- Keep the subject line under 72 characters
- Use the body of the commit message for additional details if needed

### 6. Push Your Changes

Push your branch to your fork on GitHub:

```bash
git push origin feature/issue-123
```

### 7. Create a Pull Request

Create a pull request from your branch to the CFWheels develop branch:

1. Go to your fork on GitHub
2. Click the "Compare & Pull Request" button for your branch
3. Set the base repository to `cfwheels/cfwheels` and the base branch to `develop`
4. Fill out the PR template with:
   - A clear description of the changes
   - Reference to the issue being addressed
   - Any special testing instructions
   - Screenshots if applicable (for UI changes)

### 8. Respond to Review Feedback

After submitting your PR:

1. A core team member will review your code
2. They may request changes or clarification
3. Make any requested changes by pushing additional commits to your branch
4. The PR will be automatically updated

### 9. Update Your PR if Needed

If the develop branch has been updated since you created your PR, you may need to update your branch:

```bash
git checkout feature/issue-123
git fetch upstream
git merge upstream/develop
# Resolve any conflicts if needed
git push origin feature/issue-123
```

## Tips for Successful Pull Requests

### Keep Changes Focused

Each PR should address a single issue or implement a single feature. This makes review easier and reduces the chance of conflicts.

### Include Tests

Always include tests for your changes:
- For bug fixes, add a test that would fail without your fix
- For new features, add tests covering all functionality
- Make sure all existing tests continue to pass

### Update Documentation

If your changes affect user-facing functionality, update the relevant documentation:
- Update guides in the `/guides` directory
- Add inline documentation to code
- Update the CHANGELOG.md if requested

### Use the Docker Environment Effectively

The Docker test environment is a powerful tool for ensuring your changes work across platforms:
- Test on multiple CFML engines (Lucee and Adobe ColdFusion)
- Test with different database engines
- Use the TestUI to run specific tests and view results

## Working with the Core Team

### Communication is Key

Maintain open communication during the PR process:
- Respond promptly to review comments
- Ask questions if requirements are unclear
- Be open to feedback and suggestions

### Be Patient

The core team members are volunteers with limited time. Review may take some time, especially for complex changes.

### Participate in the Community

While waiting for review, you can:
- Help review other PRs
- Answer questions in the discussions
- Report bugs or improve documentation

## After Your PR is Merged

Once your PR is merged:

1. Delete your feature branch
   ```bash
   git checkout develop
   git branch -D feature/issue-123
   ```

2. Sync your fork with the updated upstream
   ```bash
   git fetch upstream
   git merge upstream/develop
   git push origin develop
   ```

3. Celebrate your contribution to CFWheels! 🎉

## Special Considerations

### Breaking Changes

If your change introduces breaking changes:
- Clearly indicate this in the PR description
- Explain why the breaking change is necessary
- Document migration paths for users

### Performance Considerations

For changes that might impact performance:
- Include before/after benchmarks if possible
- Test with different load scenarios
- Document any performance implications

### Cross-Engine Compatibility

Remember that CFWheels supports multiple CFML engines:
- Test on both Lucee and Adobe ColdFusion
- Avoid engine-specific features or provide alternatives
- Use the Docker environment to verify compatibility

## Conclusion

Contributing to CFWheels through pull requests is a rewarding way to improve the framework and help the CFML community. By following this process, you'll help ensure that your contributions are high-quality, well-tested, and efficiently integrated into the project.

For more information on using the test environment, see [Using the Test Environment](using-the-test-environment.md).