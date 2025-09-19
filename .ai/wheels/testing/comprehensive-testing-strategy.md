# Comprehensive Testing Strategy for wheels_execute

## Overview

An enhanced testing framework that goes beyond basic unit and browser testing to ensure production-ready, accessible, secure, and performant Wheels applications.

## Multi-Dimensional Testing Matrix

### 1. Functional Testing (Enhanced)

#### A. Advanced Unit Testing
```javascript
// Model Testing with Edge Cases
describe("Advanced Model Testing", function() {
    describe("User Model", function() {
        it("should handle concurrent save operations", function() {
            // Test race conditions
            const promises = [];
            for (let i = 0; i < 10; i++) {
                promises.push(model("User").create({
                    email: `user${i}@test.com`,
                    username: `user${i}`
                }));
            }

            const results = await Promise.all(promises);
            expect(results.every(user => user.valid())).toBeTrue();
        });

        it("should handle large dataset operations", function() {
            // Performance under load
            const users = [];
            for (let i = 0; i < 1000; i++) {
                users.push({
                    email: `bulk${i}@test.com`,
                    username: `bulk${i}`
                });
            }

            const startTime = Date.now();
            const result = model("User").createBulk(users);
            const duration = Date.now() - startTime;

            expect(duration).toBeLT(5000); // Should complete in under 5 seconds
            expect(result.length).toBe(1000);
        });

        it("should maintain data integrity with complex associations", function() {
            const user = model("User").create({email: "test@test.com"});
            const posts = [];

            // Create 50 posts with comments
            for (let i = 0; i < 50; i++) {
                const post = model("Post").create({
                    title: `Post ${i}`,
                    content: `Content ${i}`,
                    userId: user.id
                });

                for (let j = 0; j < 10; j++) {
                    model("Comment").create({
                        content: `Comment ${j} on Post ${i}`,
                        postId: post.id,
                        authorEmail: `commenter${j}@test.com`
                    });
                }
            }

            // Verify relationships are maintained
            expect(user.posts().recordCount).toBe(50);

            const firstPost = user.posts()[1];
            expect(firstPost.comments().recordCount).toBe(10);

            // Test cascade delete
            user.delete();
            expect(model("Post").count()).toBe(0);
            expect(model("Comment").count()).toBe(0);
        });
    });
});
```

#### B. Integration Testing with Real Scenarios
```javascript
// Complete User Journey Testing
describe("Complete User Journeys", function() {
    describe("Blog Management Workflow", function() {
        it("should handle complete blog lifecycle", function() {
            // User registration
            const userData = {
                email: "blogger@test.com",
                password: "securepassword",
                firstName: "Jane",
                lastName: "Blogger"
            };

            let response = controller("Users").processAction("create", userData);
            expect(response.success).toBeTrue();

            // Login
            response = controller("Sessions").processAction("create", {
                email: "blogger@test.com",
                password: "securepassword"
            });
            expect(session.authenticated).toBeTrue();

            // Create post
            const postData = {
                title: "My First Blog Post",
                content: "This is my first blog post content...",
                tags: ["technology", "wheels", "cfml"],
                published: true
            };

            response = controller("Posts").processAction("create", postData);
            expect(response.post.id).toBeDefined();

            // Add comments
            for (let i = 0; i < 5; i++) {
                controller("Comments").processAction("create", {
                    postId: response.post.id,
                    content: `Great post! Comment ${i}`,
                    authorName: `Commenter ${i}`,
                    authorEmail: `commenter${i}@test.com`
                });
            }

            // Edit post
            const updatedPost = controller("Posts").processAction("update", {
                key: response.post.id,
                post: {
                    ...postData,
                    content: "Updated content with more information..."
                }
            });

            expect(updatedPost.post.content).toContain("Updated content");

            // Publish and verify public access
            response = controller("Posts").processAction("show", {
                key: response.post.id
            });

            expect(response.post.published).toBeTrue();
            expect(response.comments.recordCount).toBe(5);
        });
    });
});
```

### 2. Accessibility Testing (NEW)

#### A. WCAG Compliance Testing
```javascript
// Accessibility Testing with Puppeteer
async function runAccessibilityTests(url) {
    await mcp__puppeteer__puppeteer_navigate({url: url});

    // Color contrast testing
    const contrastResults = await mcp__puppeteer__puppeteer_evaluate({
        script: `
            const elements = document.querySelectorAll('*');
            const failures = [];

            elements.forEach(el => {
                const styles = window.getComputedStyle(el);
                const bgColor = styles.backgroundColor;
                const textColor = styles.color;

                if (bgColor && textColor) {
                    const contrast = calculateContrast(bgColor, textColor);
                    if (contrast < 4.5) { // WCAG AA standard
                        failures.push({
                            element: el.tagName + (el.className ? '.' + el.className : ''),
                            contrast: contrast,
                            background: bgColor,
                            text: textColor
                        });
                    }
                }
            });

            return failures;
        `
    });

    expect(contrastResults.length).toBe(0, "Color contrast failures found");

    // Keyboard navigation testing
    await testKeyboardNavigation();

    // Screen reader compatibility
    await testScreenReaderCompatibility();

    // Focus management
    await testFocusManagement();
}

async function testKeyboardNavigation() {
    // Test tab navigation through all interactive elements
    const interactiveElements = await mcp__puppeteer__puppeteer_evaluate({
        script: `
            return document.querySelectorAll(
                'a, button, input, textarea, select, [tabindex]:not([tabindex="-1"])'
            ).length;
        `
    });

    // Navigate through all elements using Tab key
    for (let i = 0; i < interactiveElements; i++) {
        await page.keyboard.press('Tab');

        const focusedElement = await mcp__puppeteer__puppeteer_evaluate({
            script: 'document.activeElement.tagName'
        });

        expect(focusedElement).toBeDefined("Focus should be on an element");
    }
}
```

### 3. Performance Testing (NEW)

#### A. Core Web Vitals Monitoring
```javascript
async function measureCoreWebVitals(url) {
    await mcp__puppeteer__puppeteer_navigate({url: url});

    const metrics = await mcp__puppeteer__puppeteer_evaluate({
        script: `
            return new Promise((resolve) => {
                new PerformanceObserver((list) => {
                    const entries = list.getEntries();
                    const vitals = {
                        LCP: 0, // Largest Contentful Paint
                        FID: 0, // First Input Delay
                        CLS: 0  // Cumulative Layout Shift
                    };

                    entries.forEach((entry) => {
                        switch (entry.entryType) {
                            case 'largest-contentful-paint':
                                vitals.LCP = entry.renderTime || entry.loadTime;
                                break;
                            case 'first-input':
                                vitals.FID = entry.processingStart - entry.startTime;
                                break;
                            case 'layout-shift':
                                if (!entry.hadRecentInput) {
                                    vitals.CLS += entry.value;
                                }
                                break;
                        }
                    });

                    resolve(vitals);
                }).observe({entryTypes: ['largest-contentful-paint', 'first-input', 'layout-shift']});

                // Fallback timeout
                setTimeout(() => resolve({}), 10000);
            });
        `
    });

    // Assert against Core Web Vitals thresholds
    expect(metrics.LCP).toBeLT(2500, "LCP should be under 2.5 seconds");
    expect(metrics.FID).toBeLT(100, "FID should be under 100 milliseconds");
    expect(metrics.CLS).toBeLT(0.1, "CLS should be under 0.1");

    return metrics;
}
```

#### B. Database Performance Testing
```javascript
describe("Database Performance", function() {
    it("should handle complex queries efficiently", function() {
        // Create test data
        const users = createTestUsers(1000);
        const posts = createTestPosts(5000, users);
        const comments = createTestComments(25000, posts);

        // Test query performance
        const startTime = Date.now();

        const results = model("Post")
            .findAll({
                include: "user,comments",
                where: "published = 1 AND createdAt >= ?",
                whereParams: [dateAdd("d", -30, now())],
                order: "createdAt DESC",
                page: 1,
                perPage: 20
            });

        const queryTime = Date.now() - startTime;

        expect(queryTime).toBeLT(500, "Complex query should complete in under 500ms");
        expect(results.recordCount).toBeLTE(20);

        // Verify no N+1 queries
        const queryCount = getExecutedQueryCount();
        expect(queryCount).toBeLTE(3, "Should not have N+1 query problems");
    });

    it("should scale with large datasets", function() {
        // Test with increasing data sizes
        const dataSizes = [100, 500, 1000, 5000, 10000];
        const queryTimes = [];

        for (const size of dataSizes) {
            createTestData(size);

            const startTime = Date.now();
            model("Post").findAll({order: "createdAt DESC", page: 1, perPage: 20});
            const queryTime = Date.now() - startTime;

            queryTimes.push({size, time: queryTime});

            // Performance should degrade linearly, not exponentially
            if (queryTimes.length > 1) {
                const previousTime = queryTimes[queryTimes.length - 2].time;
                const growthFactor = queryTime / previousTime;
                expect(growthFactor).toBeLT(2, "Query time should not grow exponentially");
            }
        }
    });
});
```

### 4. Security Testing (NEW)

#### A. Automated Security Scanning
```javascript
async function runSecurityTests(url) {
    // XSS Testing
    await testXSSVulnerabilities(url);

    // CSRF Protection Testing
    await testCSRFProtection(url);

    // SQL Injection Testing
    await testSQLInjection(url);

    // Authentication Security
    await testAuthenticationSecurity(url);
}

async function testXSSVulnerabilities(url) {
    const xssPayloads = [
        '<script>alert("XSS")</script>',
        'javascript:alert("XSS")',
        '<img src="x" onerror="alert(\'XSS\')"">',
        '<svg onload="alert(\'XSS\')">'
    ];

    for (const payload of xssPayloads) {
        await mcp__puppeteer__puppeteer_navigate({url: url + '/posts/new'});

        await mcp__puppeteer__puppeteer_fill({
            selector: 'input[name="post[title]"]',
            value: payload
        });

        await mcp__puppeteer__puppeteer_fill({
            selector: 'textarea[name="post[content]"]',
            value: payload
        });

        await mcp__puppeteer__puppeteer_click({selector: 'input[type="submit"]'});

        // Verify the payload was properly escaped
        const pageContent = await mcp__puppeteer__puppeteer_evaluate({
            script: 'document.body.innerHTML'
        });

        expect(pageContent).not.toContain('<script>', "XSS payload should be escaped");
        expect(pageContent).not.toContain('javascript:', "JavaScript URLs should be escaped");
    }
}

async function testCSRFProtection(url) {
    // Test that forms include CSRF tokens
    await mcp__puppeteer__puppeteer_navigate({url: url + '/posts/new'});

    const csrfToken = await mcp__puppeteer__puppeteer_evaluate({
        script: 'document.querySelector(\'input[name="authenticityToken"]\')?.value'
    });

    expect(csrfToken).toBeDefined("CSRF token should be present in forms");
    expect(csrfToken.length).toBeGT(20, "CSRF token should be sufficiently long");

    // Test that requests without CSRF tokens are rejected
    const response = await fetch(url + '/posts', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'post[title]=Test&post[content]=Content'
    });

    expect(response.status).toBe(403, "Requests without CSRF token should be rejected");
}
```

### 5. Advanced Browser Testing (ENHANCED)

#### A. Cross-Browser Compatibility Matrix
```javascript
const browserMatrix = [
    {browser: 'chrome', versions: ['latest', 'latest-1']},
    {browser: 'firefox', versions: ['latest', 'latest-1']},
    {browser: 'safari', versions: ['latest']},
    {browser: 'edge', versions: ['latest']}
];

const viewportMatrix = [
    {name: 'mobile', width: 375, height: 667},
    {name: 'tablet', width: 768, height: 1024},
    {name: 'desktop', width: 1920, height: 1080},
    {name: 'large', width: 2560, height: 1440}
];

async function runCrossBrowserTests(url) {
    for (const browser of browserMatrix) {
        for (const version of browser.versions) {
            for (const viewport of viewportMatrix) {
                await runTestSuite({
                    url,
                    browser: browser.browser,
                    version,
                    viewport
                });
            }
        }
    }
}
```

#### B. User Journey Recording and Replay
```javascript
class UserJourneyTester {
    async recordJourney(journeyName, actions) {
        const journey = {
            name: journeyName,
            timestamp: new Date(),
            actions: [],
            screenshots: []
        };

        for (const action of actions) {
            const screenshot = await this.takeScreenshot(`${journeyName}_${action.step}`);
            journey.screenshots.push(screenshot);

            const result = await this.executeAction(action);
            journey.actions.push({
                ...action,
                result,
                duration: result.duration,
                success: result.success
            });

            if (!result.success) {
                await this.handleActionFailure(action, result);
            }
        }

        await this.saveJourney(journey);
        return journey;
    }

    async replayJourney(journeyName) {
        const journey = await this.loadJourney(journeyName);

        for (const action of journey.actions) {
            const result = await this.executeAction(action);

            // Compare with original results
            this.compareResults(action.result, result);
        }
    }
}
```

## Integration with wheels_execute Command

### Enhanced Phase 4: Multi-Level Testing (UPDATED)
```markdown
### Phase 4: Comprehensive Testing Execution (10-20 minutes)

#### 4.1 Unit Testing Suite
- Model tests with edge cases and performance scenarios
- Controller tests with error conditions and security checks
- Service layer tests with complex business logic
- Utility function tests with boundary conditions

#### 4.2 Integration Testing Suite
- Complete user workflow testing
- API endpoint testing with various payloads
- Database transaction testing
- External service integration testing

#### 4.3 Accessibility Testing (NEW)
- WCAG 2.1 AA compliance testing
- Keyboard navigation validation
- Screen reader compatibility testing
- Color contrast verification

#### 4.4 Performance Testing (NEW)
- Core Web Vitals measurement
- Database query performance analysis
- Memory usage profiling
- Load testing simulation

#### 4.5 Security Testing (NEW)
- XSS vulnerability scanning
- CSRF protection verification
- SQL injection testing
- Authentication security validation

#### 4.6 Cross-Browser Testing (ENHANCED)
- Multi-browser compatibility matrix
- Responsive design validation
- JavaScript functionality verification
- CSS rendering consistency
```

### Phase 5: Advanced Browser Testing (UPDATED)
```markdown
### Phase 5: Production-Grade Browser Testing (15-25 minutes)

#### 5.1 User Journey Testing
- Record and replay critical user paths
- Measure journey completion times
- Validate error recovery paths
- Test edge cases and error scenarios

#### 5.2 Visual Regression Testing
- Screenshot comparison against baseline
- Layout shift detection
- Design system consistency verification
- Mobile vs desktop rendering comparison

#### 5.3 Performance Profiling
- Real user monitoring simulation
- Network throttling testing
- Cache effectiveness validation
- Asset optimization verification
```

## Success Metrics

### Coverage Requirements
- **Unit Testing**: 95% code coverage
- **Integration Testing**: 90% workflow coverage
- **Accessibility**: 100% WCAG AA compliance
- **Performance**: All Core Web Vitals in "Good" range
- **Security**: Zero high/critical vulnerabilities
- **Cross-Browser**: 100% compatibility with target browsers

### Performance Benchmarks
- **Page Load Time**: < 3 seconds
- **Database Queries**: < 500ms for complex queries
- **Memory Usage**: < 100MB baseline
- **Accessibility Score**: > 95/100

This comprehensive testing strategy ensures that the `wheels_execute` command produces applications that are not only functional but also accessible, performant, secure, and production-ready.