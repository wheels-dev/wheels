import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import type { Database } from '@/types';
import { ContainerStatus, ContainerHealth } from '@/types';

export const useDatabaseStore = defineStore('database', () => {
  // State
  const databases = ref<Database[]>([
    {
      id: 'mysql',
      name: 'MySQL',
      version: '8.0',
      port: 3306,
      status: ContainerStatus.Running,
      health: ContainerHealth.Healthy,
      connectionInfo: {
        host: 'mysql',
        port: 3306,
        database: 'wheels',
        username: 'wheels',
        password: 'wheels'
      }
    },
    {
      id: 'sqlserver',
      name: 'SQL Server',
      version: '2019',
      port: 1433,
      status: ContainerStatus.Running,
      health: ContainerHealth.Healthy,
      connectionInfo: {
        host: 'sqlserver',
        port: 1433,
        database: 'wheels',
        username: 'sa',
        password: 'Wheels123'
      }
    },
    {
      id: 'postgresql',
      name: 'PostgreSQL',
      version: '13',
      port: 5432,
      status: ContainerStatus.Stopped,
      connectionInfo: {
        host: 'postgresql',
        port: 5432,
        database: 'wheels',
        username: 'postgres',
        password: 'wheels'
      }
    },
    {
      id: 'h2',
      name: 'H2',
      version: 'Embedded',
      port: 0,
      status: ContainerStatus.Running,
      health: ContainerHealth.Healthy,
      connectionInfo: {
        host: 'localhost',
        port: 0,
        database: 'cfwheels',
        username: 'sa',
        password: ''
      }
    },
    {
      id: 'oracle',
      name: 'Oracle',
      version: '19.3.0',
      port: 1521,
      status: ContainerStatus.Stopped,
      connectionInfo: {
        host: 'oracle',
        port: 1521,
        database: 'cfwheels',
        username: 'system',
        password: 'oracle'
      }
    }
  ]);

  // Getters
  const runningDatabases = computed(() => 
    databases.value.filter(db => db.status === ContainerStatus.Running)
  );
  
  const getDatabaseById = computed(() => 
    (id: string) => databases.value.find(db => db.id === id)
  );

  // Actions
  function updateDatabaseStatus(id: string, status: ContainerStatus, health?: ContainerHealth) {
    const database = databases.value.find(db => db.id === id);
    if (database) {
      database.status = status;
      if (health) {
        database.health = health;
      }
    }
  }

  async function refreshDatabases() {
    // This would be replaced with actual API call to get database status
    console.log('Refreshing database status...');
    // Mock implementation for now
    // In the actual implementation, we would call the Docker API
  }

  async function startDatabase(id: string) {
    // This would be replaced with actual API call to start the database
    console.log(`Starting database ${id}...`);
    updateDatabaseStatus(id, ContainerStatus.Starting);
    
    // Simulate async operation
    setTimeout(() => {
      updateDatabaseStatus(id, ContainerStatus.Running, ContainerHealth.Healthy);
    }, 2000);
  }

  async function stopDatabase(id: string) {
    // This would be replaced with actual API call to stop the database
    console.log(`Stopping database ${id}...`);
    updateDatabaseStatus(id, ContainerStatus.Stopping);
    
    // Simulate async operation
    setTimeout(() => {
      updateDatabaseStatus(id, ContainerStatus.Stopped);
    }, 2000);
  }

  async function restartDatabase(id: string) {
    // This would be replaced with actual API call to restart the database
    console.log(`Restarting database ${id}...`);
    await stopDatabase(id);
    await startDatabase(id);
  }

  return {
    databases,
    runningDatabases,
    getDatabaseById,
    updateDatabaseStatus,
    refreshDatabases,
    startDatabase,
    stopDatabase,
    restartDatabase
  };
});