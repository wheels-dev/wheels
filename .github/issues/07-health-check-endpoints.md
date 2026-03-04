# [Feature] Health Check Endpoints

**Priority:** #7 — Essential for production and container orchestration
**Labels:** `enhancement`, `feature-request`, `devops`, `priority-medium`

## Summary

Add built-in health check endpoints (`/health`, `/health/ready`, `/health/live`) that report application health status — including database connectivity, disk space, memory usage, and custom checks. Essential for Docker, Kubernetes, load balancers, and monitoring systems.

## Justification

### Required for modern deployment

Modern deployment targets require health check endpoints:

- **Kubernetes** — `livenessProbe` and `readinessProbe` determine pod lifecycle
- **Docker** — `HEALTHCHECK` instruction determines container health
- **AWS ELB/ALB** — Health checks determine instance routing
- **Cloud Run / ECS / Fargate** — Container health monitoring
- **Uptime monitors** — Pingdom, UptimeRobot, DataDog

Without health checks, orchestrators can't distinguish a crashed application from a healthy one, leading to routing traffic to broken instances or failing to restart them.

### Current state in Wheels

Wheels has no health check infrastructure. Developers must:
1. Create a custom controller action
2. Manually check database connectivity
3. Return appropriate HTTP status codes
4. Repeat this for every application

### Competitors provide this out of the box

| Framework | Health Checks | Details |
|-----------|--------------|---------|
| **NestJS** | `@nestjs/terminus` | Configurable health indicators with `/health` endpoint |
| **Laravel** | Community packages (widely used) | `spatie/laravel-health` — monitors DB, Redis, disk, cache |
| **Rails** | `Rails.application.routes.draw { get "up" }` | Built-in since Rails 7.1 |
| **Django** | `django-health-check` | Pluggable backends — DB, cache, disk, migrations |
| **Spring Boot** | Actuator `/health` | Industry standard — liveness + readiness probes |
| **Wheels** | **Nothing** | Must build from scratch |

## Specification

### Default Endpoints

```
GET /health          → Full health check (all checks)
GET /health/live     → Liveness probe (is the app running?)
GET /health/ready    → Readiness probe (can the app serve traffic?)
GET /health/db       → Database connectivity only
GET /health/startup  → Startup probe (has the app finished initializing?)
```

### Response Format

```json
// GET /health → 200 OK (all healthy)
{
    "status": "healthy",
    "timestamp": "2026-03-04T14:30:00Z",
    "version": "1.2.3",
    "environment": "production",
    "uptime": "3d 14h 22m",
    "checks": {
        "database": {
            "status": "healthy",
            "responseTime": "3ms",
            "details": {
                "adapter": "MySQL",
                "version": "8.0.35",
                "connectionPool": {
                    "active": 5,
                    "idle": 15,
                    "max": 20
                }
            }
        },
        "diskSpace": {
            "status": "healthy",
            "details": {
                "total": "50GB",
                "free": "32GB",
                "threshold": "10%",
                "usagePercent": "36%"
            }
        },
        "memory": {
            "status": "healthy",
            "details": {
                "heapUsed": "256MB",
                "heapMax": "1024MB",
                "usagePercent": "25%"
            }
        },
        "migrations": {
            "status": "healthy",
            "details": {
                "pending": 0,
                "latest": "20260301000001"
            }
        }
    }
}

// GET /health → 503 Service Unavailable (degraded)
{
    "status": "unhealthy",
    "timestamp": "2026-03-04T14:30:00Z",
    "checks": {
        "database": {
            "status": "unhealthy",
            "error": "Connection refused",
            "responseTime": "5000ms"
        },
        "diskSpace": {
            "status": "warning",
            "details": {
                "free": "1.2GB",
                "threshold": "10%",
                "usagePercent": "97%"
            }
        }
    }
}
```

### Configuration

```cfm
// config/health.cfm
set(healthCheckEnabled=true);
set(healthCheckPath="/health");

// Choose which checks to run
set(healthChecks={
    database: { enabled: true, timeout: 5000 },
    diskSpace: { enabled: true, threshold: "10%" },
    memory: { enabled: true, threshold: "90%" },
    migrations: { enabled: true },
    custom: []
});

// Security — restrict detailed output
set(healthCheckDetailedOutput="authenticated");  // "always", "never", "authenticated"
set(healthCheckAuthToken=GetEnvironmentValue("HEALTH_CHECK_TOKEN", ""));
```

### Custom Health Checks

```cfm
// app/health/RedisCheck.cfc
component extends="wheels.HealthCheck" {

    property name="name" default="redis";

    struct function check() {
        try {
            var redis = getRedisConnection();
            var start = GetTickCount();
            redis.ping();
            var responseTime = GetTickCount() - start;

            return healthy(details={
                responseTime: "#responseTime#ms",
                version: redis.info().redis_version
            });
        } catch (any e) {
            return unhealthy(error=e.message);
        }
    }
}

// app/health/ExternalApiCheck.cfc
component extends="wheels.HealthCheck" {

    property name="name" default="paymentGateway";

    struct function check() {
        try {
            var response = httpCall(url="https://api.stripe.com/v1/health", timeout=3);
            if (response.statusCode == 200) {
                return healthy();
            }
            return degraded(error="Payment API returned #response.statusCode#");
        } catch (any e) {
            return unhealthy(error="Payment API unreachable: #e.message#");
        }
    }
}

// Register custom checks in config
set(healthChecks={
    database: { enabled: true },
    custom: [
        "app.health.RedisCheck",
        "app.health.ExternalApiCheck"
    ]
});
```

### Kubernetes Integration

```yaml
# kubernetes deployment.yaml
spec:
  containers:
    - name: wheels-app
      livenessProbe:
        httpGet:
          path: /health/live
          port: 8080
        initialDelaySeconds: 30
        periodSeconds: 10
      readinessProbe:
        httpGet:
          path: /health/ready
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 5
      startupProbe:
        httpGet:
          path: /health/startup
          port: 8080
        failureThreshold: 30
        periodSeconds: 10
```

### Docker Integration

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health/live || exit 1
```

### Built-in Checks

| Check | What It Monitors | Healthy Criteria |
|-------|-----------------|------------------|
| **Database** | Connection pool, query execution | Can execute `SELECT 1` within timeout |
| **Disk Space** | Available storage | Free space above configured threshold |
| **Memory** | JVM heap usage | Heap usage below configured threshold |
| **Migrations** | Pending migrations | No pending migrations |

### Health Status Levels

| Status | HTTP Code | Meaning |
|--------|-----------|---------|
| `healthy` | 200 | All checks passing |
| `degraded` | 200 | Non-critical check failing (app still serves traffic) |
| `unhealthy` | 503 | Critical check failing (app should not receive traffic) |

### Files Generated / Modified

| Component | File | Purpose |
|-----------|------|---------|
| **Controller** | `wheels/health/HealthController.cfc` | Health check endpoint handler |
| **Base check** | `wheels/HealthCheck.cfc` | Base class for custom checks |
| **DB check** | `wheels/health/DatabaseCheck.cfc` | Database connectivity check |
| **Disk check** | `wheels/health/DiskSpaceCheck.cfc` | Disk usage check |
| **Memory check** | `wheels/health/MemoryCheck.cfc` | JVM memory check |
| **Migration check** | `wheels/health/MigrationCheck.cfc` | Pending migrations check |
| **Config** | `config/health.cfm` | Health check configuration |
| **Routes** | Auto-registered `/health/*` routes | Health endpoints |
| **Directory** | `app/health/` | Custom health checks |

## Impact Assessment

- **Production readiness:** Makes Wheels apps container-orchestration ready out of the box
- **Monitoring:** Standard endpoint for uptime monitoring services
- **Operations:** Quick diagnosis of production issues
- **DevOps confidence:** Teams know the app is truly healthy, not just returning 200

## References

- NestJS Terminus: https://docs.nestjs.com/recipes/terminus
- Laravel Health: https://github.com/spatie/laravel-health
- Spring Boot Actuator: https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html
- Kubernetes Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
