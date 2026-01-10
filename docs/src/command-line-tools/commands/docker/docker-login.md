# wheels docker login

Login to a container registry.

## Synopsis

```bash
wheels docker login [options]
```

## Description

The `wheels docker login` command authenticates your Docker client with a container registry. It supports various registry types including Docker Hub, AWS ECR, Google GCR, Azure ACR, and GitHub GHCR. 

**Interactive Features**:
- **Username Recovery**: If you omit the `--username` argument, the command will proactively prompt you for it.
- **Secure Input**: Passwords and tokens are masked during entry.
- **Ordered Prompts**: For private and ACR registries, the command first asks for the Registry URL to ensure proper host resolution.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--registry` | Registry type: `dockerhub`, `ecr`, `gcr`, `acr`, `ghcr`, `private` | `dockerhub` |
| `--username` | Registry username (required for dockerhub, ghcr, private) | `""` |
| `--password` | Registry password or token (optional, will prompt if empty) | `""` |
| `--image` | Image name (optional, but required for ECR/ACR to determine region/registry) | `""` |
| `--local` | Execute login locally | `true` |

## Detailed Examples

### Docker Hub
The default registry. Requires your Docker Hub username and password/token.
```bash
# Prompts for password
wheels docker login --registry=dockerhub --username=myuser

# With password provided (use with caution in scripts)
wheels docker login --registry=dockerhub --username=myuser --password=mytoken
```

### AWS Elastic Container Registry (ECR)
Authenticates with AWS ECR. Requires the full image repository URI to determine the region and registry ID.
```bash
wheels docker login --registry=ecr --image=123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
```

### GitHub Container Registry (GHCR)
Authenticates with GitHub's container registry. Use your GitHub username and a Personal Access Token (PAT) with `read:packages` scope.
```bash
wheels docker login --registry=ghcr --username=mygithubuser
```

### Google Container Registry (GCR)
Authenticates with GCR. Requires the image path to determine the registry host (e.g., `gcr.io`, `us.gcr.io`).
```bash
wheels docker login --registry=gcr --image=gcr.io/my-project/my-app
```

### Azure Container Registry (ACR)
Authenticates with Azure ACR. Requires the login server address.
```bash
wheels docker login --registry=acr --image=myregistry.azurecr.io/my-app
```

### Private Registry
For self-hosted or other private registries. If you don't provide an image or URL via arguments, you will be prompted in this order: **Registry URL** -> **Username** -> **Password**.
```bash
wheels docker login --registry=private
```

## Configuration Storage

Successful logins save the registry configuration to `docker-config.json` in your project root. This configuration is used by `wheels docker push` to automatically authenticate during push operations.

**Example `docker-config.json`:**
```json
{
  "registry": "ecr",
  "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest",
  "username": "AWS",
  "namespace": "myorg"
}
```

**Security Note**: Passwords are **not** stored in `docker-config.json`. Only registry type, username, and image references are saved. You may be prompted for a password again during push operations if your session expires.
