/**
 * Theme utilities for managing dark/light mode
 */

export type Theme = 'light' | 'dark';

// Get the initial theme from localStorage or system preference
export function getInitialTheme(): Theme {
  // Check for theme in localStorage
  const savedTheme = localStorage.getItem('theme') as Theme;
  if (savedTheme === 'light' || savedTheme === 'dark') {
    return savedTheme;
  }
  
  // Check system preference
  if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
    return 'dark';
  }
  
  return 'light';
}

// Toggle between dark and light mode
export function toggleTheme(currentTheme: Theme): Theme {
  const newTheme = currentTheme === 'light' ? 'dark' : 'light';
  localStorage.setItem('theme', newTheme);
  return newTheme;
}

// Set up listener for system theme changes
export function setupThemeListener(callback: (theme: Theme) => void): () => void {
  const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  
  const listener = (e: MediaQueryListEvent) => {
    // Only change if no user preference is stored
    if (!localStorage.getItem('theme')) {
      callback(e.matches ? 'dark' : 'light');
    }
  };
  
  mediaQuery.addEventListener('change', listener);
  
  // Return cleanup function
  return () => mediaQuery.removeEventListener('change', listener);
}