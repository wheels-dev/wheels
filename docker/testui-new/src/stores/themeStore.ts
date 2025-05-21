import { defineStore } from 'pinia';
import { ref, onMounted } from 'vue';
import { getInitialTheme, toggleTheme, setupThemeListener } from '@/utils/theme';
import type { Theme } from '@/utils/theme';

export const useThemeStore = defineStore('theme', () => {
  // State
  const theme = ref<Theme>('light');
  
  // Actions
  function setTheme(newTheme: Theme) {
    theme.value = newTheme;
    document.documentElement.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
  }
  
  function toggleCurrentTheme() {
    const newTheme = toggleTheme(theme.value);
    setTheme(newTheme);
    return newTheme;
  }
  
  // Initialize theme on mount
  onMounted(() => {
    // Set initial theme
    setTheme(getInitialTheme());
    
    // Set up listener for system theme changes
    setupThemeListener(setTheme);
  });
  
  return {
    theme,
    setTheme,
    toggleCurrentTheme
  };
});