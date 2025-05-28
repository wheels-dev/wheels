# Wheels TestUI

A modern test runner interface for Wheels framework testing.

## Features

- **Modern UI** with dark and light theme support
- **Test Runner** for executing tests across different CFML engines and databases
- **Docker Integration** for managing containers directly from the UI
- **Container Management** - Start Docker containers by clicking on stopped services
- **Pre-flight System** to ensure all required services are running before tests
- **Enhanced Test Results** with detailed error information and test statistics
- **API Server** for Docker command execution from the UI

## Tech Stack

- Vue 3 with Composition API
- TypeScript for type safety
- Tailwind CSS and DaisyUI for styling
- Pinia for state management
- Vite for fast development and builds

## Quick Start

### Using Docker (Recommended)

The TestUI is integrated with Docker for easy setup and development.

#### Production Mode

```bash
# From the Wheels root directory
docker compose --profile ui up -d
```

This will start:
- **TestUI** on http://localhost:3000 - The main test runner interface
- **TestUI API** on http://localhost:3001 - API server for Docker command execution

Then visit http://localhost:3000 in your browser.

#### Development Mode

```bash
# From the testui directory
docker-compose -f docker-compose.dev.yml up
```

For more detailed Docker instructions, see [DOCKER-INTEGRATION.md](./DOCKER-INTEGRATION.md).

### Manual Development

#### Prerequisites

- Node.js 18+ and npm

#### Setup

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

### Build for Production

```bash
# Build the application
npm run build

# Preview the production build
npm run preview
```

## Project Structure

```
/src
  /assets           # Static assets like CSS, images
  /components       # Reusable Vue components
  /services         # Services for API calls and business logic
  /stores           # Pinia stores for state management
  /types            # TypeScript interfaces and types
  /utils            # Helper functions and utilities
  /views            # Main view components
  App.vue           # Root component
  main.ts           # Application entry point
```

## Docker Integration

The TestUI provides deep integration with Docker to manage CFML engine and database containers. It allows you to:

- View container status and health in real-time
- Start containers directly from the UI by clicking on stopped services
- Stop and restart running containers
- Manage container profiles for different testing scenarios
- Run pre-flight checks before test execution
- Execute Docker Compose commands through the API server

### Container Management

The TestUI includes an API server that enables container management directly from the web interface:

- **Click on stopped engines/databases** to start them automatically
- **No need to use terminal** - all container operations available in the UI
- **Automatic container detection** when services start
- **Real-time status updates** every 5 seconds

See [DOCKER-INTEGRATION.md](./DOCKER-INTEGRATION.md) for detailed information on Docker integration.

## Container Profiles

The following pre-defined container profiles are available:

- **Core Tests Profile**: Minimal setup for running core Wheels tests
- **Full Test Suite Profile**: Complete setup for running all tests across all engines and databases

## Development

For development guidelines, see [DEVELOPMENT.md](./DEVELOPMENT.md).