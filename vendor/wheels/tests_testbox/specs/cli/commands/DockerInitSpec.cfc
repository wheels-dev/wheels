/**
 * Tests for the docker init command
 * Tests file generation and configuration options
 */
component extends="BaseCommandSpec" {
	
	function run() {
		
		describe("Docker Init Command", () => {
			
			beforeEach(() => {
				// Create mock command instance
				variables.dockerInit = createMockCommand("cli.commands.wheels.docker.init");
				
				// Create basic app structure
				createDirectoryStructure([
					"config",
					"app",
					"vendor"
				]);
				
				// Create a basic Application.cfc for testing
				createTestFile("Application.cfc", 'component {
					this.name = "TestApp";
				}');
			});
			
			describe("Basic Functionality", () => {
				
				it("should generate Dockerfile with default configuration", () => {
					// Run the command
					dockerInit.run();
					
					// Check that Dockerfile was created
					assertFileExists("Dockerfile");
					
					// Verify Dockerfile content
					var dockerContent = getFileContent("Dockerfile");
					expect(dockerContent).toInclude("FROM ortussolutions/commandbox");
					expect(dockerContent).toInclude("COPY . /app");
					expect(dockerContent).toInclude("WORKDIR /app");
					expect(dockerContent).toInclude("EXPOSE 8080");
					expect(dockerContent).toInclude('CMD ["server", "start"]');
				});
				
				it("should generate docker-compose.yml", () => {
					// Run the command
					dockerInit.run();
					
					// Check that docker-compose.yml was created
					assertFileExists("docker-compose.yml");
					
					// Verify docker-compose content
					var composeContent = getFileContent("docker-compose.yml");
					expect(composeContent).toInclude("version:");
					expect(composeContent).toInclude("services:");
					expect(composeContent).toInclude("web:");
					expect(composeContent).toInclude("build: .");
					expect(composeContent).toInclude("ports:");
					expect(composeContent).toInclude("8080:8080");
				});
				
				it("should generate .dockerignore file", () => {
					// Run the command
					dockerInit.run();
					
					// Check that .dockerignore was created
					assertFileExists(".dockerignore");
					
					// Verify .dockerignore content
					var ignoreContent = getFileContent(".dockerignore");
					expect(ignoreContent).toInclude("tests/");
					expect(ignoreContent).toInclude("*.log");
					expect(ignoreContent).toInclude(".git");
					expect(ignoreContent).toInclude("node_modules/");
				});
				
			});
			
			describe("Configuration Options", () => {
				
				it("should use custom port when specified", () => {
					// Run the command with custom port
					dockerInit.run(port = 3000);
					
					// Verify Dockerfile uses custom port
					var dockerContent = getFileContent("Dockerfile");
					expect(dockerContent).toInclude("EXPOSE 3000");
					
					// Verify docker-compose uses custom port
					var composeContent = getFileContent("docker-compose.yml");
					expect(composeContent).toInclude("3000:3000");
				});
				
				it("should include database service when specified", () => {
					// Run the command with database option
					dockerInit.run(database = "mysql");
					
					// Verify docker-compose includes MySQL service
					var composeContent = getFileContent("docker-compose.yml");
					expect(composeContent).toInclude("mysql:");
					expect(composeContent).toInclude("image: mysql:");
					expect(composeContent).toInclude("MYSQL_ROOT_PASSWORD:");
					expect(composeContent).toInclude("MYSQL_DATABASE:");
				});
				
				it("should support PostgreSQL database option", () => {
					// Run the command with PostgreSQL
					dockerInit.run(database = "postgresql");
					
					// Verify docker-compose includes PostgreSQL service
					var composeContent = getFileContent("docker-compose.yml");
					expect(composeContent).toInclude("postgres:");
					expect(composeContent).toInclude("image: postgres:");
					expect(composeContent).toInclude("POSTGRES_PASSWORD:");
					expect(composeContent).toInclude("POSTGRES_DB:");
				});
				
				it("should include Redis service when caching is enabled", () => {
					// Run the command with caching option
					dockerInit.run(caching = true);
					
					// Verify docker-compose includes Redis service
					var composeContent = getFileContent("docker-compose.yml");
					expect(composeContent).toInclude("redis:");
					expect(composeContent).toInclude("image: redis:alpine");
				});
				
				it("should use custom CFML engine when specified", () => {
					// Run the command with Adobe ColdFusion
					dockerInit.run(engine = "adobe2023");
					
					// Verify Dockerfile uses Adobe image
					var dockerContent = getFileContent("Dockerfile");
					expect(dockerContent).toInclude("ortussolutions/commandbox:adobe2023");
				});
				
			});
			
			describe("Environment Configuration", () => {
				
				it("should generate .env.example file", () => {
					// Run the command
					dockerInit.run(database = "mysql");
					
					// Check that .env.example was created
					assertFileExists(".env.example");
					
					// Verify .env.example content
					var envContent = getFileContent(".env.example");
					expect(envContent).toInclude("DB_HOST=");
					expect(envContent).toInclude("DB_PORT=");
					expect(envContent).toInclude("DB_NAME=");
					expect(envContent).toInclude("DB_USER=");
					expect(envContent).toInclude("DB_PASSWORD=");
				});
				
				it("should add environment variables to docker-compose", () => {
					// Run the command
					dockerInit.run(database = "mysql");
					
					// Verify docker-compose uses environment variables
					var composeContent = getFileContent("docker-compose.yml");
					expect(composeContent).toInclude("environment:");
					expect(composeContent).toInclude("DB_HOST: mysql");
					expect(composeContent).toInclude("env_file:");
					expect(composeContent).toInclude(".env");
				});
				
			});
			
			describe("Error Handling", () => {
				
				it("should not overwrite existing Dockerfile", () => {
					// Create existing Dockerfile
					createTestFile("Dockerfile", "# Existing Dockerfile");
					
					// Run the command
					dockerInit.run();
					
					// Verify error message
					assertOutputContains("Dockerfile already exists");
					
					// Verify original file is unchanged
					var content = getFileContent("Dockerfile");
					expect(content).toBe("# Existing Dockerfile");
				});
				
				it("should handle force flag to overwrite files", () => {
					// Create existing files
					createTestFile("Dockerfile", "# Old Dockerfile");
					createTestFile("docker-compose.yml", "# Old compose");
					
					// Run the command with force flag
					dockerInit.run(force = true);
					
					// Verify files were overwritten
					var dockerContent = getFileContent("Dockerfile");
					expect(dockerContent).toInclude("FROM ortussolutions/commandbox");
					expect(dockerContent).notToInclude("# Old Dockerfile");
				});
				
			});
			
			describe("Multi-stage Builds", () => {
				
				it("should generate multi-stage Dockerfile for production", () => {
					// Run the command with production flag
					dockerInit.run(production = true);
					
					// Verify multi-stage build
					var dockerContent = getFileContent("Dockerfile");
					expect(dockerContent).toInclude("AS builder");
					expect(dockerContent).toInclude("FROM ortussolutions/commandbox:alpine");
					expect(dockerContent).toInclude("--from=builder");
				});
				
			});
			
			describe("Output Messages", () => {
				
				it("should display success messages", () => {
					// Run the command
					dockerInit.run();
					
					// Verify output messages
					assertOutputContains("Docker configuration files generated successfully");
					assertOutputContains("Dockerfile");
					assertOutputContains("docker-compose.yml");
					assertOutputContains(".dockerignore");
				});
				
				it("should display next steps", () => {
					// Run the command
					dockerInit.run();
					
					// Verify next steps are shown
					assertOutputContains("Next steps:");
					assertOutputContains("docker-compose up");
					assertOutputContains("http://localhost:8080");
				});
				
			});
			
		});
		
	}
	
}