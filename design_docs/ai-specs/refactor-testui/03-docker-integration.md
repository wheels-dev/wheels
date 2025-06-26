# Docker Container Profile Integration Specification

This document details the plan for integrating Docker container profile management directly into the CFWheels TestUI, allowing for seamless control of test environments.

## Current Docker Integration Assessment

The current TestUI has no Docker integration:
- Containers must be managed separately via command line
- No visibility into container status
- No way to manage Docker Compose profiles
- No service health monitoring
- Manual verification of required services before testing

## Docker Integration Strategy

### Docker API Integration

#### Backend Options

1. **Embedded Node.js Backend**:
   - Express.js server within the TestUI container
   - Secured Docker API access
   - RESTful endpoints for container operations
   - WebSocket support for real-time events

2. **Docker Socket Proxy**:
   - Dedicated container for secure Docker API access
   - Limited API surface exposure
   - Authentication and authorization
   - CORS configuration for UI access

3. **Docker API Bridge**:
   - Lightweight bridge between UI and Docker daemon
   - Support for Docker Compose operations
   - Rate limiting for safety
   - Logging of all operations

#### API Endpoints

- **Container Operations**:
  - `GET /api/containers`: List all containers
  - `GET /api/containers/:id`: Get container details
  - `POST /api/containers/:id/start`: Start container
  - `POST /api/containers/:id/stop`: Stop container
  - `POST /api/containers/:id/restart`: Restart container
  - `GET /api/containers/:id/logs`: Stream container logs
  - `GET /api/containers/:id/stats`: Get resource usage

- **Compose Profile Management**:
  - `GET /api/profiles`: List available profiles
  - `POST /api/profiles/:name/up`: Start profile
  - `POST /api/profiles/:name/down`: Stop profile
  - `GET /api/profiles/:name/status`: Get profile status
  - `POST /api/profiles/custom`: Create custom profile

- **System Operations**:
  - `GET /api/system/status`: Get overall system status
  - `GET /api/system/health`: Run health checks
  - `POST /api/system/prepare`: Prepare for tests

### Docker Profile Management UI

#### Profile Dashboard

- **Profile Overview Component**:
  - Card-based layout of available profiles
  - Visual status indicators (Running/Stopped/Partial)
  - Service counts by type
  - Start/Stop/Restart buttons
  - Links to detailed view

- **Profile Detail View**:
  - Full profile information
  - List of included services
  - Dependency visualization
  - Service status details
  - Operation history

- **Profile Management Controls**:
  - Create new profile
  - Edit existing profile
  - Clone profile
  - Delete profile
  - Export/import profile configuration

#### Service Matrix

- **Service List Component**:
  - Tabular view of all services
  - Filterable by type, status, profile
  - Sortable columns
  - Bulk action capability
  - Status indicators

- **Service Card Component**:
  - Individual service information
  - Status badge
  - Health indicator
  - Quick actions
  - Resource usage metrics
  - Logs preview

- **Service Detail Modal**:
  - Comprehensive service information
  - Configuration details
  - Environment variables
  - Volume mounts
  - Network configuration
  - Full logs viewer

### Container Status Dashboard

- **Status Overview Component**:
  - Summary of all container statuses
  - Resource usage charts
  - Alert indicators
  - Quick action buttons

- **Container Grid Component**:
  - Grid layout of all containers
  - Status cards with key metrics
  - Color-coded health indicators
  - Filtering and grouping options

- **Health Check Panel**:
  - Service health check results
  - Last check timestamp
  - Historical health data
  - Configuration options

### Resource Monitoring

- **Resource Charts Component**:
  - CPU usage visualization
  - Memory consumption tracking
  - Disk I/O metrics
  - Network traffic statistics

- **Alert System**:
  - Threshold-based alerts
  - Visual indicators for issues
  - Notification mechanism
  - Resolution suggestions

- **Logs Viewer**:
  - Real-time log streaming
  - Log filtering and searching
  - Log level indicators
  - Auto-scroll toggle
  - Download logs option

## Integration with Test Execution

### Pre-Test Service Selection

- **Service Requirement UI**:
  - Automatic detection of required services
  - Manual override options
  - Profile selection based on tests
  - Resource estimation

- **Dependency Visualization**:
  - Graph view of service dependencies
  - Critical path highlighting
  - Missing service indicators
  - Connection verification

### Test Workflow Integration

- **Test Preparation Workflow**:
  - Select tests to run
  - Service requirement analysis
  - Current status check
  - Start missing services
  - Wait for readiness
  - Execute tests

- **Post-Test Actions**:
  - Service shutdown options
  - Resource cleanup
  - Save configuration for reuse
  - Result correlation with services

## Technical Specifications

### Docker Service Integration Module

```typescript
// src/services/docker.ts
import axios from 'axios'

const API_BASE_URL = '/api'

export class DockerService {
  /**
   * Get all containers
   */
  async getContainers() {
    const response = await axios.get(`${API_BASE_URL}/containers`)
    return response.data
  }
  
  /**
   * Get container details
   */
  async getContainer(id: string) {
    const response = await axios.get(`${API_BASE_URL}/containers/${id}`)
    return response.data
  }
  
  /**
   * Start a container
   */
  async startContainer(id: string) {
    const response = await axios.post(`${API_BASE_URL}/containers/${id}/start`)
    return response.data
  }
  
  /**
   * Stop a container
   */
  async stopContainer(id: string) {
    const response = await axios.post(`${API_BASE_URL}/containers/${id}/stop`)
    return response.data
  }
  
  /**
   * Get container logs
   */
  async getContainerLogs(id: string, tail: number = 100) {
    const response = await axios.get(
      `${API_BASE_URL}/containers/${id}/logs?tail=${tail}`
    )
    return response.data
  }
  
  /**
   * Get all profiles
   */
  async getProfiles() {
    const response = await axios.get(`${API_BASE_URL}/profiles`)
    return response.data
  }
  
  /**
   * Start services with profile
   */
  async startProfile(name: string) {
    const response = await axios.post(`${API_BASE_URL}/profiles/${name}/up`)
    return response.data
  }
  
  /**
   * Stop services with profile
   */
  async stopProfile(name: string) {
    const response = await axios.post(`${API_BASE_URL}/profiles/${name}/down`)
    return response.data
  }
  
  /**
   * Check system health
   */
  async checkHealth() {
    const response = await axios.get(`${API_BASE_URL}/system/health`)
    return response.data
  }
  
  /**
   * Prepare system for tests
   */
  async prepareForTests(config: TestConfig) {
    const response = await axios.post(
      `${API_BASE_URL}/system/prepare`, 
      { config }
    )
    return response.data
  }
}

export default new DockerService()
```

### Docker Store Implementation

```typescript
// src/stores/docker.ts
import { defineStore } from 'pinia'
import dockerService from '../services/docker'
import { Container, Profile, ServiceStatus } from '../types/docker'

export const useDockerStore = defineStore('docker', {
  state: () => ({
    containers: [] as Container[],
    profiles: [] as Profile[],
    serviceStatus: {} as Record<string, ServiceStatus>,
    loading: false,
    error: null as Error | null,
    selectedProfile: null as string | null,
  }),
  
  getters: {
    runningContainers: (state) => 
      state.containers.filter(c => c.state === 'running'),
    
    stoppedContainers: (state) => 
      state.containers.filter(c => c.state === 'exited'),
    
    profileServices: (state) => (profileName: string) => {
      const profile = state.profiles.find(p => p.name === profileName)
      if (!profile) return []
      
      return state.containers.filter(c => 
        profile.services.includes(c.name)
      )
    },
    
    profileStatus: (state) => (profileName: string) => {
      const services = state.profileServices(profileName)
      if (services.length === 0) return 'unknown'
      
      const running = services.filter(s => s.state === 'running')
      
      if (running.length === 0) return 'stopped'
      if (running.length === services.length) return 'running'
      return 'partial'
    },
    
    servicesForTests: (state) => (testConfig: TestConfig) => {
      // Determine which services are needed for the selected tests
      const { engine, database } = testConfig
      
      return state.containers.filter(c => {
        if (engine && c.labels['service.type'] === 'engine' && 
            c.labels['engine.name'] === engine) {
          return true
        }
        
        if (database && c.labels['service.type'] === 'database' && 
            c.labels['database.name'] === database) {
          return true
        }
        
        return false
      })
    }
  },
  
  actions: {
    async fetchContainers() {
      this.loading = true
      this.error = null
      
      try {
        const containers = await dockerService.getContainers()
        this.containers = containers
      } catch (err) {
        this.error = err as Error
        console.error('Failed to fetch containers:', err)
      } finally {
        this.loading = false
      }
    },
    
    async fetchProfiles() {
      this.loading = true
      this.error = null
      
      try {
        const profiles = await dockerService.getProfiles()
        this.profiles = profiles
      } catch (err) {
        this.error = err as Error
        console.error('Failed to fetch profiles:', err)
      } finally {
        this.loading = false
      }
    },
    
    async startProfile(profileName: string) {
      this.loading = true
      this.error = null
      
      try {
        await dockerService.startProfile(profileName)
        // Refresh container list after starting profile
        await this.fetchContainers()
        return true
      } catch (err) {
        this.error = err as Error
        console.error(`Failed to start profile ${profileName}:`, err)
        return false
      } finally {
        this.loading = false
      }
    },
    
    async stopProfile(profileName: string) {
      this.loading = true
      this.error = null
      
      try {
        await dockerService.stopProfile(profileName)
        // Refresh container list after stopping profile
        await this.fetchContainers()
        return true
      } catch (err) {
        this.error = err as Error
        console.error(`Failed to stop profile ${profileName}:`, err)
        return false
      } finally {
        this.loading = false
      }
    },
    
    async startContainer(containerId: string) {
      this.loading = true
      this.error = null
      
      try {
        await dockerService.startContainer(containerId)
        // Refresh container state
        await this.fetchContainers()
        return true
      } catch (err) {
        this.error = err as Error
        console.error(`Failed to start container ${containerId}:`, err)
        return false
      } finally {
        this.loading = false
      }
    },
    
    async stopContainer(containerId: string) {
      this.loading = true
      this.error = null
      
      try {
        await dockerService.stopContainer(containerId)
        // Refresh container state
        await this.fetchContainers()
        return true
      } catch (err) {
        this.error = err as Error
        console.error(`Failed to stop container ${containerId}:`, err)
        return false
      } finally {
        this.loading = false
      }
    },
    
    async checkHealth() {
      this.loading = true
      this.error = null
      
      try {
        const healthData = await dockerService.checkHealth()
        
        // Update service status with health data
        Object.entries(healthData).forEach(([serviceId, status]) => {
          this.serviceStatus[serviceId] = status as ServiceStatus
        })
        
        return healthData
      } catch (err) {
        this.error = err as Error
        console.error('Failed to check health:', err)
        return null
      } finally {
        this.loading = false
      }
    },
    
    async prepareForTests(testConfig: TestConfig) {
      this.loading = true
      this.error = null
      
      try {
        const result = await dockerService.prepareForTests(testConfig)
        // Refresh containers after preparation
        await this.fetchContainers()
        return result
      } catch (err) {
        this.error = err as Error
        console.error('Failed to prepare for tests:', err)
        return null
      } finally {
        this.loading = false
      }
    }
  }
})
```

### Component Examples

#### Profile Dashboard Component

```vue
<template>
  <div class="profile-dashboard">
    <div class="dashboard-header">
      <h2>Docker Profiles</h2>
      <div class="actions">
        <button class="btn btn-primary" @click="refreshProfiles">
          <RefreshIcon /> Refresh
        </button>
        <button class="btn btn-outline" @click="showCreateProfile">
          <PlusIcon /> New Profile
        </button>
      </div>
    </div>
    
    <div class="profile-cards">
      <ProfileCard
        v-for="profile in profiles"
        :key="profile.name"
        :profile="profile"
        :status="getProfileStatus(profile.name)"
        @start="startProfile(profile.name)"
        @stop="stopProfile(profile.name)"
        @view="selectProfile(profile)"
      />
    </div>
    
    <ProfileDetailModal
      v-if="selectedProfile"
      :profile="selectedProfile"
      :open="!!selectedProfile"
      @close="selectedProfile = null"
    />
    
    <CreateProfileModal
      :open="showCreateModal"
      @close="showCreateModal = false"
      @create="handleCreateProfile"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useDockerStore } from '../stores/docker'
import ProfileCard from './ProfileCard.vue'
import ProfileDetailModal from './ProfileDetailModal.vue'
import CreateProfileModal from './CreateProfileModal.vue'
import { RefreshIcon, PlusIcon } from '@heroicons/vue/outline'
import type { Profile } from '../types/docker'

const dockerStore = useDockerStore()
const selectedProfile = ref<Profile | null>(null)
const showCreateModal = ref(false)

const profiles = computed(() => dockerStore.profiles)

onMounted(async () => {
  await refreshProfiles()
})

async function refreshProfiles() {
  await dockerStore.fetchProfiles()
  await dockerStore.fetchContainers()
}

function getProfileStatus(profileName: string) {
  return dockerStore.profileStatus(profileName)
}

async function startProfile(profileName: string) {
  await dockerStore.startProfile(profileName)
}

async function stopProfile(profileName: string) {
  await dockerStore.stopProfile(profileName)
}

function selectProfile(profile: Profile) {
  selectedProfile.value = profile
}

function showCreateProfile() {
  showCreateModal.value = true
}

async function handleCreateProfile(profileData: any) {
  // Implementation for profile creation
  showCreateModal.value = false
  await refreshProfiles()
}
</script>
```

#### Profile Card Component

```vue
<template>
  <div 
    class="profile-card card"
    :class="{
      'border-success': status === 'running',
      'border-warning': status === 'partial',
      'border-error': status === 'error',
      'border-base-300': status === 'stopped'
    }"
  >
    <div class="card-header">
      <h3 class="card-title">{{ profile.name }}</h3>
      <StatusBadge :status="status" />
    </div>
    
    <div class="card-body">
      <div class="service-summary">
        <div class="service-count">
          <span class="count">{{ engineCount }}</span>
          <span class="label">Engines</span>
        </div>
        <div class="service-count">
          <span class="count">{{ databaseCount }}</span>
          <span class="label">Databases</span>
        </div>
        <div class="service-count">
          <span class="count">{{ utilityCount }}</span>
          <span class="label">Utilities</span>
        </div>
      </div>
      
      <div class="profile-description" v-if="profile.description">
        {{ profile.description }}
      </div>
    </div>
    
    <div class="card-footer">
      <div class="actions">
        <button 
          v-if="status === 'stopped' || status === 'partial'"
          class="btn btn-sm btn-success"
          @click="$emit('start')"
          :disabled="loading"
        >
          <PlayIcon v-if="!loading" class="icon" />
          <LoadingIcon v-else class="icon animate-spin" />
          Start
        </button>
        
        <button 
          v-if="status === 'running' || status === 'partial'"
          class="btn btn-sm btn-error"
          @click="$emit('stop')"
          :disabled="loading"
        >
          <StopIcon v-if="!loading" class="icon" />
          <LoadingIcon v-else class="icon animate-spin" />
          Stop
        </button>
        
        <button 
          class="btn btn-sm btn-outline"
          @click="$emit('view')"
        >
          Details
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useDockerStore } from '../stores/docker'
import StatusBadge from './StatusBadge.vue'
import { PlayIcon, StopIcon, LoadingIcon } from '@heroicons/vue/outline'
import type { Profile } from '../types/docker'

const props = defineProps<{
  profile: Profile
  status: string
}>()

defineEmits<{
  (e: 'start'): void
  (e: 'stop'): void
  (e: 'view'): void
}>()

const dockerStore = useDockerStore()
const loading = computed(() => dockerStore.loading)

const profileServices = computed(() => 
  dockerStore.profileServices(props.profile.name)
)

const engineCount = computed(() => 
  profileServices.value.filter(s => 
    s.labels['service.type'] === 'engine'
  ).length
)

const databaseCount = computed(() => 
  profileServices.value.filter(s => 
    s.labels['service.type'] === 'database'
  ).length
)

const utilityCount = computed(() => 
  profileServices.value.filter(s => 
    s.labels['service.type'] === 'utility'
  ).length
)
</script>
```

#### Container Status Component

```vue
<template>
  <div class="container-status">
    <div class="status-header">
      <h3>{{ container.name }}</h3>
      <StatusBadge :status="container.state" />
    </div>
    
    <div class="status-body">
      <div class="status-info">
        <div class="info-item">
          <span class="label">ID:</span>
          <span class="value">{{ shortId }}</span>
        </div>
        <div class="info-item">
          <span class="label">Image:</span>
          <span class="value">{{ container.image }}</span>
        </div>
        <div class="info-item">
          <span class="label">Started:</span>
          <span class="value">{{ formattedStartTime }}</span>
        </div>
        <div class="info-item">
          <span class="label">Health:</span>
          <HealthIndicator :health="container.health" />
        </div>
      </div>
      
      <div class="resource-usage" v-if="container.state === 'running'">
        <div class="resource-item">
          <span class="label">CPU:</span>
          <ProgressBar :percent="cpuPercent" class="cpu-bar" />
          <span class="value">{{ cpuPercent.toFixed(1) }}%</span>
        </div>
        <div class="resource-item">
          <span class="label">Memory:</span>
          <ProgressBar :percent="memoryPercent" class="memory-bar" />
          <span class="value">{{ formattedMemory }}</span>
        </div>
      </div>
    </div>
    
    <div class="status-footer">
      <div class="actions">
        <button 
          v-if="container.state === 'exited'"
          class="btn btn-sm btn-success"
          @click="startContainer"
          :disabled="loading"
        >
          Start
        </button>
        
        <button 
          v-if="container.state === 'running'"
          class="btn btn-sm btn-warning"
          @click="restartContainer"
          :disabled="loading"
        >
          Restart
        </button>
        
        <button 
          v-if="container.state === 'running'"
          class="btn btn-sm btn-error"
          @click="stopContainer"
          :disabled="loading"
        >
          Stop
        </button>
        
        <button 
          class="btn btn-sm btn-outline"
          @click="viewLogs"
        >
          Logs
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useDockerStore } from '../stores/docker'
import StatusBadge from './StatusBadge.vue'
import HealthIndicator from './HealthIndicator.vue'
import ProgressBar from './ProgressBar.vue'
import { formatBytes, formatDate } from '../utils/formatting'
import type { Container } from '../types/docker'

const props = defineProps<{
  container: Container
}>()

const emit = defineEmits<{
  (e: 'view-logs'): void
}>()

const dockerStore = useDockerStore()
const loading = computed(() => dockerStore.loading)

const shortId = computed(() => 
  props.container.id.substring(0, 12)
)

const formattedStartTime = computed(() => 
  props.container.startedAt ? formatDate(props.container.startedAt) : 'N/A'
)

const cpuPercent = computed(() => 
  props.container.stats?.cpu_percent || 0
)

const memoryPercent = computed(() => {
  if (!props.container.stats) return 0
  const { memory_stats } = props.container.stats
  if (!memory_stats || !memory_stats.limit) return 0
  
  return (memory_stats.usage / memory_stats.limit) * 100
})

const formattedMemory = computed(() => {
  if (!props.container.stats) return 'N/A'
  const { memory_stats } = props.container.stats
  if (!memory_stats) return 'N/A'
  
  return `${formatBytes(memory_stats.usage)} / ${formatBytes(memory_stats.limit)}`
})

async function startContainer() {
  await dockerStore.startContainer(props.container.id)
}

async function stopContainer() {
  await dockerStore.stopContainer(props.container.id)
}

async function restartContainer() {
  await dockerStore.stopContainer(props.container.id)
  await dockerStore.startContainer(props.container.id)
}

function viewLogs() {
  emit('view-logs')
}
</script>
```

## Implementation Guidelines

1. Start by setting up the Docker API bridge/proxy
2. Implement basic container listing and status display
3. Add container operations (start/stop/restart)
4. Implement profile management UI
5. Add health monitoring and resource tracking
6. Integrate with test selection and execution flow

## Acceptance Criteria

- Docker container status should be accurately displayed
- Docker Compose profiles should be manageable from the UI
- Container operations should function correctly
- Resource usage should be monitored and displayed
- Health checks should provide accurate status information
- Integration with test execution should be seamless