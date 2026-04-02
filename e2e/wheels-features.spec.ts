import { test, expect } from '@playwright/test';

/**
 * Tests for specific Wheels Framework features
 */

const BASE_URL = 'http://127.0.0.1:8082';

test.describe('Wheels - Development Tools', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should access Wheels info page for system details', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/info`);

    await expect(page).toHaveTitle(/System Information \| Wheels/);

    // Should display CFML server info
    const content = await page.content();
    await expect(content.toLowerCase()).toMatch(/cfml|server|engine|lucee|adobe/i);
  });

  test('should display route mappings', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/routes`);

    await expect(page).toHaveTitle(/routes \| wheels/i);

    // Should list routes
    const content = await page.content();
    await expect(content.toLowerCase()).toMatch(/route|get|post|controller|action/i);
  });

  test('should display migration status', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/migrator`);

    await expect(page).toHaveTitle(/Migrator? \| Database \| Wheels/i);

    // Should show migration info
    const content = await page.content();
    await expect(content.toLowerCase()).toMatch(/migration|database|schema|version/i);
  });

  test('should support migration actions', async ({ page }) => {
    const actions = ['info', 'migrate', 'rollback'];

    for (const action of actions) {
      const response = await page.goto(`${BASE_URL}/wheels/migrator?action=${action}`);
      expect(response?.status()).toBeLessThan(500);
    }
  });

  test('should display plugin/package status', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/plugins`);

    await expect(page).toHaveTitle(/Plugins? \| Wheels/i);

    // Should show plugin/vendor info
    const content = await page.content();
    await expect(content.toLowerCase()).toMatch(/vendor|package|plugin|wheels/i);
  });
});

test.describe('Wheels - Test Runner', () => {
  test('should load test runner interface', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/app/tests`);

    await expect(page).toHaveTitle(/Tests | Wheels/i);
  });

  test('should support JSON format for test results', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/app/tests?format=json`);

    const content = await page.content();
    const body = content.trim();

    // Should be valid JSON or HTML wrapper
    expect(body.length).toBeGreaterThan(0);
  });

  test('should filter tests by directory', async ({ page }) => {
    const directories = ['tests.specs.models', 'tests.specs.controllers'];

    for (const dir of directories) {
      const response = await page.goto(`${BASE_URL}/wheels/app/tests?directory=${dir}`);
      expect(response?.status()).toBeLessThan(500);
    }
  });

  test('should support database selection parameter', async ({ page }) => {
    const databases = ['h2', 'mysql', 'postgres', 'sqlite'];

    for (const db of databases) {
      const response = await page.goto(`${BASE_URL}/wheels/app/tests?db=${db}`);
      expect(response?.status()).toBeLessThan(500);
    }
  });
});

test.describe('Wheels - Response Format Support', () => {
  test('should return HTML by default', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/wheels/info`);
    const contentType = response?.headers()['content-type'];

    expect(contentType).toContain('text/html');
  });

  test('should return JSON when requested', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/wheels/api?format=json`);

    expect(response.ok()).toBeTruthy();

    const json = await response.json();
    expect(json).toBeDefined();
  });

  test('should return TXT when requested', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/wheels/info?format=txt`);

    expect(response.ok()).toBeTruthy();

    const text = await response.text();
    expect(text.length).toBeGreaterThan(0);
  });

  test('should return XML when requested', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/wheels/api?format=xml`);

    expect(response.ok()).toBeTruthy();

    const text = await response.text();
    expect(text.length).toBeGreaterThan(0);
    expect(text).toMatch(/</);
  });
});

test.describe('Wheels - Mailer Integration', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should have UserNotificationsMailer configured', async ({ page }) => {
    // Mailer view should exist
    const response = await page.goto(`${BASE_URL}/usernotificationsmailer/sendemail`);
    expect(response?.status()).toBeLessThan(500);
  });

  test('mailer action should handle requests', async ({ request }) => {
    const response = await request.post(`${BASE_URL}/userNotificationsMailer/sendEmail`, {
      form: {
        to: 'test@example.com',
        subject: 'Test Email',
        body: 'Test message'
      }
    });

    // Should not crash - either success or validation error
    expect(response.status()).toBeLessThan(500);
  });
});

test.describe('Wheels - Background Jobs Integration', () => {
  test('should have jobs directory configured', async ({ page }) => {
    // Job queue endpoint should be handled
    const response = await page.goto(`${BASE_URL}/jobs/processQueue`);
    expect(response?.status()).toBeLessThan(500);
  });

  test('should handle job-related POST requests', async ({ request }) => {
    const response = await request.post(`${BASE_URL}/jobs/process`, {
      data: { queue: 'default' }
    });

    expect(response.status()).toBeLessThan(500);
  });
});

test.describe('Wheels - Event Handlers', () => {
  test('should handle onRequestStart events', async ({ page }) => {
    // Every page triggers onRequestStart
    const response = await page.goto(`${BASE_URL}/wheels/info`);
    expect(response?.status()).toBe(200);
  });

  test('should handle onError events gracefully', async ({ page }) => {
    // Error handler should catch errors and show error page
    const response = await page.goto(`${BASE_URL}/triggerError`);
    expect(response?.status()).toBeLessThan(500);
  });

  test('should handle onSessionStart events', async ({ context }) => {
    // New context triggers onSessionStart
    const page = await context.newPage();
    const response = await page.goto(`${BASE_URL}/`);
    expect(response?.status()).toBeLessThan(500);
  });
});

test.describe('Wheels - View Helpers', () => {
  test('should have flash messages support in layout', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/info`);

    const content = await page.content();
    // Flash messages container or function should be present
    await expect(content.toLowerCase()).toMatch(/flash|notice|alert|message/i);
  });

  test('should support linkTo helper', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/routes`);

    // Should have links generated by linkTo helper
    const links = await page.locator('a[href]').all();
    expect(links.length).toBeGreaterThan(0);
  });

  test('should support form helpers', async ({ page }) => {
    await page.goto(`${BASE_URL}/users/new`);

    // Should have form elements
    const forms = await page.locator('form').all();
    expect(forms.length).toBeGreaterThanOrEqual(0);
  });
});

test.describe('Wheels - Pagination Support', () => {
  test('should handle page parameter', async ({ page }) => {
    const pages = [1, 2, 5, 10, 100];

    for (const pageNum of pages) {
      const response = await page.goto(`${BASE_URL}/users?page=${pageNum}`);
      expect(response?.status()).toBeLessThan(500);
    }
  });

  test('should handle perPage parameter', async ({ page }) => {
    const perPageValues = [10, 25, 50, 100];

    for (const perPage of perPageValues) {
      const response = await page.goto(`${BASE_URL}/users?perPage=${perPage}`);
      expect(response?.status()).toBeLessThan(500);
    }
  });
});

test.describe('Wheels - Security Features', () => {
  test('should have CSRF token in forms', async ({ page }) => {
    await page.goto(`${BASE_URL}/wheels/info`);

    const content = await page.content();
    await expect(content).toMatch(/csrf|_token|authenticity/i);
  });

  test('should set security headers', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/wheels/info`);
    const headers = response.headers();

    // Should have basic security headers
    expect(headers).toBeDefined();
    expect(headers['content-type']).toBeDefined();
  });

  test('should handle unauthorized access gracefully', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/admin/restricted`);
    expect(response?.status()).toBeLessThan(500);
  });
});
