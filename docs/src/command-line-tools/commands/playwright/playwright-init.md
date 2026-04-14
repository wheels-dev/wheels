---
description: Initialize Playwright for end-to-end testing in your Wheels application.
---

# wheels playwright:init

Initialize Playwright for end-to-end testing in your Wheels application. This command launches the official Playwright setup wizard to configure your project.

## Usage

```bash
wheels playwright:init
```

## Prerequisites

- Node.js and npm must be installed
- You must be in a Wheels application root directory

## Interactive Prompts

The setup wizard will ask you:

1. **Language preference** - TypeScript or JavaScript
2. **Test directory** - Where to put your end-to-end tests
3. **GitHub Actions** - Whether to add a CI workflow
4. **Browser installation** - Answer **NO** to this

## Examples

### Basic initialization

```bash
wheels playwright:init
```

### What to expect

```
This will initialize Playwright with interactive prompts.

The wizard will ask you about:
  - TypeScript or JavaScript
  - Test directory location
  - GitHub Actions setup
  - Browser installation (answer NO - use 'wheels playwright install' instead)
```

## Browser Installation

**Important:** When the wizard asks about browser installation, answer **NO**. Use the separate `wheels playwright install` command instead, which handles browser compatibility better.

```bash
# After initialization completes
wheels playwright install
```

## Browser Compatibility

If you encounter browser installation errors (especially webkit on older macOS), the init command will automatically suggest running:

```bash
wheels playwright install
```

This command:
- Installs Chromium and Firefox by default
- Skips WebKit automatically on macOS 13 or earlier (WebKit requires macOS 14+)
- Provides better error handling than the wizard

### Browser Support Matrix

| Browser | macOS 13 | macOS 14+ | Linux | Windows |
|---------|----------|-----------|-------|---------|
| Chromium | Yes | Yes | Yes | Yes |
| Firefox | Yes | Yes | Yes | Yes |
| WebKit | No | Yes | No | No |

### Common Error

```
Error: ERROR: Playwright does not support webkit on mac13
```

This happens because webkit requires macOS 14+. Answer "n" to browser installation in the wizard, then use `wheels playwright install` which handles compatibility automatically.

## Installing Specific Browsers

If you need to install specific browsers:

```bash
# Install Chromium only
wheels playwright install --chromium --firefox=false --webkit=false

# Install Firefox only
wheels playwright install --chromium=false --firefox

# Force WebKit (only works on macOS 14+)
wheels playwright install --webkit
```

## Next Steps

After initialization:

1. **Install browsers:**
   ```bash
   wheels playwright install
   ```

2. **Run tests:**
   ```bash
   npx playwright test
   ```

3. **Open UI mode:**
   ```bash
   npx playwright test --ui
   ```

4. **Debug tests:**
   ```bash
   npx playwright test --debug
   ```

## Generated Files

The wizard creates:

- `playwright.config.{ts,js}` - Playwright configuration
- `tests/` or `e2e/` - Test directory (your choice during setup)
- `package.json` - Updated with Playwright dependencies
- `.github/workflows/playwright.yml` - GitHub Actions workflow (if enabled)

## Browser Cache Location

Browsers are cached at:

- **macOS:** `~/Library/Caches/ms-playwright/`
- **Linux:** `~/.cache/ms-playwright/`
- **Windows:** `%LOCALAPPDATA%\ms-playwright\Cache/`

## Verify Installation

Check installed browsers:

```bash
npx playwright show-browsers
```

Or run a quick test:

```bash
npx playwright test --list
```

## CI/CD Usage

```bash
# Install all available browsers
wheels playwright install

# Then run tests
npx playwright test
```

### GitHub Actions Example

```yaml
- name: Install Playwright
  run: |
    npm ci
    wheels playwright install

- name: Run E2E tests
  run: npx playwright test
```

## Additional Resources

- [Playwright Documentation](https://playwright.dev/docs/intro) - Official Playwright docs
- [Playwright CLI](https://playwright.dev/docs/cli) - Command-line reference
- [wheels test run](../test/test-run.md) - Run unit and integration tests