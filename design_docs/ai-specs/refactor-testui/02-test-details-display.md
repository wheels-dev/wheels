# Test Details Display Enhancement Specification

This document details the design for enhancing the test results display in the Wheels TestUI, including improved visualization, detailed error information, and interactive exploration features.

## Current Test Display Assessment

The current TestUI has a basic test results display:
- Simple pass/fail status indicators
- Limited error details
- No hierarchical test structure display
- Minimal filtering capabilities
- Basic summary statistics

## Test Details Enhancement Strategy

### Test Results Dashboard

#### Summary Panel

- **Overview Card**:
  - Test suite name and identification
  - Execution timestamp information (started, ended)
  - Total counts (bundles, suites, specs)
  - Pass/fail/error/skipped totals with percentage
  - Visual status indicators
  - Total duration with visual indicator
  - Quick filters for failed/passed tests

- **Stats Visualization**:
  - Donut chart showing pass/fail ratio
  - Bar chart for test counts by category
  - Timeline representation of test duration
  - Comparison with previous runs (if available)

- **Engine & Database Info**:
  - Engine type and version (Lucee 5/6, Adobe 2018/2021/2023)
  - Database type and connection details
  - Environment variables and settings
  - Connection verification status

#### Test Navigation and Filtering

- **Search and Filter Bar**:
  - Full-text search across test names and messages
  - Filter dropdowns:
    - Status (All, Passed, Failed, Error, Skipped)
    - Duration (Fast, Medium, Slow)
    - Test type or category
    - Bundle or suite name
  - Save and reuse filter combinations
  - Clear all filters button

- **Hierarchical Tree View**:
  - Expandable/collapsible tree structure
  - Bundle > Suite > Spec hierarchy
  - Color-coded status indicators at each level
  - Count badges showing pass/fail at each node
  - Quick actions (expand all, collapse all)
  - Focus on specific branch

### Test Details View

- **Test Card Component**:
  - Header with test name and status badge
  - Expandable/collapsible content
  - Duration and timestamp information
  - Tags or categories
  - Action buttons (re-run, view details, copy)

- **Success Details**:
  - Confirmation of passing status
  - Assertions passed count
  - Performance metrics
  - Before/after state (if available)

- **Error Details Panel**:
  - Error type classification
  - Full error message with formatting
  - Expected vs. actual results comparison
  - Context variables at time of error
  - Related code snippet with error line highlighted

- **Stack Trace Visualization**:
  - Formatted stack trace with syntax highlighting
  - Collapsible stack frames
  - Links to source locations (if available)
  - Filter for application vs. framework code
  - Copy functionality for debugging

### Advanced Interactions

- **Diff View for Comparisons**:
  - Side-by-side comparison for:
    - Expected vs. actual results
    - Previous vs. current runs
    - Different CFML engines
  - Syntax highlighting for differences
  - Line-by-line comparison
  - Expandable context for more lines

- **Timeline View**:
  - Chronological representation of test execution
  - Markers for significant events
  - Hover tooltips with detailed information
  - Zoom in/out functionality
  - Filtering by time range

- **Detail Expansion Controls**:
  - Progressive disclosure of information
  - "Show more" toggles for verbose content
  - Keyboard shortcuts for navigation
  - Remember expanded state between views

## Technical Specifications

### Component Architecture

- **Test Results Components**:
  - `TestSummary`: Overview with statistics
  - `TestTreeView`: Hierarchical navigation
  - `TestCard`: Individual test display
  - `ErrorDetail`: Comprehensive error information
  - `DiffViewer`: Comparison visualization
  - `TestTimeline`: Execution visualization
  - `FilterBar`: Search and filtering controls

### Data Structures

```typescript
interface TestResult {
  id: string;
  name: string;
  status: 'passed' | 'failed' | 'error' | 'skipped';
  duration: number;
  startTime: string;
  endTime: string;
  engine: string;
  database: string;
  bundles: TestBundle[];
  totalSpecs: number;
  totalPass: number;
  totalFail: number;
  totalError: number;
  totalSkipped: number;
}

interface TestBundle {
  id: string;
  name: string;
  path: string;
  suites: TestSuite[];
  totalDuration: number;
  totalPass: number;
  totalFail: number;
  totalError: number;
  totalSkipped: number;
  totalSpecs: number;
}

interface TestSuite {
  id: string;
  name: string;
  status: string;
  specs: TestSpec[];
  totalDuration: number;
  totalPass: number;
  totalFail: number;
  totalError: number;
  totalSkipped: number;
}

interface TestSpec {
  id: string;
  name: string;
  status: string;
  duration: number;
  startTime: string;
  endTime: string;
  failMessage?: string;
  failDetail?: string;
  failStacktrace?: string;
  failOrigin?: any;
  debugBuffer?: any[];
}

interface TestFilter {
  status?: string[];
  search?: string;
  duration?: [number, number];
  bundle?: string[];
  suite?: string[];
}
```

### Component Examples

#### Test Summary Component

```vue
<template>
  <div class="test-summary card">
    <div class="card-header">
      <h2 class="card-title">Test Results Summary</h2>
      <div class="actions">
        <button class="btn btn-sm" @click="exportResults">
          Export Results
        </button>
      </div>
    </div>
    
    <div class="card-body">
      <div class="summary-grid">
        <div class="summary-item">
          <h3>Overview</h3>
          <div class="stats">
            <div class="stat">
              <span class="stat-title">Total Tests</span>
              <span class="stat-value">{{ results.totalSpecs }}</span>
            </div>
            <div class="stat">
              <span class="stat-title">Bundles</span>
              <span class="stat-value">{{ results.totalBundles }}</span>
            </div>
            <div class="stat">
              <span class="stat-title">Duration</span>
              <span class="stat-value">{{ formatDuration(results.totalDuration) }}</span>
            </div>
          </div>
        </div>
        
        <div class="summary-item">
          <h3>Results</h3>
          <div class="stats">
            <div class="stat">
              <span class="stat-title">Passed</span>
              <span class="stat-value text-success">{{ results.totalPass }}</span>
            </div>
            <div class="stat">
              <span class="stat-title">Failed</span>
              <span class="stat-value text-error">{{ results.totalFail }}</span>
            </div>
            <div class="stat">
              <span class="stat-title">Errors</span>
              <span class="stat-value text-warning">{{ results.totalError }}</span>
            </div>
            <div class="stat">
              <span class="stat-title">Skipped</span>
              <span class="stat-value text-info">{{ results.totalSkipped }}</span>
            </div>
          </div>
        </div>
        
        <div class="summary-item">
          <h3>Charts</h3>
          <div class="chart-container">
            <canvas ref="resultChart"></canvas>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { Chart, registerables } from 'chart.js'
import { formatDuration } from '../utils/formatting'

Chart.register(...registerables)

const props = defineProps<{
  results: TestResult
}>()

const resultChart = ref<HTMLCanvasElement | null>(null)
let chart: Chart | null = null

onMounted(() => {
  createChart()
})

watch(() => props.results, () => {
  if (chart) {
    chart.destroy()
  }
  createChart()
})

function createChart() {
  if (!resultChart.value) return
  
  const ctx = resultChart.value.getContext('2d')
  if (!ctx) return
  
  const data = {
    labels: ['Passed', 'Failed', 'Errors', 'Skipped'],
    datasets: [{
      data: [
        props.results.totalPass,
        props.results.totalFail,
        props.results.totalError,
        props.results.totalSkipped
      ],
      backgroundColor: [
        '#10B981', // success
        '#EF4444', // error
        '#F59E0B', // warning
        '#3B82F6'  // info
      ]
    }]
  }
  
  chart = new Chart(ctx, {
    type: 'doughnut',
    data,
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'right',
        }
      }
    }
  })
}

function exportResults() {
  // Implementation for exporting results
}
</script>
```

#### Test Tree View Component

```vue
<template>
  <div class="test-tree-view">
    <div class="tree-controls">
      <button class="btn btn-sm" @click="expandAll">Expand All</button>
      <button class="btn btn-sm" @click="collapseAll">Collapse All</button>
      <button class="btn btn-sm" @click="expandFailed">Expand Failed</button>
    </div>
    
    <div class="tree-container">
      <div 
        v-for="bundle in results.bundles" 
        :key="bundle.id"
        class="tree-node bundle-node"
      >
        <div 
          class="node-header" 
          :class="{ 'has-failures': hasFailed(bundle) }"
          @click="toggleNode(bundle.id)"
        >
          <span class="toggle-icon">
            {{ isExpanded(bundle.id) ? '▼' : '►' }}
          </span>
          <StatusBadge :status="getBundleStatus(bundle)" />
          <span class="node-name">{{ bundle.name }}</span>
          <span class="node-count">
            {{ bundle.totalPass }}/{{ bundle.totalSpecs }}
          </span>
        </div>
        
        <div v-if="isExpanded(bundle.id)" class="node-children">
          <div 
            v-for="suite in bundle.suites" 
            :key="suite.id"
            class="tree-node suite-node"
          >
            <div 
              class="node-header" 
              :class="{ 'has-failures': hasFailed(suite) }"
              @click="toggleNode(suite.id)"
            >
              <span class="toggle-icon">
                {{ isExpanded(suite.id) ? '▼' : '►' }}
              </span>
              <StatusBadge :status="suite.status" />
              <span class="node-name">{{ suite.name }}</span>
              <span class="node-count">
                {{ suite.totalPass }}/{{ suite.specs.length }}
              </span>
            </div>
            
            <div v-if="isExpanded(suite.id)" class="node-children">
              <div 
                v-for="spec in suite.specs" 
                :key="spec.id"
                class="tree-node spec-node"
                @click="selectSpec(spec)"
              >
                <div class="node-header">
                  <StatusBadge :status="spec.status" />
                  <span class="node-name">{{ spec.name }}</span>
                  <span class="duration">{{ formatDuration(spec.duration) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import StatusBadge from './StatusBadge.vue'
import { formatDuration } from '../utils/formatting'

const props = defineProps<{
  results: TestResult
}>()

const emit = defineEmits<{
  (e: 'select-spec', spec: TestSpec): void
}>()

const expandedNodes = ref<Set<string>>(new Set())

function toggleNode(id: string) {
  if (expandedNodes.value.has(id)) {
    expandedNodes.value.delete(id)
  } else {
    expandedNodes.value.add(id)
  }
}

function isExpanded(id: string): boolean {
  return expandedNodes.value.has(id)
}

function expandAll() {
  const allIds = getAllNodeIds()
  expandedNodes.value = new Set(allIds)
}

function collapseAll() {
  expandedNodes.value.clear()
}

function expandFailed() {
  collapseAll()
  
  // Get IDs of all failed bundles and suites
  props.results.bundles.forEach(bundle => {
    if (hasFailed(bundle)) {
      expandedNodes.value.add(bundle.id)
      
      bundle.suites.forEach(suite => {
        if (hasFailed(suite)) {
          expandedNodes.value.add(suite.id)
        }
      })
    }
  })
}

function getAllNodeIds(): string[] {
  const ids: string[] = []
  
  props.results.bundles.forEach(bundle => {
    ids.push(bundle.id)
    bundle.suites.forEach(suite => {
      ids.push(suite.id)
    })
  })
  
  return ids
}

function hasFailed(node: TestBundle | TestSuite): boolean {
  return node.totalFail > 0 || node.totalError > 0
}

function getBundleStatus(bundle: TestBundle): string {
  if (bundle.totalError > 0) return 'error'
  if (bundle.totalFail > 0) return 'failed'
  if (bundle.totalSkipped === bundle.totalSpecs) return 'skipped'
  if (bundle.totalPass === bundle.totalSpecs) return 'passed'
  return 'mixed'
}

function selectSpec(spec: TestSpec) {
  emit('select-spec', spec)
}
</script>
```

#### Error Detail Component

```vue
<template>
  <div class="error-detail">
    <div class="card card-bordered">
      <div class="card-header bg-error text-white">
        <h3 class="card-title">Error Details</h3>
        <div class="actions">
          <button class="btn btn-sm btn-light" @click="copyError">
            Copy Error
          </button>
        </div>
      </div>
      
      <div class="card-body">
        <div class="error-message">
          <h4>Error Message</h4>
          <div class="message-content">
            {{ spec.failMessage }}
          </div>
        </div>
        
        <div v-if="spec.failDetail" class="error-detail-section">
          <h4>Details</h4>
          <pre class="detail-content">{{ spec.failDetail }}</pre>
        </div>
        
        <div v-if="spec.failStacktrace" class="stack-trace">
          <h4>Stack Trace</h4>
          <div class="tabs">
            <button 
              class="tab" 
              :class="{ 'active': activeTab === 'all' }"
              @click="activeTab = 'all'"
            >
              All Frames
            </button>
            <button 
              class="tab" 
              :class="{ 'active': activeTab === 'app' }"
              @click="activeTab = 'app'"
            >
              Application Code
            </button>
          </div>
          
          <div class="stack-frames">
            <div 
              v-for="(frame, index) in filteredStackFrames" 
              :key="index"
              class="stack-frame"
            >
              <div class="frame-location">
                {{ frame.file }}:{{ frame.line }}
              </div>
              <div class="frame-method">
                {{ frame.method }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'

const props = defineProps<{
  spec: TestSpec
}>()

const activeTab = ref('all')

const stackFrames = computed(() => {
  if (!props.spec.failStacktrace) return []
  
  // Parse stack trace into structured data
  // This is a simplified example, actual parsing would depend on format
  return parseStackTrace(props.spec.failStacktrace)
})

const filteredStackFrames = computed(() => {
  if (activeTab.value === 'all') {
    return stackFrames.value
  } else {
    // Filter to only show application code frames
    return stackFrames.value.filter(frame => 
      !frame.file.includes('vendor/wheels') && 
      !frame.file.includes('cfml/runtime')
    )
  }
})

function parseStackTrace(stacktrace: string) {
  // Simplified parser for demonstration
  // Would need to be adapted to actual stack trace format
  return stacktrace.split('\n')
    .filter(line => line.trim().length > 0)
    .map(line => {
      const parts = line.match(/at\s+(.+)\s+\((.+):(\d+)\)/) || []
      return {
        method: parts[1] || 'Unknown Method',
        file: parts[2] || 'Unknown File',
        line: parseInt(parts[3] || '0', 10)
      }
    })
}

function copyError() {
  const errorText = `
    Error: ${props.spec.failMessage}
    Details: ${props.spec.failDetail || ''}
    Stack Trace: ${props.spec.failStacktrace || ''}
  `.trim()
  
  navigator.clipboard.writeText(errorText)
    .then(() => {
      // Show success notification
    })
    .catch(err => {
      console.error('Failed to copy error details:', err)
    })
}
</script>
```

## Data Visualization

### Chart Types

- **Results Breakdown**:
  - Doughnut chart for pass/fail/error ratio
  - Bar chart for test counts by bundle
  - Stacked bar for status distribution

- **Performance Metrics**:
  - Line chart for test duration trends
  - Histogram for execution time distribution
  - Heatmap for identifying slow tests

- **Comparison Charts**:
  - Radar chart for multi-engine comparison
  - Side-by-side bars for database comparison
  - Before/after comparison for changes

### Visualization Libraries

- **Primary**: Chart.js (lightweight, responsive)
- **Alternative**: D3.js (for more complex visualizations)
- **Tables**: vue-good-table (for tabular data)

## Result Export Options

- **Format Options**:
  - JSON (raw data)
  - CSV (tabular data)
  - HTML (formatted report)
  - PDF (via html2pdf.js)

- **Sharing Options**:
  - Copy to clipboard
  - Download file
  - Generate shareable link

## Implementation Guidelines

1. Start with the basic test result card and summary display
2. Implement hierarchical tree view for navigation
3. Develop detailed error display components
4. Add interactive features (expand/collapse, filtering)
5. Implement data visualization charts
6. Add export and sharing functionality

## Acceptance Criteria

- Test results should be clearly presented with status indicators
- Hierarchical navigation should allow easy browsing of test structure
- Error details should be comprehensive and well-formatted
- Filtering should work efficiently even with large test suites
- Data visualization should accurately represent test results
- Export options should generate correctly formatted outputs