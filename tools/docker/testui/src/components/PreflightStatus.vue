<template>
  <div class="bg-base-200 rounded-lg shadow-lg p-4">
    <div class="flex justify-between items-center mb-4">
      <h2 class="text-xl font-bold">Pre-flight Checks</h2>
      <div class="flex space-x-2">
        <button 
          class="btn btn-sm btn-primary" 
          @click="startPreflight" 
          :disabled="preflight.running"
        >
          Run Checks
        </button>
        <button 
          class="btn btn-sm btn-error" 
          @click="cancelPreflight" 
          :disabled="!preflight.running"
        >
          Cancel
        </button>
      </div>
    </div>
    
    <div v-if="preflight.running" class="mb-4">
      <progress class="progress progress-primary w-full"></progress>
    </div>
    
    <div class="space-y-3">
      <div 
        v-for="step in preflight.steps" 
        :key="step.id" 
        class="bg-base-300 p-3 rounded-lg"
      >
        <div class="flex justify-between items-center">
          <div>
            <div class="font-medium">{{ step.name }}</div>
            <div class="text-sm opacity-70">{{ step.description }}</div>
          </div>
          <PreflightStepBadge :status="step.status" />
        </div>
        <div v-if="step.status === 'failed' && step.error" class="mt-2 text-sm text-error">
          {{ step.error }}
        </div>
      </div>
    </div>
    
    <div v-if="preflight.completed" class="mt-4">
      <div 
        class="alert" 
        :class="preflight.success ? 'alert-success' : 'alert-error'"
      >
        <svg v-if="preflight.success" xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <svg v-else xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <span>{{ preflight.success ? 'All pre-flight checks passed!' : 'Pre-flight checks failed. Please resolve the issues before running tests.' }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { defineProps, defineEmits } from 'vue';
import type { Preflight } from '@/types';

// A simple badge component for preflight step status
const PreflightStepBadge = (props: { status: string }) => {
  const getClass = () => {
    switch (props.status) {
      case 'success': return 'badge-success';
      case 'failed': return 'badge-error';
      case 'running': return 'badge-warning';
      case 'pending': return 'badge-neutral';
      case 'skipped': return 'badge-info';
      default: return 'badge-neutral';
    }
  };
  
  const getLabel = () => {
    switch (props.status) {
      case 'success': return 'Success';
      case 'failed': return 'Failed';
      case 'running': return 'Running';
      case 'pending': return 'Pending';
      case 'skipped': return 'Skipped';
      default: return props.status;
    }
  };
  
  return (
    <span class={`badge ${getClass()}`}>{getLabel()}</span>
  );
};

interface Props {
  preflight: Preflight;
}

const props = defineProps<Props>();
const emit = defineEmits(['start', 'cancel']);

const startPreflight = () => {
  emit('start');
};

const cancelPreflight = () => {
  emit('cancel');
};
</script>