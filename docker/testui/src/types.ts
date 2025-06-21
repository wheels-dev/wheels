// Container model
export interface Container {
  id: string;
  name: string;
  type: 'engine' | 'database' | 'other';
  image: string;
  status: 'running' | 'stopped' | 'starting' | 'stopping' | 'error' | 'unknown';
  health?: 'healthy' | 'unhealthy' | 'starting';
  ports: Record<string, string>;
  created: string;
  uptime?: string;
  // Additional fields for Wheels containers
  labels?: Record<string, string>;
  isWheelsContainer?: boolean;
  wheelsType?: string | null;
  wheelsName?: string | null;
  wheelsVersion?: string | null;
}

// Test status enum
export enum TestStatus {
  Running = 'running',
  Passed = 'passed',
  Failed = 'failed',
  Error = 'error',
  Skipped = 'skipped'
}

// CFML Engine types
export type CfmlEngineType = 'lucee5' | 'lucee6' | 'adobe2018' | 'adobe2021' | 'adobe2023';

// CFML Engine
export interface CfmlEngine {
  id: string;
  name: string;
  version: string;
  type: CfmlEngineType;
  icon?: string;
  port?: number;
}

// Database types
export type DatabaseType = 'h2' | 'mysql' | 'postgres' | 'sqlserver' | 'oracle';

// Database
export interface Database {
  id: string;
  name: string;
  type: DatabaseType;
  version?: string;
  icon?: string;
  port?: number;
}

// Test Bundle
export interface TestBundle {
  id: string;
  name: string;
  description?: string;
  path: string;
}

// Test Specification
export interface TestSpec {
  id: string;
  name: string;
  bundleId: string;
  path: string;
}

// Test Result
export interface TestResult {
  id: string;
  name: string;
  status: TestStatus;
  duration: number;
  timestamp: string;
  // References to know which engine/database ran this test
  engine?: CfmlEngine;
  database?: Database;
  bundle?: TestBundle;
  spec?: TestSpec;
  runId?: string; // Unique identifier for each test run
  testUrl?: string; // URL used to run this test
  error?: {
    message: string;
    detail?: string;
  };
}

// Test Run
export interface TestRun {
  id: string;
  engine: CfmlEngine;
  database: Database;
  bundle: TestBundle;
  spec?: TestSpec;
  status: TestStatus;
  startTime: string;
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
  testUrl?: string;
}

// Test Queue Item
export interface TestQueueItem {
  id: string;
  engine: CfmlEngine;
  database: Database;
  bundle: TestBundle;
  spec?: TestSpec;
  options: {
    preflight: boolean;
    autoStart: boolean;
    failFast: boolean;
    executionOrder: 'directory asc' | 'directory desc';
  };
}