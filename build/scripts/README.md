# Wheels Build Scripts

This directory contains the build scripts that replace the previous Ant-based build system. These scripts are used by the GitHub Actions workflow to build the three Wheels variants: Core, Base Template, and CLI.

## Scripts

### Individual Build Scripts

- **`build-core.sh`** - Builds the Wheels Core framework package
- **`build-base.sh`** - Builds the Wheels Base Template (application starter template)
- **`build-cli.sh`** - Builds the Wheels CLI commands module

Each script takes 4 parameters:
1. `VERSION` - The version string (e.g., "5.3.0+123")
2. `BRANCH` - The branch name (main or develop)
3. `BUILD_NUMBER` - The build number
4. `IS_PRERELEASE` - Whether this is a prerelease (true/false)

### Convenience Scripts

- **`build-all.sh`** - Builds all three variants sequentially (useful for local testing)

## Usage

### GitHub Actions

The scripts are automatically used by the GitHub Actions workflow in `.github/workflows/release.yml`.

### Local Testing

To test the build process locally:

```bash
# Make scripts executable
chmod +x build/scripts/*.sh

# Build all variants with defaults
./build/scripts/build-all.sh

# Build all variants with specific version
./build/scripts/build-all.sh "5.3.0+100" "develop" "100" "false"

# Build individual variant
./build/scripts/build-core.sh "5.3.0+100" "main" "100" "false"
```

## Build Process

Each build script performs the following steps:

1. **Setup** - Creates build directories and cleans up any previous builds
2. **Copy Files** - Copies the appropriate source files for each variant
3. **Template Processing** - Copies template files from `build/{variant}/` directory
4. **Version Replacement** - Replaces placeholders:
   - `@build.version@` → actual version number
   - `@build.number@` → build number (or `-snapshot` for develop branch)
5. **Packaging** - Creates ZIP files with checksums (MD5 and SHA512)
6. **Bleeding Edge** - Creates `-be.zip` versions for latest builds

## Output Structure

All builds create artifacts in the following structure:

```
artifacts/
  wheels/
    {version}/
      wheels-core-{version}.zip
      wheels-core-{version}.md5
      wheels-core-{version}.sha512
      wheels-base-template-{version}.zip
      wheels-base-template-{version}.md5
      wheels-base-template-{version}.sha512
      wheels-cli-{version}.zip
      wheels-cli-{version}.md5
      wheels-cli-{version}.sha512
    wheels-core-be.zip
    wheels-base-template-be.zip
    wheels-cli-be.zip
```

## Version Handling

The scripts handle version numbers differently based on the build type:

- **Regular Release** (main branch): Uses version as-is with build number
- **Snapshot** (develop branch): Replaces `+@build.number@` with `-snapshot`
- **PreRelease**: Uses version with build number as-is

## Migrating from Ant

This build system replaces the previous `build/build.xml` Ant script. The key differences:

- No Java/Ant dependency required
- Simpler shell scripts that are easier to maintain
- Better integration with GitHub Actions
- Parallel build capability (see `release-parallel.yml`)

The output artifacts maintain the same structure for compatibility with existing workflows and ForgeBox publishing.