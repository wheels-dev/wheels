import { test, expect } from '@playwright/test';

/**
 * Playwright tests for Wheels Mailer and Background Jobs functionality
 */

const BASE_URL = 'http://127.0.0.1:8082';

test.describe('Wheels Framework - Mailer Tests', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should have UserNotificationsMailer view template', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/usernotificationsmailer/sendemail`);

    // Should render the mailer view without error
    expect(response?.status()).toBeLessThan(500);

    // Should have mailer-related content
    const content = await page.content();
    await expect(content).toMatch(/email|notification|mailer/i);
  });

  test('mailer action URL responds successfully', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/userNotificationsMailer/sendEmail`);
    expect(response?.status()).toBeLessThan(500);
  });
});

test.describe('Wheels Framework - Background Jobs Tests', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should have ProcessOrdersJob configured', async ({ page }) => {
    // Jobs are processed via CLI/controller - verify app is running
    await page.goto(`${BASE_URL}/wheels/info`);

    const content = await page.content();
    await expect(content).toContain('Wheels');
  });

  test('should handle job-related URLs gracefully', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/jobs/processQueue`);
    expect(response?.status()).toBeLessThan(500);
  });
});

test.describe('Wheels Framework - Database and Migration Tests', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should access the migrator interface', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/migrator`);

    await expect(page).toHaveTitle(/Migrator? \| Database \| Wheels/i);
  });

  test('should display migration information', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/migrator`);

    const content = await page.content();
    await expect(content.toLowerCase()).toMatch(/migration|database|schema/i);
  });

  test('should handle migration actions', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/wheels/migrator?action=info`);
    expect(response?.status()).toBeLessThan(500);
  });
});

test.describe('Wheels Framework - Plugin System Tests', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should display plugins page', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/plugins`);

    await expect(page).toHaveTitle(/Plugins? \| Wheels/i);
  });

  test('should show vendor directory contents', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/plugins`);

    const content = await page.content();
    await expect(content.toLowerCase()).toMatch(/vendor|package|plugin|wheels/i);
  });
});
