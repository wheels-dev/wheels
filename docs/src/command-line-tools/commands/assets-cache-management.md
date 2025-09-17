# Asset Management Commands

The Wheels CLI provides commands for managing static assets in your application, including compilation, optimization, and cleanup of JavaScript, CSS, and image files.

## Available Commands

```bash
wheels assets precompile
wheels assets clean
wheels assets clobber
```

## Asset Commands

### wheels assets precompile

Prepares your assets for production deployment by minifying and optimizing them.

#### Usage

```bash
# Basic precompilation (defaults to production)
wheels assets precompile

# Force recompilation of all assets
wheels assets precompile --force

# Target specific environments (with aliases)
wheels assets precompile --environment=production    # Full minification
wheels assets precompile --environment=prod          # Alias for production
wheels assets precompile --environment=staging       # Light minification
wheels assets precompile --environment=stage         # Alias for staging
wheels assets precompile --environment=testing       # Light minification
wheels assets precompile --environment=test          # Alias for testing
wheels assets precompile --environment=maintenance   # Light minification
wheels assets precompile --environment=development   # No minification
wheels assets precompile --environment=dev           # Alias for development
```

#### Environment-Specific Processing

The command applies different levels of asset optimization based on the target environment:

- **Production** (`production`, `prod`): **Full minification** - Maximum compression, removes all comments and whitespace, optimizes code structure
- **Staging** (`staging`, `stage`): **Light minification** - Removes comments and excessive whitespace but preserves some formatting for debugging
- **Testing** (`testing`, `test`): **Light minification** - Same as staging, optimized for testing environments
- **Maintenance** (`maintenance`): **Light minification** - Minimal processing for maintenance mode deployments
- **Development** (`development`, `dev`): **No minification** - Preserves original formatting and comments for debugging

#### What it does

- **Minifies JavaScript files**: Removes comments, whitespace, and unnecessary characters (level depends on environment)
- **Minifies CSS files**: Removes comments, whitespace, and optimizes CSS rules (level depends on environment)
- **Generates cache-busted filenames**: Adds MD5 hashes to filenames (e.g., `application-a1b2c3d4.min.js`)
- **Creates manifest.json**: Maps original filenames to compiled versions
- **Processes images**: Copies images with cache-busted names
- **Output location**: Stores all compiled assets in `/public/assets/compiled/`


#### Generated Manifest Example

```json
{
  "application.js": "application-a1b2c3d4.min.js",
  "admin.js": "admin-b2c3d4e5.min.js",
  "styles.css": "styles-c3d4e5f6.min.css",
  "admin.css": "admin-d4e5f6g7.min.css",
  "logo.png": "logo-e5f6g7h8.png",
  "banner.jpg": "banner-f6g7h8i9.jpg"
}
```

### wheels assets clean

Removes old compiled assets while keeping recent versions for rollback capability.

#### Usage

```bash
# Clean old assets (keeps 3 most recent versions by default)
wheels assets clean

# Keep 5 versions of each asset
wheels assets clean --keep=5

# Preview what would be deleted without actually deleting
wheels assets clean --dryRun
```

#### What it does

- **Identifies old versions**: Finds all compiled assets with hash fingerprints
- **Keeps recent versions**: Retains the specified number of most recent versions (default: 3)
- **Removes old files**: Deletes older versions to free disk space
- **Updates manifest**: Ensures manifest.json remains current
- **Dry run option**: Preview deletions without making changes


### wheels assets clobber

Completely removes all compiled assets and the manifest file.

#### Usage

```bash
# Remove all compiled assets (with confirmation prompt)
wheels assets clobber

# Skip confirmation prompt
wheels assets clobber --force
```

#### What it does

- **Deletes compiled directory**: Removes `/public/assets/compiled/` and all contents
- **Removes manifest**: Deletes the manifest.json file
- **Confirmation prompt**: Asks for confirmation unless --force is used
- **Complete cleanup**: Useful for fresh starts or troubleshooting


## Best Practices

### Production Deployment Workflow

1. **Before deployment**:
```bash
# Compile assets for production
wheels assets precompile --environment=production

# Clean old versions to save space
wheels assets clean --keep=3
```

2. **After deployment verification**:
```bash
# If rollback needed, previous versions are still available
# If deployment successful, further cleanup can be done
wheels assets clean --keep=2
```

### Development Workflow

During development, you typically don't need compiled assets:

```bash
# Remove all compiled assets in development
wheels assets clobber --force

# Precompile only when testing production builds
wheels assets precompile --environment=development
```

### Continuous Integration

Example CI/CD pipeline step:

```yaml
# .github/workflows/deploy.yml
- name: Compile Assets
  run: |
    wheels assets precompile --environment=production
    wheels assets clean --keep=3
```

## File Structure

After running `wheels assets precompile`:

```
/public/
  /assets/
    /compiled/
      manifest.json
      application-a1b2c3d4.min.js
      styles-e5f6g7h8.min.css
      logo-i9j0k1l2.png
    /javascripts/
      application.js (original)
    /stylesheets/
      styles.css (original)
    /images/
      logo.png (original)
```

## Configuration

Configure asset handling in your Wheels application:

```cfscript
// config/settings.cfm

// Enable asset fingerprinting in production
set(useAssetFingerprinting = true);

// Set asset cache duration (in minutes)
set(assetsCacheMinutes = 1440); // 24 hours

// Define assets path
set(assetsPath = "/assets");
```

## Troubleshooting

### Assets not updating in production

```bash
# Force recompilation
wheels assets precompile --force

# Verify manifest exists and is current
cat public/assets/compiled/manifest.json
```

### Disk space issues

```bash
# Check space used by compiled assets
du -sh public/assets/compiled/

# Aggressive cleanup - keep only 1 version
wheels assets clean --keep=1

# Or remove everything and recompile
wheels assets clobber --force
wheels assets precompile
```

### Missing assets after deployment

```bash
# Ensure assets were compiled for the correct environment
wheels assets precompile --environment=production

# Check that manifest.json exists
ls -la public/assets/compiled/manifest.json
```

## Notes

- **Backup**: Always backup assets before running `clobber` in production
- **Version Control**: Don't commit compiled assets to version control
- **Deployment**: Run `precompile` as part of your deployment process
- **Performance**: Compiled assets significantly improve load times
- **Cache Busting**: Hash fingerprints ensure browsers load updated assets