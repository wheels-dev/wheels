<template>
  <div class="py-6">
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold">Container Management</h1>
      <div class="flex space-x-2">
        <button class="btn btn-primary" @click="refreshContainers">Refresh</button>
        <button class="btn btn-success" @click="startAllContainers">Start All</button>
        <button class="btn btn-error" @click="stopAllContainers">Stop All</button>
      </div>
    </div>
    
    <div class="tabs tabs-boxed mb-6">
      <a class="tab" :class="{ 'tab-active': activeTab === 'engines' }" @click="activeTab = 'engines'">CFML Engines</a>
      <a class="tab" :class="{ 'tab-active': activeTab === 'databases' }" @click="activeTab = 'databases'">Databases</a>
      <a class="tab" :class="{ 'tab-active': activeTab === 'profiles' }" @click="activeTab = 'profiles'">Profiles</a>
    </div>
    
    <!-- CFML Engines Tab -->
    <div v-if="activeTab === 'engines'" class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Lucee 5 Card -->
      <div class="card bg-base-200 shadow-lg">
        <div class="card-body">
          <div class="flex justify-between items-center">
            <h2 class="card-title">Lucee 5</h2>
            <div class="badge badge-success">Running</div>
          </div>
          
          <div class="stats bg-base-300 shadow my-4">
            <div class="stat">
              <div class="stat-title">Status</div>
              <div class="stat-value text-success">Healthy</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Uptime</div>
              <div class="stat-value text-sm">2h 15m</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Port</div>
              <div class="stat-value text-sm">8001</div>
            </div>
          </div>
          
          <div class="flex justify-between">
            <a href="http://localhost:8001" target="_blank" class="btn btn-sm">Open Admin</a>
            <div class="flex space-x-2">
              <button class="btn btn-sm btn-error">Stop</button>
              <button class="btn btn-sm">Restart</button>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Lucee 6 Card -->
      <div class="card bg-base-200 shadow-lg">
        <div class="card-body">
          <div class="flex justify-between items-center">
            <h2 class="card-title">Lucee 6</h2>
            <div class="badge badge-error">Stopped</div>
          </div>
          
          <div class="stats bg-base-300 shadow my-4">
            <div class="stat">
              <div class="stat-title">Status</div>
              <div class="stat-value text-error">Stopped</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Uptime</div>
              <div class="stat-value text-sm">-</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Port</div>
              <div class="stat-value text-sm">8002</div>
            </div>
          </div>
          
          <div class="flex justify-between">
            <a href="http://localhost:8002" target="_blank" class="btn btn-sm btn-disabled">Open Admin</a>
            <div class="flex space-x-2">
              <button class="btn btn-sm btn-success">Start</button>
              <button class="btn btn-sm btn-disabled">Restart</button>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Adobe 2021 Card -->
      <div class="card bg-base-200 shadow-lg">
        <div class="card-body">
          <div class="flex justify-between items-center">
            <h2 class="card-title">Adobe 2021</h2>
            <div class="badge badge-warning">Starting</div>
          </div>
          
          <div class="stats bg-base-300 shadow my-4">
            <div class="stat">
              <div class="stat-title">Status</div>
              <div class="stat-value text-warning">Starting</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Uptime</div>
              <div class="stat-value text-sm">-</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Port</div>
              <div class="stat-value text-sm">8003</div>
            </div>
          </div>
          
          <div class="flex justify-between">
            <a href="http://localhost:8003" target="_blank" class="btn btn-sm btn-disabled">Open Admin</a>
            <div class="flex space-x-2">
              <button class="btn btn-sm btn-error btn-disabled">Stop</button>
              <button class="btn btn-sm btn-disabled">Restart</button>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Databases Tab -->
    <div v-if="activeTab === 'databases'" class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- MySQL Card -->
      <div class="card bg-base-200 shadow-lg">
        <div class="card-body">
          <div class="flex justify-between items-center">
            <h2 class="card-title">MySQL</h2>
            <div class="badge badge-success">Running</div>
          </div>
          
          <div class="stats bg-base-300 shadow my-4">
            <div class="stat">
              <div class="stat-title">Status</div>
              <div class="stat-value text-success">Healthy</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Port</div>
              <div class="stat-value text-sm">3306</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Version</div>
              <div class="stat-value text-sm">8.0</div>
            </div>
          </div>
          
          <div class="flex justify-between">
            <button class="btn btn-sm">View Connection Info</button>
            <div class="flex space-x-2">
              <button class="btn btn-sm btn-error">Stop</button>
              <button class="btn btn-sm">Restart</button>
            </div>
          </div>
        </div>
      </div>
      
      <!-- SQL Server Card -->
      <div class="card bg-base-200 shadow-lg">
        <div class="card-body">
          <div class="flex justify-between items-center">
            <h2 class="card-title">SQL Server</h2>
            <div class="badge badge-success">Running</div>
          </div>
          
          <div class="stats bg-base-300 shadow my-4">
            <div class="stat">
              <div class="stat-title">Status</div>
              <div class="stat-value text-success">Healthy</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Port</div>
              <div class="stat-value text-sm">1433</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Version</div>
              <div class="stat-value text-sm">2019</div>
            </div>
          </div>
          
          <div class="flex justify-between">
            <button class="btn btn-sm">View Connection Info</button>
            <div class="flex space-x-2">
              <button class="btn btn-sm btn-error">Stop</button>
              <button class="btn btn-sm">Restart</button>
            </div>
          </div>
        </div>
      </div>
      
      <!-- PostgreSQL Card -->
      <div class="card bg-base-200 shadow-lg">
        <div class="card-body">
          <div class="flex justify-between items-center">
            <h2 class="card-title">PostgreSQL</h2>
            <div class="badge badge-error">Stopped</div>
          </div>
          
          <div class="stats bg-base-300 shadow my-4">
            <div class="stat">
              <div class="stat-title">Status</div>
              <div class="stat-value text-error">Stopped</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Port</div>
              <div class="stat-value text-sm">5432</div>
            </div>
            
            <div class="stat">
              <div class="stat-title">Version</div>
              <div class="stat-value text-sm">13</div>
            </div>
          </div>
          
          <div class="flex justify-between">
            <button class="btn btn-sm btn-disabled">View Connection Info</button>
            <div class="flex space-x-2">
              <button class="btn btn-sm btn-success">Start</button>
              <button class="btn btn-sm btn-disabled">Restart</button>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Profiles Tab -->
    <div v-if="activeTab === 'profiles'" class="grid grid-cols-1 gap-6">
      <!-- Core Tests Profile -->
      <div class="card bg-base-200 shadow-lg">
        <div class="card-body">
          <div class="flex justify-between items-center">
            <h2 class="card-title">Core Tests Profile</h2>
            <button class="btn btn-primary btn-sm">Start Profile</button>
          </div>
          
          <p class="my-4">This profile provides the necessary containers for running the core CFWheels tests.</p>
          
          <div class="overflow-x-auto">
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th>Container</th>
                  <th>Status</th>
                  <th>Required</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>Lucee 5</td>
                  <td><span class="badge badge-success">Running</span></td>
                  <td>Yes</td>
                </tr>
                <tr>
                  <td>MySQL</td>
                  <td><span class="badge badge-success">Running</span></td>
                  <td>Yes</td>
                </tr>
                <tr>
                  <td>SQL Server</td>
                  <td><span class="badge badge-success">Running</span></td>
                  <td>Yes</td>
                </tr>
                <tr>
                  <td>PostgreSQL</td>
                  <td><span class="badge badge-error">Stopped</span></td>
                  <td>No</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
      
      <!-- Full Test Suite Profile -->
      <div class="card bg-base-200 shadow-lg">
        <div class="card-body">
          <div class="flex justify-between items-center">
            <h2 class="card-title">Full Test Suite Profile</h2>
            <button class="btn btn-primary btn-sm">Start Profile</button>
          </div>
          
          <p class="my-4">This profile starts all containers needed for running the complete test suite across all engines and databases.</p>
          
          <div class="overflow-x-auto">
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th>Container</th>
                  <th>Status</th>
                  <th>Required</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>Lucee 5</td>
                  <td><span class="badge badge-success">Running</span></td>
                  <td>Yes</td>
                </tr>
                <tr>
                  <td>Lucee 6</td>
                  <td><span class="badge badge-error">Stopped</span></td>
                  <td>Yes</td>
                </tr>
                <tr>
                  <td>Adobe 2021</td>
                  <td><span class="badge badge-warning">Starting</span></td>
                  <td>Yes</td>
                </tr>
                <tr>
                  <td>Adobe 2023</td>
                  <td><span class="badge badge-error">Stopped</span></td>
                  <td>Yes</td>
                </tr>
                <tr>
                  <td>MySQL</td>
                  <td><span class="badge badge-success">Running</span></td>
                  <td>Yes</td>
                </tr>
                <tr>
                  <td>SQL Server</td>
                  <td><span class="badge badge-success">Running</span></td>
                  <td>Yes</td>
                </tr>
                <tr>
                  <td>PostgreSQL</td>
                  <td><span class="badge badge-error">Stopped</span></td>
                  <td>Yes</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const activeTab = ref('engines')

const refreshContainers = () => {
  // Refresh container logic will go here
}

const startAllContainers = () => {
  // Start all containers logic will go here
}

const stopAllContainers = () => {
  // Stop all containers logic will go here
}
</script>