# Wheels TestUI Development Guide

This document provides guidance for developers working on the Wheels TestUI.

## Architecture

The TestUI is built with the following technologies:

- **Vue 3**: Frontend framework with Composition API
- **TypeScript**: For type safety and better developer experience
- **Pinia**: State management
- **Tailwind CSS & DaisyUI**: UI styling
- **Vite**: Build tool and development server

## Project Structure

```
/
├── public/            # Static assets served as-is
├── src/
│   ├── assets/        # Static assets that will be processed
│   ├── components/    # Reusable Vue components
│   ├── services/      # API and service layer
│   ├── stores/        # Pinia stores
│   ├── types/         # TypeScript type definitions
│   ├── utils/         # Utility functions
│   ├── views/         # Page components
│   ├── App.vue        # Root component
│   ├── main.ts        # Application entry point
│   └── router.ts      # Vue Router configuration
├── .env               # Environment variables
├── index.html         # HTML entry point
├── package.json       # Dependencies and scripts
├── tsconfig.json      # TypeScript configuration
├── vite.config.ts     # Vite configuration
└── tailwind.config.js # Tailwind CSS configuration
```

## Development Workflow

### Prerequisites

- Node.js 18+ and npm

### Setup

1. Clone the repository
2. Install dependencies:

```bash
npm install
```

3. Start the development server:

```bash
npm run dev
```

This will start a development server at http://localhost:3000.

### Building for Production

```bash
npm run build
```

The built files will be in the `dist` directory.

### Docker Development

You can also develop using Docker:

```bash
docker-compose -f docker-compose.dev.yml up
```

## Key Features

### Theme System

The application supports dark and light themes. The theme system:

1. Respects user preference stored in localStorage
2. Falls back to system preference if no stored preference
3. Updates in real-time when system preference changes

### Docker Integration

The TestUI integrates with Docker to:

1. Manage CFML engine containers
2. Manage database containers
3. Run pre-flight checks before tests
4. Provide container health monitoring

### Test Runner

The test runner allows:

1. Selection of CFML engines and databases
2. Creation of test queues with multiple combinations
3. Detailed test result reporting
4. Test failure analysis

## Adding New Components

When adding new components:

1. Create the component in `src/components/`
2. Use TypeScript for props and emits
3. Follow the existing styling patterns
4. Add the component to the appropriate page or parent component

## State Management

We use Pinia for state management. Each store should:

1. Be focused on a specific domain (engines, databases, tests, etc.)
2. Use the Composition API style with `defineStore()`
3. Provide clear actions and computed properties
4. Handle async operations properly

## API Integration

The application communicates with backend services via:

1. Service layer in `src/services/`
2. Utility functions in `src/utils/api.ts`
3. Mock implementations for development

## Troubleshooting

### Development Server Issues

If the development server isn't working:

1. Check for TypeScript errors
2. Verify the port isn't in use
3. Check network settings if developing within Docker

### Styling Issues

If components don't look right:

1. Verify Tailwind and DaisyUI are properly configured
2. Check for CSS conflicts
3. Ensure theme classes are properly applied