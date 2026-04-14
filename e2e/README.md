# Wheels Framework End-to-End Tests

Comprehensive Playwright tests for the Wheels CFML framework.

## Test Files

| File | Description |
|------|-------------|
| `example.spec.ts` | Basic smoke tests - quick verification that the app is running |
| `wheels-framework.spec.ts` | Complete tests for all Wheels framework endpoints |
| `mailer-jobs.spec.ts` | Tests for mailer and background job functionality |
| `configuration.spec.ts` | Tests for configuration, settings, and security |
| `api-endpoints.spec.ts` | API-focused tests with various response formats |

## Prerequisites

1. Ensure your Wheels application is running on `http://127.0.0.1:8082`
2. Install Playwright dependencies:

```bash
npm install
npx playwright install
```

## Running Tests

### Run all tests
```bash
npx playwright test
```

### Run specific test file
```bash
npx playwright test e2e/wheels-framework.spec.ts
```

### Run tests in a specific directory
```bash
npx playwright test e2e/api-endpoints.spec.ts
```

### Run with UI mode (interactive)
```bash
npx playwright test --ui
```

### Run with headed browser (visible)
```bash
npx playwright test --headed
```

### Run specific test by name
```bash
npx playwright test -g "System Information"
```

### Run tests in a specific project (browser)
```bash
npx playwright test --project=chromium
npx playwright test --project=firefox
```

### Run with codegen (record new tests)
```bash
npx playwright codegen http://127.0.0.1:8082
```

## Configuration

The base URL is configured in `playwright.config.ts`:

```typescript
use: {
  baseURL: 'http://127.0.0.1:8082',
  navigationTimeout: 30000,
  actionTimeout: 15000,
}
```

## Test Coverage

### System Pages
- `/wheels/info` - System information
- `/wheels/routes` - Route listing
- `/wheels/build` - Build information
- `/wheels/guides` - Documentation guides
- `/wheels/migrator` - Database migrator
- `/wheels/plugins` - Plugin management
- `/wheels/app/tests` - Test runner
- `/wheels/api` - API endpoint

### Features Tested
- Page loading and titles
- Response formats (HTML, JSON, TXT, XML)
- Wildcard routing
- CSRF protection
- Error handling
- Layout and view rendering
- Configuration settings
- Security headers

## CI/CD Integration

Add to your CI pipeline:

```yaml
- name: Install Playwright
  run: npx playwright install --with-deps

- name: Run E2E Tests
  run: npx playwright test
```

## Troubleshooting

### Tests timeout
Increase timeout in `playwright.config.ts`:
```typescript
timeout: 60000,  // Global timeout
expect: { timeout: 30000 }  // Expect timeout
```

### Server not responding
Ensure your Wheels server is running:
```bash
# Check if server is running
curl http://127.0.0.1:8082/wheels/info
```

### Cross-origin issues
All tests run against the same base URL, so CORS should not be an issue.

## Reports

After running tests, generate an HTML report:

```bash
npx playwright show-report
```

Reports are saved to `playwright-report/` by default.

## Adding New Tests

1. Create a new `.spec.ts` file in `e2e/`
2. Use the `test.describe()` pattern for grouping related tests
3. Use `test.beforeEach()` for common setup
4. Run tests with `npx playwright test`

Example:
```typescript
import { test, expect } from '@playwright/test';

test.describe('My Feature', () => {
  test('should do something', async ({ page }) => {
    await page.goto('/my-page');
    await expect(page).toHaveTitle(/My Page/);
  });
});
```
