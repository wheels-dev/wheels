# Wheels Framework Rebranding Summary

This document summarizes the rebranding changes made from CFWheels to Wheels.

## Rebranding Changes

### 1. Framework Name
- **Old**: CFWheels (ColdFusion on Wheels)
- **New**: Wheels

### 2. Domain
- **Old**: cfwheels.org
- **New**: wheels.dev

### 3. GitHub Repository
- **Old**: cfwheels/cfwheels
- **New**: wheels-dev/wheels

### 4. Package Names
- **Old**: cfwheels (ForgeBox)
- **New**: wheels (ForgeBox)
- **Old**: cfwheels-cli
- **New**: wheels-cli

## Files Updated

### Core Documentation
- `/README.md` - Updated badges, links, and references
- `/ARCHITECTURE.md` - Updated framework name
- `/CLAUDE.md` - Updated installation command
- `/AI-MIGRATIONS.md` - Updated framework reference

### Architecture Documentation
- `/docs/architecture/README.md`
- `/docs/architecture/framework-overview.md`
- `/docs/architecture/repository-architecture.md`
- `/docs/architecture/development-guide.md`
- `/docs/architecture/adr/001-monorepo-migration.md`

### Configuration Files
- `/box.json` - Updated repository URLs and metadata
- `/cli/box.json` - Updated all references and metadata
- `/config/routes.cfm` - Updated documentation URL
- `/config/environment.cfm` - Updated documentation URL

### Test Files
- `/tests/README.md` - Updated guide URL
- `/tests/BaseSpec.cfc` - Updated WireBox injection reference

### Docker Settings
- All Docker engine settings files updated with new documentation URL

### Guides Directory
- Multiple guide files updated with new branding
- Plugin references updated
- CLI documentation updated
- Docker container names updated

## What Was NOT Changed

### Historical References
- CHANGELOG.md - Preserved historical GitHub PR links for accuracy
- Historical test data - Left unchanged as it represents past states

### Internal Code
- Internal variable names and function names were not changed
- Database table names remain unchanged
- API endpoints remain unchanged for backward compatibility

## Next Steps

1. **Update ForgeBox Packages**: The actual packages on ForgeBox need to be updated or republished under the new names
2. **Domain Setup**: Ensure wheels.dev is properly configured with all subdomains (guides, api, docs)
3. **GitHub Organization**: Ensure wheels-dev organization is properly set up
4. **Community Communication**: Announce the rebrand to the community
5. **Redirect Setup**: Set up redirects from old URLs to new ones

## Backward Compatibility

To maintain backward compatibility during the transition:
- Consider keeping cfwheels package on ForgeBox that depends on the new wheels package
- Set up redirects from cfwheels.org to wheels.dev
- Maintain GitHub redirects from cfwheels/cfwheels to wheels-dev/wheels