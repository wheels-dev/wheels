# LuCLI Chocolatey Package

Chocolatey package for distributing [LuCLI](https://github.com/cybersonic/LuCLI) on Windows.

## What it installs

- `lucli` — the Lucee CLI binary
- `wheels` — convenience wrapper that runs `lucli wheels`

Both commands are added to PATH via Chocolatey shimming.

## For users

```powershell
choco install lucli
lucli modules install wheels   # Install the Wheels framework module
wheels new myapp               # Create a new Wheels application
```

Upgrade:
```powershell
choco upgrade lucli
```

Uninstall:
```powershell
choco uninstall lucli
```

## Building locally

Requires [Chocolatey CLI](https://chocolatey.org/install) installed.

```powershell
# Build with the version already in the nuspec
.\build-choco.ps1

# Build for a specific LuCLI version
.\build-choco.ps1 -Version 0.3.0
```

Output: `lucli.<version>.nupkg`

## Publishing

The GitHub Actions workflow `publish-chocolatey.yml` handles automated publishing:

1. Go to Actions > "Publish Chocolatey Package"
2. Enter the LuCLI version to package
3. The workflow downloads the release, computes checksums, builds, and pushes to Chocolatey

Requires the `CHOCOLATEY_API_KEY` repository secret.

## File structure

```
chocolatey/
├── lucli.nuspec                  # Package metadata (NuGet format)
├── build-choco.ps1               # Local build script
├── README.md                     # This file
└── tools/
    ├── chocolateyinstall.ps1     # Install logic
    ├── chocolateyuninstall.ps1   # Uninstall logic
    └── VERIFICATION.txt          # Source verification info
```
