# Wheels Query vs Association Handling Patterns

## Critical Anti-Pattern: Association Query Confusion

### ❌ **The Problem**
```cfm
<!-- This causes "Column [COMMENTS_COUNT] not found" error -->
<cfif posts.recordCount>
    <cfloop query="posts">
        <p>#posts.comments_count# comments</p>  <!-- ERROR: This column doesn't exist -->
    </cfloop>
</cfif>
```

### ✅ **The Solution**
```cfm
<!-- Method 1: Use model count method -->
<cfif posts.recordCount>
    <cfloop query="posts">
        <cfset commentCount = model("Comment").count(where="postId = #posts.id#")>
        <p>#commentCount# comments</p>
    </cfloop>
</cfif>

<!-- Method 2: Load association and use recordCount -->
<cfif posts.recordCount>
    <cfloop query="posts">
        <cfset comments = model("Post").findByKey(posts.id).comments()>
        <p>#comments.recordCount# comments</p>
    </cfloop>
</cfif>
```

## Understanding Wheels Associations

### How Associations Return Data
```cfm
<!-- In a Post model with hasMany("comments") -->
post = model("Post").findByKey(1);
comments = post.comments();  // Returns a QUERY object, not an array

<!-- CORRECT: Use query methods -->
commentCount = comments.recordCount;
<cfloop query="comments">
    <p>#comments.content#</p>
</cfloop>

<!-- INCORRECT: Don't treat as array -->
commentCount = ArrayLen(comments);  // ERROR: comments is a query, not array
<cfloop array="#comments#" index="comment">  // ERROR: wrong loop type
    <p>#comment.content#</p>
</cfloop>
```

## Association Patterns by Type

### hasMany Associations
```cfm
<!-- Model definition -->
component extends="Model" {
    function config() {
        hasMany(name="comments");
        hasMany(name="tags");
    }
}

<!-- Usage in views -->
post = model("Post").findByKey(params.key);
comments = post.comments();  // Returns query

<!-- Display pattern -->
<cfif comments.recordCount>
    <h3>Comments (#comments.recordCount#)</h3>
    <cfloop query="comments">
        <div class="comment">
            <h4>#comments.authorName#</h4>
            <p>#comments.content#</p>
        </div>
    </cfloop>
<cfelse>
    <p>No comments yet.</p>
</cfif>
```

### belongsTo Associations
```cfm
<!-- Model definition -->
component extends="Model" {
    function config() {
        belongsTo("post");
        belongsTo("user");
    }
}

<!-- Usage in views -->
comment = model("Comment").findByKey(params.key);
post = comment.post();  // Returns single object

<!-- Display pattern -->
<h2>Comment on: #linkTo(controller="posts", action="show", key=post.id, text=post.title)#</h2>
```

## Performance Considerations

### ❌ **N+1 Query Problem**
```cfm
<!-- This creates N+1 queries (1 for posts, N for each post's comments) -->
posts = model("Post").findAll();
<cfloop query="posts">
    <cfset commentCount = model("Comment").count(where="postId = #posts.id#")>
    <p>#posts.title# (#commentCount# comments)</p>
</cfloop>
```

### ✅ **Optimized Solutions**

#### Option 1: Batch Query
```cfm
<!-- Get all posts and all comment counts in two queries -->
posts = model("Post").findAll();
commentCounts = {};

<!-- Get comment counts for all posts at once -->
<cfquery name="counts" datasource="#get('dataSourceName')#">
    SELECT postId, COUNT(*) as commentCount
    FROM comments
    GROUP BY postId
</cfquery>

<cfloop query="counts">
    <cfset commentCounts[counts.postId] = counts.commentCount>
</cfloop>

<!-- Display with cached counts -->
<cfloop query="posts">
    <cfset commentCount = structKeyExists(commentCounts, posts.id) ? commentCounts[posts.id] : 0>
    <p>#posts.title# (#commentCount# comments)</p>
</cfloop>
```

#### Option 2: Include Association (Use Carefully)
```cfm
<!-- This works but can be memory intensive for large datasets -->
posts = model("Post").findAll(include="comments");

<cfloop query="posts">
    <!-- Access loaded association data -->
    <cfset comments = model("Post").findByKey(posts.id).comments()>
    <p>#posts.title# (#comments.recordCount# comments)</p>
</cfloop>
```

## Common Query Patterns

### Filtering Associated Data
```cfm
<!-- Get posts with their published comments only -->
post = model("Post").findByKey(params.key);
publishedComments = post.comments(where="approved = 1", order="createdAt DESC");

<!-- Display filtered results -->
<cfif publishedComments.recordCount>
    <cfloop query="publishedComments">
        <div class="comment">#publishedComments.content#</div>
    </cfloop>
</cfif>
```

### Conditional Display Based on Associations
```cfm
<!-- Check if post has comments before displaying section -->
post = model("Post").findByKey(params.key);
comments = post.comments();

<cfif comments.recordCount GT 0>
    <section class="comments">
        <h3>Comments (#comments.recordCount#)</h3>
        <!-- Comment display code -->
    </section>
<cfelse>
    <section class="no-comments">
        <p>No comments yet. Be the first to comment!</p>
    </section>
</cfif>
```

## Debugging Association Issues

### Check What Type of Data You Have
```cfm
<!-- Debug association returns -->
post = model("Post").findByKey(1);
comments = post.comments();

<!-- Debug output -->
<cfdump var="#comments#" label="Comments Query Object">
<p>Type: #getMetadata(comments).name#</p>
<p>Record Count: #comments.recordCount#</p>
```

### Common Debug Patterns
```cfm
<!-- 1. Verify the association exists -->
<cfif isObject(post) AND post.hasProperty("comments")>
    <p>Post has comments association</p>
</cfif>

<!-- 2. Check if query has records -->
<cfif comments.recordCount GT 0>
    <p>Found #comments.recordCount# comments</p>
<cfelse>
    <p>No comments found</p>
</cfif>

<!-- 3. Debug specific record access -->
<cfif comments.recordCount GT 0>
    <p>First comment: #comments.content[1]#</p>  <!-- Array notation for query columns -->
</cfif>
```

## Best Practices

1. **Always check recordCount** before looping through query results
2. **Use appropriate loop type** (`<cfloop query="">` for queries)
3. **Consider performance** when accessing associations in loops
4. **Cache association results** when used multiple times
5. **Use includes sparingly** - they can impact memory usage
6. **Debug association returns** when troubleshooting

## Integration with Modern Views

### With HTMX for Dynamic Loading
```cfm
<!-- Initial load shows count only -->
<div id="comments-section" hx-get="/posts/#post.id#/comments" hx-trigger="load">
    <p>Loading #post.comments().recordCount# comments...</p>
</div>
```

### With Alpine.js for Interactivity
```cfm
<div x-data="{ showComments: false }">
    <button @click="showComments = !showComments">
        <span x-text="showComments ? 'Hide' : 'Show'"></span>
        Comments (#comments.recordCount#)
    </button>

    <div x-show="showComments" x-transition>
        <cfloop query="comments">
            <div class="comment">#comments.content#</div>
        </cfloop>
    </div>
</div>
```

This pattern was identified during real blog development where association data handling caused initial display errors.