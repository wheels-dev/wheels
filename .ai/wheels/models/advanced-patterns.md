# Advanced Model Patterns

## Description
Complex model patterns for real-world applications including e-commerce, blog systems, and user authentication.

## Key Points
- Demonstrates advanced Wheels features: callbacks, custom properties, business logic
- Shows proper validation patterns for complex data
- Illustrates performance optimization techniques
- Includes security best practices

## Advanced Model Examples

### 1. E-commerce Product Model
```cfm
/**
 * Product Model - E-commerce product catalog
 */
component extends="Model" {

    function config() {
        // Associations
        belongsTo("category");
        hasMany("orderItems");
        hasMany("productImages");
        hasMany("reviews");
        hasOne("inventory");

        // Validations
        validatesPresenceOf("name,price,categoryid");
        validatesNumericalityOf("price", greaterThan=0);
        validatesNumericalityOf("weight", greaterThan=0, allowBlank=true);
        validatesLengthOf(property="name", minimum=3, maximum=255);
        validatesLengthOf(property="sku", maximum=50, allowBlank=true);
        validatesUniquenessOf("sku", allowBlank=true);

        // Custom properties
        property(name="isactive", type="boolean", defaultValue=true);
        property(name="discountedPrice", sql=false); // Calculated property
        property(name="inStock", sql=false);

        // Callbacks
        beforeSave("generateSku", "updateSlug");
        afterUpdate("clearProductCache");

        // Soft delete enabled automatically if deletedat column exists
    }

    /**
     * Get discounted price if on sale
     */
    function getDiscountedPrice() {
        if (this.salePrice > 0 && this.salePrice < this.price) {
            return this.salePrice;
        }
        return this.price;
    }

    /**
     * Check if product is in stock
     */
    function getInStock() {
        return this.inventory().quantity > 0;
    }

    /**
     * Get primary product image
     */
    function getPrimaryImage() {
        return this.productImages(where="isPrimary = 1").first();
    }

    /**
     * Calculate average rating from reviews
     */
    function getAverageRating() {
        return this.reviews().average("rating");
    }

    /**
     * Find active products only
     */
    function findActive() {
        return findAll(where="isactive = 1 AND deletedat IS NULL");
    }

    /**
     * Find products in specific category
     */
    function findInCategory(required numeric categoryid) {
        return findAll(where="categoryid = '#arguments.categoryid#'");
    }

    /**
     * Find products on sale
     */
    function findOnSale() {
        return findAll(where="salePrice > 0 AND salePrice < price");
    }

    /**
     * Search products by name and description
     */
    function searchByText(required string searchTerm) {
        local.term = "%" & arguments.searchTerm & "%";
        return this.where("name LIKE ? OR description LIKE ?", [local.term, local.term]);
    }

    /**
     * Callback: Generate SKU if not provided
     */
    private void function generateSku() {
        if (!len(this.sku)) {
            // Generate SKU from category and name
            local.categoryCode = this.category().code ?: "GEN";
            local.namePart = reReplace(this.name, "[^A-Za-z0-9]", "", "all");
            local.namePart = left(uCase(local.namePart), 8);
            this.sku = local.categoryCode & "-" & local.namePart & "-" & randRange(1000, 9999);
        }
    }

    /**
     * Callback: Update URL slug from name
     */
    private void function updateSlug() {
        if (hasChanged("name")) {
            this.slug = createSlug(this.name);
        }
    }

    /**
     * Callback: Clear cached product data
     */
    private void function clearProductCache() {
        // Clear relevant cache entries
        cacheRemove("product_#this.id#_details");
        cacheRemove("category_#this.categoryid#_products");
    }

    /**
     * Helper: Create URL-friendly slug
     */
    private string function createSlug(required string text) {
        local.slug = lCase(trim(arguments.text));
        local.slug = reReplace(local.slug, "[^a-z0-9\s]", "", "all");
        local.slug = reReplace(local.slug, "\s+", "-", "all");
        local.slug = reReplace(local.slug, "-+", "-", "all");
        local.slug = reReplace(local.slug, "^-|-$", "", "all");

        // Ensure uniqueness
        local.counter = 1;
        local.originalSlug = local.slug;
        while (model("Product").exists(where="slug = '#local.slug#' AND id != '#this.id ?: 0#'")) {
            local.slug = local.originalSlug & "-" & local.counter;
            local.counter++;
        }

        return local.slug;
    }
}
```

### 2. Blog Post Model with Rich Features
```cfm
/**
 * Post Model - Blog posts with rich content management
 */
component extends="Model" {

    function config() {
        // Associations
        belongsTo("author", modelName="User", foreignKey="authorid");
        belongsTo("category");
        hasMany("comments");
        hasMany("tags", through="postTags");
        hasMany("postTags");

        // Validations
        validatesPresenceOf("title,content,authorid");
        validatesLengthOf(property="title", minimum=5, maximum=255);
        validatesLengthOf(property="excerpt", maximum=500, allowBlank=true);
        validatesLengthOf(property="content", minimum=50);
        validatesUniquenessOf("slug");

        // Custom properties
        property(name="status", type="string", defaultValue="draft");
        property(name="publishedAt", type="timestamp");
        property(name="wordCount", sql=false);
        property(name="readingTime", sql=false);
        property(name="isPublished", sql=false);

        // Callbacks
        beforeValidation("generateSlugFromTitle");
        beforeSave("calculateWordCount", "setPublishedDate");
        afterCreate("notifySubscribers");
        afterUpdate("clearPostCache");

        // Automatic timestamps
        set(timeStampOnCreateProperty="createdAt");
        set(timeStampOnUpdateProperty="updatedAt");
    }

    /**
     * Get calculated word count
     */
    function getWordCount() {
        local.plainText = reReplace(this.content, "<[^>]*>", "", "all");
        local.words = listToArray(local.plainText, " " & chr(10) & chr(13) & chr(9));
        return arrayLen(local.words);
    }

    /**
     * Calculate estimated reading time
     */
    function getReadingTime() {
        local.wordsPerMinute = 200; // Average reading speed
        local.minutes = ceiling(getWordCount() / local.wordsPerMinute);
        return max(1, local.minutes); // Minimum 1 minute
    }

    /**
     * Check if post is published
     */
    function getIsPublished() {
        return this.status == "published" &&
               isDate(this.publishedAt) &&
               this.publishedAt <= now();
    }

    /**
     * Get formatted excerpt or auto-generate from content
     */
    function getFormattedExcerpt(numeric length = 200) {
        if (len(this.excerpt)) {
            return this.excerpt;
        }

        // Auto-generate from content
        local.plainText = reReplace(this.content, "<[^>]*>", "", "all");
        local.plainText = reReplace(local.plainText, "\s+", " ", "all");

        if (len(local.plainText) <= arguments.length) {
            return local.plainText;
        }

        local.truncated = left(local.plainText, arguments.length - 3);
        local.lastSpace = find(" ", reverse(local.truncated));
        if (local.lastSpace > 0 && local.lastSpace < 20) {
            local.truncated = left(local.truncated, len(local.truncated) - local.lastSpace + 1);
        }

        return trim(local.truncated) & "...";
    }

    /**
     * Get next published post
     */
    function getNextPost() {
        return model("Post")
            .where("status = ? AND publishedAt > ?", ["published", this.publishedAt])
            .order("publishedAt ASC")
            .first();
    }

    /**
     * Get previous published post
     */
    function getPreviousPost() {
        return model("Post")
            .where("status = ? AND publishedAt < ?", ["published", this.publishedAt])
            .order("publishedAt DESC")
            .first();
    }

    /**
     * Get related posts by tags
     */
    function getRelatedPosts(numeric limit = 5) {
        if (!this.tags().count()) {
            return [];
        }

        local.tagIds = [];
        for (local.tag in this.tags()) {
            arrayAppend(local.tagIds, local.tag.id);
        }

        return model("Post")
            .joins("INNER JOIN postTags pt ON posts.id = pt.postId")
            .where("pt.tagId IN (?) AND posts.id != ? AND posts.status = ?",
                   [arrayToList(local.tagIds), this.id, "published"])
            .group("posts.id")
            .order("COUNT(pt.tagId) DESC, posts.publishedAt DESC")
            .limit(arguments.limit);
    }

    /**
     * Publish the post
     */
    function publish() {
        if (this.status != "published") {
            this.status = "published";
            this.publishedAt = now();
            return this.save();
        }
        return true;
    }

    /**
     * Unpublish the post (set to draft)
     */
    function unpublish() {
        this.status = "draft";
        this.publishedAt = "";
        return this.save();
    }

    /**
     * Find published posts only
     */
    function findPublished() {
        return findAll(where="status = 'published' AND publishedAt <= '#Now()#'");
    }

    /**
     * Find draft posts only
     */
    function findDrafts() {
        return findAll(where="status = 'draft'");
    }

    // Callback implementations would continue here...
}
```

## Pattern Benefits

### Business Logic Encapsulation
- Keep complex logic in models, not controllers
- Provide clear interfaces for common operations
- Use virtual properties for calculated values

### Performance Optimization
- Cache expensive calculations in callbacks
- Use statistical methods for aggregations
- Implement efficient custom finders

### Security and Validation
- Comprehensive input validation
- Automatic slug generation with uniqueness
- Proper property sanitization

## Related Documentation
- [Model Architecture](./architecture.md)
- [Model Methods Reference](./methods-reference.md)
- [Model Associations](../database/associations/)
- [Model Validations](../database/validations/)