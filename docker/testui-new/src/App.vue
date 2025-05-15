<template>
  <div :class="{ 'dark-theme': theme === 'dark', 'bg-dark text-light': theme === 'dark' }">
    <nav class="navbar navbar-expand-lg" :class="theme === 'dark' ? 'navbar-dark bg-dark' : 'navbar-light bg-light'">
      <div class="container-fluid">
        <a class="navbar-brand d-flex align-items-center" href="#">
          <div class="logo-container me-2">
            <img 
              :src="theme === 'dark' ? '/wheels_logo_transparancy_white.png' : '/wheels_logo_transparancy_black.png'" 
              alt="CFWheels Logo" 
              height="30" 
              class="d-inline-block align-top" 
            />
          </div>
          <span class="fw-bold">Test UI</span>
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
          <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
          <ul class="navbar-nav me-auto">
            <li class="nav-item">
              <router-link class="nav-link" to="/">Dashboard</router-link>
            </li>
            <li class="nav-item">
              <router-link class="nav-link" to="/tests">Tests</router-link>
            </li>
          </ul>
          <div class="d-flex align-items-center">
            <span 
              v-if="usingMockData" 
              class="badge bg-warning me-3 d-flex align-items-center"
              title="Using mock data - Docker API connection issue detected"
            >
              <i class="bi bi-exclamation-triangle-fill me-1"></i> Mock Data
            </span>
            <button 
              @click="toggleTheme" 
              class="btn btn-sm" 
              :class="theme === 'dark' ? 'btn-outline-light' : 'btn-outline-dark'"
            >
              <span v-if="theme === 'dark'">
                <i class="bi bi-sun-fill"></i> Light
              </span>
              <span v-else>
                <i class="bi bi-moon-fill"></i> Dark
              </span>
            </button>
          </div>
        </div>
      </div>
    </nav>

    <main class="container-fluid py-4">
      <router-view />
    </main>

    <footer class="footer py-3 mt-auto" :class="theme === 'dark' ? 'bg-dark text-light border-top border-secondary' : 'bg-light text-dark border-top'">
      <div class="container text-center">
        <span>CFWheels Test Environment</span>
        <span class="badge bg-primary ms-2">v1.0</span>
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch, provide, computed } from 'vue'
import { dockerService } from '@/services/docker.service'

const theme = ref('dark')
const usingMockData = ref(false)

// Provide theme to all components
provide('theme', theme)

// Check mock data status every 10 seconds
const checkMockDataStatus = () => {
  usingMockData.value = dockerService.usingMockData
}

const toggleTheme = () => {
  theme.value = theme.value === 'light' ? 'dark' : 'light'
  localStorage.setItem('theme', theme.value)
  updateBodyClass()
}

// Update body class to properly apply theme styles
const updateBodyClass = () => {
  if (theme.value === 'dark') {
    document.body.classList.add('dark-theme')
    document.documentElement.classList.add('dark-theme')
  } else {
    document.body.classList.remove('dark-theme')
    document.documentElement.classList.remove('dark-theme')
  }
}

// Check for system preference on first load
onMounted(() => {
  // First check local storage
  const savedTheme = localStorage.getItem('theme')
  if (savedTheme) {
    theme.value = savedTheme
  } else {
    // Then check system preference
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      theme.value = 'dark'
    }
  }
  
  // Apply theme immediately
  updateBodyClass()
  
  // Check mock data status initially and set up interval
  checkMockDataStatus()
  const mockStatusInterval = setInterval(checkMockDataStatus, 5000)
  
  // Listen for system preference changes
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    // Only change if user hasn't manually set a preference
    if (!localStorage.getItem('theme')) {
      theme.value = e.matches ? 'dark' : 'light'
      updateBodyClass()
    }
  })
  
  // Clean up interval on component unmount
  return () => clearInterval(mockStatusInterval)
})

// Watch for theme changes to apply them
watch(theme, () => {
  updateBodyClass()
})
</script>