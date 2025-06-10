<template>
  <span class="badge rounded-pill" :class="badgeClass">{{ label }}</span>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { ContainerStatus, ContainerHealth, TestStatus } from '@/types';

interface Props {
  status: ContainerStatus | ContainerHealth | TestStatus;
}

const props = defineProps<Props>();

const badgeClass = computed(() => {
  switch (props.status) {
    case ContainerStatus.Running:
    case ContainerHealth.Healthy:
    case TestStatus.Passed:
      return 'bg-success';
    
    case ContainerStatus.Stopped:
    case TestStatus.Failed:
    case TestStatus.Error:
    case ContainerHealth.Unhealthy:
      return 'bg-danger';
    
    case ContainerStatus.Starting:
    case ContainerHealth.Starting:
    case TestStatus.Running:
      return 'bg-warning';
    
    case TestStatus.Pending:
      return 'bg-info';
    
    case TestStatus.Skipped:
      return 'bg-secondary';
    
    default:
      return 'bg-secondary';
  }
});

const label = computed(() => {
  switch (props.status) {
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
    case ContainerStatus.Unknown:
      return 'Unknown';
    
    case ContainerHealth.Healthy:
      return 'Healthy';
    case ContainerHealth.Unhealthy:
      return 'Unhealthy';
    case ContainerHealth.Starting:
      return 'Starting';
    case ContainerHealth.Unknown:
      return 'Unknown';
    
    case TestStatus.Pending:
      return 'Pending';
    case TestStatus.Running:
      return 'Running';
    case TestStatus.Passed:
      return 'Passed';
    case TestStatus.Failed:
      return 'Failed';
    case TestStatus.Error:
      return 'Error';
    case TestStatus.Skipped:
      return 'Skipped';
    
    default:
      return props.status;
  }
});
</script>