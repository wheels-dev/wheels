# wheels docker push

Push Docker images to container registries.

## Synopsis

```bash
wheels docker push [options]
```

## Description

The `wheels docker push` command uploads your Docker images to a container registry (like Docker Hub, ECR, etc.). It can push images from your local machine or trigger remote servers to push their built images. 

**Smart Tagging & Config**:
- **Source of Truth**: Automatically reads settings from `config/deploy.yml` if available.
- **Smart Tagging**: Intelligently handles custom image names and version suffixes.
- **Interactive Registry Detection**: Prompts for Registry URLs if they cannot be found in configuration for private/ACR types.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--local` | Push image from local machine | `false` |
| `--remote` | Push image from remote server(s) | `false` |
| `--servers` | Comma-separated list of server numbers to push from (e.g., "1,3,5") - for remote only | `""` |
| `--registry` | Registry type: `dockerhub`, `ecr`, `gcr`, `acr`, `ghcr`, `private` | `dockerhub` |
| `--image` | Full image name with registry path (optional - auto-detected if not specified) | `""` |
| `--username` | Registry username | `""` |
| `--password` | Registry password or token (leave empty to prompt) | `""` |
| `--tag` | Tag/version to apply (e.g., v1.0.0, latest) | `latest` |
| `--build` | Build the image before pushing | `false` |
| `--namespace` | Registry namespace/username prefix | `""` |

## Detailed Examples

### Local Push Workflows

**Push to Docker Hub**
Pushes your image to Docker Hub under your username.
```bash
# Assumes you are logged in or will be prompted for password
wheels docker push --local --registry=dockerhub --username=myuser
```

**Push a Specific Version**
Tags the image as `v1.0.0` and pushes it.
```bash
wheels docker push --local --registry=dockerhub --username=myuser --tag=v1.0.0
```

**Build and Push**
Ensures you are pushing the absolute latest code by building first.
```bash
wheels docker push --local --registry=dockerhub --username=myuser --build
```

**Push to AWS ECR**
Pushes to a private ECR repository.
```bash
wheels docker push --local --registry=ecr --image=123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
```

### Remote Push Workflows

**Trigger Remote Push**
Instructs all remote servers to push their built images to the registry. This is useful if your remote servers build the images (e.g., during deployment) and you want to archive those exact artifacts.
```bash
wheels docker push --remote --registry=dockerhub --username=myuser
```

**Push from Specific Servers**
Only trigger the push on specific servers.
```bash
wheels docker push --remote --servers=1 --registry=dockerhub --username=myuser
```

## Configuration
 
 This command prioritizes settings in this order:
 1. Command-line arguments (`--image`, `--tag`, etc.)
 2. Centralized configuration in `config/deploy.yml`
 3. Saved session data in `docker-config.json` (created by `wheels docker login`)
 
## Workflow Explained

1.  **Tagging**: The command intelligently determines the target image name:
    *   **Custom Name**: If your image name contains a colon (e.g., `myregistry:port/path`), it is used directly as the target.
    *   **Suffix Tagging**: If no colon is present, it appends the project name and tag to the registry/namespace (e.g., `registry/namespace/project:tag`).
2.  **Authentication**:
    *   Checks for interactive password if not provided.
    *   Assumes existing session if previously logged in via `wheels docker login`.
    *   On remote servers, it uses the credentials provided in the command to authenticate before pushing.
3.  **Pushing**: It executes the `docker push` command for the resolved image.
