<template>
  <div class="container-fluid py-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <h1 class="mb-0 fs-2">Test Runner</h1>
      <div class="btn-group">
        <button class="btn btn-outline-secondary" @click="clearResults" :disabled="results.length === 0">
          <i class="bi bi-trash me-1"></i> Clear Results
        </button>
      </div>
    </div>
    
    <!-- Top row with Configuration and Test Queue side by side -->
    <div class="row g-4 mb-4">
      <!-- Test Configuration Panel -->
      <div class="col-md-6">
        <div class="card shadow-sm h-100">
          <div class="card-header bg-primary bg-opacity-10">
            <h5 class="card-title mb-0">
              <i class="bi bi-gear me-2"></i> Configuration
            </h5>
          </div>
          <div class="card-body">
            <div class="row">
              <div class="col-md-6">
                <!-- CFML Engine Selection -->
                <div class="mb-3">
                  <label class="form-label fw-bold">CFML Engine</label>
                  <select class="form-select" v-model="selectedEngine">
                    <option value="" selected>Select an engine</option>
                    <option v-for="engine in engines" :key="engine.id" :value="engine.name + ' ' + engine.version">
                      {{ engine.name }} {{ engine.version }}
                      <span v-if="engine.status !== 'running'" class="text-danger">(not running)</span>
                    </option>
                  </select>
                </div>
                
                <!-- Database Selection -->
                <div class="mb-3">
                  <label class="form-label fw-bold">Database</label>
                  <select class="form-select" v-model="selectedDatabase">
                    <option value="" selected>Select a database</option>
                    <option v-for="db in databases" :key="db.id" :value="db.name">
                      {{ db.name }} {{ db.version ? `(${db.version})` : '' }}
                      <span v-if="db.status !== 'running'" class="text-danger">(not running)</span>
                    </option>
                  </select>
                </div>
                
                <!-- Test Bundle is now hardcoded to "all" -->
                <input type="hidden" v-model="selectedBundle" value="all">
              </div>
              
              <div class="col-md-6">
                <!-- Additional Options -->
                <div class="mb-2">
                  <label class="form-label fw-bold">Options</label>
                </div>
                <div class="form-check mb-2">
                  <input class="form-check-input" type="checkbox" id="preflightCheck" v-model="preflight">
                  <label class="form-check-label" for="preflightCheck">
                    Run Pre-flight Checks
                  </label>
                </div>
                
                <div class="form-check mb-2">
                  <input class="form-check-input" type="checkbox" id="autoStart" v-model="autoStart">
                  <label class="form-check-label" for="autoStart">
                    Auto-start Required Containers
                  </label>
                </div>
                
                <div class="form-check mb-3">
                  <input class="form-check-input" type="checkbox" id="failFast" v-model="failFast">
                  <label class="form-check-label" for="failFast">
                    Fail Fast
                  </label>
                </div>
                
                <!-- Execution Order is now hardcoded to "directory asc" -->
                <input type="hidden" v-model="executionOrder" value="directory asc">
              </div>
            </div>
          </div>
          <div class="card-footer">
            <button class="btn btn-primary w-100" @click="addToQueue">
              <i class="bi bi-plus-circle me-1"></i> Add to Queue
            </button>
          </div>
        </div>
      </div>
      
      <!-- Test Queue Panel -->
      <div class="col-md-6">
        <div class="card shadow-sm h-100">
          <div class="card-header bg-primary bg-opacity-10">
            <h5 class="card-title mb-0">
              <i class="bi bi-list-check me-2"></i> Test Queue
            </h5>
          </div>
          <div class="card-body">
            <div v-if="queue.length === 0" class="text-center text-muted my-4">
              <i class="bi bi-inbox-fill fs-1 d-block mb-2"></i>
              <p>No tests in queue</p>
              <p class="small">Configure tests and click "Add to Queue"</p>
            </div>
            
            <div v-else class="list-group">
              <div v-for="(item, index) in queue" :key="item.id" 
                   class="list-group-item d-flex justify-content-between align-items-center"
                   :class="{
                     'border-primary': isRunning && currentTestIndex === index
                   }">
                <div class="flex-grow-1">
                  <div class="d-flex align-items-center">
                    <div v-if="isRunning && currentTestIndex === index" class="me-2">
                      <div class="spinner-border spinner-border-sm text-primary" role="status">
                        <span class="visually-hidden">Running...</span>
                      </div>
                    </div>
                    <div>
                      <div class="fw-semibold mb-1">{{ item.engine.name }} {{ item.engine.version }} + {{ item.database.name }}</div>
                      <div class="small text-muted">
                        {{ item.bundle.name }}
                        <span v-if="isRunning && currentTestIndex === index" class="ms-2">
                          <i class="bi bi-clock text-primary"></i>
                          <span class="text-primary">{{ formatElapsedTime(currentTestStartTime) }}</span>
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                <button class="btn btn-sm btn-outline-danger" 
                        title="Remove from queue" 
                        @click="removeFromQueue(item.id)"
                        :disabled="isRunning">
                  <i class="bi bi-x-lg"></i>
                </button>
              </div>
            </div>
            
            <div class="mt-3 pt-3 border-top">
              <div class="d-flex gap-2">
                <button class="btn btn-danger flex-grow-1" @click="clearQueue" :disabled="queue.length === 0">
                  <i class="bi bi-trash me-1"></i> Clear Queue
                </button>
                <button class="btn btn-primary flex-grow-1" @click="startTests" :disabled="isRunning || queue.length === 0">
                  <i class="bi bi-play-fill me-1"></i>
                  <span v-if="isRunning">Running...</span>
                  <span v-else>Run Tests</span>
                </button>
                <button class="btn btn-outline-danger" @click="stopTests" :disabled="!isRunning">
                  <i class="bi bi-stop-fill me-1"></i> Stop
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Results Panel - Full width below Configuration and Queue -->
    <div class="row g-4 mb-4">
      <div class="col-12">
        <div class="card shadow-sm">
          <div class="card-header bg-primary bg-opacity-10">
            <h5 class="card-title mb-0">
              <i class="bi bi-clipboard-check me-2"></i> Results
            </h5>
          </div>
          <div class="card-body">
            <!-- Overall Summary Stats -->
            <div class="row text-center g-2 mb-4">
              <div class="col-lg mb-2">
                <div class="p-3 border rounded">
                  <div class="fs-5 fw-bold">{{ summary.total }}</div>
                  <div class="small text-muted">Total Tests</div>
                </div>
              </div>
              <div class="col-lg mb-2">
                <div class="p-3 border rounded border-success bg-success bg-opacity-10">
                  <div class="fs-5 fw-bold text-success">{{ summary.passed }}</div>
                  <div class="small text-muted">Passed</div>
                </div>
              </div>
              <div class="col-lg mb-2">
                <div class="p-3 border rounded border-danger bg-danger bg-opacity-10">
                  <div class="fs-5 fw-bold text-danger">{{ summary.failed + summary.errors }}</div>
                  <div class="small text-muted">Failed</div>
                </div>
              </div>
              <div class="col-lg mb-2">
                <div class="p-3 border rounded border-warning bg-warning bg-opacity-10">
                  <div class="fs-5 fw-bold text-warning">{{ summary.skipped }}</div>
                  <div class="small text-muted">Skipped</div>
                </div>
              </div>
              <div class="col-lg mb-2">
                <div class="p-3 border rounded border-info bg-info bg-opacity-10">
                  <div class="fs-5 fw-bold text-info">
                    <i class="bi bi-hourglass-split me-1"></i>{{ formatDuration(getTotalDuration) }}
                  </div>
                  <div class="small text-muted">Duration</div>
                </div>
              </div>
            </div>
            
            <div v-if="results.length === 0 && !isRunning" class="text-center text-muted my-4">
              <i class="bi bi-clipboard-check fs-1 d-block mb-2"></i>
              <p>No test results yet</p>
              <p class="small">Run tests to see results here</p>
            </div>
            
            <div v-else>
              <!-- Group results by engine/database -->
              <div class="mb-4">
                <div v-for="(groupedRun, index) in groupedResults" :key="index" class="mb-3">
                  <div class="card w-100">
                    <div class="card-header p-2" :class="{
                      'bg-success bg-opacity-10': groupedRun.failedCount === 0,
                      'bg-danger bg-opacity-10': groupedRun.failedCount > 0,
                    }">
                      <div class="d-flex justify-content-between align-items-center">
                        <h6 class="mb-0">
                          {{ groupedRun.engine }} + {{ groupedRun.database }}
                        </h6>
                        <div>
                          <span class="badge bg-success me-1">
                            {{ groupedRun.passedCount }}
                          </span>
                          <span class="badge bg-danger me-1" v-if="groupedRun.failedCount > 0">
                            {{ groupedRun.failedCount }}
                          </span>
                          <span class="badge bg-warning me-1" v-if="groupedRun.skippedCount > 0">
                            {{ groupedRun.skippedCount }}
                          </span>
                          <span class="badge bg-secondary me-1">
                            {{ (groupedRun.totalCount > 0 ? (groupedRun.passedCount / groupedRun.totalCount * 100) : 0).toFixed(1) }}%
                          </span>
                        </div>
                      </div>
                      <div class="small mt-1 d-flex justify-content-between">
                        <div>
                          <strong>{{ groupedRun.bundle }}</strong>
                          <span class="text-muted ms-2">
                            <i class="bi bi-calendar3 me-1"></i>{{ formatTimestamp(groupedRun.timestamp) }}
                          </span>
                        </div>
                        <span class="text-muted">
                          <i class="bi bi-clock me-1"></i>{{ formatDuration(groupedRun.duration) }}
                        </span>
                      </div>
                      <div v-if="groupedRun.testUrl" class="small mt-1">
                        <a :href="getHtmlTestUrl(groupedRun.testUrl)" target="_blank" class="text-decoration-none" :title="groupedRun.testUrl">
                          <i class="bi bi-link-45deg"></i>
                          <span class="text-muted">Test URL: </span>
                          <span class="text-truncate" style="max-width: 400px; display: inline-block; vertical-align: bottom;">
                            {{ getHtmlTestUrl(groupedRun.testUrl) }}
                          </span>
                        </a>
                        <button 
                          class="btn btn-sm btn-link p-0 ms-2" 
                          @click="copyToClipboard(getHtmlTestUrl(groupedRun.testUrl))"
                          title="Copy URL to clipboard"
                        >
                          <i class="bi bi-clipboard"></i>
                        </button>
                      </div>
                    </div>
                    
                    <!-- Collapsible detail section (only displayed if there are failures) -->
                    <div v-if="groupedRun.failedCount > 0" class="card-body p-2">
                      <!-- Failed tests only -->
                      <div class="table-responsive">
                        <table class="table table-sm table-hover mb-0">
                          <thead>
                            <tr>
                              <th>Test Name</th>
                              <th class="text-center" style="width: 100px">Status</th>
                              <th class="text-end" style="width: 100px">Duration</th>
                            </tr>
                          </thead>
                          <tbody>
                            <template v-for="result in groupedRun.failedTests" :key="result.id">
                              <tr 
                                @click="toggleTestDetails(result)" 
                                style="cursor: pointer"
                                :class="{'border-danger': true, 'table-warning': result.id === activeTestId}">
                                <td>
                                  <i class="bi" :class="result.id === activeTestId ? 'bi-chevron-down' : 'bi-chevron-right'"></i>
                                  {{ result.name }}
                                </td>
                                <td class="text-center">
                                  <span class="badge" :class="{
                                    'bg-danger': result.status === TestStatus.Failed || result.status === TestStatus.Error,
                                    'bg-warning': result.status === TestStatus.Running
                                  }">
                                    {{ result.status.toUpperCase() }}
                                  </span>
                                </td>
                                <td class="text-end">{{ formatDuration(result.duration) }}</td>
                              </tr>
                              <!-- Expandable test details row -->
                              <tr v-if="result.id === activeTestId">
                                <td colspan="3" class="border-0 p-0">
                                  <div class="alert alert-danger mx-2 mb-2 mt-1">
                                    <h6 class="alert-heading">
                                      <i class="bi bi-exclamation-triangle-fill me-2"></i>Error Details
                                    </h6>
                                    <div class="small mb-2">
                                      <strong>Engine:</strong> {{ getEngineNameFromTest(result) }},
                                      <strong>Database:</strong> {{ getDatabaseNameFromTest(result) }}
                                    </div>
                                    <p class="mb-1">{{ result.error?.message }}</p>
                                  </div>
                                  <div class="bg-dark bg-opacity-10 p-3 rounded border mx-2 mb-2 error-detail-container">
                                    <pre class="mb-0"><code>{{ result.error?.detail || 'No detailed error information available.' }}</code></pre>
                                  </div>
                                </td>
                              </tr>
                            </template>
                          </tbody>
                        </table>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <div class="text-end mt-3">
              <button class="btn btn-sm btn-outline-secondary" @click="copyResults" :disabled="results.length === 0">
                <i class="bi bi-clipboard me-1"></i> Copy Results
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Test details are now shown inline with each failed test -->
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch, toRaw, unref } from 'vue'
import { dockerService } from '@/services/docker.service'
import { testService } from '@/services/test.service'
import { TestStatus, TestRun, TestQueueItem, TestResult } from '@/types'

// State
const isRunning = ref(false)
const currentRunId = ref<string | null>(null)
const currentTestIndex = ref(-1)
const currentTestStartTime = ref<Date | null>(null)
const testBundles = ref<any[]>([])
const engines = ref<any[]>([])
const databases = ref<any[]>([])
const queue = ref<TestQueueItem[]>([])
const results = ref<TestResult[]>([])
const activeTest = ref<TestResult | null>(null)
const activeTestId = ref<string | null>(null)
const summary = ref({
  total: 0,
  passed: 0,
  failed: 0,
  errors: 0,
  skipped: 0
})


// Computed property for total test duration
const getTotalDuration = computed(() => {
  if (results.value.length === 0) return 0;
  
  // Either use the sum of all test durations or the overall run duration if available
  const totalDuration = results.value.reduce((total, result) => total + (result.duration || 0), 0);
  return Math.max(totalDuration, summary.value.duration || 0);
});

// Grouped results for summary cards
const groupedResults = computed(() => {
  const groups = new Map()
  
  results.value.forEach(result => {
    // Group by runId to keep each test run separate
    const runId = result.runId || 'unknown-run'
    
    // Initialize group if it doesn't exist
    if (!groups.has(runId)) {
      const engineKey = result.engine ? `${result.engine.name} ${result.engine.version}` : 'Unknown Engine'
      const dbKey = result.database ? result.database.name : 'Unknown Database'
      const bundleKey = result.bundle ? result.bundle.name : 'Unknown Bundle'
      
      groups.set(runId, {
        runId: runId,
        engine: engineKey,
        database: dbKey,
        bundle: bundleKey,
        totalCount: 0,
        passedCount: 0,
        failedCount: 0,
        skippedCount: 0,
        failedTests: [],
        duration: 0,
        timestamp: result.timestamp || new Date().toISOString(),
        testUrl: result.testUrl
      })
    }
    
    const group = groups.get(runId)
    group.totalCount++
    
    // Add test duration to the group duration
    group.duration += result.duration || 0
    
    // Categorize test result
    if (result.status === TestStatus.Passed) {
      group.passedCount++
    } else if (result.status === TestStatus.Failed || result.status === TestStatus.Error) {
      group.failedCount++
      group.failedTests.push(result)
    } else if (result.status === TestStatus.Skipped) {
      group.skippedCount++
    }
  })
  
  // Convert map to array and sort by timestamp (most recent first)
  return Array.from(groups.values())
    .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
})

// Helper methods for test details
const getEngineNameFromTest = (test: TestResult): string => {
  return test.engine ? `${test.engine.name} ${test.engine.version}` : 'Unknown Engine'
}

const getDatabaseNameFromTest = (test: TestResult): string => {
  return test.database ? test.database.name : 'Unknown Database'
}

// Format elapsed time since start
const formatElapsedTime = (startTime: Date | null): string => {
  if (!startTime) return '0s'
  const elapsed = Date.now() - startTime.getTime()
  const seconds = Math.floor(elapsed / 1000)
  if (seconds < 60) return `${seconds}s`
  const minutes = Math.floor(seconds / 60)
  const remainingSeconds = seconds % 60
  return `${minutes}m ${remainingSeconds}s`
}

// Update elapsed time every second
let elapsedInterval: ReturnType<typeof setInterval> | null = null
const startElapsedTimer = () => {
  if (elapsedInterval) clearInterval(elapsedInterval)
  elapsedInterval = setInterval(() => {
    // Force Vue to re-render by updating the start time reference
    if (currentTestStartTime.value) {
      currentTestStartTime.value = new Date(currentTestStartTime.value)
    }
  }, 1000)
}

const stopElapsedTimer = () => {
  if (elapsedInterval) {
    clearInterval(elapsedInterval)
    elapsedInterval = null
  }
}

// Format timestamp to a human-readable string
const formatTimestamp = (timestamp: string): string => {
  const date = new Date(timestamp)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  
  if (diffMins < 1) return 'just now'
  if (diffMins < 60) return `${diffMins}m ago`
  
  const diffHours = Math.floor(diffMins / 60)
  if (diffHours < 24) return `${diffHours}h ago`
  
  // For older runs, show the actual time
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

// Format duration in seconds or milliseconds to a human-readable string
const formatDuration = (duration: number): string => {
  // Handle invalid or zero duration
  if (!duration || duration <= 0) return '0s'
  
  // Check if duration is likely in milliseconds (large number)
  // This helps handle cases where the API might return ms or seconds
  const seconds = duration > 1000 ? duration / 1000 : duration
  
  // For very short durations (less than 1 second)
  if (seconds < 1) {
    const ms = Math.round(seconds * 1000)
    return `${ms}ms`
  }
  
  // For durations less than a minute
  if (seconds < 60) {
    // Use 1 decimal place for seconds
    return `${seconds.toFixed(1)}s`
  }
  
  // For longer durations
  const minutes = Math.floor(seconds / 60)
  const remainingSeconds = Math.round(seconds % 60)
  
  if (remainingSeconds === 0) {
    return `${minutes}m`
  }
  
  return `${minutes}m ${remainingSeconds}s`
}

// Convert JSON test URL to HTML-friendly URL
const getHtmlTestUrl = (jsonUrl: string): string => {
  if (!jsonUrl) return ''
  
  // Remove format=json and timeout parameters to get a cleaner HTML URL
  const url = new URL(jsonUrl)
  url.searchParams.delete('format')
  url.searchParams.delete('timeout')
  url.searchParams.delete('sort')
  
  return url.toString()
}

// Copy text to clipboard
const copyToClipboard = async (text: string) => {
  try {
    await navigator.clipboard.writeText(text)
    // Could add a toast notification here
  } catch (err) {
    console.error('Failed to copy to clipboard:', err)
  }
}

// Form values
const selectedEngine = ref('')
const selectedDatabase = ref('')
const selectedBundle = ref('')
const preflight = ref(true)
const autoStart = ref(true)
const failFast = ref(false)
const executionOrder = ref('directory asc')

// Fetch available test bundles and engines on component load
onMounted(async () => {
  await Promise.all([
    fetchTestBundles(),
    fetchEnginesAndDatabases()
  ])
  
  // Automatically set the bundle to "all"
  selectedBundle.value = 'all'
})

// Fetch test bundles
const fetchTestBundles = async () => {
  try {
    testBundles.value = await testService.getTestBundles()
  } catch (error) {
    console.error('Error fetching test bundles:', error)
  }
}

// Fetch available engines and databases
const fetchEnginesAndDatabases = async () => {
  try {
    const containers = await dockerService.getContainers()
    
    // Extract engines
    engines.value = containers
      .filter(c => c.type === 'engine')
      .map(c => {
        // Extract engine name and version from image
        const nameParts = c.name.split('-')
        let name = 'Unknown'
        let version = ''
        
        if (c.name.includes('lucee5')) {
          name = 'Lucee'
          version = '5'
        } else if (c.name.includes('lucee6')) {
          name = 'Lucee'
          version = '6'
        } else if (c.name.includes('lucee7')) {
          name = 'Lucee'
          version = '7'
        } else if (c.name.includes('adobe2018')) {
          name = 'Adobe'
          version = '2018'
        } else if (c.name.includes('adobe2021')) {
          name = 'Adobe'
          version = '2021'
        } else if (c.name.includes('adobe2023')) {
          name = 'Adobe'
          version = '2023'
        }
        
        return {
          id: c.id,
          name,
          version,
          status: c.status,
          health: c.health
        }
      })
      
    // Extract databases
    databases.value = containers
      .filter(c => c.type === 'database')
      .map(c => {
        let name = 'Unknown'
        let version = ''
        
        if (c.name.includes('mysql') || c.image.includes('mysql')) {
          name = 'MySQL'
          version = c.image.split(':')[1] || ''
        } else if (c.name.includes('postgres') || c.image.includes('postgres')) {
          name = 'PostgreSQL'
          version = c.image.split(':')[1] || ''
        } else if (c.name.includes('sqlserver') || c.image.includes('sqlserver')) {
          name = 'SQL Server'
        } else if (c.name.includes('oracle') || c.image.includes('oracle')) {
          name = 'Oracle'
          version = c.image.split(':')[1] || ''
        }
        
        return {
          id: c.id,
          name,
          version,
          status: c.status,
          health: c.health
        }
      })
      
    // Check if any Lucee engine is running
    const hasRunningLucee = engines.value.some(e => 
      e.name === 'Lucee' && e.status === 'running'
    )
    
    // Add H2 database (embedded in Lucee)
    // Always add H2 as an option, but mark it as running only if Lucee is running
    databases.value.push({
      id: 'h2-embedded',
      name: 'H2',
      version: 'Embedded',
      status: hasRunningLucee ? 'running' : 'stopped',
      health: hasRunningLucee ? 'healthy' : undefined
    })
    
    // Auto-select H2 when Lucee is selected 
    // Add watch effect for engine selection - with type safety
    watch(selectedEngine, (newValue) => {
      // Add safety check to prevent errors with non-string values
      console.log('Watch triggered with value:', newValue, 'type:', typeof newValue);
      
      if (newValue && typeof newValue === 'string' && newValue.includes('Lucee')) {
        console.log('Auto-selecting H2 database for Lucee engine');
        selectedDatabase.value = 'H2';
      }
    })
  } catch (error) {
    console.error('Error fetching engines and databases:', error)
  }
}

// Queue a test configuration
const addToQueue = () => {
  // Always use "all" for the bundle
  selectedBundle.value = 'all'
  
  if (!selectedEngine.value || !selectedDatabase.value) {
    alert('Please select an engine and database')
    return
  }
  
  // Debug logging removed - fix has been applied
  
  // Get engine name and version directly from the raw value
  let engineName = '';
  let engineVersion = '';
  
  if (typeof selectedEngine.value === 'string') {
    const parts = selectedEngine.value.split(' ');
    engineName = parts[0] || '';
    engineVersion = parts[1] || '';
  }
  
  // Find engine by name + version combination
  const engine = engines.value.find(e => 
    e.name === engineName && e.version === engineVersion
  )
  
  // Find database by name - using the raw value directly
  const database = databases.value.find(d => 
    d.name === selectedDatabase.value
  )
  
  // Find bundle by id - using the raw value directly
  const bundle = testBundles.value.find(b => 
    b.id === selectedBundle.value
  )
  
  // If we can't find the exact objects, create them from the selected values
  let engineObj = engine
  if (!engineObj) {
    engineObj = { 
      id: `${engineName.toLowerCase()}${engineVersion}`, 
      name: engineName, 
      version: engineVersion,
      type: `${engineName.toLowerCase()}${engineVersion}` as any,
      port: engineName === 'Lucee' && engineVersion === '5' ? 60005 :
            engineName === 'Lucee' && engineVersion === '6' ? 60006 :
            engineName === 'Lucee' && engineVersion === '7' ? 60007 :
            engineName === 'Adobe' && engineVersion === '2018' ? 62018 :
            engineName === 'Adobe' && engineVersion === '2021' ? 62021 :
            engineName === 'Adobe' && engineVersion === '2023' ? 62023 : 8080
    }
  }
  
  let databaseObj = database
  if (!databaseObj) {
    databaseObj = { 
      id: selectedDatabase.value.toLowerCase().replace(/\s+/g, '-'), 
      name: selectedDatabase.value,
      type: selectedDatabase.value.toLowerCase().replace(/\s+/g, '') as any
    }
  }
  
  let bundleObj = bundle
  if (!bundleObj) {
    bundleObj = { 
      id: selectedBundle.value, 
      name: selectedBundle.value, 
      path: `/${selectedBundle.value}` 
    }
  }
  
  const queueItem: TestQueueItem = {
    id: `${Date.now()}`,
    engine: engineObj,
    database: databaseObj,
    bundle: bundleObj,
    options: {
      preflight: preflight.value,
      autoStart: autoStart.value,
      failFast: failFast.value,
      executionOrder: executionOrder.value as 'directory asc' | 'directory desc'
    }
  }
  
  queue.value.push(queueItem)
  
  // Reset selections (bundle stays as 'all')
  selectedBundle.value = 'all'
}

// Remove an item from the queue
const removeFromQueue = (itemId: string) => {
  queue.value = queue.value.filter(item => item.id !== itemId)
}

// Clear the queue
const clearQueue = () => {
  queue.value = []
}

// Start running tests
const startTests = async () => {
  if (queue.value.length === 0) {
    alert('Test queue is empty')
    return
  }
  
  try {
    isRunning.value = true
    results.value = []
    activeTest.value = null
    activeTestId.value = null
    summary.value = {
      total: 0,
      passed: 0,
      failed: 0,
      errors: 0,
      skipped: 0
    }
  
  // Reset test tracking
  currentTestIndex.value = -1
  currentTestStartTime.value = null
  
  // Start the elapsed timer
  startElapsedTimer()
  
  try {
    // Run tests for each item in the queue
    for (let i = 0; i < queue.value.length; i++) {
      const item = queue.value[i]
      if (!isRunning.value) break // Stop if tests were cancelled
      
      // Update current test tracking
      currentTestIndex.value = i
      currentTestStartTime.value = new Date()
      
      // Debug: Check if testService is available
      console.log('TestService available:', typeof testService)
      console.log('runTests method:', typeof testService.runTests)
      
      let testRun
      try {
        testRun = await testService.runTests(item.engine, item.database, item.bundle)
      } catch (serviceError) {
        console.error('Error calling testService.runTests:', serviceError)
        // Create a mock response for now
        testRun = {
          id: `${Date.now()}`,
          engine: item.engine,
          database: item.database,
          bundle: item.bundle,
          status: TestStatus.Error,
          startTime: new Date().toISOString(),
          endTime: new Date().toISOString(),
          duration: 0,
          results: [{
            id: 'error',
            name: 'Test Service Error',
            status: TestStatus.Error,
            duration: 0,
            timestamp: new Date().toISOString(),
            error: {
              message: serviceError.message || 'Unknown error',
              detail: serviceError.stack || 'No stack trace available'
            }
          }],
          summary: {
            total: 1,
            passed: 0,
            failed: 0,
            errors: 1,
            skipped: 0
          }
        }
      }
      currentRunId.value = testRun.id
      
      // Generate a unique run ID for this test suite execution
      const runId = `run-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
      
      // Add metadata to each test result to identify which engine/database/bundle it belongs to
      const resultsWithMetadata = testRun.results.map(result => ({
        ...result,
        engine: item.engine,
        database: item.database,
        bundle: item.bundle,
        runId: runId,
        testUrl: testRun.testUrl
      }))
      
      // Update results and summary
      results.value = [...results.value, ...resultsWithMetadata]
      summary.value.total += testRun.summary.total
      summary.value.passed += testRun.summary.passed
      summary.value.failed += testRun.summary.failed
      summary.value.errors += testRun.summary.errors
      summary.value.skipped += testRun.summary.skipped
      
      // If failFast is enabled and tests failed, stop
      if (item.options.failFast && (testRun.summary.failed > 0 || testRun.summary.errors > 0)) {
        break
      }
    }
  } catch (error) {
    console.error('Error running tests:', error)
  } finally {
    isRunning.value = false
    currentRunId.value = null
    currentTestIndex.value = -1
    currentTestStartTime.value = null
    stopElapsedTimer()
  }
  } catch (outerError) {
    console.error('Fatal error in startTests:', outerError)
    isRunning.value = false
    alert('An error occurred while starting tests. Please check the console.')
  }
}

// Stop running tests
const stopTests = async () => {
  if (currentRunId.value) {
    await testService.stopTests(currentRunId.value)
  }
  
  isRunning.value = false
  currentRunId.value = null
}

// Clear test results
const clearResults = () => {
  results.value = []
  summary.value = {
    total: 0,
    passed: 0,
    failed: 0,
    errors: 0,
    skipped: 0
  }
  activeTest.value = null
  activeTestId.value = null
}

// Toggle test details expansion for the clicked test
const toggleTestDetails = (test: TestResult) => {
  // If clicking the same test that's already active, collapse it
  if (activeTestId.value === test.id) {
    activeTestId.value = null
    activeTest.value = null
  } else {
    // Otherwise, expand the clicked test and collapse any others
    activeTestId.value = test.id
    activeTest.value = test
  }
}

// Copy results to clipboard
const copyResults = () => {
  const textResults = results.value.map(result => {
    return `${result.name}: ${result.status} (${result.duration.toFixed(2)}s)`
  }).join('\n')
  
  navigator.clipboard.writeText(textResults)
    .then(() => alert('Results copied to clipboard'))
    .catch(() => alert('Failed to copy results'))
}
</script>

<style scoped>
/* Custom styles for error detail container to ensure proper text color in both themes */
.error-detail-container {
  color: var(--bs-body-color);
}

/* When in dark mode, ensure text is visible */
@media (prefers-color-scheme: dark) {
  .error-detail-container {
    color: #f8f9fa !important; /* Light color for dark mode */
  }
}

/* When in light mode, ensure text is visible */
@media (prefers-color-scheme: light) {
  .error-detail-container {
    color: #212529 !important; /* Dark color for light mode */
  }
}
</style>