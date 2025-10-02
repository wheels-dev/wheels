# Blog Scaffold Command

## Description
Quickly scaffold a complete blog application with posts, comments, and modern frontend stack (Tailwind CSS, Alpine.js, HTMX). Based on successful implementation patterns from October 2025.

## Usage
```
Use this command when you want to create a blog system with:
- Post management (CRUD)
- Comment system
- Modern responsive design
- Mobile-friendly navigation
- Gravatar support for comments
```

## Command

Create a complete blog application with the following structure:

### Models
1. **Post Model** (`app/models/Post.cfc`):
   - Properties: title, slug, content, published, publishedAt
   - Validations: presence (title, content), uniqueness (slug), length constraints
   - Association: `hasMany(name="comments", dependent="delete")`
   - Methods: `generateSlug()`, `getExcerpt()`, `setSlugAndPublishDate()`
   - Callbacks: `beforeValidationOnCreate("setSlugAndPublishDate")`

2. **Comment Model** (`app/models/Comment.cfc`):
   - Properties: content, authorName, authorEmail, postId
   - Validations: presence (all fields), email format, length constraints
   - Association: `belongsTo(name="post")`
   - Methods: `getGravatarUrl(size=80)`

### Database Schema
Generate migrations for:
1. **posts** table: id, title, slug (unique indexed), content, published, publishedAt, timestamps
2. **comments** table: id, content, authorName, authorEmail, postId (foreign key, indexed), timestamps
3. **seed_blog_posts**: 10 sample tech posts (HTMX, Tailwind, Security, Testing, etc.)

### Controllers
1. **Posts Controller** (`app/controllers/Posts.cfc`):
   - Actions: index, show, new, create, edit, update, delete
   - Filters: `findPost` (for show, edit, update, delete)
   - Parameter verification: `key` must be integer
   - Flash messages for all actions

2. **Comments Controller** (`app/controllers/Comments.cfc`):
   - Actions: create, delete
   - Parameter verification: postId required for create, key for delete
   - Redirects back to post show page

### Views
1. **Layout** (`app/views/layout.cfm`):
   ```cfm
   <cfif application.contentOnly>
       <cfoutput>#flashMessages()##includeContent()#</cfoutput>
   <cfelse>
   <cfoutput>
   <!DOCTYPE html>
   <html>
   <head>
       #csrfMetaTags()#
       <title>#contentFor("title", "Tech Blog")#</title>
       <!-- Tailwind CSS CDN -->
       <script src="https://cdn.tailwindcss.com"></script>
       <!-- Alpine.js CDN -->
       <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
       <!-- HTMX CDN -->
       <script src="https://unpkg.com/htmx.org@2.0.0"></script>
   </head>
   <body>
       <nav x-data="{ mobileMenuOpen: false }">
           <!-- Navigation with Alpine.js mobile menu -->
       </nav>
       #flashMessages()#
       <main>#includeContent()#</main>
       <footer>&copy; #Year(Now())# Tech Blog</footer>
   </body>
   </html>
   </cfoutput>
   </cfif>
   ```

2. **Posts Views**:
   - `index.cfm`: Grid layout, comment counts, excerpt display
   - `show.cfm`: Full post, comments list, Alpine.js comment form toggle
   - `new.cfm`: Create form with validation errors, label=false on fields
   - `edit.cfm`: Update form with pre-populated data

### Routes (`config/routes.cfm`)
```cfm
mapper()
    .resources("posts")
    .resources("comments")
    .root(to="posts##index", method="get")
    .wildcard()
.end();
```

## Critical Implementation Rules

### 1. Layout cfoutput Structure
**MUST wrap entire HTML in single cfoutput block:**
```cfm
<cfelse>
<cfoutput>
<!DOCTYPE html>
...entire HTML...
</cfoutput>
</cfif>
```

### 2. Form Fields
**MUST use label=false when using custom HTML labels:**
```cfm
<label for="post-title">Title</label>
#textField(objectName="post", property="title", label=false)#
```

### 3. Query Association Access
**MUST fetch model object before accessing associations in loops:**
```cfm
<cfloop query="posts">
    <cfset postComments = model("Post").findByKey(posts.id).comments()>
    <p>#postComments.recordCount# comments</p>
</cfloop>
```

### 4. Consistent Arguments
**MUST use consistent argument style (all named recommended):**
```cfm
hasMany(name="comments", dependent="delete")
model("Post").findByKey(key=params.key, include="comments")
```

### 5. Database-Agnostic Dates
**MUST use CFML date functions, not database-specific SQL:**
```cfm
var day1 = DateAdd("d", -1, Now());
TIMESTAMP '#DateFormat(day1, "yyyy-mm-dd")# #TimeFormat(day1, "HH:mm:ss")#'
```

## Testing Checklist

After implementation, verify:
- [ ] `curl http://localhost:PORT` returns 200 OK
- [ ] `curl http://localhost:PORT | grep "Latest Tech Posts"` finds content
- [ ] `curl http://localhost:PORT | grep 'href="/posts"'` finds navigation links
- [ ] `curl http://localhost:PORT/posts/1` shows post detail with comments
- [ ] `curl http://localhost:PORT/posts/new` shows create form
- [ ] `curl http://localhost:PORT/posts/1/edit` shows edit form
- [ ] `curl http://localhost:PORT | grep -c "article class"` counts posts (should be 10)
- [ ] No literal `#expression#` in source: `curl http://localhost:PORT | grep '#urlFor'` returns empty

## Frontend Features Included

**Tailwind CSS:**
- Responsive grid layout (1/2/3 columns)
- Form styling with focus rings
- Flash message styling
- Button and navigation styling

**Alpine.js:**
- Mobile hamburger menu toggle
- Comment form show/hide
- Smooth transitions

**HTMX:**
- Loaded and ready for progressive enhancement
- Can be used for: live search, infinite scroll, inline editing

## Expected File Structure

```
app/
├── models/
│   ├── Post.cfc
│   └── Comment.cfc
├── controllers/
│   ├── Posts.cfc
│   └── Comments.cfc
├── views/
│   ├── layout.cfm
│   └── posts/
│       ├── index.cfm
│       ├── show.cfm
│       ├── new.cfm
│       └── edit.cfm
└── migrator/
    └── migrations/
        ├── [timestamp]_create_posts_table.cfc
        ├── [timestamp]_create_comments_table.cfc
        └── [timestamp]_seed_blog_posts.cfc
config/
└── routes.cfm (modified)
```

## Common Pitfalls to Avoid

1. ❌ Putting CFML expressions outside cfoutput blocks in layout
2. ❌ Not using `label=false` on form helpers → duplicate labels
3. ❌ Accessing `posts.comments().recordCount` inside query loop
4. ❌ Using `DATE_SUB()` or other database-specific functions
5. ❌ Mixed argument styles: `hasMany("comments", dependent="delete")`
6. ❌ Creating nested cfoutput blocks in layout
7. ❌ Not testing content, only HTTP status codes

## Success Criteria

Implementation is complete when:
- ✅ Homepage shows grid of 10 tech posts
- ✅ Each post shows comment count
- ✅ Clicking post shows full content with comments
- ✅ "Add Comment" button toggles form (Alpine.js)
- ✅ "Write Post" creates new posts
- ✅ Edit and delete work correctly
- ✅ Mobile menu works (hamburger icon)
- ✅ All navigation links work
- ✅ Flash messages display properly
- ✅ No CFML expressions visible in source code

## Estimated Time
20-30 minutes with proper documentation reference

## Related Documentation
- [Session Learnings 2025-10-01](../.ai/wheels/troubleshooting/session-learnings-2025-10-01.md)
- [Common Errors](../.ai/wheels/troubleshooting/common-errors.md)
- [Layout Best Practices](../.ai/wheels/views/layouts.md)
- [Query Association Patterns](../.ai/wheels/views/query-association-patterns.md)
