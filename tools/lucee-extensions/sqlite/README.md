# Wheels SQLite Lucee Extension

A Lucee CFML extension (`.lex`) that ships the SQLite JDBC driver as an OSGi bundle, so Lucee 7 can resolve `org.sqlite.JDBC` datasources without manual JAR drops.

## Why this exists

`wheels new` writes a SQLite-by-default datasource into `config/app.cfm`. Lucee 7 loads JDBC drivers via OSGi bundles in `lucee-server/bundles/`, but the stock Lucee Express bundles directory ships drivers for MySQL, MSSQL, PostgreSQL, and HSQLDB — **not** SQLite. Result: every fresh `wheels new` app fails on the first `wheels migrate latest` with:

```
The OSGi Bundle with name [org.xerial.sqlite-jdbc] is not available locally
[ (~/.wheels/servers/<name>/lucee-server/bundles)] or from the update provider
[ (https://update.lucee.org)].
```

This is finding **F8** in the fresh-VM onboarding journals. Until now the workaround was to hand-copy the JAR from `~/.wheels/express/<version>/lib/ext/sqlite-jdbc-*.jar` into `lucee-server/bundles/` — which works once but evaporates on every `wheels server start --force`.

## What's in the box

```
src/
  build.properties        Extension metadata (uuid, label, connection string, ...)
  SQLite.cfc              Lucee admin UI driver descriptor
  sqlite-jdbc-3.49.1.0.jar  Vendored xerial sqlite-jdbc JAR (Maven Central)
build.sh                  Build the .lex artifact
install.sh                Install into a Lucee server's bundles/ directory
dist/                     Build output: <bundle-symbolic-name>-<version>.lex
```

## Build

```bash
bash tools/lucee-extensions/sqlite/build.sh
```

Produces `dist/org.xerial.sqlite-jdbc-3.49.1.0.lex` (~14 MB). The build script:

1. Reads `src/build.properties` for extension UUID + JDBC metadata.
2. Reads OSGi headers from the bundled JAR (`Bundle-SymbolicName`, `Bundle-Version`).
3. Reads the JDBC driver class from `META-INF/services/java.sql.Driver` inside the JAR.
4. **Patches the JAR's MANIFEST.MF** (see "OSGi compatibility patch" below).
5. Stages `META-INF/MANIFEST.MF`, `jars/<jar>.jar`, `context/admin/dbdriver/SQLite.cfc`.
6. Zips → `.lex`.

## OSGi compatibility patch

The upstream `org.xerial:sqlite-jdbc` JAR is a valid OSGi bundle, but its manifest declares two things that block loading on Lucee 7 + JDK 11+:

```
Bundle-SymbolicName: org.xerial.sqlite-jdbc;singleton:=true
Require-Capability:  osgi.ee;filter:="(&(osgi.ee=JavaSE)(version=1.8))"
```

The strict `version=1.8` (exact match in some OSGi resolvers) prevents Felix on Java 21 from satisfying the requirement, even though Java 21 ⊇ Java 1.8. PostgreSQL's bundle uses `(version>=1.8)` and works; the sqlite-jdbc maintainers haven't relaxed this.

`build.sh` rewrites both headers in-place:

```
Bundle-SymbolicName: org.xerial.sqlite-jdbc
Require-Capability:  osgi.ee;filter:="(&(|(osgi.ee=J2SE)(osgi.ee=JavaSE))(version>=1.8))"
```

(The patch is applied to a copy — the original `src/sqlite-jdbc-*.jar` is untouched.)

## Install

### Option A (recommended today): direct bundle install

```bash
bash tools/lucee-extensions/sqlite/install.sh ~/.wheels/servers/<name>
```

Drops the patched bundle straight into `<server>/lucee-server/bundles/`. Restart the server and SQLite datasources resolve.

### Option B: drop the .lex into Lucee's deploy folder

```bash
cp dist/org.xerial.sqlite-jdbc-3.49.1.0.lex ~/.wheels/servers/<name>/lucee-server/deploy/
```

This is the canonical Lucee install path (Lucee polls `deploy/` every 60s). On Lucee 7.0.0.395 we observed silent rejection — the file moves to `deploy/failed-to-deploy/` without an error log. The bundle path (Option A) is deterministic; the deploy path is the future-proof distribution mechanism once we (or upstream) figure out why Lucee 7 quarantines the file.

### Option C: install via Lucee admin UI

Log into `http://localhost:<port>/lucee/admin.cfm`, go to **Server → Extensions → Applications**, upload `dist/org.xerial.sqlite-jdbc-3.49.1.0.lex`. Same end state as Option A.

## Verify

```bash
# Server must already be running with a SQLite datasource configured.
curl -s http://localhost:9988/dbtest.cfm

# Before install: FAIL ... org.xerial.sqlite-jdbc is not available locally
# After install:  OK datasource=sqliteapp result=1
```

## Upstream upgrade plan

1. Ship this artifact alongside Wheels releases (GitHub release asset on `wheels-dev/wheels`).
2. Have `wheels new` (or first `wheels start`) auto-run `install.sh` against the freshly-created server so SQLite-by-default works zero-config.
3. After 1–2 release cycles, file an upstream PR as `lucee/extension-jdbc-sqlite` so Lucee's update server distributes it. Once accepted, Wheels can drop the local bundle approach.
4. Separately, file an issue with `xerial/sqlite-jdbc` to relax their `Require-Capability: osgi.ee;version=1.8` to `version>=1.8` — eliminates the manifest-patch step and benefits everyone running OSGi.

## Trivia

- **Extension UUID**: `EACF838C-62B6-469C-A8DA-F802A9596C57` (regenerate if forking).
- **Bundle Symbolic Name**: `org.xerial.sqlite-jdbc` (matches `bundleName` in [cli/src/models/EnvironmentService.cfc:1009](../../../cli/src/models/EnvironmentService.cfc:1009) — already correct in Wheels CLI).
- **JDBC class**: `org.sqlite.JDBC` (declared by xerial's `META-INF/services/java.sql.Driver`).
- **Layout mirrors**: [lucee/extension-jdbc-postgresql](https://github.com/lucee/extension-jdbc-postgresql), [lucee/extension-jdbc-duckdb](https://github.com/lucee/extension-jdbc-duckdb).
