# Pre-flight Container Check and Startup System Specification

This document details the design for a pre-flight check system that will automatically verify and manage the required containers before running tests in the CFWheels TestUI.

## Current State Assessment

The current TestUI has no pre-flight check capabilities:
- Users must manually start required containers
- No verification of container health
- No dependency resolution
- No feedback on service readiness
- Tests fail silently if services are unavailable

## Pre-flight System Strategy

### System Architecture

#### Core Modules

1. **Service Requirement Analyzer**:
   - Determines required services for tests
   - Resolves dependencies between services
   - Identifies missing or unhealthy services

2. **Container State Manager**:
   - Tracks current container states
   - Manages container lifecycle operations
   - Handles state transitions

3. **Health Check Monitor**:
   - Performs health checks on services
   - Tracks health status over time
   - Determines service readiness

4. **Startup Orchestrator**:
   - Plans container startup sequence
   - Manages parallel/sequential startup
   - Handles recovery from failures

#### State Machine Implementation

- **Test Execution States**:
  - `IDLE`: Initial state, no operation in progress
  - `ANALYZING_REQUIREMENTS`: Determining needed services
  - `CHECKING_SERVICES`: Verifying service status
  - `PREPARING_STARTUP`: Planning startup actions
  - `STARTING_SERVICES`: Initiating containers
  - `WAITING_FOR_READINESS`: Monitoring health status
  - `RUNNING_TESTS`: Executing test cases
  - `CLEANUP`: Post-test resource management
  - `ERROR`: Error state with recovery options
  - `COMPLETED`: All operations finished

- **State Transitions**:
  - Clear paths between states
  - Ability to cancel at any point
  - Error handling for each transition
  - Retry capabilities

#### Event System

- **Publish-Subscribe Model**:
  - Components subscribe to relevant events
  - State changes trigger notifications
  - Progress updates for long operations
  - Error broadcasts for problem handling

### Service Requirements Analysis

#### Test Configuration Inspection

- **Configuration Parser**:
  - Extract engine and database requirements
  - Determine protocol and port needs
  - Identify test-specific requirements
  - Handle multiple test configurations

- **Requirement Aggregation**:
  - Combine requirements from all selected tests
  - Eliminate duplicates
  - Prioritize requirements

#### Dependency Resolution

- **Dependency Graph**:
  - Model service dependencies as directed graph
  - Identify required but unselected dependencies
  - Handle circular dependencies gracefully

- **Topological Sorting**:
  - Determine optimal startup order
  - Group independent services for parallel startup
  - Handle dependency chains

#### Resource Verification

- **System Resource Check**:
  - Verify available memory and CPU
  - Check disk space for volumes
  - Identify potential resource conflicts

- **Port Availability**:
  - Check for port conflicts
  - Verify required ports are free
  - Suggest port remapping if needed

### Container State Checking

#### Status Evaluation

- **Current State Assessment**:
  - Query Docker for container statuses
  - Classify each service as:
    - Running and healthy
    - Running but unhealthy
    - Stopped/exited
    - Not created
    - Unknown/error state

- **Reconciliation Logic**:
  - Compare current state with required state
  - Identify services needing action
  - Determine minimum required changes

#### Health Assessment

- **Docker Health Check Integration**:
  - Read Docker health check results
  - Interpret health status information
  - Track health check history

- **Application-Level Health Checks**:
  - HTTP endpoint verification for web services
  - Connection tests for databases
  - Custom verification for specific services
  - Timeout handling for slow responses

#### Readiness Determination

- **Readiness Criteria**:
  - Define service-specific readiness checks
  - Set required duration of "healthy" status
  - Verify functional capabilities

- **Overall System Readiness**:
  - Combine individual service readiness
  - Consider dependencies in readiness evaluation
  - Provide confidence level for system readiness

### Container Startup Orchestration

#### Startup Planning

- **Action Plan Generation**:
  - Create list of required actions
  - Group by action type (start, restart, etc.)
  - Estimate time for completion
  - Identify potential issues

- **User Confirmation**:
  - Present plan to user
  - Show estimated impact and duration
  - Allow customization of plan
  - Provide options for automation level

#### Startup Execution

- **Phased Startup Approach**:
  - Infrastructure phase: Networks, volumes
  - Database phase: Data storage services
  - Application phase: CFML engines and utilities
  - Verification phase: Cross-service tests

- **Progress Tracking**:
  - Overall completion percentage
  - Per-service status updates
  - Time estimates for remaining work
  - Detailed logging for troubleshooting

#### Error Handling

- **Failure Recovery**:
  - Retry logic for transient errors
  - Fallback strategies for persistent issues
  - Graceful degradation where possible
  - Clear error reporting

- **User Intervention**:
  - Identify issues requiring manual action
  - Provide specific instructions
  - Allow partial continuation where possible

### Health Monitoring System

#### Continuous Monitoring

- **Polling System**:
  - Regular status checks
  - Adaptive polling intervals
  - Event-based updates
  - Resource-efficient monitoring

- **WebSocket Updates**:
  - Real-time status streaming
  - Push notifications for state changes
  - Live health metric updates

#### Readiness Verification

- **Service-Specific Checks**:
  - Connection verification for databases
  - Endpoint testing for web services
  - Custom checks for special services

- **Cross-Service Verification**:
  - Test entire service chains
  - Verify communication between services
  - End-to-end functional testing

## Technical Specifications

### State Machine Implementation

```typescript
// src/services/preflight/states.ts
export enum PreflightState {
  IDLE = 'idle',
  ANALYZING_REQUIREMENTS = 'analyzing_requirements',
  CHECKING_SERVICES = 'checking_services',
  PREPARING_STARTUP = 'preparing_startup',
  STARTING_SERVICES = 'starting_services',
  WAITING_FOR_READINESS = 'waiting_for_readiness',
  RUNNING_TESTS = 'running_tests',
  CLEANUP = 'cleanup',
  ERROR = 'error',
  COMPLETED = 'completed'
}

export interface StateTransition {
  from: PreflightState;
  to: PreflightState;
  condition?: () => boolean;
  action?: () => Promise<void>;
}

export const allowedTransitions: StateTransition[] = [
  // Define all allowed state transitions
  { from: PreflightState.IDLE, to: PreflightState.ANALYZING_REQUIREMENTS },
  { from: PreflightState.ANALYZING_REQUIREMENTS, to: PreflightState.CHECKING_SERVICES },
  { from: PreflightState.ANALYZING_REQUIREMENTS, to: PreflightState.ERROR },
  { from: PreflightState.CHECKING_SERVICES, to: PreflightState.PREPARING_STARTUP },
  { from: PreflightState.CHECKING_SERVICES, to: PreflightState.RUNNING_TESTS },
  { from: PreflightState.CHECKING_SERVICES, to: PreflightState.ERROR },
  { from: PreflightState.PREPARING_STARTUP, to: PreflightState.STARTING_SERVICES },
  { from: PreflightState.PREPARING_STARTUP, to: PreflightState.ERROR },
  { from: PreflightState.STARTING_SERVICES, to: PreflightState.WAITING_FOR_READINESS },
  { from: PreflightState.STARTING_SERVICES, to: PreflightState.ERROR },
  { from: PreflightState.WAITING_FOR_READINESS, to: PreflightState.RUNNING_TESTS },
  { from: PreflightState.WAITING_FOR_READINESS, to: PreflightState.ERROR },
  { from: PreflightState.RUNNING_TESTS, to: PreflightState.CLEANUP },
  { from: PreflightState.RUNNING_TESTS, to: PreflightState.COMPLETED },
  { from: PreflightState.RUNNING_TESTS, to: PreflightState.ERROR },
  { from: PreflightState.CLEANUP, to: PreflightState.COMPLETED },
  { from: PreflightState.CLEANUP, to: PreflightState.ERROR },
  { from: PreflightState.ERROR, to: PreflightState.IDLE },
  // Allow cancellation from any state
  { from: PreflightState.ANALYZING_REQUIREMENTS, to: PreflightState.IDLE },
  { from: PreflightState.CHECKING_SERVICES, to: PreflightState.IDLE },
  { from: PreflightState.PREPARING_STARTUP, to: PreflightState.IDLE },
  { from: PreflightState.STARTING_SERVICES, to: PreflightState.IDLE },
  { from: PreflightState.WAITING_FOR_READINESS, to: PreflightState.IDLE }
]
```

### Preflight Service Manager

```typescript
// src/services/preflight/manager.ts
import { ref, computed } from 'vue'
import { PreflightState, allowedTransitions } from './states'
import { ServiceAnalyzer } from './analyzer'
import { HealthMonitor } from './health'
import { StartupOrchestrator } from './orchestrator'
import { EventBus } from '../eventBus'
import type { TestConfig, ServiceRequirement } from '@/types/test'
import type { Container, ServiceStatus } from '@/types/docker'

export class PreflightManager {
  private _state = ref<PreflightState>(PreflightState.IDLE)
  private _error = ref<Error | null>(null)
  private _progress = ref<number>(0)
  private _requirements = ref<ServiceRequirement[]>([])
  private _services = ref<Map<string, ServiceStatus>>(new Map())
  private _actionPlan = ref<any>(null)

  private analyzer: ServiceAnalyzer
  private healthMonitor: HealthMonitor
  private orchestrator: StartupOrchestrator

  constructor() {
    this.analyzer = new ServiceAnalyzer()
    this.healthMonitor = new HealthMonitor()
    this.orchestrator = new StartupOrchestrator()

    // Setup event listeners
    this.healthMonitor.onStatusChange((serviceId, status) => {
      this._services.value.set(serviceId, status)
      EventBus.emit('service:status-change', { serviceId, status })
    })

    this.orchestrator.onProgress((progress) => {
      this._progress.value = progress
      EventBus.emit('preflight:progress', progress)
    })
  }

  // Getters
  get state() { return this._state.value }
  get error() { return this._error.value }
  get progress() { return this._progress.value }
  get requirements() { return this._requirements.value }
  get services() { return this._services.value }
  get actionPlan() { return this._actionPlan.value }

  get isRunning() {
    return this._state.value !== PreflightState.IDLE &&
           this._state.value !== PreflightState.COMPLETED &&
           this._state.value !== PreflightState.ERROR
  }

  get isSystemReady() {
    if (this._requirements.value.length === 0) return true

    // Check if all required services are ready
    for (const req of this._requirements.value) {
      const serviceStatus = this._services.value.get(req.serviceId)
      if (!serviceStatus || serviceStatus.health !== 'healthy') {
        return false
      }
    }

    return true
  }

  // State transition methods
  private async transitionTo(newState: PreflightState) {
    const transition = allowedTransitions.find(
      t => t.from === this._state.value && t.to === newState
    )

    if (!transition) {
      throw new Error(
        `Invalid state transition from ${this._state.value} to ${newState}`
      )
    }

    if (transition.condition && !transition.condition()) {
      throw new Error(
        `Transition condition failed from ${this._state.value} to ${newState}`
      )
    }

    try {
      if (transition.action) {
        await transition.action()
      }

      this._state.value = newState
      EventBus.emit('preflight:state-change', newState)

      return true
    } catch (err) {
      this._error.value = err as Error
      this._state.value = PreflightState.ERROR
      EventBus.emit('preflight:error', err)

      return false
    }
  }

  // Main workflow methods
  async prepareForTests(testConfig: TestConfig): Promise<boolean> {
    // Reset state
    this._error.value = null
    this._progress.value = 0

    // Start the workflow
    await this.transitionTo(PreflightState.ANALYZING_REQUIREMENTS)

    try {
      // Analyze requirements
      this._requirements.value = await this.analyzer.analyzeRequirements(testConfig)
      EventBus.emit('preflight:requirements', this._requirements.value)

      // Check service status
      await this.transitionTo(PreflightState.CHECKING_SERVICES)
      const serviceStatuses = await this.healthMonitor.checkServices(
        this._requirements.value.map(r => r.serviceId)
      )

      this._services.value = new Map(
        serviceStatuses.map(s => [s.serviceId, s])
      )

      // If all services are ready, skip to running tests
      if (this.isSystemReady) {
        return await this.transitionTo(PreflightState.RUNNING_TESTS)
      }

      // Prepare startup plan
      await this.transitionTo(PreflightState.PREPARING_STARTUP)
      this._actionPlan.value = await this.orchestrator.createActionPlan(
        this._requirements.value,
        Array.from(this._services.value.values())
      )

      EventBus.emit('preflight:action-plan', this._actionPlan.value)

      // Wait for user confirmation before starting services
      return true

    } catch (err) {
      this._error.value = err as Error
      await this.transitionTo(PreflightState.ERROR)
      return false
    }
  }

  async executeActionPlan(): Promise<boolean> {
    if (!this._actionPlan.value) {
      this._error.value = new Error('No action plan to execute')
      await this.transitionTo(PreflightState.ERROR)
      return false
    }

    try {
      // Start services
      await this.transitionTo(PreflightState.STARTING_SERVICES)
      await this.orchestrator.executeActionPlan(this._actionPlan.value)

      // Wait for readiness
      await this.transitionTo(PreflightState.WAITING_FOR_READINESS)
      const ready = await this.healthMonitor.waitForReadiness(
        this._requirements.value.map(r => r.serviceId),
        30000 // 30 second timeout
      )

      if (!ready) {
        throw new Error('Timed out waiting for services to be ready')
      }

      // Ready to run tests
      return await this.transitionTo(PreflightState.RUNNING_TESTS)

    } catch (err) {
      this._error.value = err as Error
      await this.transitionTo(PreflightState.ERROR)
      return false
    }
  }

  async runTests(): Promise<boolean> {
    // This method would be called by the test runner
    // and would execute the actual tests

    try {
      // Run the tests
      // (actual test execution implementation would go here)

      // Move to cleanup phase
      return await this.transitionTo(PreflightState.CLEANUP)
    } catch (err) {
      this._error.value = err as Error
      await this.transitionTo(PreflightState.ERROR)
      return false
    }
  }

  async cleanup(keepRunning: boolean = true): Promise<boolean> {
    try {
      if (!keepRunning) {
        // Stop services that were started for this test run
        await this.orchestrator.stopServices(this._actionPlan.value?.servicesToStart || [])
      }

      // Complete the workflow
      return await this.transitionTo(PreflightState.COMPLETED)
    } catch (err) {
      this._error.value = err as Error
      await this.transitionTo(PreflightState.ERROR)
      return false
    }
  }

  async cancel(): Promise<boolean> {
    try {
      // Stop any running operations
      this.healthMonitor.stopMonitoring()
      this.orchestrator.cancelOperations()

      // Return to idle state
      return await this.transitionTo(PreflightState.IDLE)
    } catch (err) {
      this._error.value = err as Error
      await this.transitionTo(PreflightState.ERROR)
      return false
    }
  }

  async reset(): Promise<boolean> {
    this._error.value = null
    this._progress.value = 0
    this._requirements.value = []
    this._services.value = new Map()
    this._actionPlan.value = null

    return await this.transitionTo(PreflightState.IDLE)
  }

  // Event handlers
  onStateChange(callback: (state: PreflightState) => void) {
    EventBus.on('preflight:state-change', callback)
  }

  onProgress(callback: (progress: number) => void) {
    EventBus.on('preflight:progress', callback)
  }

  onError(callback: (error: Error) => void) {
    EventBus.on('preflight:error', callback)
  }

  onServiceStatusChange(callback: (serviceId: string, status: ServiceStatus) => void) {
    EventBus.on('service:status-change', ({ serviceId, status }) => {
      callback(serviceId, status)
    })
  }
}

export default new PreflightManager()
```

### Service Analyzer Implementation

```typescript
// src/services/preflight/analyzer.ts
import type { TestConfig, ServiceRequirement } from '@/types/test'
import dockerService from '../tools/docker'

export class ServiceAnalyzer {
  /**
   * Analyze test configuration to determine required services
   */
  async analyzeRequirements(testConfig: TestConfig): Promise<ServiceRequirement[]> {
    const requirements: ServiceRequirement[] = []

    // Extract engine requirement
    if (testConfig.engine) {
      const engineRequirement = await this.getEngineRequirement(testConfig.engine)
      if (engineRequirement) {
        requirements.push(engineRequirement)
      }
    }

    // Extract database requirement
    if (testConfig.database) {
      const dbRequirement = await this.getDatabaseRequirement(testConfig.database)
      if (dbRequirement) {
        requirements.push(dbRequirement)
      }
    }

    // Resolve dependencies
    const dependencies = await this.resolveDependencies(requirements)
    requirements.push(...dependencies)

    return requirements
  }

  /**
   * Get engine service requirement
   */
  private async getEngineRequirement(engineName: string): Promise<ServiceRequirement | null> {
    const containers = await dockerService.getContainers()

    const engineContainer = containers.find(c =>
      c.labels['service.type'] === 'engine' &&
      c.labels['engine.name'] === engineName
    )

    if (!engineContainer) return null

    return {
      serviceId: engineContainer.id,
      serviceName: engineContainer.name,
      serviceType: 'engine',
      required: true,
      dependencies: []
    }
  }

  /**
   * Get database service requirement
   */
  private async getDatabaseRequirement(dbName: string): Promise<ServiceRequirement | null> {
    const containers = await dockerService.getContainers()

    const dbContainer = containers.find(c =>
      c.labels['service.type'] === 'database' &&
      c.labels['database.name'] === dbName
    )

    if (!dbContainer) return null

    return {
      serviceId: dbContainer.id,
      serviceName: dbContainer.name,
      serviceType: 'database',
      required: true,
      dependencies: []
    }
  }

  /**
   * Resolve dependencies for required services
   */
  private async resolveDependencies(
    requirements: ServiceRequirement[]
  ): Promise<ServiceRequirement[]> {
    const dependencies: ServiceRequirement[] = []
    const containers = await dockerService.getContainers()

    // Check Docker Compose dependencies from labels
    for (const req of requirements) {
      const container = containers.find(c => c.id === req.serviceId)
      if (!container) continue

      const dependsOn = container.labels['com.docker.compose.depends_on']
      if (!dependsOn) continue

      const dependencyNames = dependsOn.split(',')
      for (const depName of dependencyNames) {
        const depContainer = containers.find(c => c.name === depName.trim())
        if (!depContainer) continue

        // Avoid duplicates
        if (requirements.some(r => r.serviceId === depContainer.id) ||
            dependencies.some(d => d.serviceId === depContainer.id)) {
          continue
        }

        dependencies.push({
          serviceId: depContainer.id,
          serviceName: depContainer.name,
          serviceType: depContainer.labels['service.type'] || 'other',
          required: false, // Not directly required by test, but a dependency
          dependencies: [],
          requiredBy: [req.serviceId]
        })
      }
    }

    return dependencies
  }
}
```

### Health Monitor Implementation

```typescript
// src/services/preflight/health.ts
import { EventBus } from '../eventBus'
import dockerService from '../tools/docker'
import type { ServiceStatus } from '@/types/docker'

export class HealthMonitor {
  private monitoringInterval: number | null = null
  private monitoredServices: string[] = []

  /**
   * Check health status of specified services
   */
  async checkServices(serviceIds: string[]): Promise<ServiceStatus[]> {
    try {
      const statuses: ServiceStatus[] = []

      for (const id of serviceIds) {
        const container = await dockerService.getContainer(id)

        const status: ServiceStatus = {
          serviceId: id,
          name: container.name,
          state: container.state,
          health: this.determineHealth(container),
          lastChecked: new Date(),
          statusMessage: '',
          readiness: 0
        }

        // Add additional checks based on service type
        if (container.labels['service.type'] === 'engine') {
          await this.checkEngineHealth(status)
        } else if (container.labels['service.type'] === 'database') {
          await this.checkDatabaseHealth(status)
        }

        statuses.push(status)
        EventBus.emit('service:status-change', { serviceId: id, status })
      }

      return statuses
    } catch (err) {
      console.error('Error checking service health:', err)
      throw err
    }
  }

  /**
   * Start continuous monitoring of services
   */
  startMonitoring(serviceIds: string[], interval: number = 5000): void {
    this.stopMonitoring() // Stop any existing monitoring

    this.monitoredServices = [...serviceIds]
    this.monitoringInterval = window.setInterval(async () => {
      await this.checkServices(this.monitoredServices)
    }, interval)
  }

  /**
   * Stop continuous monitoring
   */
  stopMonitoring(): void {
    if (this.monitoringInterval !== null) {
      clearInterval(this.monitoringInterval)
      this.monitoringInterval = null
    }
    this.monitoredServices = []
  }

  /**
   * Wait for services to become ready
   */
  async waitForReadiness(
    serviceIds: string[],
    timeout: number = 60000
  ): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      const startTime = Date.now()
      const checkInterval = 1000 // Check every second

      // Start monitoring
      this.startMonitoring(serviceIds, checkInterval)

      // Check function
      const checkReadiness = async () => {
        const statuses = await this.checkServices(serviceIds)
        const allReady = statuses.every(s => s.health === 'healthy' && s.readiness === 100)

        if (allReady) {
          // All services are ready
          this.stopMonitoring()
          resolve(true)
          return
        }

        if (Date.now() - startTime > timeout) {
          // Timeout reached
          this.stopMonitoring()
          resolve(false)
          return
        }

        // Continue checking
        setTimeout(checkReadiness, checkInterval)
      }

      // Start checking
      checkReadiness()
    })
  }

  /**
   * Determine health status based on container information
   */
  private determineHealth(container: any): 'healthy' | 'unhealthy' | 'unknown' {
    if (container.state !== 'running') {
      return 'unhealthy'
    }

    if (container.health && container.health.status) {
      switch (container.health.status) {
        case 'healthy':
          return 'healthy'
        case 'unhealthy':
          return 'unhealthy'
        default:
          return 'unknown'
      }
    }

    // No health information available
    return container.state === 'running' ? 'healthy' : 'unhealthy'
  }

  /**
   * Check CFML engine health by testing endpoint
   */
  private async checkEngineHealth(status: ServiceStatus): Promise<void> {
    try {
      // Extract hostname and port from container
      const container = await dockerService.getContainer(status.serviceId)
      const port = Object.keys(container.ports || {})[0] || '8080'
      const host = container.networks?.[0]?.ip || 'localhost'

      // Try to access health endpoint
      const response = await fetch(`http://${host}:${port}/health`, {
        method: 'GET',
        headers: { 'Accept': 'application/json' },
        timeout: 5000
      })

      if (response.ok) {
        status.health = 'healthy'
        status.readiness = 100
        status.statusMessage = 'Engine is responsive'
      } else {
        status.health = 'unhealthy'
        status.readiness = 50
        status.statusMessage = `Engine returned status ${response.status}`
      }
    } catch (err) {
      // If we can't connect, the engine might still be starting
      if (status.state === 'running') {
        status.health = 'unhealthy'
        status.readiness = 25
        status.statusMessage = 'Engine is not responding'
      } else {
        status.health = 'unhealthy'
        status.readiness = 0
        status.statusMessage = 'Engine is not running'
      }
    }
  }

  /**
   * Check database health by testing connection
   */
  private async checkDatabaseHealth(status: ServiceStatus): Promise<void> {
    try {
      // This would need to be implemented differently for each database type
      // or use a database connection service

      // For example purposes:
      const container = await dockerService.getContainer(status.serviceId)
      const dbType = container.labels['database.name'] || 'unknown'

      // Simulate a connection check
      if (status.state === 'running') {
        status.health = 'healthy'
        status.readiness = 100
        status.statusMessage = `${dbType} database is accepting connections`
      } else {
        status.health = 'unhealthy'
        status.readiness = 0
        status.statusMessage = `${dbType} database is not running`
      }
    } catch (err) {
      status.health = 'unhealthy'
      status.readiness = 0
      status.statusMessage = 'Unable to connect to database'
    }
  }

  /**
   * Register event handlers
   */
  onStatusChange(callback: (serviceId: string, status: ServiceStatus) => void) {
    EventBus.on('service:status-change', ({ serviceId, status }) => {
      callback(serviceId, status)
    })
  }
}
```

### Startup Orchestrator Implementation

```typescript
// src/services/preflight/orchestrator.ts
import { EventBus } from '../eventBus'
import dockerService from '../tools/docker'
import type { ServiceRequirement } from '@/types/test'
import type { ServiceStatus, ActionPlan } from '@/types/docker'

export class StartupOrchestrator {
  private cancelRequested = false

  /**
   * Create action plan for service startup
   */
  async createActionPlan(
    requirements: ServiceRequirement[],
    serviceStatuses: ServiceStatus[]
  ): Promise<ActionPlan> {
    const actionPlan: ActionPlan = {
      servicesToStart: [],
      servicesToRestart: [],
      startupOrder: [],
      estimatedTime: 0
    }

    // Build startup and restart lists
    for (const req of requirements) {
      const status = serviceStatuses.find(s => s.serviceId === req.serviceId)

      if (!status || status.state !== 'running') {
        // Service needs to be started
        actionPlan.servicesToStart.push(req.serviceId)
      } else if (status.health === 'unhealthy') {
        // Service is running but unhealthy, needs restart
        actionPlan.servicesToRestart.push(req.serviceId)
      }
    }

    // Determine startup order based on dependencies
    actionPlan.startupOrder = this.determineStartupOrder(
      requirements,
      [...actionPlan.servicesToStart, ...actionPlan.servicesToRestart]
    )

    // Estimate startup time
    actionPlan.estimatedTime = this.estimateStartupTime(
      actionPlan.servicesToStart,
      actionPlan.servicesToRestart
    )

    return actionPlan
  }

  /**
   * Execute the action plan
   */
  async executeActionPlan(plan: ActionPlan): Promise<boolean> {
    this.cancelRequested = false

    try {
      // Total operations count for progress tracking
      const totalOperations = plan.servicesToStart.length + plan.servicesToRestart.length
      let completedOperations = 0

      // Report initial progress
      this.updateProgress(0)

      // First handle restarts (usually quicker)
      for (const serviceId of plan.servicesToRestart) {
        if (this.cancelRequested) break

        await dockerService.restartContainer(serviceId)
        completedOperations++
        this.updateProgress(completedOperations / totalOperations * 100)
      }

      // Then handle starts based on dependency order
      for (const serviceId of plan.startupOrder) {
        if (this.cancelRequested) break

        if (plan.servicesToStart.includes(serviceId)) {
          await dockerService.startContainer(serviceId)
          completedOperations++
          this.updateProgress(completedOperations / totalOperations * 100)
        }
      }

      this.updateProgress(100)
      return !this.cancelRequested
    } catch (err) {
      console.error('Error executing action plan:', err)
      throw err
    }
  }

  /**
   * Stop specified services
   */
  async stopServices(serviceIds: string[]): Promise<boolean> {
    try {
      // Total operations count for progress tracking
      const totalOperations = serviceIds.length
      let completedOperations = 0

      // Report initial progress
      this.updateProgress(0)

      for (const serviceId of serviceIds) {
        await dockerService.stopContainer(serviceId)
        completedOperations++
        this.updateProgress(completedOperations / totalOperations * 100)
      }

      this.updateProgress(100)
      return true
    } catch (err) {
      console.error('Error stopping services:', err)
      throw err
    }
  }

  /**
   * Cancel current operations
   */
  cancelOperations(): void {
    this.cancelRequested = true
  }

  /**
   * Determine optimal startup order based on dependencies
   */
  private determineStartupOrder(
    requirements: ServiceRequirement[],
    serviceIdsToStart: string[]
  ): string[] {
    // Create dependency graph
    const graph: Record<string, string[]> = {}

    // Initialize graph with all services
    for (const serviceId of serviceIdsToStart) {
      graph[serviceId] = []
    }

    // Add dependencies
    for (const req of requirements) {
      if (req.dependencies && req.dependencies.length > 0) {
        // Only include dependencies that are in the serviceIdsToStart list
        graph[req.serviceId] = req.dependencies.filter(
          depId => serviceIdsToStart.includes(depId)
        )
      }
    }

    // Perform topological sort
    return this.topologicalSort(graph)
  }

  /**
   * Topological sort algorithm for dependency ordering
   */
  private topologicalSort(graph: Record<string, string[]>): string[] {
    const visited = new Set<string>()
    const temp = new Set<string>()
    const order: string[] = []

    function visit(node: string) {
      // If we've already processed this node, skip
      if (visited.has(node)) return

      // If we encounter a node we're already visiting, we have a cycle
      if (temp.has(node)) {
        console.warn(`Circular dependency detected including ${node}`)
        return
      }

      // Mark node as temporarily visited
      temp.add(node)

      // Visit all dependencies first
      const deps = graph[node] || []
      for (const dep of deps) {
        visit(dep)
      }

      // Remove from temp set and add to visited
      temp.delete(node)
      visited.add(node)

      // Add to result
      order.unshift(node)
    }

    // Visit all nodes
    for (const node of Object.keys(graph)) {
      if (!visited.has(node)) {
        visit(node)
      }
    }

    return order
  }

  /**
   * Estimate time required for startup
   */
  private estimateStartupTime(
    servicesToStart: string[],
    servicesToRestart: string[]
  ): number {
    // This is a placeholder for a more sophisticated estimation
    // based on historical startup times per service

    // Simple estimation:
    // - 5 seconds per service restart
    // - 20 seconds per service start
    const restartTime = servicesToRestart.length * 5
    const startTime = servicesToStart.length * 20

    return restartTime + startTime
  }

  /**
   * Update progress and emit event
   */
  private updateProgress(progress: number): void {
    EventBus.emit('preflight:progress', progress)
  }

  /**
   * Register event handlers
   */
  onProgress(callback: (progress: number) => void) {
    EventBus.on('preflight:progress', callback)
  }
}
```

### Preflight Dashboard Component

```vue
<template>
  <div class="preflight-dashboard">
    <div class="dashboard-header">
      <h2>Pre-flight System</h2>
      <StatusBadge :status="preflightState" />
    </div>

    <div v-if="preflightState === 'error'" class="error-alert">
      <div class="alert alert-error">
        <div class="flex-1">
          <svg class="w-6 h-6 mx-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"></path>
          </svg>
          <label>{{ errorMessage }}</label>
        </div>
      </div>
    </div>

    <div class="preflight-content">
      <!-- Requirements Section -->
      <div v-if="requirements.length > 0" class="requirements-section">
        <h3>Service Requirements</h3>
        <div class="requirements-grid">
          <ServiceRequirementCard
            v-for="req in requirements"
            :key="req.serviceId"
            :requirement="req"
            :status="getServiceStatus(req.serviceId)"
          />
        </div>
      </div>

      <!-- Action Plan Section -->
      <div v-if="actionPlan" class="action-plan-section">
        <h3>Action Plan</h3>
        <div class="plan-summary">
          <div class="summary-item">
            <span class="count">{{ actionPlan.servicesToStart.length }}</span>
            <span class="label">Services to Start</span>
          </div>
          <div class="summary-item">
            <span class="count">{{ actionPlan.servicesToRestart.length }}</span>
            <span class="label">Services to Restart</span>
          </div>
          <div class="summary-item">
            <span class="count">{{ formatTime(actionPlan.estimatedTime) }}</span>
            <span class="label">Estimated Time</span>
          </div>
        </div>

        <div class="startup-order">
          <h4>Startup Order</h4>
          <div class="order-list">
            <div
              v-for="(serviceId, index) in actionPlan.startupOrder"
              :key="serviceId"
              class="order-item"
            >
              <span class="order-number">{{ index + 1 }}</span>
              <span class="service-name">{{ getServiceName(serviceId) }}</span>
              <StatusBadge
                :status="getServiceStatus(serviceId)?.state || 'unknown'"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Progress Section -->
      <div v-if="isActive" class="progress-section">
        <h3>Operation Progress</h3>
        <div class="progress-container">
          <ProgressBar :percent="progress" :status="progressStatus" />
          <span class="progress-text">{{ progress.toFixed(0) }}%</span>
        </div>
        <div class="state-message">{{ stateMessage }}</div>
      </div>

      <!-- Action Buttons -->
      <div class="action-buttons">
        <button
          v-if="preflightState === 'idle' || preflightState === 'completed'"
          class="btn btn-primary"
          @click="startPreflight"
        >
          Start Pre-flight Check
        </button>

        <button
          v-if="preflightState === 'checking_services' || preflightState === 'preparing_startup'"
          class="btn btn-primary"
          @click="executeActionPlan"
        >
          Start Required Services
        </button>

        <button
          v-if="preflightState === 'running_tests'"
          class="btn btn-primary"
          @click="completeTests"
        >
          Complete Tests
        </button>

        <button
          v-if="isActive && preflightState !== 'error'"
          class="btn btn-warning ml-2"
          @click="cancelOperation"
        >
          Cancel
        </button>

        <button
          v-if="preflightState === 'error'"
          class="btn btn-error ml-2"
          @click="resetPreflight"
        >
          Reset
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import preflightManager from '../services/preflight/manager'
import { PreflightState } from '../services/preflight/states'
import { useTestStore } from '../stores/test'
import StatusBadge from './StatusBadge.vue'
import ProgressBar from './ProgressBar.vue'
import ServiceRequirementCard from './ServiceRequirementCard.vue'
import { formatTime } from '../utils/formatting'

const testStore = useTestStore()

// Local state
const preflightState = ref<PreflightState>(PreflightState.IDLE)
const errorMessage = ref<string>('')
const progress = ref<number>(0)

// Computed properties
const requirements = computed(() => preflightManager.requirements)
const actionPlan = computed(() => preflightManager.actionPlan)

const isActive = computed(() =>
  preflightState.value !== PreflightState.IDLE &&
  preflightState.value !== PreflightState.COMPLETED &&
  preflightState.value !== PreflightState.ERROR
)

const progressStatus = computed(() => {
  switch (preflightState.value) {
    case PreflightState.STARTING_SERVICES:
      return 'warning'
    case PreflightState.WAITING_FOR_READINESS:
      return 'info'
    case PreflightState.RUNNING_TESTS:
      return 'success'
    case PreflightState.ERROR:
      return 'error'
    default:
      return 'primary'
  }
})

const stateMessage = computed(() => {
  switch (preflightState.value) {
    case PreflightState.IDLE:
      return 'Ready to begin pre-flight check'
    case PreflightState.ANALYZING_REQUIREMENTS:
      return 'Analyzing test requirements...'
    case PreflightState.CHECKING_SERVICES:
      return 'Checking service status...'
    case PreflightState.PREPARING_STARTUP:
      return 'Preparing service startup plan...'
    case PreflightState.STARTING_SERVICES:
      return 'Starting required services...'
    case PreflightState.WAITING_FOR_READINESS:
      return 'Waiting for services to be ready...'
    case PreflightState.RUNNING_TESTS:
      return 'Running tests...'
    case PreflightState.CLEANUP:
      return 'Cleaning up resources...'
    case PreflightState.COMPLETED:
      return 'Pre-flight check completed successfully'
    case PreflightState.ERROR:
      return `Error: ${errorMessage.value}`
    default:
      return 'Unknown state'
  }
})

// Methods
function getServiceStatus(serviceId: string) {
  return preflightManager.services.get(serviceId)
}

function getServiceName(serviceId: string) {
  const status = preflightManager.services.get(serviceId)
  return status?.name || serviceId.substring(0, 12)
}

async function startPreflight() {
  await preflightManager.prepareForTests(testStore.selectedTest)
}

async function executeActionPlan() {
  await preflightManager.executeActionPlan()
}

async function completeTests() {
  await preflightManager.cleanup(true) // Keep services running
}

async function cancelOperation() {
  await preflightManager.cancel()
}

async function resetPreflight() {
  await preflightManager.reset()
}

// Event handlers
onMounted(() => {
  preflightManager.onStateChange((state) => {
    preflightState.value = state

    // When reaching the RUNNING_TESTS state, notify test store
    if (state === PreflightState.RUNNING_TESTS) {
      testStore.setReadyToRun(true)
    }
  })

  preflightManager.onProgress((value) => {
    progress.value = value
  })

  preflightManager.onError((error) => {
    errorMessage.value = error.message
  })
})

// Watch for test selection changes
watch(() => testStore.selectedTest, () => {
  if (preflightState.value === PreflightState.IDLE ||
      preflightState.value === PreflightState.COMPLETED) {
    // Auto-start preflight when test selection changes
    startPreflight()
  }
})
</script>
```

## User Interface Components

### Service Requirement Card Component

```vue
<template>
  <div
    class="service-card"
    :class="{
      'border-success': status?.health === 'healthy',
      'border-warning': status?.health === 'unknown',
      'border-error': status?.health === 'unhealthy',
      'required': requirement.required
    }"
  >
    <div class="card-header">
      <h4>{{ requirement.serviceName }}</h4>
      <div class="badges">
        <span class="type-badge">{{ requirement.serviceType }}</span>
        <span
          v-if="requirement.required"
          class="requirement-badge"
        >
          Required
        </span>
      </div>
    </div>

    <div class="card-body">
      <div class="status-section">
        <div class="status-item">
          <span class="label">State:</span>
          <StatusBadge :status="status?.state || 'unknown'" />
        </div>
        <div class="status-item">
          <span class="label">Health:</span>
          <HealthIndicator :health="status?.health || 'unknown'" />
        </div>
        <div class="status-item">
          <span class="label">Readiness:</span>
          <ProgressBar
            v-if="status"
            :percent="status.readiness"
            class="readiness-bar"
          />
          <span v-else class="unknown">Unknown</span>
        </div>
      </div>

      <div v-if="status?.statusMessage" class="status-message">
        {{ status.statusMessage }}
      </div>

      <div v-if="requirement.dependencies.length > 0" class="dependencies">
        <h5>Dependencies:</h5>
        <ul>
          <li
            v-for="depId in requirement.dependencies"
            :key="depId"
          >
            {{ getDependencyName(depId) }}
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import StatusBadge from './StatusBadge.vue'
import HealthIndicator from './HealthIndicator.vue'
import ProgressBar from './ProgressBar.vue'
import type { ServiceRequirement } from '../types/test'
import type { ServiceStatus } from '../types/docker'

const props = defineProps<{
  requirement: ServiceRequirement
  status?: ServiceStatus
}>()

function getDependencyName(serviceId: string): string {
  // This could be enhanced to look up actual service names
  return serviceId.substring(0, 12)
}
</script>
```

### Health Indicator Component

```vue
<template>
  <div
    class="health-indicator"
    :class="{
      'healthy': health === 'healthy',
      'unhealthy': health === 'unhealthy',
      'unknown': health === 'unknown'
    }"
  >
    <svg v-if="health === 'healthy'" class="w-5 h-5" viewBox="0 0 20 20" fill="currentColor">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
    </svg>

    <svg v-else-if="health === 'unhealthy'" class="w-5 h-5" viewBox="0 0 20 20" fill="currentColor">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
    </svg>

    <svg v-else class="w-5 h-5" viewBox="0 0 20 20" fill="currentColor">
      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-3a1 1 0 00-.867.5 1 1 0 11-1.731-1A3 3 0 0113 8a3.001 3.001 0 01-2 2.83V11a1 1 0 11-2 0v-1a1 1 0 011-1 1 1 0 100-2zm0 8a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" />
    </svg>

    <span class="health-label">{{ healthLabel }}</span>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  health: 'healthy' | 'unhealthy' | 'unknown'
}>()

const healthLabel = computed(() => {
  switch (props.health) {
    case 'healthy':
      return 'Healthy'
    case 'unhealthy':
      return 'Unhealthy'
    default:
      return 'Unknown'
  }
})
</script>
```

## Implementation Guidelines

1. Start with the core state machine and event system
2. Implement service requirement analysis
3. Add health monitoring functionality
4. Build startup orchestration logic
5. Create UI components for the preflight dashboard
6. Integrate with test selection and execution flow

## Acceptance Criteria

- System should correctly identify required services for tests
- Container health status should be accurately monitored
- Service dependencies should be properly resolved
- Startup sequence should respect dependencies
- UI should provide clear feedback on system status
- The system should gracefully handle errors and allow recovery
- Integration with test execution should be seamless
- Progress should be clearly communicated during operations
