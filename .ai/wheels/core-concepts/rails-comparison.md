# Rails vs CFWheels Comparison

## Description
Key differences between Ruby on Rails and CFWheels frameworks to help Rails developers transition to CFWheels development.

## Language Fundamentals
| Aspect | Rails (Ruby) | CFWheels (CFML) |
|--------|--------------|------------------|
| **Syntax** | Ruby blocks, symbols | CFScript, tag-based templates |
| **Variables** | Instance variables `@user` | Regular variables `user` |
| **Comments** | `# Comment` | `// Comment` or `<!-- Comment -->` |
| **Strings** | `"Hello #{name}"` | `"Hello #name#"` |

## Model Associations

### Basic Associations
| Rails | CFWheels |
|-------|----------|
| `has_many :comments` | `hasMany("comments")` |
| `belongs_to :user` | `belongsTo("user")` |
| `has_one :profile` | `hasOne("profile")` |

### Association Options
**Rails:**
```ruby
has_many :comments, dependent: :destroy, class_name: "Comment"
belongs_to :user, foreign_key: "author_id"
```

**CFWheels:**
```cfm
hasMany(name="comments", dependent="delete"); // Named parameters required for options
belongsTo(name="user", foreignKey="authorId");
```

**Key Differences:**
- CFWheels supports `dependent` options but requires consistent named parameter syntax
- Use `foreignKey` instead of `foreign_key` (camelCase)
- No `class_name` option - uses `modelName` instead
- Cannot mix positional and named parameters

## Form Helpers

### Available Helpers
| Rails | CFWheels | Notes |
|-------|----------|-------|
| `text_field` | `textField()` | ✅ Available |
| `email_field` | ❌ Not available | Use `textField(type="email")` |
| `password_field` | `passwordField()` | ✅ Available |
| `text_area` | `textArea()` | ✅ Available |
| `label` with text | ❌ Limited | Use HTML `<label>` tags |

### Form Syntax
**Rails:**
```erb
<%= form_with model: @user do |form| %>
  <%= form.label :name, "Full Name" %>
  <%= form.email_field :email %>
<% end %>
```

**CFWheels:**
```cfm
#startFormTag(route="user", method="put", key=user.id)#
  <label for="user-name">Full Name</label>
  #textField(objectName="user", property="email", type="email")#
#endFormTag()#
```

## Routing

### Resource Routes
**Rails:**
```ruby
Rails.application.routes.draw do
  resources :posts do
    resources :comments
  end
  root 'posts#index'
end
```

**CFWheels:**
```cfm
mapper()
  .resources("posts")
  .resources("comments")  // Separate declaration - nested syntax differs
  .root(to="posts##index", method="get")
.end();
```

**Important:** CFWheels nested resource syntax is different from Rails. Use separate `.resources()` declarations instead of nested functions.

### Custom Routes
**Rails:**
```ruby
get '/login', to: 'sessions#new', as: 'login'
```

**CFWheels:**
```cfm
.get(name="login", pattern="/login", to="sessions##new")
```

## Controllers

### Basic Structure
**Rails:**
```ruby
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :find_post, only: [:show, :edit, :update, :destroy]

  def index
    @posts = Post.all
  end
end
```

**CFWheels:**
```cfm
component extends="Controller" {
  function config() {
    filters(through="authenticate", except="index,show");
    filters(through="findPost", only="show,edit,update,delete");
  }

  function index() {
    posts = model("Post").findAll();
  }
}
```

### Parameter Handling
**Rails:**
```ruby
def create
  @user = User.new(user_params)
end

private

def user_params
  params.require(:user).permit(:name, :email)
end
```

**CFWheels:**
```cfm
function create() {
  user = model("User").new(params.user);
}
```

## Models

### Model Definition
**Rails:**
```ruby
class Post < ApplicationRecord
  has_many :comments, dependent: :destroy
  validates :title, presence: true, uniqueness: true

  before_save :generate_slug
end
```

**CFWheels:**
```cfm
component extends="Model" {
  function config() {
    hasMany("comments"); // No dependent parameter
    validatesPresenceOf("title");
    validatesUniquenessOf(property="title");
    beforeSave("generateSlug");
  }
}
```

### Validations
| Rails | CFWheels |
|-------|----------|
| `validates :email, presence: true` | `validatesPresenceOf("email")` |
| `validates :email, uniqueness: true` | `validatesUniquenessOf(property="email")` |
| `validates :email, format: { with: /regex/ }` | `validatesFormatOf(property="email", regEx="regex")` |

## Views

### Template Syntax
**Rails (ERB):**
```erb
<h1><%= @post.title %></h1>
<%= link_to 'Edit', edit_post_path(@post), class: 'btn' %>
<% @posts.each do |post| %>
  <div><%= post.title %></div>
<% end %>
```

**CFWheels:**
```cfm
<cfoutput>
<h1>#post.title#</h1>
#linkTo(route="editPost", key=post.id, text="Edit", class="btn")#
<cfloop query="posts">
  <div>#posts.title#</div>
</cfloop>
</cfoutput>
```

### Layout Structure
**Rails:**
```erb
<!-- app/views/layouts/application.html.erb -->
<%= yield %>
```

**CFWheels:**
```cfm
<!-- app/views/layout.cfm -->
#includeContent()#
```

## Database Migrations

### Migration Structure
**Rails:**
```ruby
class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :body
      t.timestamps
    end
  end
end
```

**CFWheels:**
```cfm
component extends="wheels.migrator.Migration" {
  function up() {
    t = createTable(name="posts");
    t.string(columnNames="title", allowNull=false);
    t.text(columnNames="body");
    t.timestamps();
    t.create();
  }

  function down() {
    dropTable("posts");
  }
}
```

### Running Migrations
| Rails | CFWheels |
|-------|----------|
| `rails db:migrate` | `wheels dbmigrate latest` |
| `rails db:rollback` | `wheels dbmigrate down` |
| `rails db:reset` | `wheels dbmigrate reset` |

## Key Differences Summary

1. **Association Options**: CFWheels doesn't support Rails-style `dependent` options
2. **Form Helpers**: More limited in CFWheels - supplement with HTML
3. **Parameter Names**: Rails uses underscores, CFWheels uses camelCase
4. **Syntax Style**: Rails uses symbols and blocks, CFWheels uses strings and functions
5. **Variable Scope**: Rails uses instance variables, CFWheels uses regular variables
6. **Migration Binding**: CFWheels migration parameter binding can be unreliable

## Migration Tips for Rails Developers

1. **Start Simple**: Begin with basic CFWheels patterns before adding complexity
2. **Check Documentation**: Don't assume Rails conventions work in CFWheels
3. **Use HTML Fallbacks**: When form helpers are limited, use standard HTML
4. **Test Incrementally**: Test each component before combining features
5. **Leverage Conventions**: CFWheels has strong conventions - follow them

## Related
- [Troubleshooting Common Errors](../troubleshooting/common-errors.md)
- [Model Associations](../database/associations/)
- [Form Helpers](../views/helpers/forms.md)
- [Routing Resources](./routing/resources.md)

## Important Notes
- CFWheels is inspired by Rails but has different limitations and capabilities
- Always consult CFWheels documentation rather than assuming Rails patterns
- CFML syntax and conventions differ significantly from Ruby
- Some Rails features don't have CFWheels equivalents - use workarounds