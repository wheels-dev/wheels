import { test, expect } from '@playwright/test';

/**
 * Playwright API tests for Wheels Framework endpoints
 * Tests various response formats and API functionality
 */

const BASE_URL = 'http://127.0.0.1:8082';

test.describe('Wheels Framework - API Response Formats', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should return HTML by default', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/wheels/info`);

    expect(response?.ok()).toBeTruthy();

    const contentType = response?.headers()['content-type'];
    expect(contentType).toContain('text/html');
  });

  test('should return JSON when format=json', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/wheels/api?format=json`);

    expect(response?.ok()).toBeTruthy();

    const data = await response!.json();
    expect(data).toBeTruthy();
  });

  test('should return TXT when format=txt', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/wheels/info?format=txt`);

    expect(response?.ok()).toBeTruthy();

    const contentType = response?.headers()['content-type'];
    expect(contentType).toMatch(/text\/plain|text\/html/);
  });
});

test.describe('Wheels Framework - Core API Endpoints', () => {
  const endpoints = [
    { path: '/wheels/info', title: /System Information \| Wheels/, description: 'System information' },
    { path: '/wheels/routes', title: /Routes?/i, description: 'Route listing' },
    { path: '/wheels/guides', title: /Guides?/i, description: 'Documentation guides' },
    { path: '/wheels/migrator', title: /Migrator/i, description: 'Database migrator' },
    { path: '/wheels/plugins', title: /Plugins?/i, description: 'Plugin management' },
    { path: '/wheels/app/tests', description: 'Test runner' },
    { path: '/wheels/api', description: 'API endpoint' },
  ];

  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  for (const endpoint of endpoints) {
    test(`GET ${endpoint.path} - ${endpoint.description}`, async ({ page }) => {
      const response = await page.goto(`${BASE_URL}${endpoint.path}`);

      expect(response?.status()).toBe(200);

      if (endpoint.title) {
        await expect(page).toHaveTitle(endpoint.title);
      }
    });
  }
});

test.describe('Wheels Framework - Query Parameters', () => {
  test('should handle format parameter on info endpoint', async ({ page }) => {
    const formats = ['json', 'txt', 'xml'];

    for (const format of formats) {
      const response = await page.goto(`${BASE_URL}/wheels/info?format=${format}`);
      expect(response?.status()).toBeLessThan(500);
    }
  });

  test('should handle directory parameter on test runner', async ({ page }) => {
    const directories = [
      'tests.specs.models',
      'tests.specs.controllers',
      'tests.specs.functional'
    ];

    for (const dir of directories) {
      const response = await page.goto(`${BASE_URL}/wheels/app/tests?directory=${dir}`);
      expect(response?.status()).toBeLessThan(500);
    }
  });
});

test.describe('Wheels Framework - HTTP Methods', () => {
  test('should respond to GET requests', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/wheels/info`);
    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);
  });

  test('should handle POST to wildcard routes', async ({ request }) => {
    const response = await request.post(`${BASE_URL}/test/action`);
    expect(response.status()).toBeLessThan(500);
  });

  test('should handle PUT requests', async ({ request }) => {
    const response = await request.put(`${BASE_URL}/test/action`);
    expect(response.status()).toBeLessThan(500);
  });

  test('should handle DELETE requests', async ({ request }) => {
    const response = await request.delete(`${BASE_URL}/test/action`);
    expect(response.status()).toBeLessThan(500);
  });
});

test.describe('Wheels Framework - Error Handling', () => {
  test('should handle missing controllers gracefully', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/nonexistentController/action`);
    expect(response?.status()).toBeGreaterThanOrEqual(200);
    expect(response?.status()).toBeLessThan(500);
  });

  test('should handle deeply nested URLs', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/a/b/c/d/e/f`);
    expect(response?.status()).toBeLessThan(500);
  });
});

test.describe('Wheels Framework - Response Headers', () => {
  test('should set Content-Type header', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/wheels/info`);
    const headers = response.headers();

    expect(headers['content-type']).toBeDefined();
    expect(headers['content-type']).toContain('text/html');
  });
});
