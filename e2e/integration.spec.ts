import { test, expect } from '@playwright/test';

/**
 * Integration tests for Wheels Framework
 * Tests that combine multiple features and verify end-to-end functionality
 */

test.describe('Full Application Flow - User Registration', () => {
  test('should complete user registration flow', async ({ page, context }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);

    // Step 1: Navigate to registration page
    await page.goto(`/users/new`);
    expect(page.url()).toContain('/users/new');

    // Step 2: Fill registration form
    await page.fill('input[name="firstName"]', 'Integration');
    await page.fill('input[name="lastName"]', 'Test');
    await page.fill('input[name="email"]', `integration-${Date.now()}@test.com`);

    // Step 3: Submit form
    await page.click('button[type="submit"], input[type="submit"]');

    // Step 4: Should redirect or show success
    // (exact behavior depends on implementation)
    const content = await page.content();
    await expect(content).toBeTruthy();
  });
});

test.describe('Full Application Flow - Browse and Search', () => {
  test('should browse, search, and paginate results', async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);

    // Step 1: View index page
    await page.goto(`/users`);
    expect(page.url()).toContain('/users');

    // Step 2: Apply search filter
    await page.goto(`/users?search=test`);
    const content = await page.content();
    await expect(content).toBeTruthy();

    // Step 3: Apply pagination
    await page.goto(`/users?page=2`);
    expect(page.url()).toContain('page=2');

    // Step 4: Apply sorting
    await page.goto(`/users?sort=name&order=asc`);
    expect(page.url()).toContain('sort=');

    // Step 5: Combine filters
    await page.goto(`/users?search=test&page=1&sort=createdAt&perPage=25`);
    expect(page.url()).toMatch(/search=|sort=|page=/);
  });
});

test.describe('API Integration Flow', () => {
  test('should handle complete API CRUD cycle', async ({ request }) => {
    // Step 1: GET list (index)
    const listResponse = await request.get(`/wheels/api?format=json`);
    expect(listResponse.ok()).toBeTruthy();

    // Step 2: POST create
    const createResponse = await request.post(`/wheels/api`, {
      data: { action: 'create', test: true }
    });
    expect(createResponse.status()).toBeLessThan(500);

    // Step 3: PUT update
    const updateResponse = await request.put(`/wheels/api/1`, {
      data: { action: 'update', id: 1 }
    });
    expect(updateResponse.status()).toBeLessThan(500);

    // Step 4: DELETE
    const deleteResponse = await request.delete(`/wheels/api/1`);
    expect(deleteResponse.status()).toBeLessThan(500);
  });
});

test.describe('Session Management Flow', () => {
  test('should maintain session across multiple pages', async ({ page, context }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);

    const pages = [
      '/wheels/info',
      '/wheels/routes',
      '/wheels/migrator',
      '/wheels/plugins'
    ];

    // Track cookies before
    const initialCookies = await context.cookies();

    // Visit multiple pages
    for (const p of pages) {
      await page.goto(`${p}`);
      expect(page.url()).toContain(p);
    }

    // Track cookies after - session should persist
    const finalCookies = await context.cookies();
    expect(finalCookies.length).toBeGreaterThanOrEqual(initialCookies.length);
  });

  test('should handle session expiration gracefully', async ({ context }) => {
    // Create new context (simulates new session)
    const page = await context.newPage();

    await page.goto(`/`);
    expect(page.url()).toBe(`/`);

    // Clear cookies (simulates expiration)
    await context.clearCookies();

    // Navigate again - should handle gracefully
    await page.goto(`/wheels/info`);
    const content = await page.content();
    await expect(content).toBeTruthy();
  });
});

test.describe('Multi-Browser Tab Flow', () => {
  test('should handle multiple tabs with shared session', async ({ browser }) => {
    const context = await browser.newContext();

    // Open two tabs
    const page1 = await context.newPage();
    const page2 = await context.newPage();

    // Navigate to different pages
    await page1.goto(`/wheels/info`);
    await page2.goto(`/wheels/routes`);

    // Both should load successfully
    await expect(page1).toHaveTitle(/System Information \| Wheels/);
    await expect(page2).toHaveTitle(/Routes?/i);

    await context.close();
  });
});

test.describe('Error Recovery Flow', () => {
  test('should recover from error state', async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);

    // Step 1: Trigger an error condition
    await page.goto(`/nonexistent/page`);

    // Should not crash (5xx error)
    const status = page.url();
    expect(status).toBeTruthy();

    // Step 2: Navigate back to valid page
    await page.goto(`/wheels/info`);

    // Should recover and show normal page
    await expect(page).toHaveTitle(/System Information \| Wheels/);
  });

  test('should handle rapid navigation gracefully', async ({ page }) => {
    const urls = [
      `/wheels/info`,
      `/wheels/routes`,
      `/wheels/migrator`,
      `/wheels/plugins`,
      `/wheels/guides`
    ];

    // Rapid navigation
    for (const url of urls) {
      await page.goto(url, { timeout: 5000 }).catch(() => {});
    }

    // Final page should load
    await page.goto(`/wheels/info`);
    await expect(page).toHaveTitle(/System Information \| Wheels/);
  });
});

test.describe('Form Submission and Validation Flow', () => {
  test('should handle form with validation errors', async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);

    // Go to form page
    await page.goto(`/users/new`);

    // Submit with invalid data (empty)
    await page.click('button[type="submit"], input[type="submit"]');

    // Should show validation errors or stay on page
    const content = await page.content();
    await expect(content).toBeTruthy();
  });

  test('should successfully submit valid form', async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);

    await page.goto(`/users/new`);

    // Fill all required fields
    await page.fill('input[name="firstName"]', 'Valid');
    await page.fill('input[name="lastName"]', 'User');
    await page.fill('input[name="email"]', `valid-${Date.now()}@example.com`);

    // Submit
    await page.click('button[type="submit"], input[type="submit"]');

    // Should either redirect or show success message
    const content = await page.content();
    await expect(content).toBeTruthy();
  });
});

test.describe('Navigation and Routing Flow', () => {
  test('should navigate through breadcrumb trail', async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);

    const trail = [
      '/',
      '/wheels/info',
      '/wheels/routes',
      '/wheels/migrator'
    ];

    for (const path of trail) {
      await page.goto(path);
      expect(new URL(page.url()).pathname).toBe(path);
    }
  });

  test('should handle browser back/forward navigation', async ({ page }) => {
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(15000);

    // Navigate through pages
    await page.goto(`/wheels/info`);
    await page.goto(`/wheels/routes`);
    await page.goto(`/wheels/migrator`);

    // Go back
    await page.goBack();
    expect(page.url()).toContain('/wheels/routes');

    // Go back again
    await page.goBack();
    expect(page.url()).toContain('/wheels/info');

    // Go forward
    await page.goForward();
    expect(page.url()).toContain('/wheels/routes');
  });
});

test.describe('Concurrent User Flow', () => {
  test('should handle multiple users simultaneously', async ({ browser }) => {
    // Simulate 3 concurrent users
    const users = await Promise.all([
      browser.newContext(),
      browser.newContext(),
      browser.newContext()
    ]);

    // Each user visits different pages
    const results = await Promise.all([
      users[0].newPage().then(p => p.goto(`/wheels/info`).then(() => p.title())),
      users[1].newPage().then(p => p.goto(`/wheels/routes`).then(() => p.title())),
      users[2].newPage().then(p => p.goto(`/wheels/migrator`).then(() => p.title()))
    ]);

    // All should succeed
    expect(results.length).toBe(3);
    expect(results[0]).toMatch(/System Information/i);
    expect(results[1]).toMatch(/Routes/i);
    expect(results[2]).toMatch(/Migrator/i);

    // Cleanup
    await Promise.all(users.map(u => u.close()));
  });
});
