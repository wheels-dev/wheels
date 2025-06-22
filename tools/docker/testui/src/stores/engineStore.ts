import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import type { CfmlEngine } from '@/types';
import { ContainerStatus, ContainerHealth } from '@/types';

export const useEngineStore = defineStore('engine', () => {
  // State
  const engines = ref<CfmlEngine[]>([
    {
      id: 'lucee5',
      name: 'Lucee',
      version: '5.4',
      url: 'http://localhost:8001',
      port: 8001,
      adminUrl: 'http://localhost:8001/lucee/admin/',
      status: ContainerStatus.Running,
      health: ContainerHealth.Healthy,
      uptime: '2h 15m'
    },
    {
      id: 'lucee6',
      name: 'Lucee',
      version: '6.0',
      url: 'http://localhost:8002',
      port: 8002,
      adminUrl: 'http://localhost:8002/lucee/admin/',
      status: ContainerStatus.Stopped,
    },
    {
      id: 'adobe2018',
      name: 'Adobe ColdFusion',
      version: '2018',
      url: 'http://localhost:8511',
      port: 8511,
      adminUrl: 'http://localhost:8511/CFIDE/administrator/',
      status: ContainerStatus.Stopped,
    },
    {
      id: 'adobe2021',
      name: 'Adobe ColdFusion',
      version: '2021',
      url: 'http://localhost:8003',
      port: 8003,
      adminUrl: 'http://localhost:8003/CFIDE/administrator/',
      status: ContainerStatus.Starting,
    },
    {
      id: 'adobe2023',
      name: 'Adobe ColdFusion',
      version: '2023',
      url: 'http://localhost:8005',
      port: 8005,
      adminUrl: 'http://localhost:8005/CFIDE/administrator/',
      status: ContainerStatus.Stopped,
    }
  ]);

  // Getters
  const runningEngines = computed(() => 
    engines.value.filter(engine => engine.status === ContainerStatus.Running)
  );
  
  const getEngineById = computed(() => 
    (id: string) => engines.value.find(engine => engine.id === id)
  );

  // Actions
  function updateEngineStatus(id: string, status: ContainerStatus, health?: ContainerHealth) {
    const engine = engines.value.find(e => e.id === id);
    if (engine) {
      engine.status = status;
      if (health) {
        engine.health = health;
      }
    }
  }

  async function refreshEngines() {
    // This would be replaced with actual API call to get engine status
    console.log('Refreshing engine status...');
    // Mock implementation for now
    // In the actual implementation, we would call the Docker API
  }

  async function startEngine(id: string) {
    // This would be replaced with actual API call to start the engine
    console.log(`Starting engine ${id}...`);
    updateEngineStatus(id, ContainerStatus.Starting);
    
    // Simulate async operation
    setTimeout(() => {
      updateEngineStatus(id, ContainerStatus.Running, ContainerHealth.Healthy);
    }, 2000);
  }

  async function stopEngine(id: string) {
    // This would be replaced with actual API call to stop the engine
    console.log(`Stopping engine ${id}...`);
    updateEngineStatus(id, ContainerStatus.Stopping);
    
    // Simulate async operation
    setTimeout(() => {
      updateEngineStatus(id, ContainerStatus.Stopped);
    }, 2000);
  }

  async function restartEngine(id: string) {
    // This would be replaced with actual API call to restart the engine
    console.log(`Restarting engine ${id}...`);
    await stopEngine(id);
    await startEngine(id);
  }

  return {
    engines,
    runningEngines,
    getEngineById,
    updateEngineStatus,
    refreshEngines,
    startEngine,
    stopEngine,
    restartEngine
  };
});