import { test, expect } from '@playwright/test';

/**
 * Core Playwright tests for Wheels Framework functionality
 */

const BASE_URL = 'http://127.0.0.1:8082';

test.describe('Wheels Framework - System Pages', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should load system information page', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/info`);

    await expect(page).toHaveTitle(/System Information \| Wheels/);
    await expect(page.locator('h1, h2, h3').first()).toBeVisible();
  });

  test('should display Wheels version information', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/info`);

    const content = await page.content();
    await expect(content).toContain('Wheels');
  });

  test('should load routes listing page', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/routes`);

    await expect(page).toHaveTitle(/routes \| wheels/i);

    const content = await page.content();
    await expect(content.toLowerCase()).toMatch(/route|controller|action/i);
  });

  test('should load database migrator page', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/migrator`);

    await expect(page).toHaveTitle(/Migrator \| Wheels/i);

    const content = await page.content();
    await expect(content.toLowerCase()).toMatch(/migration|database|migrator/i);
  });

  test('should load plugins management page', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/plugins`);

    await expect(page).toHaveTitle(/Plugins? \| Wheels/i);

    const content = await page.content();
    await expect(content.toLowerCase()).toMatch(/plugin|package|vendor/i);
  });

  test('should load test runner page', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/app/tests`);

    await expect(page).toHaveTitle(/Tests | Wheels/i);
  });

  test('should support JSON format for test results', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/app/tests?format=json`);

    const content = await page.content();
    const body = content.trim();

    expect(body.startsWith('{') || body.startsWith('<')).toBeTruthy();
  });
});

test.describe('Wheels Framework - Root and Wildcard Routes', () => {
  test('should handle root URL route', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/`);
    expect(response?.status()).toBeLessThan(500);
  });

  test('should handle unknown routes via wildcard', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/some/unknown/path`);
    expect(response?.status()).toBeLessThan(500);
  });

  test('should handle controller/action style URLs', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/home/index`);
    expect(response?.status()).toBeLessThan(500);
  });
});

test.describe('Wheels Framework - Layout and Views', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should use the default layout', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/info`);

    await expect(page.locator('html')).toBeVisible();
    await expect(page.locator('head')).toHaveCount(1);
    await expect(page.locator('body')).toBeVisible();
  });

  test('should include content within layout', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/info`);

    const bodyContent = await page.locator('body').textContent();
    expect(bodyContent?.trim().length).toBeGreaterThan(100);
  });

  test('should have CSRF meta tags or security configuration', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/info`);

    const content = await page.content();
    await expect(content).toMatch(/csrf|Csrf|CSRF|token|Token/i);
  });
});

test.describe('Wheels Framework - Concurrent Requests', () => {
  test('should handle multiple simultaneous requests', async ({ browser }) => {
    const urls = [
      `${BASE_URL}/wheels/info`,
      `${BASE_URL}/wheels/routes`,
      `${BASE_URL}/wheels/build`,
      `${BASE_URL}/wheels/guides`
    ];

    const context = await browser.newContext();
    const pages = await Promise.all(urls.map(() => context.newPage()));

    const results = await Promise.all(
      pages.map((page, i) => page.goto(urls[i]).then(r => r?.status()))
    );

    results.forEach(status => {
      expect(status).toBe(200);
    });

    await context.close();
  });
});
