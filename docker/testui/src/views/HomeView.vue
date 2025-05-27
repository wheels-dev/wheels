<template>
  <div class="container-fluid py-4">
    <h1 class="mb-4 fs-2">CFWheels Test Runner</h1>
    
    <div class="row row-cols-1 row-cols-md-2 g-4 mb-5">
      <!-- Test Runner Card -->
      <div class="col">
        <div class="card h-100 shadow-sm">
          <div class="card-body">
            <div class="d-flex align-items-center mb-3">
              <div class="rounded-circle bg-primary bg-opacity-10 d-flex align-items-center justify-content-center me-3" 
                   style="width: 48px; height: 48px; font-size: 24px;">
                <i class="bi bi-play-circle text-primary"></i>
              </div>
              <h5 class="card-title mb-0">Run Tests</h5>
            </div>
            <p class="card-text">Configure and run CFWheels tests across different engines and databases.</p>
          </div>
          <div class="card-footer bg-transparent border-top-0 text-end">
            <router-link to="/tests" class="btn btn-primary">
              <i class="bi bi-play-fill me-1"></i> Test Runner
            </router-link>
          </div>
        </div>
      </div>
      
      <!-- Documentation Card -->
      <div class="col">
        <div class="card h-100 shadow-sm">
          <div class="card-body">
            <div class="d-flex align-items-center mb-3">
              <div class="rounded-circle bg-info bg-opacity-10 d-flex align-items-center justify-content-center me-3"
                   style="width: 48px; height: 48px; font-size: 24px;">
                <i class="bi bi-book text-info"></i>
              </div>
              <h5 class="card-title mb-0">Documentation</h5>
            </div>
            <p class="card-text">View CFWheels documentation and testing guides.</p>
          </div>
          <div class="card-footer bg-transparent border-top-0 text-end">
            <a href="https://guides.cfwheels.org" target="_blank" class="btn btn-info text-white">
              <i class="bi bi-book-fill me-1"></i> View Docs
            </a>
          </div>
        </div>
      </div>
    </div>
    
    <h2 class="mb-4 fs-4 border-bottom pb-2">System Status</h2>
    
    <div class="row g-4">
      <!-- Engine Status -->
      <div class="col-md-6">
        <div class="card shadow-sm">
          <div class="card-header bg-primary bg-opacity-10">
            <h5 class="card-title mb-0">
              <i class="bi bi-gear me-2"></i> CFML Engines
            </h5>
          </div>
          <div class="card-body">
            <div class="table-responsive">
              <table class="table table-hover">
                <thead>
                  <tr>
                    <th>Engine</th>
                    <th class="text-end">Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr 
                    @click="openEngine('lucee5', 60005)"
                    :class="{ 'cursor-pointer': engines.lucee5?.status === 'running' }"
                    :title="engines.lucee5?.status === 'running' ? 'Click to open Lucee 5' : ''"
                  >
                    <td>Lucee 5</td>
                    <td class="text-end" v-if="engines.lucee5">
                      <span class="badge" :class="getStatusClass(engines.lucee5)">{{ getStatusText(engines.lucee5) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr 
                    @click="openEngine('lucee6', 60006)"
                    :class="{ 'cursor-pointer': engines.lucee6?.status === 'running' }"
                    :title="engines.lucee6?.status === 'running' ? 'Click to open Lucee 6' : ''"
                  >
                    <td>Lucee 6</td>
                    <td class="text-end" v-if="engines.lucee6">
                      <span class="badge" :class="getStatusClass(engines.lucee6)">{{ getStatusText(engines.lucee6) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr 
                    @click="openEngine('adobe2018', 62018)"
                    :class="{ 'cursor-pointer': engines.adobe2018?.status === 'running' }"
                    :title="engines.adobe2018?.status === 'running' ? 'Click to open Adobe 2018' : ''"
                  >
                    <td>Adobe 2018</td>
                    <td class="text-end" v-if="engines.adobe2018">
                      <span class="badge" :class="getStatusClass(engines.adobe2018)">{{ getStatusText(engines.adobe2018) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr 
                    @click="openEngine('adobe2021', 62021)"
                    :class="{ 'cursor-pointer': engines.adobe2021?.status === 'running' }"
                    :title="engines.adobe2021?.status === 'running' ? 'Click to open Adobe 2021' : ''"
                  >
                    <td>Adobe 2021</td>
                    <td class="text-end" v-if="engines.adobe2021">
                      <span class="badge" :class="getStatusClass(engines.adobe2021)">{{ getStatusText(engines.adobe2021) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr 
                    @click="openEngine('adobe2023', 62023)"
                    :class="{ 'cursor-pointer': engines.adobe2023?.status === 'running' }"
                    :title="engines.adobe2023?.status === 'running' ? 'Click to open Adobe 2023' : ''"
                  >
                    <td>Adobe 2023</td>
                    <td class="text-end" v-if="engines.adobe2023">
                      <span class="badge" :class="getStatusClass(engines.adobe2023)">{{ getStatusText(engines.adobe2023) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Database Status -->
      <div class="col-md-6">
        <div class="card shadow-sm">
          <div class="card-header bg-success bg-opacity-10">
            <h5 class="card-title mb-0">
              <i class="bi bi-database me-2"></i> Databases
            </h5>
          </div>
          <div class="card-body">
            <div class="table-responsive">
              <table class="table table-hover">
                <thead>
                  <tr>
                    <th>Database</th>
                    <th class="text-end">Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td>H2</td>
                    <td class="text-end" v-if="databases.h2">
                      <span class="badge" :class="getStatusClass(databases.h2)">{{ getStatusText(databases.h2) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr>
                    <td>MySQL</td>
                    <td class="text-end" v-if="databases.mysql">
                      <span class="badge" :class="getStatusClass(databases.mysql)">{{ getStatusText(databases.mysql) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr>
                    <td>SQL Server</td>
                    <td class="text-end" v-if="databases.sqlserver">
                      <span class="badge" :class="getStatusClass(databases.sqlserver)">{{ getStatusText(databases.sqlserver) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr>
                    <td>PostgreSQL</td>
                    <td class="text-end" v-if="databases.postgres">
                      <span class="badge" :class="getStatusClass(databases.postgres)">{{ getStatusText(databases.postgres) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr>
                    <td>Oracle</td>
                    <td class="text-end" v-if="databases.oracle">
                      <span class="badge" :class="getStatusClass(databases.oracle)">{{ getStatusText(databases.oracle) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { dockerService } from '@/services/docker.service';

// Container statuses
const engines = ref({
  lucee5: null,
  lucee6: null,
  adobe2018: null,
  adobe2021: null,
  adobe2023: null
});

const databases = ref({
  h2: null,
  mysql: null,
  sqlserver: null,
  postgres: null,
  oracle: null
});

// Helper methods for status badges
function getStatusClass(container) {
  if (!container) return 'bg-warning';
  
  switch (container.status) {
    case 'running':
      return 'bg-success';
    case 'stopped':
      return 'bg-danger';
    case 'starting':
    case 'stopping':
      return 'bg-warning';
    case 'error':
      return 'bg-danger';
    default:
      return 'bg-secondary';
  }
}

function getStatusText(container) {
  if (!container) return 'Checking...';
  
  switch (container.status) {
    case 'running':
      return 'Running';
    case 'stopped':
      return 'Stopped';
    case 'starting':
      return 'Starting';
    case 'stopping':
      return 'Stopping';
    case 'error':
      return 'Error';
    default:
      return 'Unknown';
  }
}

// Open engine URL in a new tab
function openEngine(engineKey: string, port: number) {
  const engine = engines.value[engineKey];
  if (engine && engine.status === 'running') {
    window.open(`http://localhost:${port}`, '_blank');
  }
}

// Fetch container data
async function fetchContainers() {
  try {
    console.log('Fetching container statuses for dashboard...');
    const containers = await dockerService.getContainers();
    
    // Process engines
    const engineContainers = containers.filter(c => c.type === 'engine');
    let hasRunningLucee = false;
    
    engineContainers.forEach(container => {
      if (container.name.includes('lucee5')) {
        engines.value.lucee5 = container;
        if (container.status === 'running') hasRunningLucee = true;
      } else if (container.name.includes('lucee6')) {
        engines.value.lucee6 = container;
        if (container.status === 'running') hasRunningLucee = true;
      } else if (container.name.includes('adobe2018')) {
        engines.value.adobe2018 = container;
      } else if (container.name.includes('adobe2021')) {
        engines.value.adobe2021 = container;
      } else if (container.name.includes('adobe2023')) {
        engines.value.adobe2023 = container;
      }
    });
    
    // Process databases
    const dbContainers = containers.filter(c => c.type === 'database');
    dbContainers.forEach(container => {
      if (container.name.includes('mysql') || container.image.includes('mysql')) {
        databases.value.mysql = container;
      } else if (container.name.includes('sqlserver') || container.image.includes('sqlserver')) {
        databases.value.sqlserver = container;
      } else if (container.name.includes('postgres') || container.image.includes('postgres')) {
        databases.value.postgres = container;
      } else if (container.name.includes('oracle') || container.image.includes('oracle')) {
        databases.value.oracle = container;
      }
    });
    
    // Special handling for H2 database - it's embedded in Lucee containers
    if (!databases.value.h2) {
      // Create a virtual H2 container with status dependent on Lucee containers
      databases.value.h2 = {
        id: 'virtual-h2',
        name: 'h2-embedded',
        type: 'database',
        image: 'h2:embedded',
        status: hasRunningLucee ? 'running' : 'stopped',
        health: hasRunningLucee ? 'healthy' : undefined,
        ports: { '9082': '9082' },
        created: new Date().toISOString(),
        uptime: hasRunningLucee ? 'Same as Lucee' : undefined
      };
    }
    
    console.log('Container data processed:', { engines: engines.value, databases: databases.value });
  } catch (error) {
    console.error('Error fetching containers:', error);
  }
}

// Fetch data on component mount and set up refresh interval
onMounted(() => {
  fetchContainers();
  
  // Refresh every 10 seconds
  const refreshInterval = setInterval(fetchContainers, 10000);
  
  // Clean up interval on component unmount
  return () => clearInterval(refreshInterval);
});
</script>

<style scoped>
.cursor-pointer {
  cursor: pointer;
}

.cursor-pointer:hover {
  background-color: rgba(0, 0, 0, 0.02);
}

/* Add hover effect for dark mode */
@media (prefers-color-scheme: dark) {
  .cursor-pointer:hover {
    background-color: rgba(255, 255, 255, 0.05);
  }
}
</style>