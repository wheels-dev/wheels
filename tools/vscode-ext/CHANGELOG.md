# Change Log

## [1.0.5] - 2025-09-24

### Fixed
- **Context-Aware Hover**: Fixed issue where hover documentation was shown for Wheels function names in incorrect contexts (strings, comments, variable assignments)
- **Multi-line Function Detection**: Added support for multi-line function calls where opening parenthesis is on subsequent lines
- **Improved String Detection**: Enhanced string literal detection to properly handle both single and double quotes with escape sequences
- **Comment Recognition**: Added comprehensive comment detection for CFML, CFScript, and JavaScript-style comments
- **Performance**: Added reasonable limits to multi-line scanning to prevent performance issues
- **Snippet Cursor Positioning**: Fixed cursor positioning for empty function snippets (functions without parameters) - cursor now stays after closing parenthesis instead of jumping to next line

### Changed
- Hover provider now only shows documentation when function names are used in actual function call contexts
- Enhanced error handling to fail gracefully without crashing the extension

## [1.0.4] - 2025-09-17

### Changed
- Updated migration function parameters: changed `null` to `allowNull` in migration functions for improved clarity and consistency

## [1.0.3] - 2025-09-10

### Changed
- Updated changelog management and documentation

## [1.0.2] - 2025-09-09

### Added
- Language support configuration for CFML files (.cfm, .cfc, .cfml)

## [1.0.1] - 2025-09-09

### Changed
- Updated extension logo

## [1.0.0] - 2025-09-04

### Added
- **300+ Code Snippets** for Wheels framework functions
- **Professional Hover Documentation** with examples and parameter details  
- **Smart Parameter Completion** using named syntax instead of positional
- **Multi-Version Support** with required-only and common parameter variants
- **Complete Framework Coverage** including models, controllers, views, and migrations
- **Command**: "Open Wheels Documentation" to access wheels.dev

### Initial Release
First release of the Wheels VS Code extension providing intelligent code completion and documentation for the Wheels CFML framework.