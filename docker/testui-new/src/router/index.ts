import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView
    },
    {
      path: '/tests',
      name: 'tests',
      // Route level code-splitting - generates a separate chunk
      component: () => import('../views/TestsView.vue')
    }
  ]
})

export default router