# Performance Testing for CFWheels Applications

## Description
Comprehensive performance testing patterns for CFWheels applications, focusing on Core Web Vitals, database optimization, server response times, and real-world user experience metrics.

## Key Points
- Core Web Vitals are critical for SEO and user experience
- Database query optimization prevents N+1 problems
- Server-side rendering performance affects initial page load
- Real User Monitoring (RUM) provides actual usage insights
- Progressive loading and caching strategies improve perceived performance

## Core Web Vitals Testing

### 1. Largest Contentful Paint (LCP) Testing
```javascript
async function measureLCP(page, url) {
    await page.goto(url, { waitUntil: 'networkidle0' });

    const lcpResult = await page.evaluate(() => {
        return new Promise((resolve) => {
            let lcpValue = 0;

            const observer = new PerformanceObserver((list) => {
                const entries = list.getEntries();
                const lastEntry = entries[entries.length - 1];
                lcpValue = lastEntry.renderTime || lastEntry.loadTime;
            });

            observer.observe({ entryTypes: ['largest-contentful-paint'] });

            // Fallback timeout
            setTimeout(() => {
                observer.disconnect();
                resolve({
                    value: lcpValue,
                    threshold: 2500, // Good: < 2.5s
                    rating: lcpValue < 2500 ? 'good' : lcpValue < 4000 ? 'needs-improvement' : 'poor'
                });
            }, 10000);
        });
    });

    return lcpResult;
}

// CFWheels LCP optimization testing
async function testCFWheelsLCPOptimization(page, url) {
    const tests = [];

    // Test with and without image optimization
    await page.goto(url);

    // Check for image optimization
    const imageOptimization = await page.evaluate(() => {
        const images = document.querySelectorAll('img');
        const results = {
            totalImages: images.length,
            optimized: 0,
            unoptimized: 0,
            issues: []
        };

        images.forEach((img, index) => {
            const hasLazyLoading = img.hasAttribute('loading');
            const hasAppropriateFormat = img.src.includes('.webp') || img.src.includes('.avif');
            const hasResponsiveSizes = img.hasAttribute('sizes') || img.hasAttribute('srcset');

            if (hasLazyLoading || hasAppropriateFormat || hasResponsiveSizes) {
                results.optimized++;
            } else {
                results.unoptimized++;
                results.issues.push({
                    index,
                    src: img.src,
                    missing: {
                        lazyLoading: !hasLazyLoading,
                        modernFormat: !hasAppropriateFormat,
                        responsive: !hasResponsiveSizes
                    }
                });
            }
        });

        return results;
    });

    return {
        lcp: await measureLCP(page, url),
        imageOptimization
    };
}
```

### 2. First Input Delay (FID) Testing
```javascript
async function measureFID(page, url) {
    await page.goto(url);

    const fidResult = await page.evaluate(() => {
        return new Promise((resolve) => {
            let fidValue = 0;

            const observer = new PerformanceObserver((list) => {
                const entries = list.getEntries();
                entries.forEach((entry) => {
                    fidValue = entry.processingStart - entry.startTime;
                });
            });

            observer.observe({ entryTypes: ['first-input'] });

            // Simulate user interaction
            document.addEventListener('click', () => {
                setTimeout(() => {
                    observer.disconnect();
                    resolve({
                        value: fidValue,
                        threshold: 100, // Good: < 100ms
                        rating: fidValue < 100 ? 'good' : fidValue < 300 ? 'needs-improvement' : 'poor'
                    });
                }, 1000);
            });

            // Trigger interaction after page load
            setTimeout(() => {
                const button = document.querySelector('button, a, input');
                if (button) {
                    button.click();
                } else {
                    resolve({ value: 0, rating: 'no-interaction', message: 'No interactive elements found' });
                }
            }, 1000);
        });
    });

    return fidResult;
}

// Test JavaScript bundle optimization
async function testJavaScriptPerformance(page, url) {
    await page.goto(url);

    const jsMetrics = await page.evaluate(() => {
        const performanceEntries = performance.getEntriesByType('navigation')[0];
        const resources = performance.getEntriesByType('resource');

        const jsResources = resources.filter(r => r.name.includes('.js'));
        const totalJSSize = jsResources.reduce((acc, r) => acc + (r.transferSize || 0), 0);
        const totalJSCount = jsResources.length;

        return {
            totalJavaScriptSize: totalJSSize,
            totalJavaScriptFiles: totalJSCount,
            domContentLoaded: performanceEntries.domContentLoadedEventEnd - performanceEntries.domContentLoadedEventStart,
            loadComplete: performanceEntries.loadEventEnd - performanceEntries.loadEventStart,
            recommendations: {
                bundleSize: totalJSSize > 250000 ? 'Consider code splitting or reducing bundle size' : 'JavaScript bundle size is acceptable',
                fileCount: totalJSCount > 10 ? 'Consider bundling JavaScript files to reduce requests' : 'JavaScript file count is reasonable'
            }
        };
    });

    return jsMetrics;
}
```

### 3. Cumulative Layout Shift (CLS) Testing
```javascript
async function measureCLS(page, url) {
    await page.goto(url);

    const clsResult = await page.evaluate(() => {
        return new Promise((resolve) => {
            let clsValue = 0;
            let sessionValue = 0;
            let sessionEntries = [];

            const observer = new PerformanceObserver((list) => {
                const entries = list.getEntries();

                entries.forEach((entry) => {
                    // Only count layout shifts without recent user input
                    if (!entry.hadRecentInput) {
                        const firstSessionEntry = sessionEntries[0];
                        const lastSessionEntry = sessionEntries[sessionEntries.length - 1];

                        // If the entry occurred less than 1 second after the previous entry and
                        // less than 5 seconds after the first entry in the session, include it
                        if (sessionValue &&
                            entry.startTime - lastSessionEntry.startTime < 1000 &&
                            entry.startTime - firstSessionEntry.startTime < 5000) {
                            sessionValue += entry.value;
                            sessionEntries.push(entry);
                        } else {
                            sessionValue = entry.value;
                            sessionEntries = [entry];
                        }

                        // Update the CLS value if the current session value is larger
                        if (sessionValue > clsValue) {
                            clsValue = sessionValue;
                        }
                    }
                });
            });

            observer.observe({ entryTypes: ['layout-shift'] });

            // Stop observing after 10 seconds
            setTimeout(() => {
                observer.disconnect();
                resolve({
                    value: clsValue,
                    threshold: 0.1, // Good: < 0.1
                    rating: clsValue < 0.1 ? 'good' : clsValue < 0.25 ? 'needs-improvement' : 'poor'
                });
            }, 10000);
        });
    });

    return clsResult;
}

// Test for common CLS causes in CFWheels apps
async function testCLSOptimization(page, url) {
    await page.goto(url);

    const clsAnalysis = await page.evaluate(() => {
        const issues = [];

        // Check for images without dimensions
        const images = document.querySelectorAll('img');
        images.forEach((img, index) => {
            if (!img.hasAttribute('width') || !img.hasAttribute('height')) {
                const computedStyle = window.getComputedStyle(img);
                if (!computedStyle.width || !computedStyle.height ||
                    computedStyle.width === 'auto' || computedStyle.height === 'auto') {
                    issues.push({
                        type: 'image_without_dimensions',
                        element: `img[${index}]`,
                        src: img.src,
                        recommendation: 'Add explicit width and height attributes or CSS dimensions'
                    });
                }
            }
        });

        // Check for web fonts without font-display
        const stylesheets = document.querySelectorAll('link[rel="stylesheet"]');
        stylesheets.forEach((link, index) => {
            if (link.href.includes('fonts.googleapis.com') || link.href.includes('font')) {
                issues.push({
                    type: 'potential_font_loading_issue',
                    element: `link[${index}]`,
                    href: link.href,
                    recommendation: 'Consider using font-display: swap for better loading experience'
                });
            }
        });

        // Check for dynamically inserted content areas
        const dynamicContentAreas = document.querySelectorAll('[data-dynamic], .loading, .placeholder');
        if (dynamicContentAreas.length > 0) {
            issues.push({
                type: 'dynamic_content_areas',
                count: dynamicContentAreas.length,
                recommendation: 'Reserve space for dynamic content to prevent layout shifts'
            });
        }

        return issues;
    });

    return {
        cls: await measureCLS(page, url),
        optimizationIssues: clsAnalysis
    };
}
```

## Database Performance Testing

### 1. Query Performance Analysis
```javascript
// CFWheels database performance testing
class DatabasePerformanceTester {
    async testQueryPerformance(testDataSize = 1000) {
        const results = {
            nPlusOneTests: [],
            complexQueryTests: [],
            indexUsageTests: [],
            paginationTests: []
        };

        // Test for N+1 query problems
        results.nPlusOneTests = await this.testNPlusOneQueries(testDataSize);

        // Test complex query performance
        results.complexQueryTests = await this.testComplexQueries(testDataSize);

        // Test index usage
        results.indexUsageTests = await this.testIndexUsage();

        // Test pagination performance
        results.paginationTests = await this.testPagination(testDataSize);

        return results;
    }

    async testNPlusOneQueries(dataSize) {
        const tests = [];

        // Create test data
        await this.createTestData(dataSize);

        // Test 1: Posts with comments (common N+1 scenario)
        const startTime = Date.now();
        const posts = model("Post").findAll({
            include: "comments", // This should prevent N+1
            order: "createdAt DESC",
            page: 1,
            perPage: 20
        });

        const queryTime = Date.now() - startTime;
        const queryCount = this.getQueryCount(); // Mock function to track queries

        tests.push({
            test: "posts_with_comments",
            queryTime,
            queryCount,
            recordsReturned: posts.recordCount,
            efficiency: queryCount <= 2 ? "excellent" : queryCount <= 5 ? "good" : "poor",
            recommendation: queryCount > 5 ? "Use include parameter to prevent N+1 queries" : "Query efficiency is good"
        });

        // Test 2: Users with posts and comments (more complex)
        const startTime2 = Date.now();
        const users = model("User").findAll({
            include: "posts",  // Test if nested includes work
            order: "lastName, firstName",
            page: 1,
            perPage: 10
        });

        const queryTime2 = Date.now() - startTime2;
        const queryCount2 = this.getQueryCount();

        tests.push({
            test: "users_with_posts",
            queryTime: queryTime2,
            queryCount: queryCount2,
            recordsReturned: users.recordCount,
            efficiency: queryCount2 <= 3 ? "excellent" : queryCount2 <= 6 ? "good" : "poor",
            recommendation: queryCount2 > 6 ? "Consider optimizing nested associations" : "Query efficiency is acceptable"
        });

        return tests;
    }

    async testComplexQueries(dataSize) {
        const tests = [];

        // Test complex where clauses with joins
        const startTime = Date.now();
        const complexQuery = model("Post").findAll({
            where: "published = ? AND createdAt >= ? AND userId IN (SELECT id FROM users WHERE active = ?)",
            whereParams: [true, dateAdd("d", -30, now()), true],
            include: "user,comments",
            order: "createdAt DESC, title ASC",
            page: 1,
            perPage: 50
        });

        const queryTime = Date.now() - startTime;

        tests.push({
            test: "complex_filtering_with_joins",
            queryTime,
            recordsReturned: complexQuery.recordCount,
            performance: queryTime < 500 ? "excellent" : queryTime < 1000 ? "good" : "poor",
            recommendation: queryTime > 1000 ? "Consider adding database indexes or simplifying query" : "Query performance is acceptable"
        });

        // Test aggregation queries
        const startTime2 = Date.now();
        const aggregateQuery = executeQuery("
            SELECT u.id, u.firstName, u.lastName,
                   COUNT(p.id) as postCount,
                   MAX(p.createdAt) as latestPost
            FROM users u
            LEFT JOIN posts p ON u.id = p.userId
            WHERE u.active = 1
            GROUP BY u.id, u.firstName, u.lastName
            HAVING postCount > 0
            ORDER BY postCount DESC, latestPost DESC
            LIMIT 25
        ");

        const queryTime2 = Date.now() - startTime2;

        tests.push({
            test: "aggregation_query",
            queryTime: queryTime2,
            recordsReturned: aggregateQuery.recordCount,
            performance: queryTime2 < 300 ? "excellent" : queryTime2 < 800 ? "good" : "poor",
            recommendation: queryTime2 > 800 ? "Consider optimizing GROUP BY and HAVING clauses" : "Aggregation performance is good"
        });

        return tests;
    }

    async testPagination(dataSize) {
        const tests = [];
        const pageSize = 25;
        const totalPages = Math.ceil(dataSize / pageSize);

        // Test first page performance
        const startTime1 = Date.now();
        const firstPage = model("Post").findAll({
            order: "createdAt DESC",
            page: 1,
            perPage: pageSize
        });
        const firstPageTime = Date.now() - startTime1;

        // Test middle page performance
        const middlePage = Math.ceil(totalPages / 2);
        const startTime2 = Date.now();
        const middlePageQuery = model("Post").findAll({
            order: "createdAt DESC",
            page: middlePage,
            perPage: pageSize
        });
        const middlePageTime = Date.now() - startTime2;

        // Test last page performance
        const startTime3 = Date.now();
        const lastPage = model("Post").findAll({
            order: "createdAt DESC",
            page: totalPages,
            perPage: pageSize
        });
        const lastPageTime = Date.now() - startTime3;

        tests.push({
            test: "pagination_performance",
            firstPageTime,
            middlePageTime,
            lastPageTime,
            scalability: lastPageTime / firstPageTime < 2 ? "good" : "poor",
            recommendation: lastPageTime / firstPageTime > 3 ?
                "Consider using cursor-based pagination for large datasets" :
                "Pagination performance is acceptable"
        });

        return tests;
    }
}
```

### 2. Memory Usage Testing
```javascript
async function testMemoryUsage(page, url) {
    // Enable memory monitoring
    await page.coverage.startJSCoverage();

    await page.goto(url);

    // Perform typical user actions
    await simulateUserInteractions(page);

    const memoryUsage = await page.evaluate(() => {
        if (performance.memory) {
            return {
                usedJSHeapSize: performance.memory.usedJSHeapSize,
                totalJSHeapSize: performance.memory.totalJSHeapSize,
                jsHeapSizeLimit: performance.memory.jsHeapSizeLimit,
                usage: (performance.memory.usedJSHeapSize / performance.memory.jsHeapSizeLimit) * 100
            };
        }
        return null;
    });

    const coverage = await page.coverage.stopJSCoverage();
    const unusedBytes = coverage.reduce((acc, entry) => {
        return acc + entry.ranges.reduce((innerAcc, range) => {
            return innerAcc + (range.end - range.start);
        }, 0);
    }, 0);

    const totalBytes = coverage.reduce((acc, entry) => acc + entry.text.length, 0);

    return {
        memoryUsage,
        codeUtilization: {
            totalBytes,
            unusedBytes,
            utilizationPercentage: ((totalBytes - unusedBytes) / totalBytes) * 100
        }
    };
}

async function simulateUserInteractions(page) {
    // Simulate typical user behavior
    const interactions = [
        () => page.click('a[href*="posts"]'),
        () => page.click('button, input[type="submit"]'),
        () => page.type('input[type="text"], textarea', 'test content'),
        () => page.click('nav a, .menu a'),
        () => page.scroll({ top: 1000 }),
        () => page.goBack(),
        () => page.goForward()
    ];

    for (const interaction of interactions) {
        try {
            await interaction();
            await page.waitForTimeout(1000); // Wait between interactions
        } catch (e) {
            // Ignore interaction failures
            console.log('Interaction failed:', e.message);
        }
    }
}
```

## Server Performance Testing

### 1. Response Time Testing
```javascript
async function testServerPerformance(urls) {
    const results = [];

    for (const url of urls) {
        const testResult = {
            url,
            metrics: {}
        };

        // Test cold start (first request)
        const coldStart = await measureResponseTime(url, { cache: 'no-cache' });
        testResult.metrics.coldStart = coldStart;

        // Test warm response (cached/subsequent request)
        const warmResponse = await measureResponseTime(url);
        testResult.metrics.warmResponse = warmResponse;

        // Test under load (concurrent requests)
        const loadTest = await measureConcurrentRequests(url, 10);
        testResult.metrics.loadTest = loadTest;

        results.push(testResult);
    }

    return results;
}

async function measureResponseTime(url, options = {}) {
    const startTime = Date.now();

    try {
        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'User-Agent': 'Performance-Test-Bot/1.0',
                ...options.headers
            },
            ...options
        });

        const endTime = Date.now();
        const responseTime = endTime - startTime;

        return {
            responseTime,
            status: response.status,
            statusText: response.statusText,
            headers: Object.fromEntries(response.headers.entries()),
            performance: responseTime < 200 ? 'excellent' : responseTime < 500 ? 'good' : responseTime < 1000 ? 'fair' : 'poor'
        };
    } catch (error) {
        return {
            responseTime: Date.now() - startTime,
            error: error.message,
            performance: 'error'
        };
    }
}

async function measureConcurrentRequests(url, concurrency = 10) {
    const startTime = Date.now();
    const promises = Array(concurrency).fill().map(() => measureResponseTime(url));

    const results = await Promise.all(promises);
    const totalTime = Date.now() - startTime;

    const responseTimes = results.map(r => r.responseTime);
    const averageResponseTime = responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length;
    const maxResponseTime = Math.max(...responseTimes);
    const minResponseTime = Math.min(...responseTimes);

    return {
        concurrency,
        totalTime,
        averageResponseTime,
        maxResponseTime,
        minResponseTime,
        throughput: (concurrency / totalTime) * 1000, // requests per second
        performance: averageResponseTime < 500 ? 'excellent' : averageResponseTime < 1000 ? 'good' : 'poor'
    };
}
```

## CFWheels-Specific Performance Patterns

### 1. View Rendering Performance
```cfm
<!-- Optimized CFWheels view patterns -->
<cfoutput>
<!-- Cache expensive queries -->
<cfset posts = model("Post").findAll(
    where="published = true",
    include="user",
    cache=30,  <!-- Cache for 30 minutes -->
    order="publishedAt DESC"
)>

<!-- Pagination to limit records -->
<cfset posts = model("Post").findAll(
    where="published = true",
    include="user",
    page=params.page,
    perPage=10,
    order="publishedAt DESC"
)>

<!-- Efficient loops with record count checks -->
<cfif posts.recordCount gt 0>
    <div class="posts-container">
        <cfloop query="posts">
            <article class="post">
                <h2>#posts.title#</h2>
                <p class="meta">By #posts.user.firstName# #posts.user.lastName#</p>

                <!-- Efficient comment count display -->
                <cfset commentCount = posts.commentsCount> <!-- Use calculated field instead of query -->
                <p class="comment-count">#commentCount# comments</p>

                <!-- Lazy load content preview -->
                <div class="content-preview">
                    #left(posts.content, 200)#...
                </div>
            </article>
        </cfloop>
    </div>

    <!-- Efficient pagination links -->
    <nav class="pagination">
        #paginationLinks(windowSize=5, prependToLink="page=")#
    </nav>
<cfelse>
    <p>No posts available.</p>
</cfif>
</cfoutput>
```

### 2. Database Query Optimization
```cfm
<!-- Optimized model patterns -->
<cfscript>
// In Post.cfc model
component extends="Model" {
    function config() {
        // Use includes to prevent N+1 queries
        hasMany(name="comments", dependent="delete");
        belongsTo(name="user");

        // Add calculated properties for performance
        property(name="commentsCount", sql="(SELECT COUNT(*) FROM comments WHERE postId = posts.id)");

        // Cache frequently accessed associations
        cacheAssociation("user", minutes=60);
    }

    // Optimized finder methods
    function findPublishedWithStats(page=1, perPage=10) {
        return findAll(
            select="posts.*, users.firstName, users.lastName,
                   (SELECT COUNT(*) FROM comments WHERE postId = posts.id) AS commentsCount",
            include="user",
            where="posts.published = true",
            order="posts.publishedAt DESC",
            page=arguments.page,
            perPage=arguments.perPage
        );
    }

    // Bulk operations for performance
    function publishMultiple(postIds) {
        return updateAll(
            where="id IN (#listQualify(arguments.postIds, "'")#)",
            published=true,
            publishedAt=now()
        );
    }
}
</cfscript>
```

## Performance Testing Integration with wheels_execute

### Enhanced Testing Phase
Add this to Phase 4 (Testing) in wheels_execute:

```markdown
#### 4.4 Performance Testing (MANDATORY)

##### Core Web Vitals Testing
- **LCP (Largest Contentful Paint)**: < 2.5 seconds
- **FID (First Input Delay)**: < 100 milliseconds
- **CLS (Cumulative Layout Shift)**: < 0.1

##### Database Performance Testing
- **Query Performance**: Complex queries < 500ms
- **N+1 Query Detection**: Maximum 3 queries for association loading
- **Pagination Efficiency**: Last page < 2x first page response time
- **Memory Usage**: JavaScript heap < 50MB baseline

##### Server Performance Testing
- **Response Times**: Server response < 200ms for cached content
- **Concurrent Load**: 10 concurrent requests with <2x response time degradation
- **Cold Start Performance**: First request < 1 second

##### Asset Optimization Testing
- **Image Optimization**: All images have proper dimensions and modern formats
- **JavaScript Bundles**: Total JS < 250KB, code utilization > 70%
- **CSS Optimization**: Critical CSS inlined, non-critical CSS deferred

**Success Criteria:**
- ✅ All Core Web Vitals in "Good" range
- ✅ Database queries optimized (no N+1 problems detected)
- ✅ Server response times < 500ms for dynamic content
- ✅ Asset sizes within recommended limits
- ✅ Memory usage stable under normal load
- ✅ Performance score >= 90/100 in Lighthouse
```

## Continuous Performance Monitoring

### Performance Budget Configuration
```javascript
const performanceBudget = {
    lcp: { budget: 2500, tolerance: 10 }, // 10% tolerance
    fid: { budget: 100, tolerance: 20 },
    cls: { budget: 0.1, tolerance: 15 },
    serverResponse: { budget: 500, tolerance: 25 },
    jsBundle: { budget: 250000, tolerance: 10 },
    totalPageSize: { budget: 2000000, tolerance: 15 }
};

function validatePerformanceBudget(metrics, budget) {
    const results = [];

    Object.entries(budget).forEach(([metric, config]) => {
        const actualValue = metrics[metric];
        const budgetValue = config.budget;
        const tolerance = config.tolerance;
        const maxAllowed = budgetValue * (1 + tolerance / 100);

        results.push({
            metric,
            actual: actualValue,
            budget: budgetValue,
            maxAllowed,
            passed: actualValue <= maxAllowed,
            overBudget: actualValue > budgetValue,
            overTolerance: actualValue > maxAllowed
        });
    });

    return results;
}
```

This comprehensive performance testing framework ensures CFWheels applications deliver excellent user experiences with fast load times, smooth interactions, and efficient resource usage.