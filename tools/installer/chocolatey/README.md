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

Chocolatey is a retired channel (#2761): there is no publishing workflow. The
`publish-chocolatey.yml` workflow that used to push this package was removed.
Windows users install through Scoop.

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
