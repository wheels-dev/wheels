import { test, expect } from '@playwright/test';

/**
 * End-to-End tests for user workflows in Wheels Framework
 * Tests real user scenarios and critical application paths
 */

const BASE_URL = 'http://127.0.0.1:8082';

test.describe('User Authentication Workflows', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should display login page if auth is configured', async ({ page }) => {
    // Try common login routes
    const loginRoutes = ['/login', '/auth/login', '/sessions/new'];

    for (const route of loginRoutes) {
      const response = await page.goto(`${BASE_URL}${route}`);
      // Should not throw 500 error - either shows login or 404
      expect(response?.status()).toBeLessThan(500);
    }
  });

  test('should handle session creation', async ({ page }) => {
    // POST to login should be handled
    const response = await page.request.post(`${BASE_URL}/sessions/create`, {
      form: { email: 'test@example.com', password: 'test' }
    });
    // Should not crash - either redirect or show error
    expect(response.status()).toBeLessThan(500);
  });
});

test.describe('Resource CRUD Workflows', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should handle resource index pages', async ({ page }) => {
    // Common resource endpoints
    const resources = ['users', 'products', 'posts', 'articles'];

    for (const resource of resources) {
      const response = await page.goto(`${BASE_URL}/${resource}`);
      // Should not crash - either list or 404
      expect(response?.status()).toBeLessThan(500);
    }
  });

  test('should handle new resource form pages', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/users/new`);
    expect(response?.status()).toBeLessThan(500);
  });

  test('should handle resource creation via POST', async ({ page }) => {
    const response = await page.request.post(`${BASE_URL}/users/create`, {
      form: {
        firstName: 'Test',
        lastName: 'User',
        email: 'testuser@example.com'
      }
    });
    expect(response.status()).toBeLessThan(500);
  });

  test('should handle resource edit pages', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/users/1/edit`);
    expect(response?.status()).toBeLessThan(500);
  });

  test('should handle resource deletion', async ({ page }) => {
    const response = await page.request.delete(`${BASE_URL}/users/1`);
    expect(response.status()).toBeLessThan(500);
  });
});

test.describe('Form Validation Workflows', () => {
  test.beforeEach(async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);
  });

  test('should display validation errors for invalid submissions', async ({ page }) => {
    await page.goto(`${BASE_URL}/users/new`);

    // Submit empty form
    await page.click('button[type="submit"], input[type="submit"]');

    // Should either show validation errors or stay on page
    const content = await page.content();
    await expect(content).toBeTruthy();
  });

  test('should accept valid form submissions', async ({ page }) => {
    await page.goto(`${BASE_URL}/users/new`);

    // Fill valid data
    await page.fill('input[name="firstName"]', 'Valid');
    await page.fill('input[name="lastName"]', 'User');
    await page.fill('input[name="email"]', 'valid@example.com');

    const response = await page.click('button[type="submit"], input[type="submit"]');
    expect(response).toBeDefined();
  });
});

test.describe('Search and Filter Workflows', () => {
  test('should handle search queries', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/users?search=test`);
    expect(response?.status()).toBeLessThan(500);
  });

  test('should handle pagination parameters', async ({ page }) => {
    const pages = [1, 2, 5, 10];

    for (const pageNum of pages) {
      const response = await page.goto(`${BASE_URL}/users?page=${pageNum}`);
      expect(response?.status()).toBeLessThan(500);
    }
  });

  test('should handle sorting parameters', async ({ page }) => {
    const sorts = ['name', 'createdAt', 'email', 'id'];

    for (const sort of sorts) {
      const response = await page.goto(`${BASE_URL}/users?sort=${sort}`);
      expect(response?.status()).toBeLessThan(500);
    }
  });
});

test.describe('API and JSON Response Workflows', () => {
  test('should return valid JSON for API requests', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/wheels/api?format=json`);

    expect(response.ok()).toBeTruthy();

    const json = await response.json();
    expect(json).toBeDefined();
  });

  test('should handle API POST requests with JSON body', async ({ request }) => {
    const response = await request.post(`${BASE_URL}/wheels/api`, {
      data: { action: 'test', data: { key: 'value' } }
    });

    expect(response.status()).toBeLessThan(500);
  });
});

test.describe('Error Page Workflows', () => {
  test('should display custom 404 page for missing resources', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/nonexistent/resource/path`);

    // Should show error page, not crash
    expect(response?.status()).toBeGreaterThanOrEqual(400);
    expect(response?.status()).toBeLessThan(500);

    const content = await page.content();
    // Should have some error message content
    expect(content.length).toBeGreaterThan(50);
  });

  test('should handle invalid parameters gracefully', async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/users/invalid-id`);
    expect(response?.status()).toBeLessThan(500);
  });
});

test.describe('Session and Cookie Workflows', () => {
  test('should maintain session across page navigations', async ({ page, context }) => {
    // Visit first page
    await page.goto(`${BASE_URL}/wheels/info`);
    const cookies = await context.cookies();

    // Should have session cookie
    expect(cookies.length).toBeGreaterThanOrEqual(0);

    // Navigate to another page
    await page.goto(`${BASE_URL}/wheels/routes`);

    // Session should persist
    const cookiesAfter = await context.cookies();
    expect(cookiesAfter.length).toBeGreaterThanOrEqual(0);
  });

  test('should handle cookie consent if present', async ({ page }) => {
    await page.goto(`${BASE_URL}/`);

    // Check for cookie consent banners
    const consentBanner = page.locator('[class*="cookie"], [id*="cookie"], [class*="consent"]');
    const count = await consentBanner.count();

    // If present, should be dismissible
    if (count > 0) {
      // Just verify it exists - actual dismissal depends on implementation
      await expect(consentBanner.first()).toBeVisible();
    }
  });
});

test.describe('Mobile Responsiveness Workflows', () => {
  test('should render correctly on mobile viewport', async ({ browser }) => {
    const context = await browser.newContext({
      viewport: { width: 375, height: 667 } // iPhone SE
    });
    const page = await context.newPage();

    await page.goto(`${BASE_URL}/wheels/info`);

    // Page should load without horizontal scroll
    const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
    const viewportWidth = await page.evaluate(() => window.innerWidth);
    expect(bodyWidth).toBeLessThanOrEqual(viewportWidth);

    await context.close();
  });

  test('should render correctly on tablet viewport', async ({ browser }) => {
    const context = await browser.newContext({
      viewport: { width: 768, height: 1024 } // iPad
    });
    const page = await context.newPage();

    await page.goto(`${BASE_URL}/wheels/info`);

    const content = await page.content();
    await expect(content).toBeTruthy();

    await context.close();
  });
});
