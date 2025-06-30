# Wheels Snapshot Publishing Process Flow

## Overview
When a commit is made to the `develop` branch, an automated process runs tests and publishes a snapshot version to ForgeBox.

## Flow Diagram

```mermaid
flowchart TD
    A[Commit pushed to develop branch] --> B[snapshot.yml workflow triggered]
    B --> C[Call reusable tests.yml workflow]

    C --> D{Run Test Matrix}
    D --> E1[lucee5 + MySQL/Postgres/SQLServer/H2/Oracle]
    D --> E2[lucee6 + MySQL/Postgres/SQLServer/H2/Oracle]
    D --> E3[adobe2018 + MySQL/Postgres/SQLServer]
    D --> E4[adobe2021 + MySQL/Postgres/SQLServer]
    D --> E5[adobe2023 + MySQL/Postgres/SQLServer]
    D --> E6[lucee7 + All DBs - Experimental]
    D --> E7[adobe2025 + MySQL/Postgres/SQLServer - Experimental]

    E1 --> F[Upload test artifacts]
    E2 --> F
    E3 --> F
    E4 --> F
    E5 --> F
    E6 --> F
    E7 --> F

    F --> G{All tests pass?}
    G -->|No| H[Workflow fails]
    G -->|Yes| I[Call release.yml workflow]

    I --> J[Calculate version number]
    J --> K[Version = box.json version + GitHub run number]
    K --> L[e.g., 3.0.0-SNAPSHOT+123]

    L --> M[Run Ant build]
    M --> N[Build 3 variants]

    N --> O1[wheels-core variant]
    N --> O2[wheels-base-template variant]
    N --> O3[wheels-cli variant]

    O1 --> P1[Create artifacts + checksums]
    O2 --> P2[Create artifacts + checksums]
    O3 --> P3[Create artifacts + checksums]

    P1 --> Q[Upload to GitHub Actions artifacts]
    P2 --> Q
    P3 --> Q

    Q --> R[Publish to ForgeBox]
    R --> S1[Publish wheels-core package]
    R --> S2[Publish wheels-base-template package]
    R --> S3[Publish wheels-cli package]

    S1 --> T[Available on ForgeBox as snapshot]
    S2 --> T
    S3 --> T
```

## Process Details

### 1. Trigger (snapshot.yml)
- **Trigger**: Push to `develop` branch
- **Purpose**: Run tests and create snapshot releases

### 2. Test Phase (tests.yml)
- **Test Matrix**:
  - 5 CF engines (Lucee 5/6/7, Adobe 2018/2021/2023/2025)
  - 5 databases (MySQL, PostgreSQL, SQL Server, H2, Oracle)
  - Some combinations excluded (e.g., Adobe engines don't test with H2/Oracle)
  - Lucee 7 and Adobe 2025 marked as experimental (non-blocking)

### 3. Build Phase (release.yml)
- **Version Calculation**:
  - Base version from box.json (3.0.0-SNAPSHOT)
  - Appends GitHub run number (e.g., +123)
- **Build Process**: Uses Ant (build.xml) to create 3 variants:
  1. **wheels-core**: Core framework files
  2. **wheels-base-template**: Base application template
  3. **wheels-cli**: CommandBox CLI module

### 4. Publishing Phase
- **Artifacts**: Each variant gets:
  - ZIP file
  - MD5 checksum
  - SHA512 checksum
  - Bleeding edge (be) version
- **ForgeBox Publishing**: Uses pixl8/github-action-box-publish
  - Authenticates with wheels-dev user
  - Force publishes to overwrite existing snapshots
  - Each variant published separately

### 5. Key Files
- `.github/workflows/snapshot.yml`: Main workflow for develop branch
- `.github/workflows/tests.yml`: Reusable test workflow
- `.github/workflows/release.yml`: Reusable release/publish workflow
- `build/build.xml`: Ant build configuration
- `box.json`: Package configuration for each variant

### 6. Environment Variables
- `WHEELS_VERSION`: Calculated version with build number
- `BRANCH`: Set to "develop" for snapshots
- `WHEELS_PRERELEASE`: Set to false for snapshots
- `FORGEBOX_API_TOKEN` & `FORGEBOX_PASS`: Authentication secrets

This process ensures that every commit to develop is thoroughly tested across multiple CF engines and databases before being published as a snapshot for community testing.
