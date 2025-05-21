# CFWheels TestUI Modernization Plan

This document outlines the comprehensive plan for modernizing the CFWheels TestUI, including a fresh visual design, improved functionality, and Docker container integration.

## Table of Contents

1. [Current State Assessment](#current-state-assessment)
2. [Modernization Goals](#modernization-goals)
3. [Technical Approach](#technical-approach)
4. [Feature Specifications](#feature-specifications)
5. [Implementation Timeline](#implementation-timeline)
6. [Getting Started](#getting-started)

## Current State Assessment

The existing CFWheels TestUI is a basic web interface that provides functionality for running tests against different CFML engines and database combinations. Its limitations include:

- Outdated visual design (Bootstrap 4.4.1)
- Limited user feedback and interaction
- No theme support (light mode only)
- Basic error handling and display
- No Docker container management
- Limited test result information display
- No pre-flight checks for required services
- Single-page application with minimal structure
- No build process or modern framework usage

## Modernization Goals

The modernization effort aims to:

1. Implement a fresh, modern UI with both dark and light themes
2. Enhance test results display with detailed information and visualization
3. Integrate Docker container profile management directly into the UI
4. Add pre-flight container checks and automatic service startup
5. Improve the overall user experience with responsive design and better interactivity
6. Adopt modern frontend technologies for better maintainability and extensibility

## Technical Approach

### Technology Stack

#### Frontend
- **Framework**: Vue.js 3 (with Composition API)
- **Build Tool**: Vite
- **Type Safety**: TypeScript
- **Styling**: Tailwind CSS + DaisyUI
- **State Management**: Pinia
- **HTTP Client**: Axios
- **Real-time Updates**: WebSockets

#### Backend Integration
- Docker API access via proxy or bridge
- Health check endpoints for services
- WebSocket for container event streaming

### Architecture

1. **Core Modules**:
   - Test Runner: Handles test selection, execution, and result display
   - Docker Manager: Controls container lifecycle and monitoring
   - Pre-flight System: Handles service dependencies and readiness checks

2. **State Management**:
   - Centralized state stores for tests, containers, and UI
   - Reactive updates via Vue 3 reactivity system
   - Persistence for user preferences and configurations

3. **UI Components**:
   - Common: Reusable UI elements with theme support
   - Test: Components specific to test selection and results
   - Docker: Components for container management
   - Layout: Page structure and navigation elements

## Feature Specifications

### Theme Support and UI Modernization

- **Dark/Light Theme Toggle**
  - System preference detection via CSS media queries
  - Manual toggle with persistent setting in localStorage
  - Smooth transitions between themes

- **Modern Design Elements**
  - Card-based interface with clean typography
  - Improved spacing and layout
  - Interactive elements with hover and focus states
  - Consistent color palette with theme variants

- **Responsive Design**
  - Mobile-friendly layouts
  - Adaptive components based on screen size
  - Touch-optimized controls for mobile devices

### Test Details Display Enhancement

- **Summary Dashboard**
  - Overview statistics with pass/fail counts
  - Test duration information
  - Status indicators and badges
  - Charts for result visualization

- **Test Navigation**
  - Hierarchical tree view of bundles, suites, and specs
  - Filtering and searching of test results
  - Quick navigation to failed tests
  - Expandable/collapsible sections

- **Detailed Test View**
  - Individual test cards with status and duration
  - Full error messages with syntax highlighting
  - Stack traces with source line highlighting
  - Contextual information for failures

- **Data Visualization**
  - Pass/fail ratio charts
  - Test duration metrics
  - Performance comparison between engines
  - Historical test results comparison

### Docker Container Integration

- **Profile Management**
  - Visual representation of available Docker Compose profiles
  - Status indicators for running services
  - Start/stop/restart controls for profiles
  - Custom profile creation interface

- **Container Status Dashboard**
  - Real-time container status monitoring
  - Health check indicators
  - Resource usage metrics
  - Quick access to logs and shell

- **Service Management**
  - Individual service cards with status
  - Action buttons for container operations
  - Configuration display
  - Connection verification

### Pre-flight Container Check System

- **Service Requirements Analysis**
  - Automatic detection of required services for tests
  - Dependency resolution for services
  - Resource verification for containers

- **Container State Checking**
  - Status evaluation of required containers
  - Health assessment with custom checks
  - Readiness determination for test execution

- **Startup Orchestration**
  - Planning of necessary actions
  - User confirmation for operations
  - Phased startup process with progress tracking
  - Error handling and recovery strategies

- **Health Monitoring**
  - Continuous service health checks
  - Status tracking with history
  - Readiness verification with timeout handling
  - Cross-service connectivity validation

### Workflow Integration

- **Test Preparation Flow**
  - Select tests to run
  - Verify required services
  - Start missing services if needed
  - Execute tests when ready
  - Display results with rich details

- **Post-test Actions**
  - Option to keep or shutdown services
  - Resource cleanup recommendations
  - Result exporting and sharing
  - Test comparison with previous runs

## Implementation Timeline

### Phase 1: Foundation (Weeks 1-2)

#### Week 1: Project Setup and Framework Migration
- Set up Vue 3 + Vite + TypeScript project
- Configure essential tooling and dependencies
- Migrate core test selection functionality
- Implement basic state management

#### Week 2: Theme Support and UI
- Create responsive layout structure
- Implement dark/light theme toggle
- Develop core UI components
- Set up basic styling with Tailwind CSS

### Phase 2: Test Results Enhancement (Weeks 3-4)

#### Week 3: Test Results UI
- Develop enhanced test result components
- Create hierarchical result navigation
- Implement syntax highlighting for errors
- Add result filtering capabilities

#### Week 4: Advanced Test Details
- Create detailed test information display
- Implement data visualization components
- Add export and sharing functionality
- Develop result history features

### Phase 3: Docker Integration (Weeks 5-7)

#### Week 5: Docker API Connection
- Set up Docker API communication
- Implement container status querying
- Create container operations interface
- Add error handling and security measures

#### Week 6: Container UI
- Develop container status dashboard
- Create profile management interface
- Implement log viewing components
- Add resource monitoring displays

#### Week 7: Pre-flight System
- Create service requirement analyzer
- Implement health check monitoring
- Develop startup orchestration logic
- Build pre-flight dashboard UI

### Phase 4: Polish and Performance (Weeks 8-9)

#### Week 8: Performance Optimization
- Implement lazy loading and code splitting
- Add virtualized lists for large datasets
- Optimize component rendering
- Set up WebWorkers for heavy processing

#### Week 9: Finalization
- Conduct comprehensive UI testing
- Fix cross-browser compatibility issues
- Add accessibility improvements
- Create documentation and deployment guide

## Getting Started

1. Clone the repository
2. Install dependencies: `npm install`
3. Start development server: `npm run dev`
4. Build for production: `npm run build`

The modernized TestUI will enhance developer productivity by providing a more intuitive and informative testing experience with seamless Docker integration.