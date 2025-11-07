/**
 * Generate a background job for asynchronous processing
 * 
 * Examples:
 * wheels generate job ProcessOrders
 * wheels generate job SendNewsletters queue=emails priority=high
 * wheels generate job DataExport schedule="0 0 * * *"
 * wheels generate job CleanupOldRecords delay=3600
 */
component aliases='wheels g job' extends="../base" {
    
    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="helpers" inject="helpers@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @name.hint Name of the job (e.g., ProcessOrdersJob, SendEmailJob)
     * @queue.hint Queue name for the job (default: default)
     * @priority.hint Job priority: low, normal, high (default: normal)
     * @schedule.hint Cron expression for scheduled jobs
     * @delay.hint Delay in seconds before job runs
     * @retries.hint Number of retry attempts on failure (default: 3)
     * @timeout.hint Job timeout in seconds (default: 300)
     * @description.hint Job description
     * @force.hint Overwrite existing files
     */
    function run(
        required string name,
        string queue = "default",
        string priority = "normal",
        string schedule = "",
        numeric delay = 0,
        numeric retries = 3,
        numeric timeout = 300,
        string description = "",
        boolean force = false
    ) {
        detailOutput.header("⚡", "Generating job: #arguments.name#");
        
        // Ensure name ends with "Job"
        if (!reFindNoCase("Job$", arguments.name)) {
            arguments.name &= "Job";
        }
        
        // Validate job name
        var validation = codeGenerationService.validateName(arguments.name, "job");
        if (!validation.valid) {
            error("Invalid job name: " & arrayToList(validation.errors, ", "));
            return;
        }
        
        // Validate priority
        if (!listFindNoCase("low,normal,high", arguments.priority)) {
            error("Invalid priority. Must be 'low', 'normal', or 'high'.");
            return;
        }
        
        // Set up paths
        var jobsDir = helpers.getAppPath() & "/jobs";
        if (!directoryExists(jobsDir)) {
            directoryCreate(jobsDir);
            detailOutput.output("Created jobs directory: /jobs");
        }
        
        var jobPath = jobsDir & "/" & arguments.name & ".cfc";
        
        // Check if file exists
        if (fileExists(jobPath) && !arguments.force) {
            error("Job already exists: #arguments.name#.cfc. Use force=true to overwrite.");
            return;
        }
        
        // Generate job content
        var jobContent = generateJobContent(arguments);
        
        // Write job file
        fileWrite(jobPath, jobContent);
        detailOutput.success("Created job: /jobs/#arguments.name#.cfc");
        
        // Create test file
        createJobTest(arguments.name);
        
        // Create job configuration if scheduled
        if (len(arguments.schedule)) {
            createJobSchedule(arguments);
        }
        
        // Show usage example
        detailOutput.separator();
        detailOutput.output("Usage example:");
        
        if (len(arguments.schedule)) {
            detailOutput.code('// Job will run automatically based on schedule: #arguments.schedule#
// To run manually:
job = createObject("component", "jobs.#arguments.name#");
job.perform(data);', "cfscript");
        } else {
            detailOutput.code('// Queue a job for immediate processing
job = createObject("component", "jobs.#arguments.name#");
job.enqueue(data);

// Queue with delay
job.enqueueIn(seconds: 60, data: data);

// Queue for specific time
job.enqueueAt(datetime: dateAdd("h", 1, now()), data: data);', "cfscript");
        }
    }
    
    /**
     * Generate job component content
     */
    private string function generateJobContent(required struct args) {
        var content = "/**" & chr(10);
        content &= " * #args.name#" & chr(10);
        if (len(args.description)) {
            content &= " * #args.description#" & chr(10);
        }
        content &= " * Queue: #args.queue#" & chr(10);
        content &= " * Priority: #args.priority#" & chr(10);
        if (len(args.schedule)) {
            content &= " * Schedule: #args.schedule#" & chr(10);
        }
        content &= " */" & chr(10);
        content &= "component extends=""wheels.Job"" {" & chr(10) & chr(10);
        
        // Properties
        content &= chr(9) & "// Job configuration" & chr(10);
        content &= chr(9) & "property name=""queue"" default=""#args.queue#"";" & chr(10);
        content &= chr(9) & "property name=""priority"" default=""#args.priority#"";" & chr(10);
        content &= chr(9) & "property name=""retries"" default=""#args.retries#"";" & chr(10);
        content &= chr(9) & "property name=""timeout"" default=""#args.timeout#"";" & chr(10);
        if (args.delay > 0) {
            content &= chr(9) & "property name=""delay"" default=""#args.delay#"";" & chr(10);
        }
        content &= chr(10);
        
        // Constructor
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Constructor - Configure job settings" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "function init() {" & chr(10);
        content &= chr(9) & chr(9) & "// Initialize job configuration" & chr(10);
        content &= chr(9) & chr(9) & "variables.jobName = ""#args.name#"";" & chr(10);
        if (len(args.schedule)) {
            content &= chr(9) & chr(9) & "variables.schedule = ""#args.schedule#"";" & chr(10);
        }
        content &= chr(9) & chr(9) & "return this;" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        // Main perform method
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Main job execution method" & chr(10);
        content &= chr(9) & " * @data.hint Job data/parameters" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "public void function perform(struct data = {}) {" & chr(10);
        content &= chr(9) & chr(9) & "try {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "// Log job start" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "logInfo(""Starting #args.name# with data: "" & serializeJSON(arguments.data));" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & chr(9) & "// Validate input data" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "validateJobData(arguments.data);" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & chr(9) & "// TODO: Implement your job logic here" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "processJobData(arguments.data);" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & chr(9) & "// Log job completion" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "logInfo(""Completed #args.name# successfully"");" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "} catch (any e) {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "// Log error" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "logError(""Error in #args.name#: "" & e.message, e);" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & chr(9) & "// Re-throw to trigger retry logic" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "throw(object=e);" & chr(10);
        content &= chr(9) & chr(9) & "}" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        // Helper methods
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Enqueue job for processing" & chr(10);
        content &= chr(9) & " * @data.hint Job data" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "public void function enqueue(struct data = {}) {" & chr(10);
        content &= chr(9) & chr(9) & "// Add job to queue" & chr(10);
        content &= chr(9) & chr(9) & "super.enqueue(" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "jobName = variables.jobName," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "data = arguments.data," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "queue = variables.queue," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "priority = variables.priority" & chr(10);
        content &= chr(9) & chr(9) & ");" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Enqueue job with delay" & chr(10);
        content &= chr(9) & " * @seconds.hint Delay in seconds" & chr(10);
        content &= chr(9) & " * @data.hint Job data" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "public void function enqueueIn(required numeric seconds, struct data = {}) {" & chr(10);
        content &= chr(9) & chr(9) & "enqueueAt(" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "datetime = dateAdd(""s"", arguments.seconds, now())," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "data = arguments.data" & chr(10);
        content &= chr(9) & chr(9) & ");" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Enqueue job for specific time" & chr(10);
        content &= chr(9) & " * @datetime.hint When to run the job" & chr(10);
        content &= chr(9) & " * @data.hint Job data" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "public void function enqueueAt(required date datetime, struct data = {}) {" & chr(10);
        content &= chr(9) & chr(9) & "super.enqueueAt(" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "jobName = variables.jobName," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "data = arguments.data," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "queue = variables.queue," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "priority = variables.priority," & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "runAt = arguments.datetime" & chr(10);
        content &= chr(9) & chr(9) & ");" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= chr(9) & "// ========================================" & chr(10);
        content &= chr(9) & "// Private Methods" & chr(10);
        content &= chr(9) & "// ========================================" & chr(10) & chr(10);
        
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Validate job data" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "private void function validateJobData(required struct data) {" & chr(10);
        content &= chr(9) & chr(9) & "// Add validation logic here" & chr(10);
        content &= chr(9) & chr(9) & "// Example: if (!structKeyExists(arguments.data, ""requiredField"")) {" & chr(10);
        content &= chr(9) & chr(9) & "//     throw(type=""ValidationException"", message=""Missing required field"");" & chr(10);
        content &= chr(9) & chr(9) & "// }" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Process job data" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "private void function processJobData(required struct data) {" & chr(10);
        content &= chr(9) & chr(9) & "// Implement your job processing logic here" & chr(10);
        content &= chr(9) & chr(9) & "// Example:" & chr(10);
        content &= chr(9) & chr(9) & "// - Process batch records" & chr(10);
        content &= chr(9) & chr(9) & "// - Send emails" & chr(10);
        content &= chr(9) & chr(9) & "// - Generate reports" & chr(10);
        content &= chr(9) & chr(9) & "// - Sync with external APIs" & chr(10);
        content &= chr(9) & chr(9) & "// - Clean up old data" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Log info message" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "private void function logInfo(required string message) {" & chr(10);
        content &= chr(9) & chr(9) & "if (structKeyExists(application, ""log"")) {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "application.log.info(arguments.message);" & chr(10);
        content &= chr(9) & chr(9) & "}" & chr(10);
        content &= chr(9) & chr(9) & "writeLog(text=arguments.message, type=""information"", file=""jobs"");" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= chr(9) & "/**" & chr(10);
        content &= chr(9) & " * Log error message" & chr(10);
        content &= chr(9) & " */" & chr(10);
        content &= chr(9) & "private void function logError(required string message, any exception) {" & chr(10);
        content &= chr(9) & chr(9) & "if (structKeyExists(application, ""log"")) {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "application.log.error(arguments.message, arguments.exception);" & chr(10);
        content &= chr(9) & chr(9) & "}" & chr(10);
        content &= chr(9) & chr(9) & "writeLog(text=arguments.message, type=""error"", file=""jobs"");" & chr(10);
        content &= chr(9) & "}" & chr(10);
        
        content &= "}";
        
        return content;
    }
    
    /**
     * Create test file for job
     */
    private void function createJobTest(required string jobName) {
        var testsDir = helpers.getTestPath() & "/specs/jobs";

        if (!directoryExists(testsDir)) {
            directoryCreate(testsDir, true);
        }

        var testPath = testsDir & "/" & jobName & "Spec.cfc";

        if (!fileExists(testPath)) {
            var testContent = generateJobTest(jobName);
            fileWrite(testPath, testContent);
            detailOutput.output("Created test: /tests/specs/jobs/#jobName#Spec.cfc");
        }
    }
    
    /**
     * Generate job test content
     */
    private string function generateJobTest(required string jobName) {
        var content = "component extends=""wheels.Test"" {" & chr(10) & chr(10);
        
        content &= chr(9) & "function setup() {" & chr(10);
        content &= chr(9) & chr(9) & "job = createObject(""component"", ""jobs.#jobName#"").init();" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= chr(9) & "function test_job_initialization() {" & chr(10);
        content &= chr(9) & chr(9) & "assert(isObject(job), ""Job should be initialized"");" & chr(10);
        content &= chr(9) & chr(9) & "assert(isInstanceOf(job, ""jobs.#jobName#""), ""Job should be correct type"");" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= chr(9) & "function test_perform_with_valid_data() {" & chr(10);
        content &= chr(9) & chr(9) & "// Arrange" & chr(10);
        content &= chr(9) & chr(9) & "local.testData = {" & chr(10);
        content &= chr(9) & chr(9) & chr(9) & "// Add test data here" & chr(10);
        content &= chr(9) & chr(9) & "};" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "// Act & Assert - should not throw" & chr(10);
        content &= chr(9) & chr(9) & "job.perform(local.testData);" & chr(10);
        content &= chr(9) & chr(9) & "assert(true, ""Job should complete without errors"");" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= chr(9) & "function test_enqueue() {" & chr(10);
        content &= chr(9) & chr(9) & "// Test that job can be enqueued" & chr(10);
        content &= chr(9) & chr(9) & "// Note: This would require a queue implementation" & chr(10);
        content &= chr(9) & chr(9) & "local.testData = {};" & chr(10);
        content &= chr(10);
        content &= chr(9) & chr(9) & "// Should not throw" & chr(10);
        content &= chr(9) & chr(9) & "// job.enqueue(local.testData);" & chr(10);
        content &= chr(9) & chr(9) & "assert(true, ""Enqueue test placeholder"");" & chr(10);
        content &= chr(9) & "}" & chr(10) & chr(10);
        
        content &= "}";
        
        return content;
    }
    
    /**
     * Create job schedule configuration
     */
    private void function createJobSchedule(required struct args) {
        var scheduleDir = helpers.getAppPath() & "/config/schedules";
        
        if (!directoryExists(scheduleDir)) {
            directoryCreate(scheduleDir);
        }
        
        var schedulePath = scheduleDir & "/" & lCase(args.name) & ".json";
        
        var scheduleConfig = {
            "name": args.name,
            "schedule": args.schedule,
            "job": "jobs." & args.name,
            "queue": args.queue,
            "priority": args.priority,
            "enabled": true,
            "description": len(args.description) ? args.description : "Scheduled job: #args.name#"
        };
        
        fileWrite(schedulePath, serializeJSON(scheduleConfig));
        detailOutput.output("Created schedule config: /config/schedules/#lCase(args.name)#.json");
    }
}