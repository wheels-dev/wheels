import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import type { TestBundle, TestQueue, TestQueueItem, TestRun, TestResult } from '@/types';
import { TestStatus } from '@/types';
import { useEngineStore } from './engineStore';
import { useDatabaseStore } from './databaseStore';

export const useTestStore = defineStore('test', () => {
  // Dependencies
  const engineStore = useEngineStore();
  const databaseStore = useDatabaseStore();

  // State
  const testBundles = ref<TestBundle[]>([
    {
      id: 'all',
      name: 'All Tests',
      description: 'Run all available tests',
      path: '/'
    },
    {
      id: 'core',
      name: 'Core Tests',
      description: 'Tests for Wheels core functionality',
      path: '/core'
    },
    {
      id: 'model',
      name: 'Model Tests',
      description: 'Tests for model-related functionality',
      path: '/models'
    },
    {
      id: 'controller',
      name: 'Controller Tests',
      description: 'Tests for controller-related functionality',
      path: '/controllers'
    },
    {
      id: 'view',
      name: 'View Tests',
      description: 'Tests for view-related functionality',
      path: '/views'
    },
    {
      id: 'plugin',
      name: 'Plugin Tests',
      description: 'Tests for plugins',
      path: '/plugins'
    }
  ]);

  const testQueue = ref<TestQueue>({
    items: [],
    running: false,
    currentIndex: -1
  });

  const testResults = ref<TestRun[]>([]);

  // Getters
  const getBundleById = computed(() => 
    (id: string) => testBundles.value.find(bundle => bundle.id === id)
  );
  
  const currentTestRun = computed(() => {
    const currentItem = testQueue.value.items[testQueue.value.currentIndex];
    if (currentItem) {
      return testResults.value.find(run => run.id === currentItem.id);
    }
    return undefined;
  });

  const testSummary = computed(() => {
    const summary = {
      total: 0,
      passed: 0,
      failed: 0,
      errors: 0,
      skipped: 0
    };
    
    testResults.value.forEach(run => {
      summary.total += run.summary.total;
      summary.passed += run.summary.passed;
      summary.failed += run.summary.failed;
      summary.errors += run.summary.errors;
      summary.skipped += run.summary.skipped;
    });
    
    return summary;
  });

  // Actions
  function addToQueue(engineId: string, databaseId: string, bundleId: string) {
    const engine = engineStore.getEngineById(engineId);
    const database = databaseStore.getDatabaseById(databaseId);
    const bundle = getBundleById.value(bundleId);
    
    if (engine && database && bundle) {
      const id = `${engineId}_${databaseId}_${bundleId}_${Date.now()}`;
      
      testQueue.value.items.push({
        id,
        engine,
        database,
        bundle,
        status: TestStatus.Pending
      });
    }
  }

  function clearQueue() {
    if (!testQueue.value.running) {
      testQueue.value.items = [];
      testQueue.value.currentIndex = -1;
    }
  }

  function removeFromQueue(index: number) {
    if (!testQueue.value.running) {
      testQueue.value.items.splice(index, 1);
    }
  }

  async function startTests() {
    if (testQueue.value.running || testQueue.value.items.length === 0) {
      return;
    }
    
    testQueue.value.running = true;
    testQueue.value.currentIndex = 0;
    
    await runNextTest();
  }

  async function runNextTest() {
    if (!testQueue.value.running) {
      return;
    }
    
    const currentItem = testQueue.value.items[testQueue.value.currentIndex];
    
    if (!currentItem) {
      testQueue.value.running = false;
      testQueue.value.currentIndex = -1;
      return;
    }
    
    // Update status to running
    currentItem.status = TestStatus.Running;
    
    // Create a new test run
    const testRun: TestRun = {
      id: currentItem.id,
      engine: currentItem.engine,
      database: currentItem.database,
      bundle: currentItem.bundle,
      spec: currentItem.spec,
      status: TestStatus.Running,
      startTime: new Date().toISOString(),
      results: [],
      summary: {
        total: 0,
        passed: 0,
        failed: 0,
        errors: 0,
        skipped: 0
      }
    };
    
    testResults.value.push(testRun);
    
    // In a real implementation, this would make an API call to run the tests
    // For now, let's simulate a test run with random results
    await simulateTestRun(testRun);
    
    // Move to the next test in the queue
    testQueue.value.currentIndex++;
    
    if (testQueue.value.currentIndex < testQueue.value.items.length) {
      await runNextTest();
    } else {
      testQueue.value.running = false;
      testQueue.value.currentIndex = -1;
    }
  }

  // Helper function to simulate a test run with random results
  async function simulateTestRun(testRun: TestRun) {
    const totalTests = Math.floor(Math.random() * 100) + 20;
    testRun.summary.total = totalTests;
    
    // Simulate test execution with a delay
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // Generate random results
    for (let i = 0; i < totalTests; i++) {
      const random = Math.random();
      let status;
      
      if (random > 0.9) {
        status = TestStatus.Failed;
        testRun.summary.failed++;
      } else if (random > 0.85) {
        status = TestStatus.Error;
        testRun.summary.errors++;
      } else if (random > 0.8) {
        status = TestStatus.Skipped;
        testRun.summary.skipped++;
      } else {
        status = TestStatus.Passed;
        testRun.summary.passed++;
      }
      
      const result: TestResult = {
        id: `test_${i}`,
        name: `Test ${i} - ${generateRandomTestName()}`,
        status,
        duration: Math.random() * 0.5,
        timestamp: new Date().toISOString()
      };
      
      if (status === TestStatus.Failed || status === TestStatus.Error) {
        result.error = {
          message: `Test failed: Expected value to be true but got false`,
          detail: `Assertion failed at line ${Math.floor(Math.random() * 100) + 1}`
        };
      }
      
      testRun.results.push(result);
    }
    
    // Update the test run status based on results
    if (testRun.summary.failed > 0 || testRun.summary.errors > 0) {
      testRun.status = TestStatus.Failed;
    } else {
      testRun.status = TestStatus.Passed;
    }
    
    testRun.endTime = new Date().toISOString();
    testRun.duration = 3 + Math.random() * 2; // Simulate 3-5 seconds duration
  }

  function generateRandomTestName() {
    const testTypes = [
      'should return correct result',
      'should handle invalid input',
      'should validate input correctly',
      'should throw exception for invalid state',
      'should process data correctly',
      'should handle edge cases'
    ];
    
    const components = [
      'model validation',
      'controller filters',
      'pagination',
      'query execution',
      'view rendering',
      'data binding',
      'cache handling',
      'transactions'
    ];
    
    return `${components[Math.floor(Math.random() * components.length)]} ${testTypes[Math.floor(Math.random() * testTypes.length)]}`;
  }
  
  function stopTests() {
    testQueue.value.running = false;
    
    const currentItem = testQueue.value.items[testQueue.value.currentIndex];
    if (currentItem) {
      currentItem.status = TestStatus.Skipped;
      
      const testRun = testResults.value.find(run => run.id === currentItem.id);
      if (testRun && testRun.status === TestStatus.Running) {
        testRun.status = TestStatus.Skipped;
        testRun.endTime = new Date().toISOString();
      }
    }
  }
  
  function clearResults() {
    testResults.value = [];
  }

  return {
    testBundles,
    testQueue,
    testResults,
    getBundleById,
    currentTestRun,
    testSummary,
    addToQueue,
    clearQueue,
    removeFromQueue,
    startTests,
    stopTests,
    clearResults
  };
});