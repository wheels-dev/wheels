# CLAUDE.md - Jobs (Background Tasks)

This file provides guidance to Claude Code (claude.ai/code) when working with Wheels background jobs.

## Overview

The `/app/jobs/` folder contains background job classes for asynchronous processing in your Wheels application. Jobs are used for tasks that should run outside the request/response cycle, such as sending emails, processing large datasets, generating reports, or integrating with external APIs.

**Why Use Background Jobs:**
- Offload time-consuming tasks from web requests
- Improve user experience with faster response times
- Handle batch processing and data imports
- Schedule recurring tasks
- Retry failed operations automatically
- Process work in parallel with queues

**Note:** While Wheels includes job generation and patterns, the actual job queue system needs to be implemented using external queue systems or CFML scheduled tasks.

## Job Architecture

### Base Job Class
All jobs extend `wheels.Job`, which provides:
- Queue management interface
- Retry logic handling
- Error logging and handling
- Job state management
- Scheduling capabilities

### Core Job Methods

#### Required Methods
- **`perform(struct data = {})`** - Main execution method that contains job logic
- **`init()`** - Constructor for job configuration

#### Queue Methods
- **`enqueue(struct data = {})`** - Add job to immediate processing queue
- **`enqueueIn(numeric seconds, struct data = {})`** - Add job with delay
- **`enqueueAt(date datetime, struct data = {})`** - Schedule job for specific time

#### Configuration Properties
- **`queue`** - Queue name (default: "default")
- **`priority`** - Job priority: low, normal, high (default: "normal")
- **`retries`** - Number of retry attempts on failure (default: 3)
- **`timeout`** - Job timeout in seconds (default: 300)

## Job Generation

### CLI Generator
Use the Wheels CLI to generate job classes:

```bash
# Basic job
wheels g job ProcessOrders

# Job with configuration
wheels g job SendNewsletters queue=emails priority=high

# Scheduled job with cron expression
wheels g job CleanupOldRecords schedule="0 0 * * *"

# Job with delay and description
wheels g job DataExport delay=3600 description="Export user data to CSV"
```

### Generator Options
- **`name`** - Job name (automatically suffixed with "Job")
- **`queue`** - Queue name for job organization
- **`priority`** - Job priority level (low, normal, high)
- **`schedule`** - Cron expression for recurring jobs
- **`delay`** - Default delay in seconds
- **`retries`** - Number of retry attempts
- **`timeout`** - Job execution timeout
- **`description`** - Job description for documentation
- **`force`** - Overwrite existing files

## Basic Job Structure

### Job Template
```cfm
/**
 * ProcessOrdersJob
 * Queue: default
 * Priority: normal
 */
component extends="wheels.Job" {

    // Job configuration properties
    property name="queue" default="default";
    property name="priority" default="normal";
    property name="retries" default="3";
    property name="timeout" default="300";

    /**
     * Constructor - Configure job settings
     */
    function init() {
        variables.jobName = "ProcessOrdersJob";
        return this;
    }

    /**
     * Main job execution method
     * @data.hint Job data/parameters
     */
    public void function perform(struct data = {}) {
        try {
            // Log job start
            logInfo("Starting ProcessOrdersJob with data: " & serializeJSON(arguments.data));

            // Validate input data
            validateJobData(arguments.data);

            // Execute job logic
            processJobData(arguments.data);

            // Log completion
            logInfo("Completed ProcessOrdersJob successfully");

        } catch (any e) {
            // Log error
            logError("Error in ProcessOrdersJob: " & e.message, e);

            // Re-throw to trigger retry logic
            throw(object=e);
        }
    }

    // Queue methods and private helper methods...
}
```

### Key Components

#### 1. Job Configuration
```cfm
// Standard properties that control job behavior
property name="queue" default="default";
property name="priority" default="normal";
property name="retries" default="3";
property name="timeout" default="300";
```

#### 2. Constructor Pattern
```cfm
function init() {
    // Set job identifier
    variables.jobName = "ProcessOrdersJob";
    
    // Additional initialization if needed
    variables.batchSize = 100;
    variables.logFile = "orders";
    
    return this;
}
```

#### 3. Main Execution Method
```cfm
public void function perform(struct data = {}) {
    try {
        // Always validate input first
        validateJobData(arguments.data);
        
        // Execute the actual work
        processJobData(arguments.data);
        
    } catch (any e) {
        // Log error and re-throw for retry handling
        logError("Job failed: " & e.message, e);
        throw(object=e);
    }
}
```

## Common Job Patterns

### 1. Email Processing Job
```cfm
/**
 * SendWelcomeEmailJob - Send welcome emails to new users
 */
component extends="wheels.Job" {
    
    property name="queue" default="emails";
    property name="priority" default="normal";
    property name="retries" default="5";
    
    function init() {
        variables.jobName = "SendWelcomeEmailJob";
        return this;
    }
    
    public void function perform(struct data = {}) {
        try {
            validateJobData(arguments.data);
            
            // Get user information
            local.user = model("User").findByKey(arguments.data.userId);
            if (!isObject(local.user)) {
                throw(type="ValidationException", message="User not found: #arguments.data.userId#");
            }
            
            // Send welcome email
            sendWelcomeEmail(local.user);
            
            // Update user status
            local.user.update(welcomeEmailSent=true, welcomeEmailSentAt=now());
            
            logInfo("Welcome email sent to user #local.user.id#: #local.user.email#");
            
        } catch (any e) {
            logError("Failed to send welcome email: " & e.message, e);
            throw(object=e);
        }
    }
    
    private void function validateJobData(required struct data) {
        if (!structKeyExists(arguments.data, "userId") || !isNumeric(arguments.data.userId)) {
            throw(type="ValidationException", message="Valid userId required");
        }
    }
    
    private void function sendWelcomeEmail(required any user) {
        // Use Wheels mail functionality or external service
        mail(
            to=arguments.user.email,
            from=get("fromEmail"),
            subject="Welcome to Our App!",
            template="welcome",
            templatedata={user: arguments.user}
        );
    }
}
```

### 2. Batch Processing Job
```cfm
/**
 * ProcessOrdersJob - Process pending orders in batches
 */
component extends="wheels.Job" {
    
    property name="queue" default="processing";
    property name="priority" default="high";
    property name="retries" default="3";
    property name="timeout" default="600"; // 10 minutes
    
    function init() {
        variables.jobName = "ProcessOrdersJob";
        variables.batchSize = 50;
        return this;
    }
    
    public void function perform(struct data = {}) {
        try {
            local.batchSize = structKeyExists(arguments.data, "batchSize") ? 
                arguments.data.batchSize : variables.batchSize;
                
            // Get pending orders
            local.pendingOrders = model("Order").findAll(
                where="status = ?",
                whereParams=["pending"],
                order="createdAt",
                maxRows=local.batchSize
            );
            
            logInfo("Processing #local.pendingOrders.recordCount# pending orders");
            
            // Process each order
            local.processed = 0;
            local.failed = 0;
            
            for (local.order in local.pendingOrders) {
                try {
                    processOrder(local.order);
                    local.processed++;
                } catch (any e) {
                    local.failed++;
                    logError("Failed to process order #local.order.id#: #e.message#", e);
                    
                    // Mark order as failed
                    local.order.update(status="failed", failureReason=e.message);
                }
            }
            
            logInfo("Batch processing complete: #local.processed# processed, #local.failed# failed");
            
            // Enqueue next batch if there might be more orders
            if (local.pendingOrders.recordCount == local.batchSize) {
                enqueueIn(seconds=30, data={batchSize: local.batchSize});
                logInfo("Enqueued next batch for processing");
            }
            
        } catch (any e) {
            logError("Batch processing job failed: " & e.message, e);
            throw(object=e);
        }
    }
    
    private void function processOrder(required any order) {
        // Validate order data
        if (!len(arguments.order.customerEmail)) {
            throw(type="ValidationException", message="Order missing customer email");
        }
        
        // Process payment
        local.paymentResult = processPayment(arguments.order);
        if (!local.paymentResult.success) {
            throw(type="PaymentException", message=local.paymentResult.message);
        }
        
        // Update inventory
        decrementInventory(arguments.order.items);
        
        // Send confirmation email
        sendOrderConfirmation(arguments.order);
        
        // Update order status
        arguments.order.update(
            status="processed",
            processedAt=now(),
            paymentId=local.paymentResult.transactionId
        );
    }
}
```

### 3. File Processing Job
```cfm
/**
 * ProcessFileUploadJob - Process uploaded files asynchronously
 */
component extends="wheels.Job" {
    
    property name="queue" default="files";
    property name="priority" default="normal";
    property name="timeout" default="1800"; // 30 minutes
    
    function init() {
        variables.jobName = "ProcessFileUploadJob";
        variables.maxFileSize = 50 * 1024 * 1024; // 50MB
        return this;
    }
    
    public void function perform(struct data = {}) {
        try {
            validateJobData(arguments.data);
            
            local.upload = model("FileUpload").findByKey(arguments.data.uploadId);
            if (!isObject(local.upload)) {
                throw(type="ValidationException", message="Upload not found: #arguments.data.uploadId#");
            }
            
            // Update status to processing
            local.upload.update(status="processing", processedAt=now());
            
            // Process file based on type
            switch (local.upload.fileType) {
                case "csv":
                    processCSVFile(local.upload);
                    break;
                case "image":
                    processImageFile(local.upload);
                    break;
                case "pdf":
                    processPDFFile(local.upload);
                    break;
                default:
                    throw(type="UnsupportedFileType", message="Unsupported file type: #local.upload.fileType#");
            }
            
            // Mark as completed
            local.upload.update(status="completed", completedAt=now());
            
            logInfo("File processing completed for upload #local.upload.id#");
            
        } catch (any e) {
            // Mark upload as failed
            if (structKeyExists(local, "upload") && isObject(local.upload)) {
                local.upload.update(status="failed", errorMessage=e.message);
            }
            
            logError("File processing failed: " & e.message, e);
            throw(object=e);
        }
    }
    
    private void function validateJobData(required struct data) {
        if (!structKeyExists(arguments.data, "uploadId") || !isNumeric(arguments.data.uploadId)) {
            throw(type="ValidationException", message="Valid uploadId required");
        }
    }
    
    private void function processCSVFile(required any upload) {
        local.filePath = expandPath(arguments.upload.filePath);
        
        if (!fileExists(local.filePath)) {
            throw(type="FileNotFoundException", message="File not found: #local.filePath#");
        }
        
        // Read and process CSV
        local.csvData = csvToQuery(local.filePath);
        local.processedRows = 0;
        
        for (local.row = 1; local.row <= local.csvData.recordCount; local.row++) {
            try {
                processCSVRow(local.csvData, local.row);
                local.processedRows++;
            } catch (any e) {
                logError("Failed to process CSV row #local.row#: #e.message#", e);
            }
        }
        
        // Update upload with results
        arguments.upload.update(
            processedRows=local.processedRows,
            totalRows=local.csvData.recordCount
        );
        
        logInfo("Processed #local.processedRows# of #local.csvData.recordCount# CSV rows");
    }
}
```

### 4. Scheduled Cleanup Job
```cfm
/**
 * CleanupOldRecordsJob - Remove old records and files
 * Schedule: 0 2 * * * (daily at 2 AM)
 */
component extends="wheels.Job" {
    
    property name="queue" default="maintenance";
    property name="priority" default="low";
    
    function init() {
        variables.jobName = "CleanupOldRecordsJob";
        variables.schedule = "0 2 * * *"; // Daily at 2 AM
        variables.retentionDays = 90;
        return this;
    }
    
    public void function perform(struct data = {}) {
        try {
            local.cutoffDate = dateAdd("d", -variables.retentionDays, now());
            local.totalDeleted = 0;
            
            logInfo("Starting cleanup of records older than #dateFormat(local.cutoffDate, 'yyyy-mm-dd')#");
            
            // Clean up different types of records
            local.totalDeleted += cleanupAuditLogs(local.cutoffDate);
            local.totalDeleted += cleanupTempFiles(local.cutoffDate);
            local.totalDeleted += cleanupExpiredSessions(local.cutoffDate);
            local.totalDeleted += cleanupLogFiles(local.cutoffDate);
            
            logInfo("Cleanup completed: #local.totalDeleted# items removed");
            
        } catch (any e) {
            logError("Cleanup job failed: " & e.message, e);
            throw(object=e);
        }
    }
    
    private numeric function cleanupAuditLogs(required date cutoffDate) {
        local.deleted = model("AuditLog").deleteAll(
            where="createdAt < ?",
            whereParams=[arguments.cutoffDate]
        );
        
        logInfo("Deleted #local.deleted# old audit log entries");
        return local.deleted;
    }
    
    private numeric function cleanupTempFiles(required date cutoffDate) {
        local.tempDir = expandPath("/tmp/uploads/");
        local.deleted = 0;
        
        if (directoryExists(local.tempDir)) {
            local.files = directoryList(
                path=local.tempDir,
                recurse=true,
                listInfo="query"
            );
            
            for (local.file in local.files) {
                if (local.file.dateLastModified < arguments.cutoffDate) {
                    try {
                        fileDelete(local.file.path);
                        local.deleted++;
                    } catch (any e) {
                        logError("Failed to delete temp file #local.file.path#: #e.message#", e);
                    }
                }
            }
        }
        
        logInfo("Deleted #local.deleted# old temp files");
        return local.deleted;
    }
}
```

## Job Testing

### Test Structure
Jobs should include comprehensive test coverage:

```cfm
/**
 * ProcessOrdersJobTest
 */
component extends="wheels.Test" {

    function setup() {
        // Initialize job instance
        variables.job = createObject("component", "jobs.ProcessOrdersJob").init();
        
        // Create test data
        variables.testUser = model("User").create(
            name="Test User",
            email="test@example.com"
        );
        
        variables.testOrder = model("Order").create(
            userId=variables.testUser.id,
            status="pending",
            total=99.99
        );
    }

    function teardown() {
        // Clean up test data
        variables.testOrder.delete();
        variables.testUser.delete();
    }

    function test_job_initialization() {
        assert(isObject(variables.job), "Job should be initialized");
        assert(isInstanceOf(variables.job, "jobs.ProcessOrdersJob"), "Job should be correct type");
        assert(variables.job.jobName == "ProcessOrdersJob", "Job name should be set");
    }

    function test_perform_with_valid_data() {
        // Arrange
        local.jobData = {
            orderId: variables.testOrder.id,
            batchSize: 10
        };

        // Act & Assert - should not throw
        variables.job.perform(local.jobData);
        
        // Verify order was processed
        variables.testOrder.reload();
        assert(variables.testOrder.status == "processed", "Order should be processed");
        assert(isDate(variables.testOrder.processedAt), "Processed timestamp should be set");
    }

    function test_perform_with_invalid_data() {
        // Test with missing required data
        local.jobData = {};

        // Should throw validation error
        expectedException(
            type="ValidationException",
            message="Valid orderId required"
        );
        
        variables.job.perform(local.jobData);
    }

    function test_enqueue_methods() {
        local.jobData = {orderId: variables.testOrder.id};

        // Test immediate enqueue
        // Note: This would require a queue implementation
        // variables.job.enqueue(local.jobData);

        // Test delayed enqueue
        // variables.job.enqueueIn(seconds=60, data=local.jobData);

        // Test scheduled enqueue
        // local.futureTime = dateAdd("h", 1, now());
        // variables.job.enqueueAt(datetime=local.futureTime, data=local.jobData);

        assert(true, "Enqueue methods should be callable");
    }

    function test_error_handling() {
        // Test job behavior with database errors
        local.invalidData = {orderId: 99999}; // Non-existent order

        expectedException(type="ValidationException");
        variables.job.perform(local.invalidData);
    }

    function test_logging() {
        // Verify job logs appropriately
        local.jobData = {orderId: variables.testOrder.id};
        
        // Capture log output
        variables.job.perform(local.jobData);
        
        // Check that log entries were created
        // This would require accessing log files or mock logging
        assert(true, "Job should log execution details");
    }
}
```

### Test Best Practices

#### 1. Test Data Management
```cfm
function setup() {
    // Use transactions for test isolation
    transaction action="begin" {
        // Create test data
        variables.testData = createTestData();
    }
}

function teardown() {
    // Roll back transaction to clean up
    transaction action="rollback";
}
```

#### 2. Mock External Services
```cfm
function test_email_job_with_mock_service() {
    // Mock the email service
    variables.mockEmailService = createMock("EmailService");
    variables.mockEmailService.send(any(), any()).returns(true);
    
    // Inject mock into job
    variables.job.setEmailService(variables.mockEmailService);
    
    // Test job execution
    variables.job.perform({userId: variables.testUser.id});
    
    // Verify mock was called
    variables.mockEmailService.verify().send(any(), any());
}
```

#### 3. Test Error Scenarios
```cfm
function test_job_retry_logic() {
    // Create job that will fail twice then succeed
    variables.failingJob = createObject("component", "jobs.FlakeyJob").init();
    variables.failingJob.setFailureCount(2);
    
    // First attempt should fail
    expectedException();
    variables.failingJob.perform({});
    
    // Second attempt should fail
    expectedException();
    variables.failingJob.perform({});
    
    // Third attempt should succeed
    variables.failingJob.perform({});
    assert(true, "Job should eventually succeed");
}
```

## Job Queue Implementation

### Queue Interface
While Wheels provides the job structure, you need to implement or integrate with a queue system:

#### Option 1: CFML Scheduled Tasks
```cfm
// In Application.cfc or scheduled task
function processJobQueue() {
    try {
        // Get jobs from database queue
        local.jobs = model("QueuedJob").findAll(
            where="status = ? AND runAt <= ?",
            whereParams=["pending", now()],
            order="priority DESC, createdAt",
            maxRows=10
        );
        
        for (local.job in local.jobs) {
            try {
                // Mark as processing
                local.job.update(status="processing", startedAt=now());
                
                // Execute job
                local.jobInstance = createObject("component", local.job.jobClass).init();
                local.jobInstance.perform(deserializeJSON(local.job.data));
                
                // Mark as completed
                local.job.update(status="completed", completedAt=now());
                
            } catch (any e) {
                // Handle retry logic
                if (local.job.attempts < local.job.maxRetries) {
                    local.job.update(
                        status="pending",
                        attempts=local.job.attempts + 1,
                        runAt=dateAdd("n", pow(2, local.job.attempts), now()), // Exponential backoff
                        lastError=e.message
                    );
                } else {
                    local.job.update(
                        status="failed",
                        failedAt=now(),
                        lastError=e.message
                    );
                }
                
                logError("Job #local.job.id# failed: #e.message#", e);
            }
        }
        
    } catch (any e) {
        logError("Queue processing failed: #e.message#", e);
    }
}
```

#### Option 2: External Queue Systems
Integration with external queue systems like Redis, RabbitMQ, or cloud services:

```cfm
// Redis queue example
component {
    
    function enqueueJob(required string jobClass, required struct data, string queue = "default") {
        local.redis = getRedisConnection();
        local.jobPayload = {
            id: createUUID(),
            class: arguments.jobClass,
            data: arguments.data,
            queue: arguments.queue,
            enqueuedAt: now(),
            attempts: 0
        };
        
        local.redis.lpush("queue:#arguments.queue#", serializeJSON(local.jobPayload));
    }
    
    function processQueue(string queue = "default") {
        local.redis = getRedisConnection();
        
        while (true) {
            // Block waiting for job
            local.job = local.redis.brpop("queue:#arguments.queue#", timeout=30);
            
            if (arrayLen(local.job)) {
                local.jobData = deserializeJSON(local.job[2]);
                processJob(local.jobData);
            }
        }
    }
}
```

### Job Scheduling

#### Cron-style Scheduling
```cfm
// Schedule configuration in /config/schedules/
{
    "name": "CleanupOldRecordsJob",
    "schedule": "0 2 * * *",
    "job": "jobs.CleanupOldRecordsJob",
    "queue": "maintenance",
    "enabled": true,
    "description": "Daily cleanup of old records"
}
```

#### Job Scheduler Component
```cfm
component {
    
    function scheduleJob(required struct config) {
        // Parse cron expression
        local.nextRun = calculateNextRun(arguments.config.schedule);
        
        // Store in database or queue system
        model("ScheduledJob").create(
            name=arguments.config.name,
            jobClass=arguments.config.job,
            schedule=arguments.config.schedule,
            nextRun=local.nextRun,
            enabled=arguments.config.enabled
        );
    }
    
    function processScheduledJobs() {
        local.dueJobs = model("ScheduledJob").findAll(
            where="enabled = ? AND nextRun <= ?",
            whereParams=[true, now()]
        );
        
        for (local.job in local.dueJobs) {
            // Enqueue job for processing
            enqueueJob(local.job.jobClass, {});
            
            // Calculate next run time
            local.nextRun = calculateNextRun(local.job.schedule);
            local.job.update(
                lastRun=now(),
                nextRun=local.nextRun,
                runCount=local.job.runCount + 1
            );
        }
    }
}
```

## Usage Examples

### In Controllers
```cfm
component extends="Controller" {

    function processOrder() {
        // Process order synchronously for immediate feedback
        local.order = model("Order").findByKey(params.id);
        local.order.update(status="processing");
        
        // Enqueue background job for heavy processing
        local.job = createObject("component", "jobs.ProcessOrdersJob").init();
        local.job.enqueue({orderId: local.order.id});
        
        flashInsert(success="Order queued for processing");
        redirectTo(action="show", key=local.order.id);
    }
    
    function bulkImport() {
        // Handle file upload
        local.upload = fileUpload(destination=expandPath("/tmp/uploads/"));
        
        // Create upload record
        local.fileUpload = model("FileUpload").create(
            originalName=local.upload.clientFile,
            filePath="/tmp/uploads/#local.upload.serverFile#",
            fileType=local.upload.fileExt,
            status="pending"
        );
        
        // Queue processing job
        local.job = createObject("component", "jobs.ProcessFileUploadJob").init();
        local.job.enqueueIn(seconds=5, data={uploadId: local.fileUpload.id});
        
        renderJSON({
            success: true,
            uploadId: local.fileUpload.id,
            message: "File uploaded and queued for processing"
        });
    }
}
```

### In Models
```cfm
component extends="Model" {

    function config() {
        // Send welcome email after user creation
        afterCreate("sendWelcomeEmail");
    }
    
    private void function sendWelcomeEmail() {
        // Queue welcome email job
        local.job = createObject("component", "jobs.SendWelcomeEmailJob").init();
        local.job.enqueueIn(seconds=30, data={userId: this.id});
    }
    
    function requestPasswordReset() {
        // Generate reset token
        this.passwordResetToken = generateSecureToken();
        this.passwordResetExpires = dateAdd("h", 2, now());
        this.save();
        
        // Queue password reset email
        local.job = createObject("component", "jobs.SendPasswordResetJob").init();
        local.job.enqueue({userId: this.id});
    }
}
```

### Job Monitoring
```cfm
// Job status monitoring
component extends="Controller" {

    function jobStatus() {
        local.stats = {
            pending: model("QueuedJob").count(where="status = 'pending'"),
            processing: model("QueuedJob").count(where="status = 'processing'"),
            completed: model("QueuedJob").count(where="status = 'completed'"),
            failed: model("QueuedJob").count(where="status = 'failed'")
        };
        
        local.recentJobs = model("QueuedJob").findAll(
            order="createdAt DESC",
            maxRows=50,
            include="User"
        );
        
        renderJSON({
            stats: local.stats,
            recentJobs: local.recentJobs
        });
    }
    
    function retryFailedJob() {
        local.job = model("QueuedJob").findByKey(params.id);
        
        if (local.job.status == "failed") {
            local.job.update(
                status="pending",
                runAt=now(),
                attempts=0,
                lastError=""
            );
            
            flashInsert(success="Job queued for retry");
        } else {
            flashInsert(error="Job is not in failed state");
        }
        
        redirectTo(action="index");
    }
}
```

## Best Practices

### 1. Job Design
- **Single Responsibility**: Each job should have one clear purpose
- **Idempotent**: Jobs should be safe to run multiple times
- **Small Data**: Pass minimal data, use IDs to fetch current state
- **Error Handling**: Always include comprehensive error handling
- **Logging**: Log job start, progress, and completion

### 2. Data Validation
```cfm
private void function validateJobData(required struct data) {
    local.errors = [];
    
    // Check required fields
    if (!structKeyExists(arguments.data, "userId") || !isNumeric(arguments.data.userId)) {
        arrayAppend(local.errors, "Valid userId required");
    }
    
    // Validate data types
    if (structKeyExists(arguments.data, "batchSize") && !isNumeric(arguments.data.batchSize)) {
        arrayAppend(local.errors, "batchSize must be numeric");
    }
    
    // Business rule validation
    if (structKeyExists(arguments.data, "amount") && arguments.data.amount <= 0) {
        arrayAppend(local.errors, "Amount must be positive");
    }
    
    if (arrayLen(local.errors)) {
        throw(type="ValidationException", message="Validation failed: #arrayToList(local.errors, ', ')#");
    }
}
```

### 3. Progress Tracking
```cfm
public void function perform(struct data = {}) {
    try {
        local.total = getTotalWorkItems(arguments.data);
        local.processed = 0;
        
        // Update progress periodically
        for (local.item in getWorkItems(arguments.data)) {
            processItem(local.item);
            local.processed++;
            
            // Update progress every 10 items
            if (local.processed % 10 == 0) {
                updateProgress(local.processed, local.total);
            }
        }
        
        updateProgress(local.processed, local.total, "completed");
        
    } catch (any e) {
        updateProgress(local.processed, local.total, "failed", e.message);
        throw(object=e);
    }
}

private void function updateProgress(numeric processed, numeric total, string status = "processing", string message = "") {
    if (structKeyExists(variables, "progressTracker")) {
        variables.progressTracker.update(
            processed=arguments.processed,
            total=arguments.total,
            percentage=round((arguments.processed / arguments.total) * 100),
            status=arguments.status,
            message=arguments.message
        );
    }
}
```

### 4. Resource Management
```cfm
public void function perform(struct data = {}) {
    local.resources = [];
    
    try {
        // Acquire resources
        local.dbConnection = getDatabaseConnection();
        arrayAppend(local.resources, local.dbConnection);
        
        local.fileHandle = openFile(arguments.data.filePath);
        arrayAppend(local.resources, local.fileHandle);
        
        // Process job
        processWithResources(local.resources, arguments.data);
        
    } catch (any e) {
        logError("Job failed: " & e.message, e);
        throw(object=e);
        
    } finally {
        // Always clean up resources
        for (local.resource in local.resources) {
            try {
                if (isStruct(local.resource) && structKeyExists(local.resource, "close")) {
                    local.resource.close();
                }
            } catch (any cleanupError) {
                logError("Failed to cleanup resource: " & cleanupError.message, cleanupError);
            }
        }
    }
}
```

### 5. Environment Configuration
```cfm
function init() {
    variables.jobName = "ProcessOrdersJob";
    
    // Environment-specific configuration
    if (get("environment") == "development") {
        variables.batchSize = 10;
        variables.logLevel = "debug";
    } else if (get("environment") == "production") {
        variables.batchSize = 100;
        variables.logLevel = "info";
    }
    
    // Load configuration from settings
    variables.retryAttempts = get("jobRetryAttempts", 3);
    variables.timeout = get("jobTimeout", 300);
    
    return this;
}
```

## Important Notes

- **Queue System Required**: Wheels provides job structure but requires external queue implementation
- **Error Handling**: Always include comprehensive error handling and logging
- **Testing**: Jobs should be thoroughly tested including failure scenarios
- **Monitoring**: Implement job monitoring and alerting for production systems
- **Performance**: Consider job size and execution time for optimal performance
- **Data Consistency**: Use database transactions where appropriate
- **Resource Cleanup**: Always clean up resources in finally blocks
- **Security**: Validate and sanitize all job data inputs

Background jobs provide powerful capabilities for handling asynchronous processing in Wheels applications while maintaining responsive user experiences.