# Contributing to Wheels VS Code Extension

## Repository

The Wheels VS Code Extension is located in the main Wheels repository at `tools/vscode-ext/`:

**[GitHub Repository](https://github.com/wheels-dev/wheels/tree/develop/tools/vscode-ext)**

## Development Setup

### Prerequisites
- Node.js (version 14 or higher)
- VS Code
- Git

### Initial Setup
1. Clone the Wheels repository:
   ```bash
   git clone https://github.com/wheels-dev/wheels.git
   cd wheels/tools/vscode-ext
   ```

2. Install VS Code Extension CLI globally (optional, for packaging):
   ```bash
   npm install -g vsce
   ```

## Extension Structure

```
tools/vscode-ext/
├── src/                      # Extension source code
│   ├── extension.js          # Extension functions
├── snippets/                 # Code snippets for Wheels 
│   ├── wheels-api.json       # Contains wheels all API functions
│   ├── wheels.code-snippets  # Model-specific snippets
├── assets/                   # Extension assets (icons, etc.)
│   ├── wheels_logo.png       # Extension code snippets
├── package.json              # Extension manifest and configuration
├── README.md                 # Extension documentation
├── CHANGELOG.md              # Version history
└── LICENSE                   # License
```

## Making Changes

### Adding New Snippets
1. Navigate to the appropriate snippet file in `/snippets/`
2. Add your snippet following the existing pattern:
   ```json
   "functionName": {
     "prefix": "functionName",
     "body": [
       "functionName(${1:param} = \"${2:value}\")"
     ],
     "description": "Function description"
   }
   ```

### Updating Function Documentation
1. Edit files in `/src/` directory
2. Update hover documentation and parameter information
3. Ensure examples are accurate and helpful

### Modifying Extension Configuration
1. Update `package.json` for:
   - Version numbers
   - New file type support
   - Activation events
   - Contribution points

## Testing Your Changes

### Local Testing
1. Open the extension directory in VS Code
2. Press `F5` to launch Extension Development Host
3. Test your changes in the new VS Code window
4. Verify:
   - Snippets work correctly
   - Hover documentation displays properly
   - Completions appear as expected
   - No errors in Developer Console

### Building and Testing VSIX
1. Package the extension:
   ```bash
   vsce package
   ```
2. Install the generated `.vsix` file locally
3. Test in a real world environment

## Code Quality Standards

### Snippet Guidelines
- Use meaningful prefixes that match function names
- Provide both basic and full parameter versions where applicable
- Include helpful default values
- Add clear descriptions

### Documentation Standards
- Keep hover documentation concise but comprehensive
- Include practical examples
- Document all parameters with types
- Maintain consistency with Wheels documentation

## Upgrading and Maintenance

### Keeping Snippets Current
1. Monitor Wheels framework releases for new functions
2. Update existing snippets when function signatures change
3. Remove deprecated functions
4. Test against latest Wheels version

### Version Management
1. Follow semantic versioning (MAJOR.MINOR.PATCH)
2. Update `package.json` version
3. Document changes in `CHANGELOG.md`
4. Tag releases appropriately

### Compatibility Testing
Test extension with:
- Latest stable VS Code version
- Different CFML file types (.cfm, .cfc)
- Various Wheels project structures
- Multiple operating systems if possible

## Contributing Process

Follow the standard Wheels contribution process:

1. **Open an Issue**: Before making changes, open an issue in the [issue tracker](https://github.com/wheels-dev/wheels/issues) describing your proposed changes
2. **Get Approval**: Wait for core team approval before starting development
3. **Fork and Branch**: Create a feature branch from `develop`
4. **Make Changes**: Implement your changes following the guidelines above
5. **Test Thoroughly**: Test your changes locally and with packaged VSIX
6. **Submit Pull Request**: Create a pull request to the `develop` branch, before creating a PR, please also review [Contributing to Wheels](working-with-wheels/contributing-to-wheels.md) and [Submitting Pull Requests](working-with-wheels/submitting-pull-requests.md) guide
7. **Code Review**: Address any feedback from the core team

### Pull Request Guidelines
- Reference the issue number in your PR description
- Include clear commit messages
- Test against multiple VS Code versions if possible
- Update CHANGELOG.md for user-facing changes
- Ensure no breaking changes without proper deprecation

## Reporting Issues

Found a bug or have a feature request for the VS Code extension?

**[Report Issues](https://github.com/wheels-dev/wheels/issues)**

When reporting extension-specific issues, please include:
- VS Code version
- Extension version (found in Extensions panel)
- Wheels framework version
- Operating system
- Steps to reproduce the issue
- Expected vs. actual behavior
- Any error messages from Developer Console

## Release Process

Extension releases follow the main Wheels release cycle:

1. Changes are merged to `develop` branch
2. During Wheels release preparation, extension version is updated
3. Extension is packaged and tested
4. VSIX file will be generated at our side and tested
5. Extension may be published to VS Code Marketplace after proper testing

## Support

For help with extension development:
- **[Community Discussions](https://github.com/wheels-dev/wheels/discussions)** - Ask questions and share ideas
- **[Issue Tracker](https://github.com/wheels-dev/wheels/issues)** - Report bugs and request features
- **[Wheels Documentation](https://wheels.dev)** - Complete framework documentation