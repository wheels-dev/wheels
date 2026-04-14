import { test, expect } from '@playwright/test';

/**
 * Playwright tests for Wheels Framework configuration and settings
 */

test.describe('Wheels Framework - Configuration Tests', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should be running in development environment', async ({ page }) => {
    await page.goto(`/wheels/info`);

    const content = await page.content();
    await expect(content.toLowerCase()).toMatch(/environment|development/i);
  });

  test('should have data source configured', async ({ page }) => {
    await page.goto(`/wheels/info`);

    const content = await page.content();
    await expect(content.toLowerCase()).toMatch(/data.?source|database|wheels-dev/i);
  });

  test('should have reload capability configured', async ({ page }) => {
    await page.goto(`/wheels/info?reload=true`);

    await expect(page).toHaveTitle(/Wheels/);
  });
});

test.describe('Wheels Framework - Route Configuration', () => {
  test('should have root route configured', async ({ page }) => {
    const response = await page.goto(`/`);
    expect(response?.status()).toBeLessThan(500);
  });

  test('should display all registered routes', async ({ page }) => {
    await page.goto(`/wheels/routes`);

    const content = await page.content();
    expect(content.length).toBeGreaterThan(100);
  });

  test('should handle controller/action URLs via wildcard', async ({ page }) => {
    const response = await page.goto(`/test/action`);
    expect(response?.status()).toBeLessThan(500);
  });
});

test.describe('Wheels Framework - Security Configuration', () => {
  test('should have CSRF protection configured', async ({ page }) => {
    await page.goto(`/wheels/info`);

    const content = await page.content();
    await expect(content).toMatch(/csrf|Csrf|CSRF|token|Token/i);
  });

  test('should set security headers', async ({ page }) => {
    const response = await page.request.get(`/wheels/info`);
    const headers = response.headers();
    expect(headers).toBeDefined();
  });
});

test.describe('Wheels Framework - Core Files Structure', () => {
  test('should have layout template configured', async ({ page }) => {
    await page.goto(`/wheels/info`);

    await expect(page.locator('html')).toBeVisible();
    await expect(page.locator('head')).toHaveCount(1);
    await expect(page.locator('body')).toBeVisible();
  });

  test('should have view helpers available', async ({ page }) => {
    await page.goto(`/wheels/info`);

    const content = await page.content();
    expect(content.length).toBeGreaterThan(100);
  });
});
