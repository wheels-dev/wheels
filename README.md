![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/wheels-dev/wheels/snapshot.yml?style=flat-square&logo=github&label=Wheels%20Snapshots)
<img src="https://www.forgebox.io/api/v1/entry/wheels-core/badges/version" />
<img src="https://www.forgebox.io/api/v1/entry/wheels-core/badges/downloads" />
![Dynamic JSON Badge](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fwww.forgebox.io%2Fapi%2Fv1%2Fentry%2Fwheels-core%2Fbadges%2F&query=%24.data.versions.0.version&style=flat-square&label=Bleeding%20Edge%20Release)

# Wheels

[Wheels][1] provides fast application development, a great organization system for your code, and is just plain fun to use.

One of our biggest goals is for you to be able to get up and running with Wheels quickly. We want for you to be able to learn it as rapidly as it is to write applications with it.

## Getting Started

### Quick Start

Create a new Wheels application using the CLI:

```bash
wheels new myapp
```

### Learning Wheels

In this [Beginner Tutorial: Hello World][2], we'll be writing a simple application to make sure we have Wheels installed properly and that everything is working as it should. Along the way, you'll get to know some basics about how applications built on top of Wheels work.

## System Requirements

**CFML Engines:**

- **Adobe ColdFusion**: 2018, 2021, 2023, 2025
- **Lucee**: 5.x, 6.x, 7.x
- **BoxLang**: 1.x

**Supported Databases:**

- SQLite (new in 3.0!)
- Oracle (new in 3.0!)
- Microsoft SQL Server
- PostgreSQL
- MySQL
- H2

**Note:** Adobe ColdFusion 2016 is no longer supported as of Wheels 3.0.

## Project Structure

Wheels 3.0 introduces a clean, modern project structure:

```
your-app/
├── app/
│   ├── controllers/
│   ├── models/
│   ├── views/
│   └── ...
├── config/
├── public/
├── tests/
├── vendor/
│   ├── wheels/
│   ├── wirebox/
│   └── testbox/
└── ...
```

## Monorepo Structure

This repository contains the complete Wheels ecosystem in a monorepo structure. All components are developed together but distributed as separate ForgeBox packages.

```
wheels-monorepo/
├── cli/                    # Wheels CLI (CommandBox module)
│   └── src/                # Published as 'wheels-cli'
├── core/                   # Framework Core
│   └── src/wheels/         # Published as 'wheels-core'
├── templates/              # Application Templates
│   └── base/src/           # Starting structure for new apps
├── docs/                   # Documentation
│   └── src/                # Published to wheels.dev/guides
├── examples/               # Example applications
├── tools/
│   └── build/scripts/      # Build and packaging scripts
└── tests/                  # Framework test suite
```

**Key Components:**
- **CLI** (`wheels-cli`): Development tools and generators (CommandBox module)
- **Core** (`wheels-core`): Framework runtime installed in `/vendor/wheels`
- **Base Template** (`wheels-base-template`): Starting structure downloaded by CLI for new applications
- **Documentation**: Comprehensive guides published to wheels.dev/guides
- **Build System**: Automated packaging and ForgeBox distribution

**Package Flow**: CLI downloads base template from ForgeBox during `wheels new myapp`, which includes dependency on core framework. Documentation is automatically published to wheels.dev/guides. All components are versioned together and distributed as separate ForgeBox packages that work seamlessly together.

**For detailed monorepo documentation**, see [MONOREPO.md](MONOREPO.md) which includes:
- Complete directory structure breakdown
- Component relationships and dependency graphs
- Development workflow and testing procedures
- Build and distribution pipeline details

## Contributing

We encourage you to contribute to Wheels! Whether you're fixing bugs, adding features, improving documentation, or helping with discussions, your contributions make Wheels better for everyone.

**Two Ways to Contribute:**

1. **Developer Applications** - Built using `wheels new` command for application development
2. **Framework Core** - The [wheels-dev/wheels](https://github.com/wheels-dev/wheels) monorepo for core framework contributions

Please check out our [Contributing Guide][3] for detailed guidelines on how to get started. We've made the contribution process as smooth as possible with Docker support, comprehensive testing setup, and clear documentation.


## Running Tests

**Important: Before running tests, make sure that all debugging is turned OFF**. This could add a considerable amount of time for the tests to complete and may cause your engine to become unresponsive.

### Test Database Setup

1. Create a database on a supported database server named `wheelstestdb`
   - Supported servers: SQLite, Oracle, Microsoft SQL Server, PostgreSQL, MySQL, H2
2. Create a datasource in your CFML engine's administrator named `wheelstestdb` pointing to the `wheelstestdb` database
3. **Important:** Make sure to give it CLOB and BLOB support
4. Open your browser to the Wheels Welcome Page
5. In the navigation menu, click the `Tests > core Tests`

### Docker Testing

 1. Create a database on a supported database server named `wheelstestdb`. At this time the supported
    database servers are H2, Microsoft SQL Server, PostgreSQL, MySQL, Oracle and SQLite.
 2. Create a datasource in your CFML engine's administrator named `wheelstestdb` pointing to the
    `wheelstestdb` database and make sure to give it CLOB and BLOB support.
 3. Open your browser to the Wheels Welcome Page.
 4. In the gray debug area at the bottom of the page, click the `Run Tests` link next to the version number
    on the `Framework` line.
    
For multi-engine testing, use our [Docker setup](https://wheels.dev/3.0.0/guides/working-with-wheels/testing-your-application#running-tests-with-docker)

### Reporting Issues

Please report any errors you encounter on our [issue tracker][4]. When reporting, please include:

- Database engine and version
- CFML engine and version  
- HTTP server and version
- Steps to reproduce the issue

## Getting Help

- **Documentation:** [wheels.dev](https://wheels.dev/docs)
- **Community:** [GitHub Discussions](https://github.com/wheels-dev/wheels/discussions)
- **Issues:** [GitHub Issues][4]
- **Guides:** [Framework Guides](https://wheels.dev/guides)

## Supported CFML Engines

Wheels supports the following CFML engines:

- **Adobe ColdFusion**: 2018, 2021, 2023, 2025
- **Lucee**: 5.x, 6.x, 7.x
- **BoxLang**: 1.x

## License

[Wheels][1] is released under the Apache License Version 2.0.

## Our Contributors

<a href="https://github.com/wheels-dev/wheels/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=wheels-dev/wheels" />
</a>

Made with [contrib.rocks](https://contrib.rocks).

---

**Wheels 3.0** - Faster, more organized, and just plain fun to use!

[1]: https://wheels.dev/
[2]: https://wheels.dev/3.0.0/guides/introduction/readme/beginner-tutorial-hello-world
[3]: ./CONTRIBUTING.md
[4]: https://github.com/wheels-dev/wheels/issues
