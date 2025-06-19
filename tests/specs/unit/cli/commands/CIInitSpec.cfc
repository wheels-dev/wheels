/**
 * Tests for the ci init command
 * Tests CI/CD configuration file generation
 */
component extends="BaseCommandSpec" {
	
	function run() {
		
		describe("CI Init Command", () => {
			
			beforeEach(() => {
				// Create mock command instance
				variables.ciInit = createMockCommand("cli.commands.wheels.ci.init");
				
				// Create basic app structure
				createDirectoryStructure([
					".github/workflows",
					"tests",
					"config"
				]);
				
				// Create basic files
				createTestFile("box.json", '{
					"name": "test-app",
					"version": "1.0.0"
				}');
			});
			
			describe("GitHub Actions", () => {
				
				it("should generate GitHub Actions workflow", () => {
					// Run the command
					ciInit.run(provider = "github");
					
					// Check that workflow was created
					assertFileExists(".github/workflows/ci.yml");
					
					// Verify workflow content
					var workflowContent = getFileContent(".github/workflows/ci.yml");
					expect(workflowContent).toInclude("name: CI");
					expect(workflowContent).toInclude("on:");
					expect(workflowContent).toInclude("push:");
					expect(workflowContent).toInclude("pull_request:");
					expect(workflowContent).toInclude("jobs:");
					expect(workflowContent).toInclude("test:");
				});
				
				it("should include test job with matrix strategy", () => {
					// Run the command
					ciInit.run(provider = "github", engines = "lucee@5,adobe@2021");
					
					// Verify matrix strategy
					var workflowContent = getFileContent(".github/workflows/ci.yml");
					expect(workflowContent).toInclude("strategy:");
					expect(workflowContent).toInclude("matrix:");
					expect(workflowContent).toInclude("cfengine:");
					expect(workflowContent).toInclude("lucee@5");
					expect(workflowContent).toInclude("adobe@2021");
				});
				
				it("should setup CommandBox and dependencies", () => {
					// Run the command
					ciInit.run(provider = "github");
					
					// Verify CommandBox setup
					var workflowContent = getFileContent(".github/workflows/ci.yml");
					expect(workflowContent).toInclude("Setup CommandBox");
					expect(workflowContent).toInclude("box install");
					expect(workflowContent).toInclude("box server start");
				});
				
				it("should include database services when specified", () => {
					// Run the command with database
					ciInit.run(provider = "github", database = "mysql");
					
					// Verify database service
					var workflowContent = getFileContent(".github/workflows/ci.yml");
					expect(workflowContent).toInclude("services:");
					expect(workflowContent).toInclude("mysql:");
					expect(workflowContent).toInclude("image: mysql:");
					expect(workflowContent).toInclude("MYSQL_ROOT_PASSWORD:");
					expect(workflowContent).toInclude("MYSQL_DATABASE: wheelstestdb");
				});
				
				it("should add code coverage reporting", () => {
					// Run the command with coverage
					ciInit.run(provider = "github", coverage = true);
					
					// Verify coverage steps
					var workflowContent = getFileContent(".github/workflows/ci.yml");
					expect(workflowContent).toInclude("Run tests with coverage");
					expect(workflowContent).toInclude("--coverage");
					expect(workflowContent).toInclude("Upload coverage");
				});
				
			});
			
			describe("GitLab CI", () => {
				
				it("should generate GitLab CI configuration", () => {
					// Run the command
					ciInit.run(provider = "gitlab");
					
					// Check that .gitlab-ci.yml was created
					assertFileExists(".gitlab-ci.yml");
					
					// Verify GitLab CI content
					var ciContent = getFileContent(".gitlab-ci.yml");
					expect(ciContent).toInclude("stages:");
					expect(ciContent).toInclude("- test");
					expect(ciContent).toInclude("test:lucee:");
					expect(ciContent).toInclude("script:");
				});
				
				it("should use GitLab CI services for databases", () => {
					// Run the command with database
					ciInit.run(provider = "gitlab", database = "postgresql");
					
					// Verify PostgreSQL service
					var ciContent = getFileContent(".gitlab-ci.yml");
					expect(ciContent).toInclude("services:");
					expect(ciContent).toInclude("- postgres:latest");
					expect(ciContent).toInclude("POSTGRES_DB: wheelstestdb");
					expect(ciContent).toInclude("POSTGRES_PASSWORD:");
				});
				
				it("should cache dependencies", () => {
					// Run the command
					ciInit.run(provider = "gitlab");
					
					// Verify cache configuration
					var ciContent = getFileContent(".gitlab-ci.yml");
					expect(ciContent).toInclude("cache:");
					expect(ciContent).toInclude("paths:");
					expect(ciContent).toInclude("- .commandbox/");
					expect(ciContent).toInclude("- modules/");
				});
				
			});
			
			describe("Bitbucket Pipelines", () => {
				
				it("should generate Bitbucket Pipelines configuration", () => {
					// Run the command
					ciInit.run(provider = "bitbucket");
					
					// Check that bitbucket-pipelines.yml was created
					assertFileExists("bitbucket-pipelines.yml");
					
					// Verify Bitbucket content
					var pipelinesContent = getFileContent("bitbucket-pipelines.yml");
					expect(pipelinesContent).toInclude("pipelines:");
					expect(pipelinesContent).toInclude("default:");
					expect(pipelinesContent).toInclude("- step:");
					expect(pipelinesContent).toInclude("name: Test");
				});
				
				it("should define services for databases", () => {
					// Run the command with database
					ciInit.run(provider = "bitbucket", database = "mysql");
					
					// Verify MySQL service definition
					var pipelinesContent = getFileContent("bitbucket-pipelines.yml");
					expect(pipelinesContent).toInclude("definitions:");
					expect(pipelinesContent).toInclude("services:");
					expect(pipelinesContent).toInclude("mysql:");
					expect(pipelinesContent).toInclude("image: mysql:");
				});
				
			});
			
			describe("CircleCI", () => {
				
				it("should generate CircleCI configuration", () => {
					// Create .circleci directory
					createDirectoryStructure([".circleci"]);
					
					// Run the command
					ciInit.run(provider = "circleci");
					
					// Check that config.yml was created
					assertFileExists(".circleci/config.yml");
					
					// Verify CircleCI content
					var circleContent = getFileContent(".circleci/config.yml");
					expect(circleContent).toInclude("version: 2.1");
					expect(circleContent).toInclude("jobs:");
					expect(circleContent).toInclude("test:");
					expect(circleContent).toInclude("workflows:");
				});
				
				it("should use CircleCI orbs for efficiency", () => {
					// Create .circleci directory
					createDirectoryStructure([".circleci"]);
					
					// Run the command
					ciInit.run(provider = "circleci");
					
					// Verify orb usage
					var circleContent = getFileContent(".circleci/config.yml");
					expect(circleContent).toInclude("orbs:");
				});
				
			});
			
			describe("Common Features", () => {
				
				it("should add deployment stage when specified", () => {
					// Run the command with deployment
					ciInit.run(provider = "github", deploy = true);
					
					// Verify deployment job
					var workflowContent = getFileContent(".github/workflows/ci.yml");
					expect(workflowContent).toInclude("deploy:");
					expect(workflowContent).toInclude("needs: test");
					expect(workflowContent).toInclude("if: github.ref == 'refs/heads/main'");
				});
				
				it("should add linting stage", () => {
					// Run the command with linting
					ciInit.run(provider = "github", lint = true);
					
					// Verify linting job
					var workflowContent = getFileContent(".github/workflows/ci.yml");
					expect(workflowContent).toInclude("lint:");
					expect(workflowContent).toInclude("box run-script format:check");
				});
				
				it("should add security scanning", () => {
					// Run the command with security scan
					ciInit.run(provider = "github", security = true);
					
					// Verify security scanning
					var workflowContent = getFileContent(".github/workflows/ci.yml");
					expect(workflowContent).toInclude("security:");
					expect(workflowContent).toInclude("dependency scanning");
				});
				
				it("should configure environment variables", () => {
					// Run the command
					ciInit.run(provider = "github", database = "mysql");
					
					// Verify environment variables
					var workflowContent = getFileContent(".github/workflows/ci.yml");
					expect(workflowContent).toInclude("env:");
					expect(workflowContent).toInclude("DB_HOST:");
					expect(workflowContent).toInclude("DB_PORT:");
					expect(workflowContent).toInclude("DB_NAME:");
				});
				
			});
			
			describe("Error Handling", () => {
				
				it("should validate provider option", () => {
					// Run with invalid provider
					ciInit.run(provider = "invalid");
					
					// Verify error message
					assertOutputContains("Invalid CI provider");
					assertOutputContains("Valid providers: github, gitlab, bitbucket, circleci");
				});
				
				it("should not overwrite existing CI configuration", () => {
					// Create existing workflow
					createTestFile(".github/workflows/ci.yml", "# Existing workflow");
					
					// Run the command
					ciInit.run(provider = "github");
					
					// Verify warning
					assertOutputContains("CI configuration already exists");
					
					// Verify file unchanged
					var content = getFileContent(".github/workflows/ci.yml");
					expect(content).toBe("# Existing workflow");
				});
				
				it("should handle force flag", () => {
					// Create existing workflow
					createTestFile(".github/workflows/ci.yml", "# Old workflow");
					
					// Run with force flag
					ciInit.run(provider = "github", force = true);
					
					// Verify file was overwritten
					var content = getFileContent(".github/workflows/ci.yml");
					expect(content).toInclude("name: CI");
					expect(content).notToInclude("# Old workflow");
				});
				
			});
			
			describe("Output Messages", () => {
				
				it("should display success message with file location", () => {
					// Run the command
					ciInit.run(provider = "github");
					
					// Verify output
					assertOutputContains("CI configuration generated successfully");
					assertOutputContains(".github/workflows/ci.yml");
				});
				
				it("should display next steps", () => {
					// Run the command
					ciInit.run(provider = "github");
					
					// Verify next steps
					assertOutputContains("Next steps:");
					assertOutputContains("Commit and push");
					assertOutputContains("Configure secrets");
				});
				
				it("should show provider-specific instructions", () => {
					// Run for GitHub
					ciInit.run(provider = "github");
					assertOutputContains("GitHub Actions");
					assertOutputContains("Settings > Secrets");
					
					// Clear output and run for GitLab
					clearPrintBuffer();
					ciInit.run(provider = "gitlab");
					assertOutputContains("GitLab CI");
					assertOutputContains("Settings > CI/CD > Variables");
				});
				
			});
			
		});
		
	}
	
}