# Blog Application Example

A complete blog application built with Wheels framework demonstrating MVC patterns, authentication, and CRUD operations.

## Features

- User registration and authentication
- Create, read, update, and delete blog posts
- Comment system with nested replies
- Categories and tags
- Search functionality
- User profiles
- Admin panel
- Featured images with upload handling
- RSS feed
- SEO-friendly URLs

## Setup

1. Copy this example to your workspace:
```bash
cp -r examples/blog-app ../workspace/my-blog
cd ../workspace/my-blog
```

2. Install dependencies:
```bash
box install
```

3. Configure database in `config/settings.cfm`:
```cfscript
// Database configuration
set(dataSourceName: "blog");
```

4. Create database and run migrations:
```bash
wheels db create
wheels db migrate
wheels db seed  # Optional: loads sample data
```

5. Start the application:
```bash
server start
```

6. Visit http://localhost:3000

## Project Structure

```
/blog-app
  /app
    /controllers
      Admin.cfc         # Admin base controller
      AdminPosts.cfc    # Admin post management
      Comments.cfc      # Comment handling
      Posts.cfc         # Public post display
      Sessions.cfc      # Authentication
      Users.cfc         # User management
    /models
      Comment.cfc       # Comment model
      Post.cfc          # Post model with validations
      Tag.cfc           # Tag model
      User.cfc          # User model with authentication
    /views
      /layouts
        default.cfm     # Main layout
        admin.cfm       # Admin layout
      /posts
        index.cfm       # Post listing
        show.cfm        # Single post view
        _form.cfm       # Reusable form partial
      /users
        new.cfm         # Registration form
        profile.cfm     # User profile
  /config
    routes.cfm          # URL routing configuration
    settings.cfm        # Application settings
  /db
    /migrate
      001_create_users.cfc
      002_create_posts.cfc
      003_create_comments.cfc
      004_create_tags.cfc
  /tests
    /models
      PostTest.cfc
      UserTest.cfc
    /controllers
      PostsControllerTest.cfc

## Key Patterns Demonstrated

### Authentication
- Session-based authentication
- Password hashing with BCrypt
- Remember me functionality
- Authorization filters

### Model Associations
```cfscript
// User model
hasMany("posts");
hasMany("comments");

// Post model
belongsTo("author", modelName: "User", foreignKey: "userId");
hasMany("comments", dependent: "delete");
hasAndBelongsToMany("tags");
```

### Validations
```cfscript
// Post model validations
validatesPresenceOf("title,content");
validatesUniquenessOf("slug");
validatesLengthOf(property: "title", maximum: 200);
```

### RESTful Routes
```cfscript
// config/routes.cfm
mapper()
    .resources("posts")
        .resources("comments", only: "create,delete")
    .end()
    .namespace("admin")
        .resources("posts")
        .resources("users")
    .end()
.end();
```

### File Uploads
```cfscript
// Handle featured image upload
if (structKeyExists(params.post, "featuredImage")) {
    params.post.featuredImage = fileUpload(
        destination: expandPath("/images/posts/"),
        fileField: "post[featuredImage]",
        allowedExtensions: "jpg,jpeg,png,gif"
    );
}
```

## Testing

Run all tests:
```bash
wheels test app
```

Run specific test:
```bash
wheels test app PostTest
```

## Customization

- Modify styles in `/stylesheets/blog.css`
- Add new features by generating scaffolds
- Extend models with custom methods
- Add API endpoints for mobile apps

## Common Tasks

### Add a new field to posts:
```bash
wheels g migration AddPublishedAtToPosts
# Edit migration to add column
wheels db migrate
# Update model and forms
```

### Create admin user:
```cfscript
// Run in console or create seed file
user = model("User").create(
    email: "admin@example.com",
    password: "adminpass",
    role: "admin"
);
```

## Troubleshooting

- **Images not uploading**: Check file permissions on `/images/posts/`
- **Routes not working**: Run `wheels routes` to see all routes
- **Database errors**: Ensure migrations ran with `wheels db info`