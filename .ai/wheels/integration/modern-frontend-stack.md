# CFWheels Modern Frontend Integration

## Integrating Tailwind CSS, HTMX, and Alpine.js with CFWheels

This guide documents successful patterns for integrating modern frontend technologies with CFWheels applications, based on real-world blog development.

## Complete Stack Integration

### Layout Foundation
```cfm
<!--- app/views/layout.cfm --->
<!DOCTYPE html>
<html lang="en" class="h-full">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <cfoutput>#csrfMetaTags()#</cfoutput>
    <title><cfoutput>#contentFor("title", "My CFWheels App")#</cfoutput></title>

    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        'sans': ['Inter', 'system-ui', 'sans-serif'],
                    }
                }
            }
        }
    </script>

    <!-- Alpine.js -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>

    <!-- HTMX -->
    <script src="https://unpkg.com/htmx.org@1.9.10"></script>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
</head>

<body class="h-full bg-gray-50 font-sans">
    <!-- Navigation -->
    <nav class="bg-white shadow-sm border-b">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center h-16">
                <div class="flex items-center">
                    <cfoutput>
                        #linkTo(controller="posts", action="index", text="My Blog", class="text-xl font-bold text-gray-900 hover:text-blue-600 transition-colors")#
                    </cfoutput>
                </div>

                <!-- Desktop Navigation -->
                <div class="hidden md:block">
                    <div class="ml-10 flex items-baseline space-x-4">
                        <cfoutput>
                            #linkTo(controller="posts", action="index", text="Home", class="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium transition-colors")#
                            #linkTo(controller="posts", action="new", text="Write Post", class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors")#
                        </cfoutput>
                    </div>
                </div>

                <!-- Mobile menu button (Alpine.js) -->
                <div class="md:hidden" x-data="{ open: false }">
                    <button @click="open = !open" class="text-gray-600 hover:text-gray-900">
                        <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                        </svg>
                    </button>

                    <!-- Mobile menu -->
                    <div x-show="open" @click.away="open = false" class="absolute top-16 right-4 bg-white rounded-md shadow-lg py-2 w-48 z-50">
                        <cfoutput>
                            #linkTo(controller="posts", action="index", text="Home", class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100")#
                            #linkTo(controller="posts", action="new", text="Write Post", class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100")#
                        </cfoutput>
                    </div>
                </div>
            </div>
        </div>
    </nav>

    <!-- Main Content -->
    <main class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
        <!-- Flash Messages -->
        <div id="flash-messages" class="mb-6">
            <cfoutput>#flashMessages()#</cfoutput>
        </div>

        <!-- Page Content -->
        <cfoutput>#includeContent()#</cfoutput>
    </main>

    <!-- Footer -->
    <footer class="bg-white border-t mt-12">
        <div class="max-w-7xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
            <div class="text-center text-gray-600">
                <p>&copy; <cfoutput>#Year(Now())#</cfoutput> My App. Built with CFWheels, Tailwind CSS, HTMX, and Alpine.js.</p>
            </div>
        </div>
    </footer>

    <!-- Custom Styles for Flash Messages -->
    <style>
        .flash-message {
            @apply p-4 rounded-md mb-4;
        }
        .flash-success {
            @apply bg-green-50 border border-green-200 text-green-800;
        }
        .flash-error {
            @apply bg-red-50 border border-red-200 text-red-800;
        }
        .flash-notice {
            @apply bg-blue-50 border border-blue-200 text-blue-800;
        }
    </style>
</body>
</html>
```

## Component Patterns

### 1. Responsive Grid Layout (Tailwind CSS)
```cfm
<!-- Blog posts grid that adapts to screen size -->
<div class="grid gap-8 lg:grid-cols-2 xl:grid-cols-3">
    <cfif posts.recordCount>
        <cfloop query="posts">
            <article class="bg-white rounded-lg shadow-sm border hover:shadow-md transition-shadow">
                <div class="p-6">
                    <h2 class="text-xl font-bold text-gray-900 mb-3 line-clamp-2">
                        <cfoutput>
                            #linkTo(controller="posts", action="show", key=posts.id, text=posts.title, class="hover:text-blue-600 transition-colors")#
                        </cfoutput>
                    </h2>

                    <div class="text-gray-600 mb-4 line-clamp-3">
                        <cfoutput>
                            #Left(ReReplace(posts.content, "<[^>]*>", "", "all"), 150)#<cfif Len(posts.content) gt 150>...</cfif>
                        </cfoutput>
                    </div>

                    <div class="flex items-center justify-between text-sm text-gray-500">
                        <span><cfoutput>#DateFormat(posts.publishedAt, "mmm d, yyyy")#</cfoutput></span>
                        <cfoutput>
                            #linkTo(controller="posts", action="edit", key=posts.id, text="Edit", class="text-blue-600 hover:text-blue-800")#
                        </cfoutput>
                    </div>
                </div>
            </article>
        </cfloop>
    </cfif>
</div>
```

### 2. Interactive Components (Alpine.js)
```cfm
<!-- Collapsible comment section -->
<div x-data="{ showComments: false, commentCount: #comments.recordCount# }">
    <button @click="showComments = !showComments" class="flex items-center space-x-2 text-gray-600 hover:text-gray-900">
        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M18 10c0 3.866-3.582 7-8 7a8.841 8.841 0 01-4.083-.98L2 17l1.338-3.123C2.493 12.767 2 11.434 2 10c0-3.866 3.582-7 8-7s8 3.134 8 7z" clip-rule="evenodd"></path>
        </svg>
        <span x-text="showComments ? 'Hide Comments' : 'Show Comments'"></span>
        <span x-text="'(' + commentCount + ')'"></span>
    </button>

    <div x-show="showComments" x-transition class="mt-4">
        <cfif comments.recordCount>
            <cfloop query="comments">
                <div class="border-b border-gray-200 py-4">
                    <div class="flex items-start space-x-3">
                        <img class="h-8 w-8 rounded-full" src="<cfoutput>#model('Comment').findByKey(comments.id).getGravatarUrl(32)#</cfoutput>" alt="">
                        <div class="flex-1">
                            <h4 class="text-sm font-medium"><cfoutput>#comments.authorName#</cfoutput></h4>
                            <p class="text-sm text-gray-600 mt-1"><cfoutput>#comments.content#</cfoutput></p>
                        </div>
                    </div>
                </div>
            </cfloop>
        </cfif>
    </div>
</div>
```

### 3. Form Enhancement (HTMX)
```cfm
<!-- Dynamic form submission without page reload -->
<div id="comment-form">
    #startFormTag(controller="comments", action="create",
                  class="space-y-4",
                  "hx-post"="/comments",
                  "hx-target"="##comment-form-result",
                  "hx-swap"="innerHTML")#

        #hiddenFieldTag(name="comment[postId]", value=post.id)#

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div>
                <cfoutput>
                    #textField(objectName="comment", property="authorName",
                              label="Name *",
                              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500")#
                </cfoutput>
            </div>
            <div>
                <cfoutput>
                    #textField(objectName="comment", property="authorEmail",
                              label="Email *",
                              type="email",
                              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500")#
                </cfoutput>
            </div>
        </div>

        <div>
            <cfoutput>
                #textArea(objectName="comment", property="content",
                         label="Comment *",
                         rows="4",
                         class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500",
                         placeholder="Share your thoughts...")#
            </cfoutput>
        </div>

        <div>
            <cfoutput>
                #submitTag(value="Post Comment",
                          class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-md font-medium transition-colors")#
            </cfoutput>
        </div>

    #endFormTag()#

    <!-- HTMX will replace this div with server response -->
    <div id="comment-form-result" class="mt-4"></div>
</div>
```

## Advanced Patterns

### 4. Modal Dialogs (Alpine.js + Tailwind)
```cfm
<!-- Delete confirmation modal -->
<div x-data="{ showModal: false }">
    <button @click="showModal = true" class="text-red-600 hover:text-red-800">Delete Post</button>

    <!-- Modal backdrop -->
    <div x-show="showModal" class="fixed inset-0 z-50 overflow-y-auto" style="display: none;">
        <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <!-- Background overlay -->
            <div x-show="showModal" @click="showModal = false"
                 x-transition:enter="ease-out duration-300" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100"
                 x-transition:leave="ease-in duration-200" x-transition:leave-start="opacity-100" x-transition:leave-end="opacity-0"
                 class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>

            <!-- Modal panel -->
            <div x-show="showModal"
                 x-transition:enter="ease-out duration-300" x-transition:enter-start="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95" x-transition:enter-end="opacity-100 translate-y-0 sm:scale-100"
                 x-transition:leave="ease-in duration-200" x-transition:leave-start="opacity-100 translate-y-0 sm:scale-100" x-transition:leave-end="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
                 class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">

                <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                    <h3 class="text-lg leading-6 font-medium text-gray-900">Delete Post</h3>
                    <p class="mt-2 text-sm text-gray-500">Are you sure you want to delete this post? This action cannot be undone.</p>
                </div>

                <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                    <cfoutput>
                        #linkTo(controller="posts", action="delete", key=post.id,
                               text="Delete",
                               method="delete",
                               class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 sm:ml-3 sm:w-auto sm:text-sm")#
                    </cfoutput>
                    <button @click="showModal = false" type="button" class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
                        Cancel
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>
```

### 5. Live Search (HTMX + Alpine.js)
```cfm
<!-- Search with live results -->
<div x-data="{ query: '', loading: false }" class="relative">
    <input x-model="query"
           @input.debounce.300ms="loading = true"
           hx-get="/search"
           hx-trigger="input changed delay:300ms"
           hx-target="#search-results"
           hx-indicator="#search-loading"
           class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
           placeholder="Search posts...">

    <!-- Loading indicator -->
    <div id="search-loading" class="htmx-indicator absolute right-3 top-3">
        <svg class="animate-spin h-4 w-4 text-blue-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
    </div>

    <!-- Results container -->
    <div id="search-results" class="absolute z-10 w-full bg-white shadow-lg rounded-md mt-1 max-h-96 overflow-y-auto"></div>
</div>
```

## Performance Optimizations

### CSS Optimizations
```html
<!-- Custom CSS for better performance -->
<style>
    /* Line clamping for consistent layouts */
    .line-clamp-2 {
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }

    .line-clamp-3 {
        display: -webkit-box;
        -webkit-line-clamp: 3;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }

    /* HTMX loading states */
    .htmx-indicator {
        display: none;
    }

    .htmx-request .htmx-indicator {
        display: block;
    }

    /* Smooth transitions */
    .transition-all {
        transition: all 0.3s ease;
    }
</style>
```

### JavaScript Optimizations
```html
<!-- Defer non-critical JavaScript -->
<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>

<!-- Configure HTMX for better UX -->
<script>
    document.addEventListener('DOMContentLoaded', function() {
        // Global HTMX configuration
        htmx.config.globalViewTransitions = true;
        htmx.config.scrollBehavior = 'smooth';

        // Custom HTMX events
        document.body.addEventListener('htmx:beforeSwap', function(evt) {
            if (evt.detail.xhr.status === 422) {
                // Handle validation errors
                evt.detail.shouldSwap = true;
                evt.detail.isError = false;
            }
        });
    });
</script>
```

## Integration with CFWheels Features

### Flash Messages with Tailwind Styling
```cfm
<!-- Custom flash message styling -->
<cffunction name="flashMessages" returntype="string" output="false">
    <cfset var flashTypes = "success,error,notice,warning">
    <cfset var output = "">

    <cfloop list="#flashTypes#" index="type">
        <cfif flashKeyExists(type)>
            <cfset var cssClass = "">
            <cfswitch expression="#type#">
                <cfcase value="success">
                    <cfset cssClass = "bg-green-50 border border-green-200 text-green-800">
                </cfcase>
                <cfcase value="error">
                    <cfset cssClass = "bg-red-50 border border-red-200 text-red-800">
                </cfcase>
                <cfcase value="notice">
                    <cfset cssClass = "bg-blue-50 border border-blue-200 text-blue-800">
                </cfcase>
                <cfcase value="warning">
                    <cfset cssClass = "bg-yellow-50 border border-yellow-200 text-yellow-800">
                </cfcase>
            </cfswitch>

            <cfset output &= "<div class='#cssClass# p-4 rounded-md mb-4'>#flash(type)#</div>">
        </cfif>
    </cfloop>

    <cfreturn output>
</cffunction>
```

### Form Validation with Tailwind Error States
```cfm
<!-- Enhanced form field with error styling -->
<cffunction name="enhancedTextField" returntype="string" output="false">
    <cfargument name="objectName" type="string" required="true">
    <cfargument name="property" type="string" required="true">
    <cfargument name="label" type="string" required="false">
    <cfargument name="class" type="string" required="false" default="">

    <cfset var hasError = model(arguments.objectName).hasErrors(arguments.property)>
    <cfset var errorClass = hasError ? "border-red-300 focus:border-red-500 focus:ring-red-500" : "border-gray-300 focus:border-blue-500 focus:ring-blue-500">
    <cfset var finalClass = "mt-1 block w-full rounded-md shadow-sm #errorClass# #arguments.class#">

    <cfset var output = "">

    <cfif structKeyExists(arguments, "label")>
        <cfset output &= "<label class='block text-sm font-medium text-gray-700'>#arguments.label#</label>">
    </cfif>

    <cfset output &= textField(objectName=arguments.objectName, property=arguments.property, class=finalClass)>

    <cfif hasError>
        <cfset output &= "<p class='mt-1 text-sm text-red-600'>#model(arguments.objectName).allErrors(arguments.property)[1]#</p>">
    </cfif>

    <cfreturn output>
</cffunction>
```

## Best Practices

### 1. CDN vs Local Assets
```cfm
<!-- Development: Use CDN for faster iteration -->
<script src="https://cdn.tailwindcss.com"></script>

<!-- Production: Download and serve locally -->
<!-- <link href="/stylesheets/tailwind.min.css" rel="stylesheet"> -->
```

### 2. Progressive Enhancement
```cfm
<!-- Ensure basic functionality works without JavaScript -->
<noscript>
    <style>
        [x-cloak] { display: none !important; }
        .htmx-indicator { display: none !important; }
    </style>
</noscript>

<!-- Hide Alpine.js components until loaded -->
<div x-data="{ loaded: false }" x-init="loaded = true" x-cloak>
    <div x-show="loaded">
        <!-- Content here -->
    </div>
</div>
```

### 3. Accessibility Considerations
```cfm
<!-- ARIA labels and roles -->
<button @click="showMenu = !showMenu"
        :aria-expanded="showMenu"
        aria-label="Toggle navigation menu"
        class="md:hidden">
    <span class="sr-only">Open main menu</span>
    <!-- Icon -->
</button>

<!-- Semantic HTML structure -->
<main role="main" aria-label="Main content">
    <cfoutput>#includeContent()#</cfoutput>
</main>
```

This integration pattern was successfully tested in a real CFWheels blog application, demonstrating seamless compatibility between traditional server-side rendering and modern frontend technologies.