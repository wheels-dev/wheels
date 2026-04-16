---
description: A comprehensive guide to end-to-end testing your Wheels application using Playwright...
---

# End-to-End Testing with Playwright

This guide covers how to install, configure, and run Playwright end-to-end (E2E) tests for your Wheels application. Playwright enables you to test your application from a user's perspective, simulating real browser interactions across multiple browsers.

{% hint style="info" %}
This guide covers the **Node.js/TypeScript Playwright** approach. For native CFML browser testing that runs inside TestBox, see [Browser Testing](browser-testing.md).
{% endhint %}

## Overview

Playwright is a modern end-to-end testing framework that allows you to:

- Test your application in real browsers (Chromium, Firefox, WebKit)
- Simulate user interactions (clicks, form submissions, navigation)
- Verify page content, titles, and response statuses
- Run tests in headed (visible) or headless mode
- Generate visual test reports
- Record tests with codegen for quick test creation

## Prerequisites

Before running E2E tests, ensure you have:

1. **Node.js 18+** installed
2. **npm** or **pnpm** package manager
3. **A running Wheels application** on `http://127.0.0.1:<port>` (default: 8080)

## Installation

### 1. Install Playwright

```bash
npm install
```

This installs Playwright and its dependencies. The `package.json` should already include the necessary dev dependencies.

### 2. Install Browser Binaries

```bash
npx playwright install
```

This downloads the browser binaries for Chromium and Firefox. You can also install specific browsers:

```bash
npx playwright install chromium
npx playwright install firefox
npx playwright install webkit
```

For CI environments, install with system dependencies:

```bash
npx playwright install --with-deps
```

## Configuration

The Playwright configuration is located in `playwright.config.ts` at the project root. Key settings include:

```typescript
export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: baseURL,
    trace: 'on-first-retry',
    navigationTimeout: 30000,
    actionTimeout: 15000,
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
  ],
});
```

### Base URL Configuration

The base URL is determined in this order:

1. `BASE_URL` environment variable (if set)
2. Port from `server.json`
3. Fallback to `http://127.0.0.1:8080`

Set a custom base URL:

```bash
BASE_URL=http://localhost:3000 npx playwright test
```

### Timeout Settings

For CFML applications, increased timeouts are recommended:

```typescript
use: {
  navigationTimeout: 30000,  // 30 seconds for page loads
  actionTimeout: 15000,      // 15 seconds for actions
},
```

## Project Structure

Your E2E test files should be located in the `e2e/` directory:

```
your-app/
├── e2e/
│   ├── api-endpoints.spec.ts
│   ├── configuration.spec.ts
│   ├── integration.spec.ts
│   ├── user-workflows.spec.ts
│   ├── wheels-features.spec.ts
│   └── wheels-framework.spec.ts
├── playwright.config.ts
└── package.json
```

## Writing Tests

### Basic Test Structure

Create test files with the `.spec.ts` extension:

```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature Name', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should load the page successfully', async ({ page }) => {
    const response = await page.goto('/');
    expect(response?.status()).toBeLessThan(500);
  });

  test('should display expected content', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/Your Title/);
  });
});
```

### Testing Page Load

Test that pages load without errors:

```typescript
test('should load the home page', async ({ page }) => {
  const response = await page.goto('/');
  await expect(page).toHaveURL('/');
  await expect(page).toHaveTitle(/Home/);
});
```

### Testing Forms

Test form functionality:

```typescript
test('should handle form submission', async ({ page }) => {
  await page.goto('/users/new');
  
  await page.fill('input[name="firstName"]', 'John');
  await page.fill('input[name="lastName"]', 'Doe');
  await page.fill('input[name="email"]', 'john@example.com');
  
  await page.click('button[type="submit"]');
  
  // Verify redirect or success message
  await expect(page).toHaveURL(/\/users/);
});
```

### Testing API Endpoints

Test JSON API responses:

```typescript
test('should return JSON for API endpoint', async ({ request }) => {
  const response = await request.get('/api/users');
  expect(response.status()).toBe(200);
  
  const body = await response.json();
  expect(body).toHaveProperty('data');
  expect(Array.isArray(body.data)).toBe(true);
});
```

### Testing Response Formats

Wheels supports multiple response formats:

```typescript
test('should return JSON response', async ({ request }) => {
  const response = await request.get('/wheels/info', {
    headers: { 'Accept': 'application/json' }
  });
  expect(response.headers()['content-type']).toContain('application/json');
});

test('should return XML response', async ({ request }) => {
  const response = await request.get('/wheels/info', {
    headers: { 'Accept': 'application/xml' }
  });
  const body = await response.text();
  expect(body).toMatch(/<\?xml/);
});
```

### Testing Error Handling

Test that errors are handled gracefully:

```typescript
test('should return 404 for missing resource', async ({ page }) => {
  const response = await page.goto('/non-existent-page');
  expect(response?.status()).toBe(404);
});

test('should not crash on invalid route', async ({ page }) => {
  const response = await page.goto('/invalid/route/path');
  expect(response?.status()).toBeLessThan(500);
});
```

### Testing CSRF Protection

Test CSRF token handling:

```typescript
test('should include CSRF token in forms', async ({ page }) => {
  await page.goto('/form-page');
  const csrfInput = page.locator('input[name="csrf_token"]');
  await expect(csrfInput).toBeVisible();
  
  const token = await csrfInput.inputValue();
  expect(token.length).toBeGreaterThan(0);
});

test('should reject form without CSRF token', async ({ request }) => {
  const response = await request.post('/form-handler', {
    form: { name: 'Test' }
    // No CSRF token
  });
  expect(response.status()).toBe(400);
});
```

## Running Tests

### Run All Tests

```bash
npx playwright test
```

### Run Specific Test File

```bash
npx playwright test e2e/api-endpoints.spec.ts
```

### Run Tests by Pattern

```bash
npx playwright test -g "should return JSON"
```

### Run in Specific Browser

```bash
npx playwright test --project=chromium
npx playwright test --project=firefox
```

### Run with UI Mode

Interactive mode with visual test runner:

```bash
npx playwright test --ui
```

### Run with Visible Browser

```bash
npx playwright test --headed
```

### Run Tests in Parallel

```bash
npx playwright test --workers=4
```

### Generate Test with Codegen

Record interactions to create new tests:

```bash
npx playwright codegen http://127.0.0.1:8080
```

## Test Coverage Areas

Your E2E tests should cover:

### Core Framework Features

- `/wheels/info` - System information
- `/wheels/routes` - Route listing
- `/wheels/build` - Build information
- `/wheels/guides` - Documentation guides
- `/wheels/migrator` - Database migrator
- `/wheels/plugins` - Plugin management
- `/wheels/app/tests` - Test runner
- `/wheels/api` - API endpoint

### User Workflows

- Authentication flows (login, logout, registration)
- Resource CRUD operations
- Form validation
- Error handling and edge cases

### Application Features

- Page loading and titles
- Response formats (HTML, JSON, TXT, XML)
- Wildcard routing
- CSRF protection
- Layout and view rendering
- Configuration settings
- Security headers

## Reports

### View HTML Report

After running tests, generate and view the HTML report:

```bash
npx playwright show-report
```

Reports are saved to `playwright-report/` by default.

### Generate JSON Report

For CI/CD integration:

```bash
npx playwright test --reporter=json > test-results.json
```

## CI/CD Integration

### GitHub Actions

```yaml
name: E2E Tests
on: [push, pull_request]
jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Install Playwright browsers
        run: npx playwright install --with-deps
      
      - name: Start Wheels server
        run: npm run start &
      
      - name: Wait for server
        run: npx wait-on http://127.0.0.1:8080 --timeout 60000
      
      - name: Run E2E tests
        run: npx playwright test
      
      - name: Upload report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-report
          path: playwright-report/
```

### GitLab CI

```yaml
e2e-tests:
  image: mcr.microsoft.com/playwright:v1.40.0
  services:
    - docker:dind
  script:
    - npm ci
    - npx playwright install --with-deps
    - npm run start &
    - npx wait-on http://127.0.0.1:8080 --timeout 60000
    - npx playwright test
  artifacts:
    when: always
    paths:
      - playwright-report/
```

## Troubleshooting

### Tests Timeout

Increase timeout in `playwright.config.ts`:

```typescript
use: {
  navigationTimeout: 60000,
  actionTimeout: 30000,
},
```

### Server Not Responding

Ensure your Wheels server is running:

```bash
# Check if server is running
curl http://127.0.0.1:8080/wheels/info

# Or set a different port
BASE_URL=http://localhost:9000 npx playwright test
```

### Cross-Origin Issues

All tests run against the same base URL, so CORS should not be an issue by default.

### Browser Crashes

If browsers crash during tests:

```bash
# Install system dependencies
npx playwright install --with-deps

# Or install specific dependencies
npx playwright install-deps
```

### Connection Refused

Verify the server is listening on the correct interface:

```bash
# Check server configuration
# The server should bind to 127.0.0.1, not just localhost
```

## Best Practices

1. **Use descriptive test names**: Test names should clearly describe what they verify
2. **Keep tests independent**: Each test should be able to run in isolation
3. **Use `beforeEach` for common setup**: Set up page timeouts and common configurations
4. **Verify the minimum necessary**: Test the expected outcome, not implementation details
5. **Handle async properly**: Use `await` for all async operations
6. **Clean up test data**: Tests should not leave permanent data in the database
7. **Use appropriate assertions**: Use specific assertions like `toHaveTitle()`, `toBeVisible()` over generic ones
8. **Run tests regularly**: Integrate E2E tests into your development workflow

## Related Documentation

- [Testing Your Application](testing-your-application.md) - Unit and integration testing with TestBox
- [Using the Test Environment](using-the-test-environment.md) - Docker-based test environment for framework testing
- [Request Handling](handling-requests-with-controllers/request-handling.md) - Understanding Wheels request lifecycle
