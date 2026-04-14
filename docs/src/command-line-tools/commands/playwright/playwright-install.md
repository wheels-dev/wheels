---
description: Install Playwright browsers after initialization or for specific browsers only.
---

# wheels playwright:install

Install Playwright browsers. Use this command after [`wheels playwright:init`](playwright-init.md) if browser installation failed, or to install specific browsers.

## Usage

```bash
wheels playwright:install [options]
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--chromium` | boolean | `true` | Install Chromium browser |
| `--firefox` | boolean | `true` | Install Firefox browser |
| `--webkit` | boolean | `false` | Install WebKit browser (macOS 14+ only) |

## Examples

### Install default browsers (Chromium + Firefox)

```bash
wheels playwright:install
```

### Install specific browsers

```bash
# Chromium only
wheels playwright:install --chromium=false --firefox=false

# Firefox only
wheels playwright:install --chromium=false

# Include WebKit (macOS 14+ only)
wheels playwright:install --webkit
```

## When to Use This Command

This command is useful when:

1. **Browser installation failed during init** - The init wizard may fail on webkit
2. **You need specific browsers only** - Save space by installing only what you need
3. **Reinstalling browsers** - After upgrading Playwright version

## Browser Compatibility

| Browser | macOS 13 | macOS 14+ | Linux | Windows |
|---------|----------|-----------|-------|---------|
| Chromium | Yes | Yes | Yes | Yes |
| Firefox | Yes | Yes | Yes | Yes |
| WebKit | No | Yes | No | No |

### WebKit on macOS 13

WebKit requires macOS 14 (Sonoma) or later. If you try:

```bash
wheels playwright:install --webkit
```

On macOS 13 or earlier, you'll see:

```
[WARNING] Webkit requires macOS 14+. Skipping webkit installation.
```

WebKit is skipped automatically, and Chromium and Firefox install normally.

## Error Handling

### WebKit Error

If you encounter:

```
Error: ERROR: Playwright does not support webkit on mac13
```

**Solution:** Don't use `--webkit` on macOS 13:

```bash
wheels playwright:install --webkit=false
```

### Installation Fails

If browser installation fails:

```bash
# Try installing specific browsers
wheels playwright:install --chromium --firefox

# Or install manually
npx playwright install chromium
```

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

```yaml
- name: Install Playwright
  run: |
    npm ci
    wheels playwright install

- name: Run E2E tests
  run: npx playwright test
```

## See Also

- [`wheels playwright:init`](playwright-init.md) - Initialize Playwright project
- [Playwright Installation](https://playwright.dev/docs/browsers) - Official browser installation docs