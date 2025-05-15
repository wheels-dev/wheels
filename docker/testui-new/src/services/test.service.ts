import type { TestBundle, TestSpec, TestRun, TestResult, CfmlEngine, Database } from '@/types';
import { TestStatus } from '@/types';

class TestService {
  private apiBase: string = '/api/tests';
  
  // In a real implementation, this would make actual API calls
  // For now, we'll simulate responses
  
  async getTestBundles(): Promise<TestBundle[]> {
    console.log('Fetching test bundles...');
    
    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Return mock data
    return [
      {
        id: 'all',
        name: 'All Tests',
        description: 'Run all available tests',
        path: '/'
      },
      {
        id: 'core',
        name: 'Core Tests',
        description: 'Tests for CFWheels core functionality',
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
    ];
  }
  
  async getTestSpecs(bundleId: string): Promise<TestSpec[]> {
    console.log(`Fetching test specs for bundle ${bundleId}...`);
    
    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Return mock data - in reality this would depend on the bundleId
    return [
      {
        id: 'spec1',
        name: 'Core Functionality',
        bundleId,
        path: `/${bundleId}/core`
      },
      {
        id: 'spec2',
        name: 'Basic Operations',
        bundleId,
        path: `/${bundleId}/basic`
      },
      {
        id: 'spec3',
        name: 'Advanced Features',
        bundleId,
        path: `/${bundleId}/advanced`
      }
    ];
  }
  
  async runTests(engine: CfmlEngine, database: Database, bundle: TestBundle, spec?: TestSpec): Promise<TestRun> {
    console.log(`Running tests for ${engine.name} ${engine.version} with ${database.name} using bundle ${bundle.name}...`);
    
    // Get engine port and database config
    const enginePort = this.getEnginePort(engine);
    const dbConfig = this.getDatabaseConfig(database);
    
    // ===== OLD FORMAT URL (WHAT WE'LL ACTUALLY USE) =====
    const oldFormatHost = `http://localhost:${enginePort}`;
    const oldFormatParams = new URLSearchParams();
    oldFormatParams.append('format', 'json');
    oldFormatParams.append('sort', 'directory asc');
    oldFormatParams.append('db', database.name.toLowerCase());
    
    // Add timeout parameter to prevent test runner from timing out
    oldFormatParams.append('timeout', '1800');  // 30 minutes in seconds
    
    if (bundle.id !== 'all') {
      oldFormatParams.append('testBundles', bundle.id);
    }
    if (spec) {
      oldFormatParams.append('testSpecs', spec.id);
    }
    
    // The actual URL we'll use for tests (old format)
    const testRunnerUrl = `${oldFormatHost}/wheels/testbox?`;
    const params = oldFormatParams;
    
    // ===== NEW FORMAT URL (FOR REFERENCE ONLY) =====
    const newFormatUrl = `http://${engine.name.toLowerCase()}${engine.version}:${enginePort}/tests/runner.cfm?`;
    const newFormatParams = new URLSearchParams();
    newFormatParams.append('testBundles', bundle.id);
    if (spec) {
      newFormatParams.append('testSpecs', spec.id);
    }
    
    // Add database config parameters to new format (for reference only)
    Object.entries(dbConfig).forEach(([key, value]) => {
      newFormatParams.append(key, value.toString());
    });
    
    // Log the full URL that would be called
    console.log('=======================================================');
    console.log('            DETAILED TEST CALL INFORMATION             ');
    console.log('=======================================================');
    console.log('ACTUAL URL BEING USED (OLD FORMAT):');
    console.log(`${testRunnerUrl}${params.toString()}`);
    console.log('');
    console.log('NEW FORMAT URL (FOR REFERENCE ONLY):');
    console.log(`${newFormatUrl}${newFormatParams.toString()}`);
    console.log('');
    console.log('HTTP Method: GET');
    console.log('');
    console.log('Engine Container Info:');
    console.log(` - Name: ${engine.name}`);
    console.log(` - Version: ${engine.version}`);
    console.log(` - Port: ${enginePort}`);
    console.log('');
    console.log('Database Info:');
    console.log(` - Type: ${database.name}`);
    console.log(` - Configuration: `, dbConfig);
    console.log('');
    console.log('Test Bundle Info:');
    console.log(` - ID: ${bundle.id}`);
    console.log(` - Path: ${bundle.path}`);
    if (spec) {
      console.log('Test Spec Info:');
      console.log(` - ID: ${spec.id}`);
      console.log(` - Path: ${spec.path}`);
    }
    console.log('=======================================================');
    
    const testRun: TestRun = {
      id: `${Date.now()}`,
      engine,
      database,
      bundle,
      spec,
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
    
    try {
      // In a real implementation, we would make the actual HTTP request here
      // For now, let's simulate a response with a large number of tests
      
      // Create simulated tests - using 1613 as specified
      console.log(`Generating 1613 simulated test results...`);
      const totalTests = 1613;
      testRun.summary.total = totalTests;
      
      // Show a loading message in console
      console.log(`Starting test execution simulation (this may take a while for 1613 tests)...`);
      
      // Use a longer delay to better simulate the full test suite
      await new Promise(resolve => setTimeout(resolve, 5000));
      
      // Generate test results - with most tests passing
      for (let i = 0; i < totalTests; i++) {
        // Simulate realistic pass/fail rates - 95% pass rate
        const random = Math.random();
        let status;
        
        // Add more failed tests if this is SQL Server (simulating common issues)
        const isSQLServer = database.name === 'SQL Server';
        const failureThreshold = isSQLServer ? 0.85 : 0.95;
        
        if (random > failureThreshold) {
          status = TestStatus.Failed;
          testRun.summary.failed++;
        } else if (random > failureThreshold - 0.02) {
          status = TestStatus.Error;
          testRun.summary.errors++;
        } else if (random > failureThreshold - 0.05) {
          status = TestStatus.Skipped;
          testRun.summary.skipped++;
        } else {
          status = TestStatus.Passed;
          testRun.summary.passed++;
        }
        
        const result: TestResult = {
          id: `test_${i}`,
          name: this.generateRealisticTestName(bundle.id, i),
          status,
          duration: 0.05 + Math.random() * 0.8, // Most tests are fast, some are slower
          timestamp: new Date().toISOString()
        };
        
        if (status === TestStatus.Failed || status === TestStatus.Error) {
          result.error = {
            message: this.generateRealisticErrorMessage(database.name, status),
            detail: this.generateRealisticErrorDetail(bundle.id)
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
      
      // Realistic duration for 1613 tests - between 30-60 seconds
      const endTime = new Date();
      const startTime = new Date(testRun.startTime);
      testRun.duration = (endTime.getTime() - startTime.getTime()) / 1000;
      
      console.log(`Test run complete with ${testRun.summary.total} tests (${testRun.summary.passed} passed, ${testRun.summary.failed + testRun.summary.errors} failed)`);
    } catch (error) {
      console.error('Error running tests:', error);
      
      // Handle test execution failure
      testRun.status = TestStatus.Error;
      testRun.endTime = new Date().toISOString();
      testRun.duration = 0;
      
      // Add a single result indicating the error
      testRun.results.push({
        id: 'error',
        name: 'Test execution failed',
        status: TestStatus.Error,
        duration: 0,
        timestamp: new Date().toISOString(),
        error: {
          message: error instanceof Error ? error.message : 'Unknown error',
          detail: error instanceof Error ? error.stack : 'No details available'
        }
      });
      
      testRun.summary.total = 1;
      testRun.summary.errors = 1;
    }
    
    return testRun;
  }
  
  // Generate realistic test names based on the bundle
  private generateRealisticTestName(bundleId: string, index: number): string {
    // Use the bundle ID to generate context-appropriate test names
    const coreTests = [
      'init() should create a new instance',
      'new() should create a new object',
      'findAll() should return query result',
      'findByKey() should locate correct record',
      'findOne() should return a single record',
      'save() should persist the object',
      'update() should modify existing record',
      'delete() should remove record',
      'validatesPresenceOf() should require field',
      'validatesLengthOf() should enforce limits',
      'propertyNames() should return fields',
      'hasMany() should define association',
      'belongsTo() should define association',
      'allowBlank param should work as expected',
      'transaction() should handle rollbacks',
      'addError() should add to error collection',
      'errorMessages() should format error correctly',
      'updateAll() should update multiple records',
      'deleteAll() should remove multiple records',
      'average() should calculate correctly'
    ];
    
    const controllerTests = [
      'verifies() should validate parameters',
      'provides() should set content type',
      'renderView() should render template',
      'redirectTo() should set location header',
      'onMissingTemplate() should handle 404',
      'filters() should apply before actions',
      'filterChain() should execute in order',
      'usesLayout() should apply layout',
      'processAction() should invoke method',
      'sendFile() should set proper headers',
      'sendEmail() should deliver message',
      'renderPartial() should include fragment',
      'pagination() should handle page breaks',
      'caching() should store rendered content',
      'provides("json") should return JSON',
      'responds properly to different formats',
      'filters run in correct order',
      'params struct contains form values',
      'can set status codes correctly',
      'flash notices persist between requests'
    ];
    
    const viewTests = [
      'textField() outputs correct HTML',
      'select() creates dropdown correctly',
      'submitTag() includes CSRF tokens',
      'dateSelect() formats dates correctly',
      'errorMessageOn() shows validation errors',
      'imageTag() generates correct URLs',
      'linkTo() creates anchor tags',
      'styleSheetLinkTag() includes CSS',
      'javaScriptIncludeTag() adds scripts',
      'startFormTag() sets form attributes',
      'paginationLinks() shows page controls',
      'highlight() wraps text properly',
      'excerpt() truncates strings correctly',
      'timeAgoInWords() handles time formatting',
      'checkBox() creates input correctly',
      'radioButton() works with selection',
      'textArea() preserves content',
      'titleize() formats text properly',
      'autoLink() converts URLs to links',
      'truncate() handles long strings'
    ];
    
    const pluginTests = [
      'plugin hooks initialize correctly',
      'plugin can extend controller methods',
      'plugin can add model methods',
      'plugin version is compatible',
      'plugin settings are configured',
      'multiple plugins can coexist',
      'plugin can define custom tags',
      'plugin lifecycle events fire correctly',
      'plugin can apply application-wide changes',
      'plugin dependencies resolve correctly',
      'plugin documentation is valid',
      'plugin migrations run correctly',
      'plugin can be uninstalled cleanly',
      'plugin settings form works correctly',
      'plugin localization works',
      'plugin can modify core behavior',
      'plugin defaults are applied correctly',
      'plugin initialization order is respected',
      'plugin can work with multiple CFML engines',
      'plugin assets are accessible'
    ];
    
    const allTests = [...coreTests, ...controllerTests, ...viewTests, ...pluginTests];
    
    // Choose an appropriate list based on bundle ID
    let testPool: string[];
    switch (bundleId) {
      case 'core':
        testPool = coreTests;
        break;
      case 'controller':
        testPool = controllerTests;
        break;
      case 'view':
        testPool = viewTests;
        break;
      case 'plugin':
        testPool = pluginTests;
        break;
      case 'model':
        testPool = coreTests;
        break;
      default:
        testPool = allTests;
    }
    
    // Use modulo to cycle through available test names
    const testName = testPool[index % testPool.length];
    
    // For "all" tests, prefix with the category
    if (bundleId === 'all') {
      const category = index % 4 === 0 ? 'Core' : 
                      index % 4 === 1 ? 'Controller' : 
                      index % 4 === 2 ? 'View' : 'Plugin';
      return `${category}: ${testName}`;
    }
    
    return testName;
  }
  
  // Generate realistic error messages
  private generateRealisticErrorMessage(dbType: string, status: TestStatus): string {
    if (status === TestStatus.Error) {
      const errors = [
        'Database connection failed',
        `Unable to connect to ${dbType} database`,
        'Query timeout exceeded',
        'Out of memory error during test execution',
        'Connection pool exhausted',
        'Required dependency not found',
        'Incompatible driver version',
        'Unsupported operation in current engine',
        'Configuration missing for test execution',
        'Test setup failed due to environment issues'
      ];
      return errors[Math.floor(Math.random() * errors.length)];
    } else {
      const failures = [
        'Expected [true] but got [false]',
        'Expected query to return records but none found',
        'Expected exception to be thrown',
        'Expected [1] but got [0]',
        'Expected validation to fail but it passed',
        'Expected record to be created but none found',
        'Expected string to match pattern',
        'Unexpected null value',
        'Expected object to have property',
        'Invalid test assumption'
      ];
      return failures[Math.floor(Math.random() * failures.length)];
    }
  }
  
  // Generate detailed error information
  private generateRealisticErrorDetail(bundleId: string): string {
    const fileBase = bundleId === 'controller' ? 'Controller.cfc' :
                    bundleId === 'view' ? 'View.cfc' :
                    bundleId === 'plugin' ? 'Plugin.cfc' : 'Model.cfc';
    
    const lineNumber = Math.floor(Math.random() * 500) + 1;
    const columnNumber = Math.floor(Math.random() * 80) + 1;
    
    return `Error in /wheels/tests/${bundleId}/${fileBase} at line ${lineNumber}, column ${columnNumber}.\n\nStack trace:\n` +
           `at runAssert (/wheels/test/TestCase.cfc:${lineNumber})\n` +
           `at runTest (/wheels/test/TestRunner.cfc:${lineNumber-45})\n` +
           `at executeTest (/wheels/test/TestBox.cfc:${lineNumber-87})`;
  }
  
  private generateRandomTestName(): string {
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
  
  async stopTests(runId: string): Promise<void> {
    console.log(`Stopping test run ${runId}...`);
    
    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // In a real implementation, this would make an API call to stop the test run
    return;
  }

  // Helper method to get the engine port based on engine type and version
  private getEnginePort(engine: CfmlEngine): number {
    // Default ports based on engine name and version
    if (engine.name === 'Lucee') {
      if (engine.version === '5') return 60005;
      if (engine.version === '6') return 60006;
    } else if (engine.name === 'Adobe') {
      if (engine.version === '2018') return 62018;
      if (engine.version === '2021') return 62021;
      if (engine.version === '2023') return 62023;
    }
    
    // Default port if not found
    return 8080;
  }
  
  // Helper method to get database configuration
  private getDatabaseConfig(database: Database): Record<string, string | number | boolean> {
    // Default database configurations
    if (database.name === 'H2') {
      return {
        dsn: 'wheelstestdb',
        database_type: 'h2',
        h2_inmemory: true
      };
    } else if (database.name === 'MySQL') {
      return {
        dsn: 'wheelstestdb',
        database_type: 'mysql',
        host: 'mysql',
        port: 3306,
        username: 'wheelstestdb',
        password: 'wheelstestdb'
      };
    } else if (database.name === 'PostgreSQL') {
      return {
        dsn: 'wheelstestdb',
        database_type: 'postgresql',
        host: 'postgres',
        port: 5432,
        username: 'wheelstestdb',
        password: 'wheelstestdb'
      };
    } else if (database.name === 'SQL Server') {
      return {
        dsn: 'wheelstestdb',
        database_type: 'sqlserver',
        host: 'sqlserver',
        port: 1433,
        username: 'sa',
        password: 'x!bsT8t60yo0cTVTPq'
      };
    }
    
    // Default config if not found
    return {
      dsn: 'wheelstestdb',
      database_type: 'unknown'
    };
  }
}

export const testService = new TestService();