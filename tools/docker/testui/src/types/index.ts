// Server/Engine Types
export interface CfmlEngine {
  id: string;
  name: string;
  version: string;
  url: string;
  port: number;
  adminUrl: string;
  containerId?: string;
  status: ContainerStatus;
  health?: ContainerHealth;
  uptime?: string;
}

// Database Types
export interface Database {
  id: string;
  name: string;
  version: string;
  port: number;
  containerId?: string;
  status: ContainerStatus;
  health?: ContainerHealth;
  connectionInfo: {
    host: string;
    port: number;
    database: string;
    username: string;
    password: string;
  };
}

// Container Types
export enum ContainerStatus {
  Running = 'running',
  Stopped = 'stopped',
  Starting = 'starting',
  Stopping = 'stopping',
  Error = 'error',
  Unknown = 'unknown'
}

export enum ContainerHealth {
  Healthy = 'healthy',
  Unhealthy = 'unhealthy',
  Starting = 'starting',
  Unknown = 'unknown'
}

export interface Container {
  id: string;
  name: string;
  type: 'engine' | 'database' | 'other';
  image: string;
  status: ContainerStatus;
  health?: ContainerHealth;
  ports: Record<string, string>;
  created: string;
  uptime?: string;
}

export interface ContainerProfile {
  id: string;
  name: string;
  description: string;
  containers: {
    containerId: string;
    required: boolean;
  }[];
}

// Test Types
export interface TestBundle {
  id: string;
  name: string;
  description?: string;
  path: string;
}

export interface TestSpec {
  id: string;
  name: string;
  bundleId: string;
  path: string;
}

export enum TestStatus {
  Pending = 'pending',
  Running = 'running',
  Passed = 'passed',
  Failed = 'failed',
  Error = 'error',
  Skipped = 'skipped'
}

export interface TestResult {
  id: string;
  name: string;
  status: TestStatus;
  duration: number;
  error?: {
    message: string;
    detail: string;
    stacktrace?: string;
  };
  timestamp: string;
}

export interface TestRun {
  id: string;
  engine: CfmlEngine;
  database: Database;
  bundle: TestBundle;
  spec?: TestSpec;
  status: TestStatus;
  startTime?: string;
  endTime?: string;
  duration?: number;
  results: TestResult[];
  summary: {
    total: number;
    passed: number;
    failed: number;
    errors: number;
    skipped: number;
  };
}

export interface TestQueue {
  items: TestQueueItem[];
  running: boolean;
  currentIndex: number;
}

export interface TestQueueItem {
  id: string;
  engine: CfmlEngine;
  database: Database;
  bundle: TestBundle;
  spec?: TestSpec;
  status: TestStatus;
}

// Preflight Types
export enum PreflightStepStatus {
  Pending = 'pending',
  Running = 'running',
  Success = 'success',
  Failed = 'failed',
  Skipped = 'skipped'
}

export interface PreflightStep {
  id: string;
  name: string;
  description: string;
  status: PreflightStepStatus;
  error?: string;
  dependsOn?: string[];
}

export interface Preflight {
  id: string;
  steps: PreflightStep[];
  running: boolean;
  success: boolean;
  completed: boolean;
}