<template>
  <div class="container-fluid py-4">
    <h1 class="mb-4 fs-2">Wheels Test Runner</h1>
    
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
            <p class="card-text">Configure and run Wheels tests across different engines and databases.</p>
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
            <p class="card-text">View Wheels documentation and testing guides.</p>
          </div>
          <div class="card-footer bg-transparent border-top-0 text-end">
            <a href="https://guides.wheels.dev" target="_blank" class="btn btn-info text-white">
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
                    @click="handleEngineClick('lucee5', 60005)"
                    :class="{ 'cursor-pointer': true }"
                    :title="!engines.lucee5 ? 'Click to see how to start Lucee 5' : engines.lucee5.status === 'running' ? 'Click to open Lucee 5' : 'Click to start Lucee 5'"
                  >
                    <td>Lucee 5</td>
                    <td class="text-end" v-if="engines.lucee5">
                      <span class="badge" :class="getStatusClass(engines.lucee5)">{{ getStatusText(engines.lucee5) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr 
                    @click="handleEngineClick('lucee6', 60006)"
                    :class="{ 'cursor-pointer': true }"
                    :title="!engines.lucee6 ? 'Click to see how to start Lucee 6' : engines.lucee6.status === 'running' ? 'Click to open Lucee 6' : 'Click to start Lucee 6'"
                  >
                    <td>Lucee 6</td>
                    <td class="text-end" v-if="engines.lucee6">
                      <span class="badge" :class="getStatusClass(engines.lucee6)">{{ getStatusText(engines.lucee6) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr 
                    @click="handleEngineClick('adobe2018', 62018)"
                    :class="{ 'cursor-pointer': true }"
                    :title="!engines.adobe2018 ? 'Click to see how to start Adobe 2018' : engines.adobe2018.status === 'running' ? 'Click to open Adobe 2018' : 'Click to start Adobe 2018'"
                  >
                    <td>Adobe 2018</td>
                    <td class="text-end" v-if="engines.adobe2018">
                      <span class="badge" :class="getStatusClass(engines.adobe2018)">{{ getStatusText(engines.adobe2018) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr 
                    @click="handleEngineClick('adobe2021', 62021)"
                    :class="{ 'cursor-pointer': true }"
                    :title="!engines.adobe2021 ? 'Click to see how to start Adobe 2021' : engines.adobe2021.status === 'running' ? 'Click to open Adobe 2021' : 'Click to start Adobe 2021'"
                  >
                    <td>Adobe 2021</td>
                    <td class="text-end" v-if="engines.adobe2021">
                      <span class="badge" :class="getStatusClass(engines.adobe2021)">{{ getStatusText(engines.adobe2021) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr 
                    @click="handleEngineClick('adobe2023', 62023)"
                    :class="{ 'cursor-pointer': true }"
                    :title="!engines.adobe2023 ? 'Click to see how to start Adobe 2023' : engines.adobe2023.status === 'running' ? 'Click to open Adobe 2023' : 'Click to start Adobe 2023'"
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
                  <tr
                    @click="handleDatabaseClick('h2')"
                    :class="{ 'cursor-pointer': !databases.h2 || databases.h2?.status === 'stopped' }"
                    :title="!databases.h2 || databases.h2?.status === 'stopped' ? 'H2 is embedded in Lucee' : ''"
                  >
                    <td>H2</td>
                    <td class="text-end" v-if="databases.h2">
                      <span class="badge" :class="getStatusClass(databases.h2)">{{ getStatusText(databases.h2) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr
                    @click="handleDatabaseClick('mysql')"
                    :class="{ 'cursor-pointer': !databases.mysql || databases.mysql?.status !== 'running' }"
                    :title="!databases.mysql ? 'Click to see how to start MySQL' : databases.mysql.status !== 'running' ? 'Click to start MySQL' : ''"
                  >
                    <td>MySQL</td>
                    <td class="text-end" v-if="databases.mysql">
                      <span class="badge" :class="getStatusClass(databases.mysql)">{{ getStatusText(databases.mysql) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr
                    @click="handleDatabaseClick('sqlserver')"
                    :class="{ 'cursor-pointer': !databases.sqlserver || databases.sqlserver?.status !== 'running' }"
                    :title="!databases.sqlserver ? 'Click to see how to start SQL Server' : databases.sqlserver.status !== 'running' ? 'Click to start SQL Server' : ''"
                  >
                    <td>SQL Server</td>
                    <td class="text-end" v-if="databases.sqlserver">
                      <span class="badge" :class="getStatusClass(databases.sqlserver)">{{ getStatusText(databases.sqlserver) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr
                    @click="handleDatabaseClick('postgres')"
                    :class="{ 'cursor-pointer': !databases.postgres || databases.postgres?.status !== 'running' }"
                    :title="!databases.postgres ? 'Click to see how to start PostgreSQL' : databases.postgres.status !== 'running' ? 'Click to start PostgreSQL' : ''"
                  >
                    <td>PostgreSQL</td>
                    <td class="text-end" v-if="databases.postgres">
                      <span class="badge" :class="getStatusClass(databases.postgres)">{{ getStatusText(databases.postgres) }}</span>
                    </td>
                    <td class="text-end" v-else><span class="badge bg-warning">Checking...</span></td>
                  </tr>
                  <tr
                    @click="handleDatabaseClick('oracle')"
                    :class="{ 'cursor-pointer': !databases.oracle || databases.oracle?.status !== 'running' }"
                    :title="!databases.oracle ? 'Click to see how to start Oracle' : databases.oracle.status !== 'running' ? 'Click to start Oracle' : ''"
                  >
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

// Copy text to clipboard
async function copyToClipboard(text: string) {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch (err) {
    console.error('Failed to copy to clipboard:', err);
    return false;
  }
}

// Show Docker command and copy to clipboard
function showDockerCommand(serviceName: string, command: string) {
  const message = `${serviceName} is not running.\n\nRun this command to start it:\n\n${command}\n\nThe command has been copied to your clipboard.`;
  
  copyToClipboard(command).then(success => {
    if (success) {
      alert(message);
    } else {
      // Fallback if clipboard API fails
      prompt(`${serviceName} is not running. Copy this command to start it:`, command);
    }
  });
}

// Handle engine click - open if running, show start instructions if not found
async function handleEngineClick(engineKey: string, port: number) {
  const engine = engines.value[engineKey];
  
  if (!engine) {
    // Container not found - show command to start it
    const command = `docker compose up -d ${engineKey}`;
    showDockerCommand(engineKey.toUpperCase(), command);
    return;
  }
  
  if (engine.status === 'running') {
    // Open in browser if running
    window.open(`http://localhost:${port}`, '_blank');
  } else if (engine.status === 'stopped' || engine.status === 'exited') {
    // Show command to start the existing container
    const containerName = engine.names[0].replace(/^\//, '');
    const command = `docker start ${containerName}`;
    showDockerCommand(engineKey.toUpperCase(), command);
  }
}

// Handle database click - show start instructions if not found
async function handleDatabaseClick(dbKey: string) {
  const database = databases.value[dbKey];
  
  // H2 is embedded, can't be started separately
  if (dbKey === 'h2') {
    if (!database || database.status === 'stopped') {
      alert('H2 is embedded in Lucee. Start a Lucee engine to use H2.');
    }
    return;
  }
  
  if (!database) {
    // Container not found - show command to start it
    const dbName = dbKey === 'sqlserver' ? 'SQL Server' : dbKey.charAt(0).toUpperCase() + dbKey.slice(1);
    
    if (dbKey === 'oracle') {
      alert(`Oracle database is not included in the default Docker Compose setup.\n\nTo use Oracle, you'll need to add it to your compose.yml file or run it separately.`);
    } else {
      // Map database keys to actual service names
      const serviceMap = {
        'sqlserver': 'sqlserver',
        'mysql': 'mysql',
        'postgres': 'postgres'
      };
      const serviceName = serviceMap[dbKey] || dbKey;
      const command = `docker compose up -d ${serviceName}`;
      showDockerCommand(dbName, command);
    }
    return;
  }
  
  if (database.status === 'stopped' || database.status === 'exited') {
    // Show command to start the existing container
    const containerName = database.names[0].replace(/^\//, '');
    const command = `docker start ${containerName}`;
    const dbName = dbKey === 'sqlserver' ? 'SQL Server' : dbKey.charAt(0).toUpperCase() + dbKey.slice(1);
    showDockerCommand(dbName, command);
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

/* Visual hint for non-running containers */
.cursor-pointer .badge.bg-danger,
.cursor-pointer .badge.bg-warning {
  transition: transform 0.2s ease;
}

.cursor-pointer:hover .badge.bg-danger,
.cursor-pointer:hover .badge.bg-warning {
  transform: scale(1.1);
}

/* Add hover effect for dark mode */
@media (prefers-color-scheme: dark) {
  .cursor-pointer:hover {
    background-color: rgba(255, 255, 255, 0.05);
  }
}
</style>