     │ Comprehensive CLI Commands for Modern CFML Framework (Wheels)                                                 │
     │                                                                                                               │
     │ Based on research of Rails, Laravel, Django, Phoenix, and CommandBox capabilities, here's a comprehensive     │
     │ list of CLI commands organized by functionality:                                                              │
     │                                                                                                               │
     │ 1. Project & Application Management                                                                           │
     │                                                                                                               │
     │ - wheels new [app-name] - Create new Wheels application                                                       │
     │ - wheels init - Initialize existing project as Wheels app                                                     │
     │ - wheels info - Display application info and environment                                                      │
     │ - wheels version - Show Wheels version                                                                        │
     │ - wheels upgrade - Upgrade Wheels to latest version                                                           │
     │ - wheels doctor - Check application health/dependencies                                                       │
     │                                                                                                               │
     │ 2. Code Generation                                                                                            │
     │                                                                                                               │
     │ - wheels g/generate scaffold [model] [fields] - Full CRUD scaffold                                            │
     │ - wheels g/generate model [name] [fields] - Generate model                                                    │
     │ - wheels g/generate controller [name] [actions] - Generate controller                                         │
     │ - wheels g/generate view [controller] [action] - Generate view                                                │
     │ - wheels g/generate resource [name] [fields] - RESTful resource                                               │
     │ - wheels g/generate api-resource [name] [fields] - API-only resource                                          │
     │ - wheels g/generate test [type] [name] - Generate test files                                                  │
     │ - wheels g/generate property [model] [name:type] - Add property to model                                      │
     │ - wheels g/generate route [method] [path] [controller#action] - Add route                                     │
     │ - wheels g/generate mailer [name] - Email mailer                                                              │
     │ - wheels g/generate job [name] - Background job                                                               │
     │ - wheels g/generate helper [name] - Helper functions                                                          │
     │ - wheels g/generate plugin [name] - Plugin scaffold                                                           │
     │ - wheels g/generate middleware [name] - Middleware component                                                  │
     │ - wheels g/generate service [name] - Service object                                                           │
     │ - wheels g/generate form [name] - Form object                                                                 │
     │ - wheels g/generate validator [name] - Custom validator                                                       │
     │                                                                                                               │
     │ 3. Database Management                                                                                        │
     │                                                                                                               │
     │ - wheels db:create - Create database                                                                          │
     │ - wheels db:drop - Drop database                                                                              │
     │ - wheels db:reset - Drop, create, migrate, seed                                                               │
     │ - wheels db:migrate - Run pending migrations                                                                  │
     │ - wheels db:rollback [steps] - Rollback migrations                                                            │
     │ - wheels db:status - Show migration status                                                                    │
     │ - wheels db:seed - Run database seeders                                                                       │
     │ - wheels db:schema:dump - Export schema                                                                       │
     │ - wheels db:schema:load - Import schema                                                                       │
     │ - wheels dbmigrate create [name] - Create migration                                                           │
     │ - wheels dbmigrate up/down - Run specific migration                                                           │
     │                                                                                                               │
     │ 4. Server & Development                                                                                       │
     │                                                                                                               │
     │ - wheels server/serve - Start development server                                                              │
     │ - wheels server:stop - Stop server                                                                            │
     │ - wheels server:restart - Restart server                                                                      │
     │ - wheels server:status - Server status                                                                        │
     │ - wheels console/repl - Interactive console                                                                   │
     │ - wheels tinker - Interactive debugging console                                                               │
     │ - wheels watch - Watch files for changes                                                                      │
     │ - wheels reload [environment] - Reload application                                                            │
     │                                                                                                               │
     │ 5. Testing                                                                                                    │
     │                                                                                                               │
     │ - wheels test [type] - Run tests                                                                              │
     │ - wheels test:unit - Run unit tests                                                                           │
     │ - wheels test:integration - Run integration tests                                                             │
     │ - wheels test:coverage - Generate coverage report                                                             │
     │ - wheels test:watch - Watch mode for TDD                                                                      │
     │ - wheels test:debug - Debug test mode                                                                         │
     │ - wheels test:migrate - Migrate test database                                                                 │
     │                                                                                                               │
     │ 6. Package Management                                                                                         │
     │                                                                                                               │
     │ - wheels install [package] - Install package                                                                  │
     │ - wheels uninstall [package] - Remove package                                                                 │
     │ - wheels update [package] - Update packages                                                                   │
     │ - wheels list - List installed packages                                                                       │
     │ - wheels search [term] - Search packages                                                                      │
     │ - wheels publish - Publish package                                                                            │
     │                                                                                                               │
     │ 7. Configuration & Environment                                                                                │
     │                                                                                                               │
     │ - wheels config:list - List all config                                                                        │
     │ - wheels config:get [key] - Get config value                                                                  │
     │ - wheels config:set [key] [value] - Set config                                                                │
     │ - wheels config:clear - Clear config cache                                                                    │
     │ - wheels env:list - List environments                                                                         │
     │ - wheels env:switch [env] - Switch environment                                                                │
     │ - wheels env:setup - Setup environment                                                                        │
     │                                                                                                               │
     │ 8. Assets & Frontend                                                                                          │
     │                                                                                                               │
     │ - wheels assets:compile - Compile assets                                                                      │
     │ - wheels assets:watch - Watch assets                                                                          │
     │ - wheels assets:clean - Clean compiled assets                                                                 │
     │ - wheels assets:precompile - Precompile for production                                                        │
     │                                                                                                               │
     │ 9. Deployment & Production                                                                                    │
     │                                                                                                               │
     │ - wheels deploy:init - Initialize deployment                                                                  │
     │ - wheels deploy:push - Deploy to server                                                                       │
     │ - wheels deploy:rollback - Rollback deployment                                                                │
     │ - wheels deploy:status - Deployment status                                                                    │
     │ - wheels deploy:logs - View deployment logs                                                                   │
     │ - wheels optimize - Optimize for production                                                                   │
     │ - wheels cache:clear - Clear application cache                                                                │
     │                                                                                                               │
     │ 10. Documentation & Help                                                                                      │
     │                                                                                                               │
     │ - wheels docs - Open documentation                                                                            │
     │ - wheels docs:generate - Generate API docs                                                                    │
     │ - wheels routes - Display all routes                                                                          │
     │ - wheels routes:list - List routes with details                                                               │
     │ - wheels help [command] - Get help for command                                                                │
     │                                                                                                               │
     │ 11. Security & Analysis                                                                                       │
     │                                                                                                               │
     │ - wheels security:scan - Security audit                                                                       │
     │ - wheels analyze:code - Code analysis                                                                         │
     │ - wheels analyze:performance - Performance analysis                                                           │
     │ - wheels lint - Code linting                                                                                  │
     │ - wheels format - Format code                                                                                 │
     │                                                                                                               │
     │ 12. Docker & CI/CD                                                                                            │
     │                                                                                                               │
     │ - wheels docker:init - Setup Docker files                                                                     │
     │ - wheels docker:build - Build Docker image                                                                    │
     │ - wheels docker:deploy - Deploy with Docker                                                                   │
     │ - wheels ci:init - Setup CI/CD config                                                                         │
     │                                                                                                               │
     │ 13. Plugin Management                                                                                         │
     │                                                                                                               │
     │ - wheels plugin:install [name] - Install plugin                                                               │
     │ - wheels plugin:remove [name] - Remove plugin                                                                 │
     │ - wheels plugin:list - List plugins                                                                           │
     │ - wheels plugin:create [name] - Create plugin                                                                 │
     │                                                                                                               │
     │ 14. Maintenance & Admin                                                                                       │
     │                                                                                                               │
     │ - wheels maintenance:on - Enable maintenance mode                                                             │
     │ - wheels maintenance:off - Disable maintenance mode                                                           │
     │ - wheels queue:work - Process job queue                                                                       │
     │ - wheels schedule:run - Run scheduled tasks                                                                   │
     │ - wheels logs:tail - Tail application logs                                                                    │
     │                                                                                                               │
     │ 15. Development Tools                                                                                         │
     │                                                                                                               │
     │ - wheels make:command [name] - Create custom command                                                          │
     │ - wheels ide:helper - Generate IDE helpers                                                                    │
     │ - wheels stub:publish - Publish stubs for customization                                                       │
     │ - wheels vendor:publish - Publish vendor resources                                                            │
     │                                                                                                               │
     │ This comprehensive list combines the best practices from modern frameworks while leveraging CommandBox's      │
     │ native capabilities and maintaining consistency with Wheels' conventions.
