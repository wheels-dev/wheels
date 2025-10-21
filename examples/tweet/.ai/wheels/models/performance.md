# Model Performance and Optimization

## Description
Best practices and techniques for optimizing Wheels model performance, including query optimization, caching strategies, and efficient data loading patterns.

## Query Optimization

### Efficient Data Loading with Includes
```cfm
component extends="Model" {

    /**
     * Avoid N+1 queries by eager loading associations
     */
    function getPostsWithAuthors() {
        return this.findAll(
            include="author",
            select="posts.*, authors.firstname, authors.lastname",
            order="posts.createdat DESC"
        );
    }

    /**
     * Load multiple associations in one query
     */
    function getPostsWithAllData() {
        return this.findAll(
            include="author,category,comments",
            order="posts.createdat DESC"
        );
    }

    /**
     * Nested associations for complex data
     */
    function getPostsWithAuthorProfiles() {
        return this.findAll(
            include="author(profile)",
            order="posts.createdat DESC"
        );
    }
}
```

### Selective Column Loading
```cfm
component extends="Model" {

    /**
     * Use specific selects to reduce data transfer
     */
    function getRecentPostTitles(numeric days = 7) {
        return this.findAll(
            select="id, title, createdat",
            where="createdat > '#dateAdd("d", -arguments.days, now())#'",
            order="createdat DESC"
        );
    }

    /**
     * Load only essential fields for listings
     */
    function getPostSummaries() {
        return this.findAll(
            select="id, title, excerpt, createdat, authorid",
            include="author",
            order="createdat DESC"
        );
    }

    /**
     * Minimal data for dropdown options
     */
    function getPostOptions() {
        return this.findAll(
            select="id, title",
            where="status = 'published'",
            order="title"
        );
    }
}
```

### Efficient Pagination
```cfm
component extends="Model" {

    /**
     * Paginate large datasets efficiently
     */
    function getPostsPaginated(numeric page = 1, numeric perPage = 10) {
        return this.findAll(
            page=arguments.page,
            perPage=arguments.perPage,
            order="createdat DESC",
            include="author"  // Load author data to avoid N+1
        );
    }

    /**
     * Count records efficiently for pagination
     */
    function getPostCount() {
        return this.count();
    }

    /**
     * Get pagination metadata
     */
    function getPaginationInfo(numeric page = 1, numeric perPage = 10) {
        local.totalRecords = this.count();
        local.totalPages = ceiling(local.totalRecords / arguments.perPage);

        return {
            currentPage = arguments.page,
            perPage = arguments.perPage,
            totalRecords = local.totalRecords,
            totalPages = local.totalPages,
            hasNextPage = arguments.page < local.totalPages,
            hasPreviousPage = arguments.page > 1
        };
    }
}
```

### Boolean Existence Checks
```cfm
component extends="Model" {

    /**
     * Use exists() instead of count() for boolean checks
     */
    function hasRecentActivity(numeric days = 30) {
        return this.posts().exists(
            where="createdat > '#dateAdd("d", -arguments.days, now())#'"
        );
    }

    /**
     * Check for related records efficiently
     */
    function hasPublishedPosts() {
        return this.posts().exists(where="status = 'published'");
    }

    /**
     * Efficient user verification
     */
    function userExists(required string email) {
        return model("User").exists(where="email = '#arguments.email#'");
    }
}
```

## Caching Strategies

### Query Result Caching
```cfm
component extends="Model" {

    function config() {
        // Enable automatic query caching
        afterFind("enableQueryCache");
        afterSave("clearRelatedCache");
    }

    /**
     * Cache expensive calculations
     */
    function getStatistics() {
        local.cacheKey = "user_#this.id#_stats";

        if (!cacheKeyExists(local.cacheKey)) {
            local.stats = {
                postCount = this.posts().count(),
                commentCount = this.comments().count(),
                totalViews = this.posts().sum("viewCount"),
                averageRating = this.posts().average("rating")
            };

            cachePut(local.cacheKey, local.stats, createTimeSpan(0, 1, 0, 0)); // 1 hour
        }

        return cacheGet(local.cacheKey);
    }

    /**
     * Cache frequently accessed data
     */
    function getPopularPosts(numeric limit = 10) {
        local.cacheKey = "popular_posts_#arguments.limit#";

        if (!cacheKeyExists(local.cacheKey)) {
            local.posts = this.findAll(
                order="viewCount DESC",
                limit=arguments.limit,
                include="author"
            );

            cachePut(local.cacheKey, local.posts, createTimeSpan(0, 0, 30, 0)); // 30 minutes
        }

        return cacheGet(local.cacheKey);
    }

    /**
     * Clear related caches when data changes
     */
    private void function clearRelatedCache() {
        cacheRemove("user_#this.id#_stats");
        cacheRemove("popular_posts_*");
        cacheRemove("recent_posts");
        cacheRemove("top_authors");
    }
}
```

### Smart Cache Invalidation
```cfm
component extends="Model" {

    function config() {
        afterSave("invalidateRelatedCaches");
        afterDelete("invalidateRelatedCaches");
    }

    /**
     * Invalidate specific cache patterns
     */
    private void function invalidateRelatedCaches() {
        // Clear specific object cache
        cacheRemove("post_#this.id#");

        // Clear category-related caches
        if (this.categoryid) {
            cacheRemove("category_#this.categoryid#_posts");
            cacheRemove("category_#this.categoryid#_count");
        }

        // Clear author-related caches
        if (this.authorid) {
            cacheRemove("author_#this.authorid#_posts");
            cacheRemove("author_#this.authorid#_stats");
        }

        // Clear general listing caches
        cacheRemove("recent_posts");
        cacheRemove("featured_posts");
    }

    /**
     * Cache with dependency tracking
     */
    function getCachedContent() {
        local.cacheKey = "post_#this.id#_content";
        local.dependencies = ["post_#this.id#", "category_#this.categoryid#"];

        if (!cacheKeyExists(local.cacheKey)) {
            local.content = this.generateRichContent();
            cachePut(local.cacheKey, local.content, createTimeSpan(0, 2, 0, 0), local.dependencies);
        }

        return cacheGet(local.cacheKey);
    }
}
```

## Database Performance Optimization

### Index-Aware Queries
```cfm
component extends="Model" {

    /**
     * Use indexed columns in WHERE clauses
     */
    function findByIndexedFields() {
        // Assuming indexes exist on status, createdat, and categoryid
        return this.findAll(
            where="status = 'published' AND createdat > '#dateAdd("d", -30, now())#'",
            order="createdat DESC"
        );
    }

    /**
     * Combine indexed fields efficiently
     */
    function findActiveUserPosts(required numeric userid) {
        return this.findAll(
            where="authorid = '#arguments.userid#' AND status = 'published'",
            order="createdat DESC"
        );
    }

    /**
     * Use LIMIT to reduce result sets
     */
    function getLatestPosts(numeric limit = 5) {
        return this.findAll(
            order="createdat DESC",
            limit=arguments.limit,
            include="author"
        );
    }
}
```

### Efficient Aggregation Queries
```cfm
component extends="Model" {

    /**
     * Use database aggregation functions
     */
    function getUserStatistics(required numeric userid) {
        return {
            postCount = model("Post").count(where="authorid = '#arguments.userid#'"),
            totalViews = model("Post").sum(property="viewCount", where="authorid = '#arguments.userid#'"),
            averageRating = model("Post").average(property="rating", where="authorid = '#arguments.userid#'"),
            maxViews = model("Post").maximum(property="viewCount", where="authorid = '#arguments.userid#'")
        };
    }

    /**
     * Group by for efficient counting
     */
    function getPostCountsByCategory() {
        local.sql = "
            SELECT c.name, COUNT(p.id) as postCount
            FROM categories c
            LEFT JOIN posts p ON c.id = p.categoryid
            WHERE p.status = 'published'
            GROUP BY c.id, c.name
            ORDER BY postCount DESC
        ";

        return queryExecute(local.sql, {}, {datasource = application.datasource});
    }
}
```

### Raw SQL for Complex Queries
```cfm
component extends="Model" {

    /**
     * Use raw SQL for complex operations
     */
    function getTopAuthors(numeric limit = 10) {
        local.sql = "
            SELECT u.id, u.firstname, u.lastname, u.email,
                   COUNT(p.id) as postCount,
                   SUM(p.viewCount) as totalViews,
                   AVG(p.rating) as averageRating
            FROM users u
            INNER JOIN posts p ON u.id = p.authorid
            WHERE p.status = 'published'
            GROUP BY u.id, u.firstname, u.lastname, u.email
            ORDER BY postCount DESC, totalViews DESC
            LIMIT :limit
        ";

        return queryExecute(
            local.sql,
            { limit = { value = arguments.limit, cfsqltype = "cf_sql_integer" } },
            { datasource = application.datasource }
        );
    }

    /**
     * Complex search with full-text indexing
     */
    function searchPosts(required string searchTerm, numeric limit = 20) {
        local.sql = "
            SELECT p.*, u.firstname, u.lastname,
                   MATCH(p.title, p.content) AGAINST(:searchTerm) as relevance
            FROM posts p
            INNER JOIN users u ON p.authorid = u.id
            WHERE MATCH(p.title, p.content) AGAINST(:searchTerm)
              AND p.status = 'published'
            ORDER BY relevance DESC, p.createdat DESC
            LIMIT :limit
        ";

        return queryExecute(
            local.sql,
            {
                searchTerm = { value = arguments.searchTerm, cfsqltype = "cf_sql_varchar" },
                limit = { value = arguments.limit, cfsqltype = "cf_sql_integer" }
            },
            { datasource = application.datasource }
        );
    }
}
```

## Memory and Resource Optimization

### Lazy Loading Patterns
```cfm
component extends="Model" {

    /**
     * Load associations only when needed
     */
    function getAuthor() {
        if (!structKeyExists(variables, "_author")) {
            variables._author = model("User").findByKey(this.authorid);
        }
        return variables._author;
    }

    /**
     * Lazy load expensive calculations
     */
    function getWordCount() {
        if (!structKeyExists(variables, "_wordCount")) {
            variables._wordCount = listLen(this.content, " ");
        }
        return variables._wordCount;
    }

    /**
     * Cache method results
     */
    function getRelatedPosts() {
        if (!structKeyExists(variables, "_relatedPosts")) {
            variables._relatedPosts = model("Post").findAll(
                where="categoryid = '#this.categoryid#' AND id != '#this.id#'",
                limit=5,
                order="createdat DESC"
            );
        }
        return variables._relatedPosts;
    }
}
```

### Batch Processing
```cfm
component extends="Model" {

    /**
     * Process records in batches to avoid memory issues
     */
    function processAllPosts(required function callback) {
        local.batchSize = 100;
        local.offset = 0;
        local.hasMore = true;

        while (local.hasMore) {
            local.posts = this.findAll(
                offset=local.offset,
                limit=local.batchSize,
                order="id"
            );

            if (local.posts.recordCount == 0) {
                local.hasMore = false;
            } else {
                // Process this batch
                for (local.post in local.posts) {
                    arguments.callback(local.post);
                }

                local.offset += local.batchSize;
                local.hasMore = (local.posts.recordCount == local.batchSize);
            }
        }
    }

    /**
     * Bulk update for better performance
     */
    function markAllAsRead(required numeric userid) {
        return this.updateAll(
            isRead=true,
            where="userid = '#arguments.userid#' AND isRead = 0"
        );
    }
}
```

## Performance Monitoring

### Query Performance Tracking
```cfm
component extends="Model" {

    function config() {
        if (application.environment == "development") {
            beforeFind("startQueryTimer");
            afterFind("logQueryPerformance");
        }
    }

    /**
     * Track query execution time
     */
    private void function startQueryTimer() {
        variables.queryStartTime = getTickCount();
    }

    /**
     * Log slow queries for optimization
     */
    private void function logQueryPerformance() {
        local.executionTime = getTickCount() - variables.queryStartTime;

        if (local.executionTime > 1000) { // Log queries slower than 1 second
            writeLog(
                file="slow_queries",
                text="Slow query in #this.getModelName()#: #local.executionTime#ms",
                type="warning"
            );
        }
    }

    /**
     * Performance testing helper
     */
    function benchmarkQuery(required function queryFunction, numeric iterations = 10) {
        local.times = [];

        for (local.i = 1; local.i <= arguments.iterations; local.i++) {
            local.startTime = getTickCount();
            arguments.queryFunction();
            local.endTime = getTickCount();
            arrayAppend(local.times, local.endTime - local.startTime);
        }

        return {
            iterations = arguments.iterations,
            totalTime = arraySum(local.times),
            averageTime = arraySum(local.times) / arguments.iterations,
            minTime = arrayMin(local.times),
            maxTime = arrayMax(local.times)
        };
    }
}
```

## Connection and Resource Management

### Database Connection Optimization
```cfm
component extends="Model" {

    /**
     * Use transactions for multiple operations
     */
    function createUserWithProfile(required struct userData, required struct profileData) {
        transaction {
            local.user = model("User").create(arguments.userData);

            if (!local.user.valid()) {
                transaction action="rollback";
                return local.user;
            }

            arguments.profileData.userid = local.user.id;
            local.profile = model("Profile").create(arguments.profileData);

            if (!local.profile.valid()) {
                transaction action="rollback";
                local.user.addErrors(local.profile.allErrors());
                return local.user;
            }

            return local.user;
        }
    }

    /**
     * Efficient bulk operations
     */
    function createMultiplePosts(required array postData) {
        local.results = [];

        transaction {
            for (local.data in arguments.postData) {
                local.post = model("Post").create(local.data);
                if (!local.post.valid()) {
                    transaction action="rollback";
                    throw(type="ValidationError", message="Failed to create post: #local.post.allErrorsAsString()#");
                }
                arrayAppend(local.results, local.post);
            }
        }

        return local.results;
    }
}
```

## Performance Best Practices

### 1. Query Optimization
- Use `include` to avoid N+1 queries
- Select only necessary columns
- Use indexed columns in WHERE clauses
- Implement proper pagination for large datasets
- Use `exists()` instead of `count()` for boolean checks

### 2. Caching Strategy
- Cache expensive calculations and queries
- Implement smart cache invalidation
- Use cache dependencies for related data
- Monitor cache hit rates and effectiveness

### 3. Database Design
- Create appropriate indexes on frequently queried columns
- Use composite indexes for multi-column queries
- Consider denormalization for read-heavy applications
- Implement proper foreign key constraints

### 4. Memory Management
- Use lazy loading for expensive operations
- Process large datasets in batches
- Clear unused object references
- Monitor memory usage in production

### 5. Connection Management
- Use database transactions appropriately
- Avoid long-running transactions
- Pool database connections effectively
- Monitor connection usage and limits

### 6. Monitoring and Profiling
- Log slow queries for investigation
- Monitor application performance metrics
- Use profiling tools to identify bottlenecks
- Implement performance alerts and notifications

## Common Performance Anti-Patterns

### ❌ N+1 Query Problem
```cfm
// BAD: Causes N+1 queries
posts = model("Post").findAll();
for (post in posts) {
    author = post.author(); // Separate query for each post
}
```

### ✅ Solution: Use Includes
```cfm
// GOOD: Single query with join
posts = model("Post").findAll(include="author");
```

### ❌ Loading Unnecessary Data
```cfm
// BAD: Loading all columns when only need title
posts = model("Post").findAll();
```

### ✅ Solution: Select Specific Columns
```cfm
// GOOD: Only load necessary data
posts = model("Post").findAll(select="id, title, createdat");
```

### ❌ Inefficient Counting
```cfm
// BAD: Counting with count() when you just need boolean
if (user.posts().count() > 0) {
    // User has posts
}
```

### ✅ Solution: Use Exists
```cfm
// GOOD: Boolean check with exists()
if (user.posts().exists()) {
    // User has posts
}
```

## Related Documentation
- [Model Architecture](./architecture.md)
- [Model Associations](./associations.md)
- [Advanced Patterns](./advanced-patterns.md)
- [Database Configuration](../../configuration/database.md)