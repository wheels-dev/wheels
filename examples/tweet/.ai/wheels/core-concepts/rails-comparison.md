# Rails vs Wheels Comparison

## Description
Key differences between Ruby on Rails and Wheels frameworks to help Rails developers transition to Wheels development.

## Language Fundamentals
| Aspect | Rails (Ruby) | Wheels (CFML) |
|--------|--------------|------------------|
| **Syntax** | Ruby blocks, symbols | CFScript, tag-based templates |
| **Variables** | Instance variables `@user` | Regular variables `user` |
| **Comments** | `# Comment` | `// Comment` or `<!-- Comment -->` |
| **Strings** | `"Hello #{name}"` | `"Hello #name#"` |

## Model Associations

### Basic Associations
| Rails | Wheels |
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

**Wheels:**
```cfm
hasMany(name="comments", dependent="delete"); // Named parameters required for options
belongsTo(name="user", foreignKey="authorId");
```

**Key Differences:**
- Wheels supports `dependent` options but requires consistent named parameter syntax
- Use `foreignKey` instead of `foreign_key` (camelCase)
- No `class_name` option - uses `modelName` instead
- Cannot mix positional and named parameters

## Form Helpers

### Available Helpers
| Rails | Wheels | Notes |
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

**Wheels:**
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

**Wheels:**
```cfm
mapper()
  .resources("posts")
  .resources("comments")  // Separate declaration - nested syntax differs
  .root(to="posts##index", method="get")
.end();
```

**Important:** Wheels nested resource syntax is different from Rails. Use separate `.resources()` declarations instead of nested functions.

### Custom Routes
**Rails:**
```ruby
get '/login', to: 'sessions#new', as: 'login'
```

**Wheels:**
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

**Wheels:**
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

**Wheels:**
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

**Wheels:**
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
| Rails | Wheels |
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

**Wheels:**
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

**Wheels:**
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

**Wheels:**
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
| Rails | Wheels |
|-------|----------|
| `rails db:migrate` | `wheels dbmigrate latest` |
| `rails db:rollback` | `wheels dbmigrate down` |
| `rails db:reset` | `wheels dbmigrate reset` |

## Key Differences Summary

1. **Association Options**: Wheels doesn't support Rails-style `dependent` options
2. **Form Helpers**: More limited in Wheels - supplement with HTML
3. **Parameter Names**: Rails uses underscores, Wheels uses camelCase
4. **Syntax Style**: Rails uses symbols and blocks, Wheels uses strings and functions
5. **Variable Scope**: Rails uses instance variables, Wheels uses regular variables
6. **Migration Binding**: Wheels migration parameter binding can be unreliable

## Migration Tips for Rails Developers

1. **Start Simple**: Begin with basic Wheels patterns before adding complexity
2. **Check Documentation**: Don't assume Rails conventions work in Wheels
3. **Use HTML Fallbacks**: When form helpers are limited, use standard HTML
4. **Test Incrementally**: Test each component before combining features
5. **Leverage Conventions**: Wheels has strong conventions - follow them

## Related
- [Troubleshooting Common Errors](../troubleshooting/common-errors.md)
- [Model Associations](../database/associations/)
- [Form Helpers](../views/helpers/forms.md)
- [Routing Resources](./routing/resources.md)

## Important Notes
- Wheels is inspired by Rails but has different limitations and capabilities
- Always consult Wheels documentation rather than assuming Rails patterns
- CFML syntax and conventions differ significantly from Ruby
- Some Rails features don't have Wheels equivalents - use workarounds