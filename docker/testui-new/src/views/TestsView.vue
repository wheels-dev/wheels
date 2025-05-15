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
                
                <!-- Test Bundle Selection -->
                <div class="mb-3">
                  <label class="form-label fw-bold">Test Bundle</label>
                  <select class="form-select" v-model="selectedBundle">
                    <option value="" selected>Select a test bundle</option>
                    <option v-for="bundle in testBundles" :key="bundle.id" :value="bundle.id">
                      {{ bundle.name }}
                    </option>
                  </select>
                </div>
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
                
                <div>
                  <label class="form-label fw-bold">Execution Order</label>
                  <div class="form-check mb-2">
                    <input class="form-check-input" type="radio" name="executionOrder" id="orderAsc" 
                          value="directory asc" v-model="executionOrder">
                    <label class="form-check-label" for="orderAsc">
                      directory asc
                    </label>
                  </div>
                  <div class="form-check">
                    <input class="form-check-input" type="radio" name="executionOrder" id="orderDesc" 
                          value="directory desc" v-model="executionOrder">
                    <label class="form-check-label" for="orderDesc">
                      directory desc
                    </label>
                  </div>
                </div>
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
              <div v-for="item in queue" :key="item.id" class="list-group-item d-flex justify-content-between align-items-center mb-2">
                <div>
                  <div class="fw-semibold mb-1">{{ item.engine.name }} {{ item.engine.version }} + {{ item.database.name }}</div>
                  <div class="small text-muted">{{ item.bundle.name }}</div>
                </div>
                <button class="btn btn-sm btn-outline-danger" title="Remove from queue" @click="removeFromQueue(item.id)">
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
              <div class="col-md-4">
                <div class="p-3 border rounded">
                  <div class="fs-5 fw-bold">{{ summary.total }}</div>
                  <div class="small text-muted">Total Tests</div>
                </div>
              </div>
              <div class="col-md-4">
                <div class="p-3 border rounded border-success bg-success bg-opacity-10">
                  <div class="fs-5 fw-bold text-success">{{ summary.passed }}</div>
                  <div class="small text-muted">Passed</div>
                </div>
              </div>
              <div class="col-md-4">
                <div class="p-3 border rounded border-danger bg-danger bg-opacity-10">
                  <div class="fs-5 fw-bold text-danger">{{ summary.failed + summary.errors }}</div>
                  <div class="small text-muted">Failed</div>
                </div>
              </div>
            </div>
            
            <div v-if="results.length === 0" class="text-center text-muted my-4">
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
                          <span class="badge me-2" :class="{
                            'bg-success': groupedRun.failedCount === 0,
                            'bg-danger': groupedRun.failedCount > 0
                          }">
                            {{ groupedRun.passedCount }}/{{ groupedRun.totalCount }}
                          </span>
                          <span class="badge bg-secondary">
                            {{ (groupedRun.totalCount > 0 ? (groupedRun.passedCount / groupedRun.totalCount * 100) : 0).toFixed(1) }}%
                          </span>
                        </div>
                      </div>
                      <div class="small mt-1">
                        <strong>{{ groupedRun.bundle }}</strong>
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
                            <tr v-for="result in groupedRun.failedTests" :key="result.id" 
                                @click="showTestDetails(result)" style="cursor: pointer"
                                class="border-danger">
                              <td>{{ result.name }}</td>
                              <td class="text-center">
                                <span class="badge" :class="{
                                  'bg-danger': result.status === TestStatus.Failed || result.status === TestStatus.Error,
                                  'bg-warning': result.status === TestStatus.Running
                                }">
                                  {{ result.status.toUpperCase() }}
                                </span>
                              </td>
                              <td class="text-end">{{ result.duration.toFixed(2) }}s</td>
                            </tr>
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
    
    <!-- Test Details (shown only for failed tests) -->
    <div class="row" v-if="activeTest && (activeTest.status === TestStatus.Failed || activeTest.status === TestStatus.Error)">
      <div class="col-12">
        <div class="card shadow-sm">
          <div class="card-header bg-danger bg-opacity-10">
            <h5 class="card-title mb-0">
              <i class="bi bi-file-earmark-code me-2"></i> Failed Test Details
            </h5>
          </div>
          <div class="card-body">
            <div class="alert alert-danger">
              <h5 class="alert-heading">
                <i class="bi bi-exclamation-triangle-fill me-2"></i>{{ activeTest.name }}
              </h5>
              <div class="small mb-2">
                <strong>Engine:</strong> {{ getEngineNameFromTest(activeTest) }},
                <strong>Database:</strong> {{ getDatabaseNameFromTest(activeTest) }}
              </div>
              <p class="mb-0">{{ activeTest.error?.message }}</p>
            </div>
            
            <div class="bg-light p-3 rounded border">
              <pre class="mb-0"><code>{{ activeTest.error?.detail || 'No detailed error information available.' }}</code></pre>
            </div>
          </div>
        </div>
      </div>
    </div>
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
const testBundles = ref<any[]>([])
const engines = ref<any[]>([])
const databases = ref<any[]>([])
const queue = ref<TestQueueItem[]>([])
const results = ref<TestResult[]>([])
const activeTest = ref<TestResult | null>(null)
const summary = ref({
  total: 0,
  passed: 0,
  failed: 0,
  errors: 0,
  skipped: 0
})

// Grouped results for summary cards
const groupedResults = computed(() => {
  const groups = new Map()
  
  results.value.forEach(result => {
    // Create a unique key for each engine/database combination
    const engineKey = result.engine ? `${result.engine.name} ${result.engine.version}` : 'Unknown Engine'
    const dbKey = result.database ? result.database.name : 'Unknown Database'
    const bundleKey = result.bundle ? result.bundle.name : 'Unknown Bundle'
    const groupKey = `${engineKey}|${dbKey}|${bundleKey}`
    
    // Initialize group if it doesn't exist
    if (!groups.has(groupKey)) {
      groups.set(groupKey, {
        engine: engineKey,
        database: dbKey,
        bundle: bundleKey,
        totalCount: 0,
        passedCount: 0,
        failedCount: 0,
        skippedCount: 0,
        failedTests: []
      })
    }
    
    const group = groups.get(groupKey)
    group.totalCount++
    
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
  
  // Convert map to array and sort by failed count (descending)
  return Array.from(groups.values())
    .sort((a, b) => b.failedCount - a.failedCount)
})

// Helper methods for test details
const getEngineNameFromTest = (test: TestResult): string => {
  return test.engine ? `${test.engine.name} ${test.engine.version}` : 'Unknown Engine'
}

const getDatabaseNameFromTest = (test: TestResult): string => {
  return test.database ? test.database.name : 'Unknown Database'
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
  if (!selectedEngine.value || !selectedDatabase.value || !selectedBundle.value) {
    alert('Please select an engine, database, and test bundle')
    return
  }
  
  // Debug information with a direct check of the actual raw values
  console.log('====== CLAUDE FIX APPLIED - VERSION 2.0 ======');
  console.log('Selected engine (raw value):', selectedEngine.value);
  console.log('Selected database (raw value):', selectedDatabase.value);
  console.log('Selected bundle (raw value):', selectedBundle.value);
  
  // Get engine name and version directly from the raw value
  let engineName = '';
  let engineVersion = '';
  
  if (typeof selectedEngine.value === 'string') {
    const parts = selectedEngine.value.split(' ');
    engineName = parts[0] || '';
    engineVersion = parts[1] || '';
    console.log('Split engine parts:', engineName, engineVersion);
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
      id: `${engineName}-${engineVersion}`, 
      name: engineName, 
      version: engineVersion 
    }
  }
  
  let databaseObj = database
  if (!databaseObj) {
    databaseObj = { 
      id: selectedDatabase.toLowerCase().replace(/\s+/g, '-'), 
      name: selectedDatabase 
    }
  }
  
  let bundleObj = bundle
  if (!bundleObj) {
    bundleObj = { 
      id: selectedBundle, 
      name: selectedBundle, 
      path: `/${selectedBundle}` 
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
  console.log('Added to queue:', queueItem)
  
  // Reset selections
  selectedBundle.value = ''
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
  
  isRunning.value = true
  results.value = []
  summary.value = {
    total: 0,
    passed: 0,
    failed: 0,
    errors: 0,
    skipped: 0
  }
  
  try {
    // Run tests for each item in the queue
    for (const item of queue.value) {
      if (!isRunning.value) break // Stop if tests were cancelled
      
      const testRun = await testService.runTests(item.engine, item.database, item.bundle)
      currentRunId.value = testRun.id
      
      // Add metadata to each test result to identify which engine/database/bundle it belongs to
      const resultsWithMetadata = testRun.results.map(result => ({
        ...result,
        engine: item.engine,
        database: item.database,
        bundle: item.bundle
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
}

// Show details for a specific test
const showTestDetails = (test: TestResult) => {
  activeTest.value = test
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