Perfect! The wheels docker test command is now working correctly. The application is
  running on port 60006 (the default for Lucee 6).

  Summary

  The Docker test command is now successfully implemented and working:

  1. ✅ Detects whether you're in a template or example directory
  2. ✅ Automatically uses the engine's default port (60006 for Lucee 6, 62021 for Adobe
  2021, etc.)
  3. ✅ Properly mounts the src directory for templates
  4. ✅ Generates docker-compose.yml dynamically
  5. ✅ Starts containers successfully

  You can now use:
  - box wheels docker test run - Run with default settings
  - box wheels docker test run --engine=adobe@2021 - Test with Adobe 2021 (port 62021)
  - box wheels docker test run --db=mysql - Test with MySQL database
  - box wheels docker test run --port=8081 - Override default port
  - box wheels docker test logs - View logs
  - box wheels docker test stop - Stop containers
  - box wheels docker test clean - Clean up everything
