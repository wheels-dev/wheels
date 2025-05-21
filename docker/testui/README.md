# cfwheels-test-suite-ui

This web application provides a way of queuing tests for each of the docker containers. It starts on localhost:3000 when using `docker compose up` with the appropriate profile.

## Features

- Simple web interface to run tests
- Support for multiple CFML engines (Lucee 5/6, Adobe 2018/2021/2023)
- Support for multiple databases (MySQL, PostgreSQL, SQL Server, H2)
- Real-time test results display
- Test queue management

## Usage

1. Start the TestUI container along with the desired CFML engines and databases:
   ```bash
   docker compose --profile ui --profile lucee --profile db up -d
   ```

2. Access the TestUI at http://localhost:3000

3. Click on a CFML engine + database combination to add it to the test queue

4. Click "Start Queue" to run the tests

5. View results in the Results panel

## Recent Changes

- **2025-05-15**: Fixed issue with test queue not clearing between runs, which was causing subsequent test runs to rerun previous tests

## Project setup for local development
```
npm install
```

Installs required dependencies in `node_modules` (which is git ignored)

### Compiles and hot-reloads
```
npm run serve
```

Starts the local development server. It will try for localhost:3000 but if it can't open on that port will try 3001 etc

### Compiles and minifies for production
```
npm run build
```

When you've made your changes, build it and commit the changes

### Lints and fixes files
```
npm run lint
```

### Key Files

- `index.html` - Main UI and application logic
- `services/servers.js` - Configuration for CFML engine endpoints
- `services/databases.js` - Configuration for database options
- `services/testsuites.js` - Combines servers and databases into runnable test suites