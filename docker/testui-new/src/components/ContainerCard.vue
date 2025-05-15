<template>
  <div class="card mb-4 shadow-sm" :class="{'border-warning': container.status === 'starting' || container.status === 'stopping'}">
    <div class="card-header d-flex justify-content-between align-items-center py-3">
      <div class="d-flex align-items-center">
        <div 
          class="rounded d-flex align-items-center justify-content-center me-3" 
          :class="type === 'engine' ? 'bg-primary bg-opacity-10 text-primary' : 'bg-success bg-opacity-10 text-success'" 
          style="width: 48px; height: 48px; font-size: 24px;"
        >
          <i v-if="type === 'engine'" class="bi bi-gear"></i>
          <i v-else-if="type === 'database'" class="bi bi-hdd-rack"></i>
          <i v-else class="bi bi-box"></i>
        </div>
        <div>
          <h5 class="card-title mb-0">{{ container.name }}</h5>
          <div class="text-muted small">{{ versionDisplay || container.image }}</div>
        </div>
      </div>
      <span 
        class="badge rounded-pill" 
        :class="{
          'bg-success': container.status === 'running',
          'bg-danger': container.status === 'stopped',
          'bg-warning': container.status === 'starting' || container.status === 'stopping',
          'bg-secondary': container.status === 'unknown'
        }"
      >
        {{ statusText }}
      </span>
    </div>
    
    <div class="card-body">
      <div class="row g-3 mb-3">
        <div class="col-md-4">
          <div class="p-3 rounded bg-light bg-opacity-75 h-100" :class="{'bg-dark bg-opacity-10': theme === 'dark'}">
            <div class="text-uppercase small text-muted mb-1">Status</div>
            <div class="d-flex align-items-center">
              <span 
                class="status-indicator me-2" 
                :class="{
                  'status-running': container.status === 'running',
                  'status-stopped': container.status === 'stopped',
                  'status-starting': container.status === 'starting',
                  'status-stopping': container.status === 'stopping'
                }"
              ></span>
              <strong>{{ statusText }}</strong>
              
              <span 
                v-if="container.health" 
                class="badge ms-2" 
                :class="{
                  'bg-success': container.health === 'healthy',
                  'bg-danger': container.health === 'unhealthy',
                  'bg-warning': container.health === 'starting'
                }"
                style="font-size: 0.7rem;"
              >
                {{ container.health }}
              </span>
            </div>
          </div>
        </div>
        
        <div class="col-md-4">
          <div class="p-3 rounded bg-light bg-opacity-75 h-100" :class="{'bg-dark bg-opacity-10': theme === 'dark'}">
            <div class="text-uppercase small text-muted mb-1">{{ portTitle }}</div>
            <div><strong>{{ portValue }}</strong></div>
          </div>
        </div>
        
        <div class="col-md-4" v-if="container.uptime">
          <div class="p-3 rounded bg-light bg-opacity-75 h-100" :class="{'bg-dark bg-opacity-10': theme === 'dark'}">
            <div class="text-uppercase small text-muted mb-1">Uptime</div>
            <div><strong>{{ container.uptime || '-' }}</strong></div>
          </div>
        </div>
      </div>
      
      <div class="d-flex justify-content-between">
        <slot name="left-actions">
          <button 
            class="btn btn-sm btn-outline-secondary" 
            :disabled="container.status !== 'running'"
          >
            <i class="bi bi-info-circle me-1"></i> Details
          </button>
        </slot>
        
        <div class="btn-group" role="group">
          <button 
            v-if="container.status === 'running'" 
            class="btn btn-sm btn-danger"
            @click="$emit('stop')"
          >
            <i class="bi bi-stop-fill me-1"></i> Stop
          </button>
          
          <button 
            v-if="container.status === 'stopped'" 
            class="btn btn-sm btn-success"
            @click="$emit('start')"
          >
            <i class="bi bi-play-fill me-1"></i> Start
          </button>
          
          <button 
            class="btn btn-sm btn-outline-secondary" 
            :disabled="container.status !== 'running'"
            @click="$emit('restart')"
          >
            <i class="bi bi-arrow-repeat me-1"></i> Restart
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, inject } from 'vue';
import type { Container } from '@/types';
import { ContainerStatus } from '@/types';

interface Props {
  container: Container | any; // Using any here to accommodate both engines and databases
  type: 'engine' | 'database';
}

const props = defineProps<Props>();
const theme = inject('theme', 'light');

defineEmits(['start', 'stop', 'restart']);

const versionDisplay = computed(() => {
  return props.container.version ? props.container.version : '';
});

const statusText = computed(() => {
  switch (props.container.status) {
    case ContainerStatus.Running:
      return 'Running';
    case ContainerStatus.Stopped:
      return 'Stopped';
    case ContainerStatus.Starting:
      return 'Starting';
    case ContainerStatus.Stopping:
      return 'Stopping';
    case ContainerStatus.Error:
      return 'Error';
    default:
      return 'Unknown';
  }
});

const statusTextClass = computed(() => {
  if (props.container.status === ContainerStatus.Running) {
    return 'text-success';
  } else if (props.container.status === ContainerStatus.Stopped) {
    return 'text-danger';
  } else if (props.container.status === ContainerStatus.Starting) {
    return 'text-warning';
  } else if (props.container.status === ContainerStatus.Stopping) {
    return 'text-warning';
  } else if (props.container.status === ContainerStatus.Error) {
    return 'text-danger';
  } else {
    return '';
  }
});

const portTitle = computed(() => {
  return props.type === 'engine' ? 'Port' : 'Port';
});

const portValue = computed(() => {
  if (props.container.port) {
    return props.container.port;
  } else if (props.container.ports && Object.keys(props.container.ports).length > 0) {
    const ports = Object.entries(props.container.ports)
      .map(([key, value]) => `${key} → ${value}`)
      .join(', ');
    return ports;
  } else {
    return '-';
  }
});
</script>