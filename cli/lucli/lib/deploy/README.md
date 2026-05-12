# Deploy JARs

Bundled third-party JARs used by `wheels deploy`. Loaded via URLClassLoader
isolation (`cli/lucli/services/deploy/lib/JarLoader.cfc`) to avoid version
collisions with Lucee's bundled crypto and YAML parsers.

| JAR | Version | License | Purpose |
|-----|---------|---------|---------|
| jmustache | 1.16 | BSD-2 | Logic-free template rendering for deploy artifacts |
| snakeyaml | 2.3 | Apache-2.0 | YAML parsing of `deploy.yml` |
| sshj | 0.39.0 | Apache-2.0 | SSH client + SFTP |
| bcprov-jdk18on | 1.78 | MIT | Crypto transitive of sshj |
| bcpkix-jdk18on | 1.78 | MIT | PKI transitive of sshj |
| bcutil-jdk18on | 1.78 | MIT | Utility transitive of sshj |
| eddsa | 0.3.0 | CC0 | Ed25519 keys |
| jzlib | 1.1.3 | BSD-3 | Compression |
| slf4j-api | 2.0.13 | MIT | Logging facade |
| slf4j-nop | 2.0.13 | MIT | Logging no-op binding |

Regenerate `manifest.json` after any JAR change.
