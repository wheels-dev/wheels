# UI Modernization Specification

This document details the UI modernization plan for the CFWheels TestUI, including theme support, component design, and overall visual refresh.

## Current UI Assessment

The current TestUI uses:
- Bootstrap 4.4.1 for styling (outdated)
- Plain HTML/JS with no modern framework
- Basic layout with limited interactivity
- No theme support (light mode only)
- Limited responsive design considerations

## UI Modernization Strategy

### Framework and Build System

#### Technology Choices

- **Vue.js 3**: Modern, lightweight framework with Composition API
  - Component-based architecture
  - Reactive state management
  - TypeScript support
  - SFC (Single File Component) pattern

- **Vite**: Fast, modern build tool
  - Hot Module Replacement (HMR)
  - ES module-based dev server
  - Optimized production builds
  - Plugin ecosystem

- **TypeScript**: Enhanced type safety
  - Type definitions for components, props, and state
  - Improved developer experience
  - Better refactoring support
  - Reduced runtime errors

#### UI Component Library

- **Tailwind CSS**: Utility-first styling framework
  - Consistent design system
  - Customizable via configuration
  - Built-in responsive design utilities
  - Low CSS footprint with purging

- **DaisyUI**: Tailwind component library
  - Pre-built, customizable components
  - Theme support out of the box
  - Semantic component names
  - Accessibility considerations

### Theme Implementation

#### Dark/Light Theme System

- **Theme Toggle**:
  - Prominent placement in header/navbar
  - Icon-based toggle (sun/moon)
  - Keyboard shortcut support (Alt+T)
  - Remembers user preference

- **Theme Detection**:
  - Initial theme based on system preference
  - `prefers-color-scheme` media query
  - Override with manual selection
  - Graceful fallback to light theme

- **Theme Storage**:
  - Save theme preference in localStorage
  - Apply theme immediately on page load
  - Synchronize across tabs

#### Color Palettes

- **Base Colors** (with dark/light variants):
  - Primary: #3B82F6 (blue-500)
  - Secondary: #10B981 (emerald-500)
  - Accent: #8B5CF6 (violet-500)
  - Neutral: #6B7280 (gray-500)
  - Error: #EF4444 (red-500)
  - Warning: #F59E0B (amber-500)
  - Success: #10B981 (emerald-500)
  - Info: #3B82F6 (blue-500)

- **Background Colors**:
  - Light mode: #FFFFFF (white), #F3F4F6 (gray-100)
  - Dark mode: #1F2937 (gray-800), #111827 (gray-900)

- **Text Colors**:
  - Light mode: #111827 (gray-900), #374151 (gray-700)
  - Dark mode: #F9FAFB (gray-50), #D1D5DB (gray-300)

- **Border and Shadow**:
  - Light mode: subtle shadows, light borders
  - Dark mode: stronger shadows, darker borders

#### Theme Transitions

- Smooth transitions between themes:
  - CSS transitions for color properties
  - Subtle animation duration (150-300ms)
  - Consistent timing across elements

### Layout Redesign

#### Responsive Layout Structure

- **Container Layout**:
  - Sidebar + Main Content pattern
  - Collapsible sidebar on smaller screens
  - Full-width content on mobile
  - Adaptive breakpoints (sm, md, lg, xl)

- **Grid System**:
  - Flexible grid using CSS Grid and Flexbox
  - Auto-adjusting columns based on screen size
  - Consistent spacing between elements
  - Equal height cards in rows

- **Navigation**:
  - Sidebar navigation on desktop
  - Bottom tabs or drawer on mobile
  - Breadcrumbs for nested screens
  - Persistent header with key actions

#### Component Design

- **Card Components**:
  - Subtle shadows and rounded corners
  - Consistent padding and spacing
  - Header, body, footer structure
  - Interactive hover/focus states

- **Form Elements**:
  - Custom styled inputs and selects
  - Clear focus states
  - Inline validation
  - Accessible labels and hints

- **Buttons and Controls**:
  - Clear visual hierarchy
  - Consistent sizing and padding
  - Hover/active/focus states
  - Icon + text combinations

- **Status Indicators**:
  - Color-coded badges (success, error, warning)
  - Progress indicators for operations
  - Loading states for async actions
  - Empty states for no-content scenarios

### Animations and Interactions

- **Micro-interactions**:
  - Subtle feedback on user actions
  - Loading indicators
  - Transition effects between states
  - Hover animations

- **Page Transitions**:
  - Smooth transitions between views
  - Fade in/out effects
  - Slide transitions for related content
  - Maintain scroll position where appropriate

- **Skeleton Screens**:
  - Placeholder content during loading
  - Progressive loading of content
  - Avoid layout shifts

### Accessibility Considerations

- **Color Contrast**:
  - WCAG AA compliance for all text
  - Sufficient contrast in both themes
  - Non-color indicators for status

- **Keyboard Navigation**:
  - Logical tab order
  - Focus indicators
  - Keyboard shortcuts for common actions
  - Skip links for screen readers

- **Screen Reader Support**:
  - Semantic HTML
  - ARIA labels where needed
  - Accessible notifications
  - Alternative text for visual elements

## UI Component Specifications

### Header Component

```vue
<template>
  <header class="app-header">
    <div class="logo-container">
      <img src="/wheels_logo.png" alt="CFWheels Logo" class="logo">
      <h1 class="app-title">Test UI</h1>
    </div>
    
    <div class="controls">
      <ThemeToggle />
      <StatusIndicator :status="systemStatus" />
      <button class="btn btn-sm" @click="showSettings">
        <SettingsIcon />
      </button>
    </div>
  </header>
</template>
```

### Sidebar Component

```vue
<template>
  <aside class="sidebar" :class="{ 'sidebar-collapsed': isCollapsed }">
    <button class="collapse-toggle" @click="toggleCollapse">
      <ChevronIcon :direction="isCollapsed ? 'right' : 'left'" />
    </button>
    
    <nav class="nav-menu">
      <section class="nav-section">
        <h3 class="section-title">Tests</h3>
        <ul class="nav-list">
          <li><NavLink to="/tests">Run Tests</NavLink></li>
          <li><NavLink to="/results">Results</NavLink></li>
          <li><NavLink to="/history">History</NavLink></li>
        </ul>
      </section>
      
      <section class="nav-section">
        <h3 class="section-title">Docker</h3>
        <ul class="nav-list">
          <li><NavLink to="/containers">Containers</NavLink></li>
          <li><NavLink to="/profiles">Profiles</NavLink></li>
          <li><NavLink to="/logs">Logs</NavLink></li>
        </ul>
      </section>
    </nav>
    
    <div class="sidebar-footer">
      <SystemStatus />
    </div>
  </aside>
</template>
```

### Theme Toggle Component

```vue
<template>
  <button 
    class="theme-toggle" 
    @click="toggleTheme" 
    :aria-label="isDark ? 'Switch to light theme' : 'Switch to dark theme'"
  >
    <SunIcon v-if="isDark" />
    <MoonIcon v-else />
  </button>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { useThemeStore } from '../stores/theme'

const themeStore = useThemeStore()
const isDark = ref(themeStore.isDark)

function toggleTheme() {
  themeStore.toggleTheme()
  isDark.value = themeStore.isDark
}

onMounted(() => {
  // Initialize based on system preference or stored setting
  themeStore.initTheme()
  isDark.value = themeStore.isDark
})

watch(() => themeStore.isDark, (newValue) => {
  isDark.value = newValue
})
</script>
```

### Card Component

```vue
<template>
  <div 
    class="card" 
    :class="{ 
      'card-bordered': bordered,
      [`card-${variant}`]: variant
    }"
  >
    <div v-if="$slots.header || title" class="card-header">
      <slot name="header">
        <h3 class="card-title">{{ title }}</h3>
      </slot>
    </div>
    
    <div class="card-body">
      <slot></slot>
    </div>
    
    <div v-if="$slots.footer" class="card-footer">
      <slot name="footer"></slot>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps({
  title: {
    type: String,
    default: ''
  },
  variant: {
    type: String,
    default: 'default',
    validator: (value: string) => 
      ['default', 'primary', 'secondary', 'accent', 'info', 'success', 'warning', 'error'].includes(value)
  },
  bordered: {
    type: Boolean,
    default: true
  }
})
</script>
```

## Tailwind Configuration

```javascript
// tailwind.config.js
module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Custom color palette
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      spacing: {
        // Custom spacing values
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-in-out',
        'slide-in': 'slideIn 0.3s ease-in-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideIn: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
    },
  },
  plugins: [
    require('daisyui'),
  ],
  daisyui: {
    themes: [
      {
        light: {
          // DaisyUI light theme customization
        },
        dark: {
          // DaisyUI dark theme customization
        },
      },
    ],
  },
}
```

## Theme Store Implementation

```typescript
// src/stores/theme.ts
import { defineStore } from 'pinia'

export const useThemeStore = defineStore('theme', {
  state: () => ({
    darkMode: false,
  }),
  
  getters: {
    isDark: (state) => state.darkMode,
  },
  
  actions: {
    initTheme() {
      // Check localStorage first
      const savedTheme = localStorage.getItem('theme')
      
      if (savedTheme) {
        this.darkMode = savedTheme === 'dark'
      } else {
        // Check system preference
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
        this.darkMode = prefersDark
      }
      
      this.applyTheme()
    },
    
    toggleTheme() {
      this.darkMode = !this.darkMode
      localStorage.setItem('theme', this.darkMode ? 'dark' : 'light')
      this.applyTheme()
    },
    
    applyTheme() {
      if (this.darkMode) {
        document.documentElement.classList.add('dark')
      } else {
        document.documentElement.classList.remove('dark')
      }
    },
  },
})
```

## Implementation Guidelines

1. Start with theme implementation as it affects all components
2. Create base layout components (Header, Sidebar, Footer)
3. Develop reusable UI components (Cards, Buttons, Inputs)
4. Implement responsive design patterns
5. Add animations and transitions last

## Acceptance Criteria

- UI should be fully responsive from mobile to desktop
- Theme toggle should work and persist user preference
- All components should adapt correctly to both themes
- Animations should be subtle and enhance usability
- UI should be accessible and WCAG AA compliant
- Performance should be maintained with smooth interactions