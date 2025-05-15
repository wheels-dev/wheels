<template>
  <div class="card mb-2" :class="{
    'border-success': result.status === 'passed',
    'border-danger': result.status === 'failed' || result.status === 'error',
    'border-warning': result.status === 'running',
    'border-info': result.status === 'pending'
  }">
    <div 
      class="card-header py-2 d-flex justify-content-between align-items-center cursor-pointer"
      @click="expanded = !expanded"
    >
      <span :class="{
        'text-success': result.status === 'passed',
        'text-danger': result.status === 'failed' || result.status === 'error',
        'text-warning': result.status === 'running',
      }">
        <i v-if="result.status === 'passed'" class="bi bi-check-circle-fill me-1"></i>
        <i v-else-if="result.status === 'failed' || result.status === 'error'" class="bi bi-x-circle-fill me-1"></i>
        <i v-else-if="result.status === 'running'" class="bi bi-arrow-clockwise me-1"></i>
        <i v-else-if="result.status === 'pending'" class="bi bi-hourglass me-1"></i>
        {{ result.name }}
      </span>
      <div>
        <StatusBadge :status="result.status" />
        <small class="text-muted ms-2">{{ formatDuration(result.duration) }}</small>
        <button class="btn btn-sm btn-link ms-2 p-0">
          <i 
            class="bi" 
            :class="expanded ? 'bi-chevron-up' : 'bi-chevron-down'"
          ></i>
        </button>
      </div>
    </div>
    <div v-if="expanded && (result.status === 'failed' || result.status === 'error')" class="card-body py-3 bg-danger bg-opacity-10">
      <div class="alert alert-danger mb-2">
        <i class="bi bi-exclamation-triangle-fill me-2"></i>
        <strong>{{ result.error?.message || 'Test failed' }}</strong>
      </div>
      <div class="small text-muted mb-2">{{ result.error?.detail || '' }}</div>
      <pre v-if="result.error?.stacktrace" class="bg-light p-2 rounded border small mb-0">{{ result.error.stacktrace }}</pre>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import StatusBadge from './StatusBadge.vue';
import type { TestResult } from '@/types';

interface Props {
  result: TestResult;
}

const props = defineProps<Props>();
const expanded = ref(false);

// Format the duration in seconds with 2 decimal places
function formatDuration(duration: number): string {
  return `${(duration / 1000).toFixed(2)}s`;
}
</script>