<template>
  <div class="stats shadow w-full">
    <div class="stat">
      <div class="stat-title">Total Tests</div>
      <div class="stat-value">{{ summary.total }}</div>
    </div>
    
    <div class="stat">
      <div class="stat-title">Passing</div>
      <div class="stat-value text-success">{{ summary.passed }}</div>
    </div>
    
    <div class="stat">
      <div class="stat-title">Failing</div>
      <div class="stat-value text-error">{{ summary.failed }}</div>
    </div>
    
    <div class="stat">
      <div class="stat-title">Errors</div>
      <div class="stat-value text-error">{{ summary.errors }}</div>
    </div>
    
    <div class="stat" v-if="summary.skipped">
      <div class="stat-title">Skipped</div>
      <div class="stat-value text-info">{{ summary.skipped }}</div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface TestSummary {
  total: number;
  passed: number;
  failed: number;
  errors: number;
  skipped: number;
}

interface Props {
  summary: TestSummary;
}

defineProps<Props>();
</script>