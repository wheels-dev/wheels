# wheels generate frontend (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Generate frontend code including JavaScript, CSS, and interactive components.

> ⚠️ **Note**: This command is currently marked as disabled in the codebase. The documentation below represents the intended functionality when the command is restored.

## Synopsis

```bash
wheels generate frontend [type] [name] [options]
wheels g frontend [type] [name] [options]
```

## Description

The `wheels generate frontend` command creates frontend assets including JavaScript modules, CSS stylesheets, and interactive components. It supports various frontend frameworks and patterns while integrating seamlessly with Wheels views.

## Current Status

**This command is temporarily disabled.** Use manual approaches:

```bash
# Create frontend files manually in:
# /public/javascripts/
# /public/stylesheets/
# /views/components/
```

## Arguments (When Enabled)

| Argument | Description | Default |
|----------|-------------|---------|
| `type` | Type of frontend asset (component, module, style) | Required |
| `name` | Name of the asset | Required |

## Options (When Enabled)

| Option | Description | Default |
|--------|-------------|---------|
| `--framework` | Frontend framework (vanilla, alpine, vue, htmx) | `vanilla` |
| `--style` | CSS framework (none, bootstrap, tailwind) | `none` |
| `--bundler` | Use bundler (webpack, vite, none) | `none` |
| `--typescript` | Generate TypeScript files | `false` |
| `--test` | Generate test files | `true` |
| `--force` | Overwrite existing files | `false` |
| `--help` | Show help information | |

## Intended Functionality

### Generate Component
```bash
wheels generate frontend component productCard --framework=alpine
```

Would generate:

`/public/javascripts/components/productCard.js`:
```javascript
// Product Card Component
document.addEventListener('alpine:init', () => {
    Alpine.data('productCard', (initialData = {}) => ({
        // State
        product: initialData.product || {},
        isLoading: false,
        isFavorite: false,
        
        // Computed
        get formattedPrice() {
            return new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: 'USD'
            }).format(this.product.price || 0);
        },
        
        // Methods
        async toggleFavorite() {
            this.isLoading = true;
            try {
                const response = await fetch(`/api/products/${this.product.id}/favorite`, {
                    method: this.isFavorite ? 'DELETE' : 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-Token': this.getCsrfToken()
                    }
                });
                
                if (response.ok) {
                    this.isFavorite = !this.isFavorite;
                    this.$dispatch('favorite-changed', {
                        productId: this.product.id,
                        isFavorite: this.isFavorite
                    });
                }
            } catch (error) {
                console.error('Failed to toggle favorite:', error);
                this.$dispatch('notification', {
                    type: 'error',
                    message: 'Failed to update favorite status'
                });
            } finally {
                this.isLoading = false;
            }
        },
        
        async addToCart() {
            this.isLoading = true;
            try {
                const response = await fetch('/api/cart/items', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-Token': this.getCsrfToken()
                    },
                    body: JSON.stringify({
                        productId: this.product.id,
                        quantity: 1
                    })
                });
                
                if (response.ok) {
                    this.$dispatch('cart-updated');
                    this.$dispatch('notification', {
                        type: 'success',
                        message: 'Added to cart'
                    });
                }
            } catch (error) {
                console.error('Failed to add to cart:', error);
            } finally {
                this.isLoading = false;
            }
        },
        
        getCsrfToken() {
            return document.querySelector('meta[name="csrf-token"]')?.content || '';
        }
    }));
});
```

`/public/stylesheets/components/productCard.css`:
```css
/* Product Card Styles */
.product-card {
    @apply bg-white rounded-lg shadow-md overflow-hidden transition-transform hover:scale-105;
}

.product-card__image {
    @apply w-full h-48 object-cover;
}

.product-card__content {
    @apply p-4;
}

.product-card__title {
    @apply text-lg font-semibold text-gray-800 mb-2;
}

.product-card__price {
    @apply text-xl font-bold text-blue-600 mb-3;
}

.product-card__actions {
    @apply flex justify-between items-center;
}

.product-card__button {
    @apply px-4 py-2 rounded font-medium transition-colors;
}

.product-card__button--primary {
    @apply bg-blue-500 text-white hover:bg-blue-600;
}

.product-card__button--secondary {
    @apply bg-gray-200 text-gray-700 hover:bg-gray-300;
}

.product-card__button:disabled {
    @apply opacity-50 cursor-not-allowed;
}
```

`/views/components/_productCard.cfm`:
```cfm
<div class="product-card" 
     x-data="productCard({
         product: #SerializeJSON({
             id: arguments.product.id,
             name: arguments.product.name,
             price: arguments.product.price,
             image: arguments.product.imageUrl
         })#
     })">
    
    <img :src="product.image" 
         :alt="product.name" 
         class="product-card__image">
    
    <div class="product-card__content">
        <h3 class="product-card__title" x-text="product.name"></h3>
        <p class="product-card__price" x-text="formattedPrice"></p>
        
        <div class="product-card__actions">
            <button @click="addToCart" 
                    :disabled="isLoading"
                    class="product-card__button product-card__button--primary">
                <span x-show="!isLoading">Add to Cart</span>
                <span x-show="isLoading">Adding...</span>
            </button>
            
            <button @click="toggleFavorite" 
                    :disabled="isLoading"
                    class="product-card__button product-card__button--secondary">
                <span x-show="!isFavorite">♡</span>
                <span x-show="isFavorite">♥</span>
            </button>
        </div>
    </div>
</div>
```

### Generate JavaScript Module
```bash
wheels generate frontend module api --typescript
```

Would generate `/public/javascripts/modules/api.ts`:
```typescript
// API Module
interface RequestOptions extends RequestInit {
    params?: Record<string, any>;
}

interface ApiResponse<T = any> {
    data: T;
    meta?: Record<string, any>;
    errors?: Array<{
        field: string;
        message: string;
    }>;
}

class ApiClient {
    private baseUrl: string;
    private defaultHeaders: Record<string, string>;
    
    constructor(baseUrl: string = '/api') {
        this.baseUrl = baseUrl;
        this.defaultHeaders = {
            'Content-Type': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
        };
        
        // Add CSRF token if available
        const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content;
        if (csrfToken) {
            this.defaultHeaders['X-CSRF-Token'] = csrfToken;
        }
    }
    
    async request<T = any>(
        endpoint: string,
        options: RequestOptions = {}
    ): Promise<ApiResponse<T>> {
        const { params, ...fetchOptions } = options;
        
        // Build URL with params
        const url = new URL(this.baseUrl + endpoint, window.location.origin);
        if (params) {
            Object.entries(params).forEach(([key, value]) => {
                if (value !== undefined && value !== null) {
                    url.searchParams.append(key, String(value));
                }
            });
        }
        
        // Merge headers
        const headers = {
            ...this.defaultHeaders,
            ...fetchOptions.headers
        };
        
        try {
            const response = await fetch(url.toString(), {
                ...fetchOptions,
                headers
            });
            
            if (!response.ok) {
                throw new ApiError(response.status, await response.text());
            }
            
            const data = await response.json();
            return data;
            
        } catch (error) {
            if (error instanceof ApiError) {
                throw error;
            }
            throw new ApiError(0, 'Network error');
        }
    }
    
    get<T = any>(endpoint: string, params?: Record<string, any>): Promise<ApiResponse<T>> {
        return this.request<T>(endpoint, { method: 'GET', params });
    }
    
    post<T = any>(endpoint: string, data?: any): Promise<ApiResponse<T>> {
        return this.request<T>(endpoint, {
            method: 'POST',
            body: JSON.stringify(data)
        });
    }
    
    put<T = any>(endpoint: string, data?: any): Promise<ApiResponse<T>> {
        return this.request<T>(endpoint, {
            method: 'PUT',
            body: JSON.stringify(data)
        });
    }
    
    delete<T = any>(endpoint: string): Promise<ApiResponse<T>> {
        return this.request<T>(endpoint, { method: 'DELETE' });
    }
}

class ApiError extends Error {
    constructor(public status: number, message: string) {
        super(message);
        this.name = 'ApiError';
    }
}

// Export singleton instance
export const api = new ApiClient();

// Export types
export type { ApiResponse, RequestOptions };
export { ApiClient, ApiError };
```

### Generate HTMX Component
```bash
wheels generate frontend component searchForm --framework=htmx
```

Would generate:

`/views/components/_searchForm.cfm`:
```cfm
<form hx-get="/products/search" 
      hx-trigger="submit, keyup changed delay:500ms from:input[name='q']"
      hx-target="##search-results"
      hx-indicator="##search-spinner"
      class="search-form">
    
    <div class="search-form__input-group">
        <input type="search" 
               name="q" 
               value="#params.q ?: ''#"
               placeholder="Search products..."
               class="search-form__input">
        
        <button type="submit" class="search-form__button">
            Search
        </button>
    </div>
    
    <div class="search-form__filters">
        <select name="category" 
                hx-get="/products/search"
                hx-trigger="change"
                hx-target="##search-results"
                hx-include="[name='q']"
                class="search-form__select">
            <option value="">All Categories</option>
            <cfloop query="categories">
                <option value="#categories.id#" 
                        <cfif params.category == categories.id>selected</cfif>>
                    #categories.name#
                </option>
            </cfloop>
        </select>
        
        <select name="sort" 
                hx-get="/products/search"
                hx-trigger="change"
                hx-target="##search-results"
                hx-include="[name='q'],[name='category']"
                class="search-form__select">
            <option value="relevance">Relevance</option>
            <option value="price-asc">Price: Low to High</option>
            <option value="price-desc">Price: High to Low</option>
            <option value="name">Name</option>
        </select>
    </div>
</form>

<div id="search-spinner" class="htmx-indicator">
    <div class="spinner"></div>
</div>

<div id="search-results">
    <!--- Results will be loaded here --->
</div>
```

### Generate Vue Component
```bash
wheels generate frontend component todoList --framework=vue
```

Would generate `/public/javascripts/components/TodoList.vue`:
```vue
<template>
  <div class="todo-list">
    <h2>{{ title }}</h2>
    
    <form @submit.prevent="addTodo" class="todo-form">
      <input
        v-model="newTodo"
        type="text"
        placeholder="Add a new todo..."
        class="todo-form__input"
      >
      <button type="submit" class="todo-form__button">
        Add
      </button>
    </form>
    
    <ul class="todo-items">
      <li
        v-for="todo in filteredTodos"
        :key="todo.id"
        class="todo-item"
        :class="{ 'todo-item--completed': todo.completed }"
      >
        <input
          type="checkbox"
          v-model="todo.completed"
          @change="updateTodo(todo)"
        >
        <span class="todo-item__text">{{ todo.text }}</span>
        <button
          @click="deleteTodo(todo.id)"
          class="todo-item__delete"
        >
          ×
        </button>
      </li>
    </ul>
    
    <div class="todo-filters">
      <button
        v-for="filter in filters"
        :key="filter"
        @click="currentFilter = filter"
        :class="{ active: currentFilter === filter }"
        class="todo-filter"
      >
        {{ filter }}
      </button>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue';
import { api } from '../modules/api';

export default {
  name: 'TodoList',
  props: {
    title: {
      type: String,
      default: 'Todo List'
    }
  },
  setup() {
    const todos = ref([]);
    const newTodo = ref('');
    const currentFilter = ref('all');
    const filters = ['all', 'active', 'completed'];
    
    const filteredTodos = computed(() => {
      switch (currentFilter.value) {
        case 'active':
          return todos.value.filter(todo => !todo.completed);
        case 'completed':
          return todos.value.filter(todo => todo.completed);
        default:
          return todos.value;
      }
    });
    
    const loadTodos = async () => {
      try {
        const response = await api.get('/todos');
        todos.value = response.data;
      } catch (error) {
        console.error('Failed to load todos:', error);
      }
    };
    
    const addTodo = async () => {
      if (!newTodo.value.trim()) return;
      
      try {
        const response = await api.post('/todos', {
          text: newTodo.value,
          completed: false
        });
        todos.value.push(response.data);
        newTodo.value = '';
      } catch (error) {
        console.error('Failed to add todo:', error);
      }
    };
    
    const updateTodo = async (todo) => {
      try {
        await api.put(`/todos/${todo.id}`, {
          completed: todo.completed
        });
      } catch (error) {
        console.error('Failed to update todo:', error);
        todo.completed = !todo.completed;
      }
    };
    
    const deleteTodo = async (id) => {
      try {
        await api.delete(`/todos/${id}`);
        todos.value = todos.value.filter(todo => todo.id !== id);
      } catch (error) {
        console.error('Failed to delete todo:', error);
      }
    };
    
    onMounted(loadTodos);
    
    return {
      todos,
      newTodo,
      currentFilter,
      filters,
      filteredTodos,
      addTodo,
      updateTodo,
      deleteTodo
    };
  }
};
</script>

<style scoped>
.todo-list {
  max-width: 500px;
  margin: 0 auto;
}

.todo-form {
  display: flex;
  margin-bottom: 1rem;
}

.todo-form__input {
  flex: 1;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px 0 0 4px;
}

.todo-form__button {
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 0 4px 4px 0;
  cursor: pointer;
}

.todo-items {
  list-style: none;
  padding: 0;
}

.todo-item {
  display: flex;
  align-items: center;
  padding: 0.5rem;
  border-bottom: 1px solid #eee;
}

.todo-item--completed .todo-item__text {
  text-decoration: line-through;
  opacity: 0.6;
}

.todo-item__delete {
  margin-left: auto;
  background: none;
  border: none;
  color: #dc3545;
  font-size: 1.5rem;
  cursor: pointer;
}

.todo-filters {
  display: flex;
  gap: 0.5rem;
  margin-top: 1rem;
}

.todo-filter {
  padding: 0.25rem 0.75rem;
  border: 1px solid #ddd;
  background: white;
  cursor: pointer;
  border-radius: 4px;
}

.todo-filter.active {
  background: #007bff;
  color: white;
  border-color: #007bff;
}
</style>
```

## Workaround Implementation

Until the command is fixed, create frontend assets manually:

### 1. Directory Structure
```
/public/
├── javascripts/
│   ├── app.js
│   ├── components/
│   ├── modules/
│   └── vendor/
├── stylesheets/
│   ├── app.css
│   ├── components/
│   └── vendor/
└── images/
```

### 2. Basic App Structure

`/public/javascripts/app.js`:
```javascript
// Main application JavaScript
(function() {
    'use strict';
    
    // Initialize on DOM ready
    document.addEventListener('DOMContentLoaded', function() {
        initializeComponents();
        setupEventListeners();
        loadDynamicContent();
    });
    
    function initializeComponents() {
        // Initialize all components
        document.querySelectorAll('[data-component]').forEach(element => {
            const componentName = element.dataset.component;
            if (window.components && window.components[componentName]) {
                new window.components[componentName](element);
            }
        });
    }
    
    function setupEventListeners() {
        // Global event delegation
        document.addEventListener('click', handleClick);
        document.addEventListener('submit', handleSubmit);
    }
    
    function handleClick(event) {
        // Handle data-action clicks
        const action = event.target.closest('[data-action]');
        if (action) {
            event.preventDefault();
            const actionName = action.dataset.action;
            // Handle action
        }
    }
    
    function handleSubmit(event) {
        // Handle AJAX forms
        const form = event.target;
        if (form.dataset.remote === 'true') {
            event.preventDefault();
            submitFormAjax(form);
        }
    }
    
    function submitFormAjax(form) {
        const formData = new FormData(form);
        
        fetch(form.action, {
            method: form.method,
            body: formData,
            headers: {
                'X-Requested-With': 'XMLHttpRequest'
            }
        })
        .then(response => response.json())
        .then(data => {
            // Handle response
        })
        .catch(error => {
            console.error('Form submission error:', error);
        });
    }
    
    function loadDynamicContent() {
        // Load content marked for lazy loading
        const lazyElements = document.querySelectorAll('[data-lazy-load]');
        
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    loadContent(entry.target);
                    observer.unobserve(entry.target);
                }
            });
        });
        
        lazyElements.forEach(el => observer.observe(el));
    }
    
    function loadContent(element) {
        const url = element.dataset.lazyLoad;
        fetch(url)
            .then(response => response.text())
            .then(html => {
                element.innerHTML = html;
                initializeComponents();
            });
    }
    
})();
```

### 3. CSS Structure

`/public/stylesheets/app.css`:
```css
/* Base styles */
:root {
    --primary-color: #007bff;
    --secondary-color: #6c757d;
    --success-color: #28a745;
    --danger-color: #dc3545;
    --warning-color: #ffc107;
    --info-color: #17a2b8;
    --light-color: #f8f9fa;
    --dark-color: #343a40;
}

/* Layout */
.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 1rem;
}

/* Components */
@import 'components/buttons.css';
@import 'components/forms.css';
@import 'components/cards.css';
@import 'components/modals.css';

/* Utilities */
.hidden {
    display: none !important;
}

.loading {
    opacity: 0.6;
    pointer-events: none;
}

/* Animations */
@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}

.fade-in {
    animation: fadeIn 0.3s ease-in;
}
```

## Best Practices

1. **Organize by feature**: Group related files together
2. **Use modules**: Keep code modular and reusable
3. **Follow conventions**: Consistent naming and structure
4. **Progressive enhancement**: Work without JavaScript
5. **Optimize performance**: Minimize and bundle assets
6. **Test components**: Unit and integration tests
7. **Document APIs**: Clear component documentation
8. **Handle errors**: Graceful error handling
9. **Accessibility**: ARIA labels and keyboard support
10. **Security**: Validate inputs, use CSRF tokens

## See Also

- [wheels generate view](view.md) - Generate view files
- [wheels generate controller](controller.md) - Generate controllers
- [wheels scaffold](scaffold.md) - Generate complete CRUD