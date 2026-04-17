---
title: >-
  Behind the Scenes: How a Single Commit Becomes a Running Application Across
  40+ Configurations
slug: >-
  behind-the-scenes-how-a-single-commit-becomes-a-running-application-across-40-configurations
publishedAt: '2026-03-03T14:00:00.000Z'
updatedAt: '2026-03-04T00:51:33.101Z'
author: Peter Amiri
tags:
  - ci-cd
  - docker
  - github-actions
  - deployment
  - devops
  - docker-swarm
categories:
  - Website
  - Tutorials
excerpt: >-
  When a developer opens a pull request against the Wheels framework, it kicks
  off one of the most comprehensive CI/CD pipelines you'll find in any
  open-source project. Whether you're a first-time co...
coverImage: null
legacyId: '1151026256903536642'
---

When a developer opens a pull request against the Wheels framework, it kicks off one of the most comprehensive CI/CD pipelines you'll find in any open-source project. Whether you're a first-time contributor fixing a typo or a core maintainer shipping a new feature, the moment your PR hits the `develop` branch, the same gauntlet runs: dozens of engine and database combinations are tested, four distinct packages are built and published to a package registry, documentation is synced, container images are built, and a production Docker Swarm deployment rolls out -- all without a single manual intervention.

You don't need commit access to trigger this. You just need a pull request.

This is the story of how that sausage gets made.

## The Scale of the Problem

Wheels is a Rails-inspired MVC framework for CFML (ColdFusion Markup Language). Unlike most frameworks that target a single runtime, Wheels supports **eight different server engines** -- Lucee 5, 6, and 7, Adobe ColdFusion 2018, 2021, 2023, and 2025, and the new BoxLang runtime. It also supports **six different databases**: MySQL, PostgreSQL, SQL Server, H2, Oracle, and SQLite.

That matrix creates over 40 unique test configurations. Every one of them runs on every commit to the development branch. There are no shortcuts.

## Stage 1: The Test Matrix

When a commit lands on the `develop` branch, GitHub Actions fires the `snapshot.yml` workflow, which immediately calls a reusable `tests.yml` workflow. This is where things get interesting.

The test matrix spins up parallel jobs for each valid engine-and-database combination. Some pairs are excluded -- Adobe 2018 doesn't support SQLite, for example -- but the remaining combinations all run simultaneously. Each job follows the same sequence:

1. **Start the CFML engine container** on a dedicated port (Lucee 5 gets port 60005, Adobe 2023 gets 62023, and so on)
2. **Start the database container** (except for embedded databases like H2 and SQLite)
3. **Wait for both services** with retry logic to handle cold-start delays
4. **Patch compatibility files** where needed -- Oracle on Adobe engines requires a serialization filter update
5. **Install engine-specific packages** via the CFML package manager
6. **Execute the full test suite** via HTTP, passing the database type as a parameter
7. **Capture and upload results** as JSON artifacts with detailed workflow logs

Each engine gets its own purpose-built Docker image. The Lucee images include H2, Oracle JDBC extensions, and SQLite drivers. The Adobe images handle their own package management quirks. BoxLang runs on its own runtime entirely. The test infrastructure treats each engine as a first-class citizen, not an afterthought.

If even one of those 40+ jobs fails, the pipeline stops. Nothing gets published until the entire matrix is green.

## Stage 2: Four Packages, One Pipeline

Once the test matrix passes, the release pipeline takes over. Wheels isn't distributed as a single monolithic package -- it's split into four distinct artifacts, each with its own purpose:

- **Wheels Core**: The framework engine itself -- routing, ORM, controllers, views, and the internal machinery
- **Wheels Base Template**: The application scaffold that developers start new projects from
- **Wheels CLI**: Command-line tooling for scaffolding, migrations, and development workflows
- **Wheels Starter App**: A ready-to-run example application for learning

Each package has its own preparation script that assembles the right files, replaces version placeholders (like `@build.version@` and `@build.number@`), and structures the output for publishing. The version string itself carries meaning: `3.0.0` is a stable release, `3.0.0-rc.1` is a release candidate, and `3.0.0-SNAPSHOT` marks bleeding-edge development builds. A build number suffix (e.g., `+1234`) tracks the exact CI run.

After preparation, each package goes through validation -- checking that `box.json` manifests parse correctly, file counts match expectations, and version strings are consistent. Only then does the pipeline authenticate with ForgeBox (the CFML package registry) and publish all four packages.

The pipeline also builds ZIP archives with MD5 and SHA512 checksums, uploading them as GitHub Actions artifacts and attaching them to GitHub Releases with auto-generated release notes pulled from the changelog.

## Stage 3: Documentation Sync

In parallel with package publishing, the pipeline syncs framework documentation to the community website. A dedicated `docs-sync.yml` workflow checks out both the framework repository and the website repository, then uses `rsync` to synchronize:

- **Guide content** (Markdown files) flows from the framework's `docs/src/` directory into the website's versioned guides path
- **Image assets** are copied additively so that old screenshots aren't accidentally removed
- **API documentation** (JSON) is synced to the website's public directory for the interactive API browser

If any files changed during the sync, the workflow commits and pushes to the website repository automatically. This triggers the next stage.

## Stage 4: Container Build

When the website repository receives a push to `main` -- whether from a documentation sync or a direct code change -- the `swarm-deploy.yml` workflow fires. This is where the application becomes a container.

The build job runs on a standard GitHub-hosted Ubuntu runner. It generates an environment file from GitHub Secrets containing database credentials, SMTP configuration for transactional email, a Sentry DSN for error tracking, and various application secrets. It installs CommandBox (the CFML build tool), pulls all dependencies, and builds a Docker image.

The base image is `ortussolutions/commandbox:lucee6`, which provides a Lucee 6 runtime managed by CommandBox. The Dockerfile layers on a PostgreSQL JDBC driver, copies the application code, and includes a production-tuned `server.json` that configures JVM heap sizes, connection pools, and the server warmup sequence.

The resulting image gets tagged twice -- once with `:latest` and once with the Git commit SHA for traceability -- then pushed to GitHub Container Registry (GHCR).

## Stage 5: Swarm Deployment

The final stage runs on a self-hosted GitHub Actions runner that lives inside the Docker Swarm cluster itself. This runner authenticates with GHCR, pulls the freshly-built image, and executes `docker stack deploy`.

The Swarm configuration deploys **three replicas** of the application behind a Traefik reverse proxy. Rolling updates proceed one replica at a time with a 15-second delay between each, using a start-first strategy -- meaning the new container must be healthy before the old one is removed. This ensures zero-downtime deployments.

Each replica is allocated up to 2 CPUs and 4 GB of memory, with reserved minimums of 0.25 CPUs and 1 GB to guarantee baseline performance. The JVM is tuned with a 2 GB minimum and 3 GB maximum heap, sized to fit comfortably within the container's memory limit.

Sessions are stored in the database with clustering enabled, so any replica can serve any request -- no sticky sessions required. Traefik handles load balancing and TLS termination, while a Cloudflare tunnel provides the public-facing edge with DDoS protection and global CDN caching.

Shared storage volumes backed by CephFS allow all three replicas to access the same uploaded images, file attachments, generated sitemaps, and documentation content. This is critical -- without shared storage, a file uploaded through one replica would be invisible to the others.

## The Full Picture

Here's what happens in the roughly 15-20 minutes between a developer pushing to `develop` and the changes being live:

```
git push origin develop
    |
    v
GitHub Actions: snapshot.yml
    |
    v
40+ parallel test jobs (8 engines x 6 databases)
    |
    v (all green)
    +---> Package 4 artifacts (core, base, cli, starter-app)
    +---> Validate and publish to ForgeBox
    +---> Upload to GitHub Releases with checksums
    +---> Sync documentation to wheels.dev repo
              |
              v
         wheels.dev repo receives push
              |
              v
         Build Docker image on ubuntu-latest
              |
              v
         Push to GitHub Container Registry
              |
              v
         Self-hosted runner deploys to Docker Swarm
              |
              v
         3 replicas with rolling updates
              |
              v
         Live at wheels.dev
```

## Why This Matters

For a framework that promises to run anywhere -- on any supported engine, against any supported database -- the CI/CD pipeline is the proof. It's not enough to claim compatibility; every commit verifies it across every combination.

The four-package distribution model means developers install only what they need. The automated documentation pipeline means the website is never stale. The container-based deployment with rolling updates means releases happen without anyone noticing downtime.

Is this level of orchestration overkill for an open-source CFML framework? Maybe. But for the developers who depend on Wheels in production, knowing that every commit survives a gauntlet of 40+ test configurations before it ever reaches them -- that's not overkill. That's trust.
