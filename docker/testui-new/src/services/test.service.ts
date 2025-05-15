import type { TestBundle, TestSpec, TestRun, TestResult, CfmlEngine, Database } from '@/types';
import { TestStatus } from '@/types';
import { api } from '@/utils/api';

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
      // Make the actual HTTP request to the test runner
      console.log(`Making real HTTP request to test runner at: ${testRunnerUrl}${params.toString()}`);
      
      // Determine the engine API name
      const engineApiName = this.getEngineApiName(engine);
      if (!engineApiName) {
        throw new Error(`Unknown engine: ${engine.name} ${engine.version}`);
      }
      
      // Use the api.cfml method to make a request through the NGINX proxy
      // The path must NOT include the leading slash as the NGINX configuration will add it
      const requestPath = `wheels/testbox?${params.toString()}`;
      console.log(`Making request to CFML engine: ${engineApiName}, path: ${requestPath}`);
      
      // Log the full URL that will be constructed
      console.log(`Full API URL will be: /api/${engineApiName}/${requestPath}`);
      
      // Make the API request through the NGINX proxy
      const response = await api.cfml<any>(engineApiName, requestPath, {
        headers: {
          'Accept': 'application/json'
        }
      });
      
      if (response.error || !response.data) {
        throw new Error(`Test request failed: ${response.error || 'No data returned'}`);
      }
      
      const testData = response.data;
      console.log('Test response received type:', typeof testData);
      
      // Log a truncated version of the response for debugging
      const truncatedResponse = typeof testData === 'string' 
        ? testData.substring(0, 500) + '...[truncated]' 
        : JSON.stringify(testData).substring(0, 500) + '...[truncated]';
      console.log('Test response sample:', truncatedResponse);
      
      // Handle string responses (in case the API returns plain text or HTML)
      if (typeof testData === 'string') {
        // If it looks like JSON, try to parse it
        if (testData.trim().startsWith('{') || testData.trim().startsWith('[')) {
          try {
            const parsedData = JSON.parse(testData);
            console.log('Successfully parsed string response as JSON');
            
            // Continue with the parsed data
            if (!parsedData.totalExecuted && !parsedData.totalFailed && !parsedData.totalError) {
              console.error('Parsed response does not match expected TestBox format');
              throw new Error('Invalid test response format. Expected TestBox JSON output.');
            }
            
            // Update summary with parsed data
            testRun.summary.total = parsedData.totalExecuted || 0;
            testRun.summary.passed = (parsedData.totalExecuted || 0) - 
                                  (parsedData.totalFailed || 0) - 
                                  (parsedData.totalError || 0) - 
                                  (parsedData.totalSkipped || 0);
            testRun.summary.failed = parsedData.totalFailed || 0;
            testRun.summary.errors = parsedData.totalError || 0;
            testRun.summary.skipped = parsedData.totalSkipped || 0;
            
            // Use the parsed data for results processing
            if (parsedData.results && Array.isArray(parsedData.results)) {
              return this.processTestResults(testRun, parsedData);
            }
          } catch (e) {
            console.error('Failed to parse string response as JSON:', e);
            throw new Error('Failed to parse test response as JSON');
          }
        } else {
          console.error('Response is a string but not JSON. HTML response?');
          throw new Error('Received HTML or text response instead of JSON. Check test runner URL and format parameter.');
        }
      } else if (typeof testData === 'object' && testData !== null) {
        // Handle direct object responses - check for TestBox format
        // TestBox may have different field names based on version
        console.log('TestBox response fields:', Object.keys(testData).join(', '));
        
        // Check for any of the expected TestBox formats
        const hasTestBoxFields = testData.totalSpecs !== undefined || 
                               testData.totalPass !== undefined ||
                               testData.totalExecuted !== undefined;
        
        if (!hasTestBoxFields) {
          console.error('Response object does not seem to be TestBox format:', testData);
          throw new Error('Invalid test response format. Expected TestBox JSON output.');
        }
        
        // Update summary data from the actual response
        // Handle different field names in different TestBox versions
        testRun.summary.total = testData.totalSpecs || testData.totalExecuted || testData.totalTests || 0;
        testRun.summary.passed = testData.totalPass || 
                               ((testData.totalExecuted || 0) - 
                               (testData.totalFail || testData.totalFailed || 0) - 
                               (testData.totalError || 0) - 
                               (testData.totalSkipped || 0));
        testRun.summary.failed = testData.totalFail || testData.totalFailed || 0;
        testRun.summary.errors = testData.totalError || 0;
        testRun.summary.skipped = testData.totalSkipped || 0;
        
        console.log('Parsed summary:', testRun.summary);
      } else {
        console.error('Unexpected response type:', typeof testData);
        throw new Error('Unexpected response type from test runner');
      }
      
      // Process test results from the response and return the updated testRun
      const processedTestRun = this.processTestResults(testRun, testData);
      
      console.log(`Test run complete with ${processedTestRun.summary.total} tests (${processedTestRun.summary.passed} passed, ${processedTestRun.summary.failed + processedTestRun.summary.errors} failed)`);
      
      return processedTestRun;
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
  
  // Process test results data and update the testRun object
  private processTestResults(testRun: TestRun, testData: any): TestRun {
    console.log('Processing test results from TestBox data. Looking for detailed results...');
    
    // First check for modern TestBox format with bundleStats
    if (testData.bundleStats && Array.isArray(testData.bundleStats)) {
      console.log(`Found ${testData.bundleStats.length} bundles with test results`);
      
      // Process each bundle's test specs
      let allResults: TestResult[] = [];
      
      testData.bundleStats.forEach((bundle: any, bundleIndex: number) => {
        const bundleName = bundle.path || `Bundle ${bundleIndex}`;
        
        // Process specs if available
        if (bundle.suiteStats && Array.isArray(bundle.suiteStats)) {
          bundle.suiteStats.forEach((suite: any) => {
            if (suite.specStats && Array.isArray(suite.specStats)) {
              // Add each spec as a test result
              suite.specStats.forEach((spec: any, specIndex: number) => {
                // Determine test status
                const status = spec.status === 'Passed' ? TestStatus.Passed :
                              spec.status === 'Failed' ? TestStatus.Failed :
                              spec.status === 'Error' ? TestStatus.Error :
                              spec.status === 'Skipped' ? TestStatus.Skipped :
                              TestStatus.Unknown;
                
                // Create test result
                const testResult: TestResult = {
                  id: `${bundleIndex}_${specIndex}`,
                  name: spec.name || `${bundleName}: ${suite.name || 'Unknown'} - Test ${specIndex}`,
                  status,
                  duration: spec.totalDuration || 0,
                  timestamp: new Date().toISOString()
                };
                
                // Add error details if available
                if (status === TestStatus.Failed || status === TestStatus.Error) {
                  testResult.error = {
                    message: spec.failMessage || spec.error || 'Test failed',
                    detail: spec.failDetail || spec.stacktrace || 'No detailed error information available'
                  };
                }
                
                allResults.push(testResult);
              });
            }
          });
        }
      });
      
      console.log(`Processed ${allResults.length} individual test results from bundles`);
      
      // Update results if we found any
      if (allResults.length > 0) {
        testRun.results = allResults;
      } else {
        console.log('No individual test results found in bundle stats. Creating summary results.');
        
        // Create summary results for each bundle
        testData.bundleStats.forEach((bundle: any, index: number) => {
          const bundleName = bundle.path || `Bundle ${index}`;
          const hasFailed = (bundle.totalFail || 0) > 0 || (bundle.totalError || 0) > 0;
          
          testRun.results.push({
            id: `bundle_${index}`,
            name: bundleName,
            status: hasFailed ? TestStatus.Failed : TestStatus.Passed,
            duration: bundle.totalDuration || 0,
            timestamp: new Date().toISOString(),
            error: hasFailed ? {
              message: `${bundle.totalFail || 0} tests failed in this bundle`,
              detail: `Bundle Path: ${bundleName}`
            } : undefined
          });
        });
      }
    }
    // Legacy format with results array
    else if (testData.results && Array.isArray(testData.results)) {
      console.log(`Found legacy format with ${testData.results.length} results`);
      
      testRun.results = testData.results.map((result: any, index: number) => {
        // Convert TestBox status to our TestStatus enum
        const status = result.status === 'Passed' ? TestStatus.Passed :
                      result.status === 'Failed' ? TestStatus.Failed :
                      result.status === 'Error' ? TestStatus.Error :
                      result.status === 'Skipped' ? TestStatus.Skipped :
                      TestStatus.Unknown;
                      
        // Create the test result object
        const testResult: TestResult = {
          id: result.id || `test_${index}`,
          name: result.name || `Unknown Test ${index}`,
          status,
          duration: result.duration || 0,
          timestamp: result.timestamp || new Date().toISOString()
        };
        
        // Add error details for failed or errored tests
        if (status === TestStatus.Failed || status === TestStatus.Error) {
          testResult.error = {
            message: result.message || result.failMessage || 'Test failed or errored',
            detail: result.failDetail || result.detail || 'No detailed error information available'
          };
        }
        
        return testResult;
      });
    } else {
      console.log('No detailed test results found. Creating summary result.');
      
      // Fallback for unsupported response format - create a single result
      testRun.results.push({
        id: 'summary',
        name: 'Test Suite Summary',
        status: testRun.summary.failed > 0 || testRun.summary.errors > 0 ? 
               TestStatus.Failed : TestStatus.Passed,
        duration: 0,
        timestamp: new Date().toISOString()
      });
    }
    
    // Update the test run status based on results
    if (testRun.summary.failed > 0 || testRun.summary.errors > 0) {
      testRun.status = TestStatus.Failed;
    } else {
      testRun.status = TestStatus.Passed;
    }
    
    // Set end time and calculate duration
    testRun.endTime = new Date().toISOString();
    const endTime = new Date();
    const startTime = new Date(testRun.startTime);
    testRun.duration = (endTime.getTime() - startTime.getTime()) / 1000;
    
    return testRun;
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
  
  // Helper method to get the engine API name for NGINX proxy
  private getEngineApiName(engine: CfmlEngine): string | null {
    if (engine.name === 'Lucee') {
      if (engine.version === '5') return 'lucee5';
      if (engine.version === '6') return 'lucee6';
    } else if (engine.name === 'Adobe') {
      if (engine.version === '2018') return 'adobe2018';
      if (engine.version === '2021') return 'adobe2021';
      if (engine.version === '2023') return 'adobe2023';
    }
    
    // Unknown engine
    return null;
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