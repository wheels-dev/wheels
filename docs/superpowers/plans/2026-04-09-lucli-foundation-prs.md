# LuCLI Foundation PRs — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land three PRs in LuCLI that unblock the Wheels CLI integration: `{project}` placeholder resolution, binary-name-driven profile/branding, and SQLite JDBC auto-install.

**Architecture:** Each PR is independent and can merge in any order. All changes are in the LuCLI Java codebase at `~/GitHub/bpamiri/LuCLI`. The project uses Maven (`pom.xml`), picocli for CLI, and Jackson for JSON processing. Tests use JUnit 5.

**Tech Stack:** Java 21, Maven, picocli, Jackson (databind), JUnit 5

**Repo:** `/Users/peter/GitHub/bpamiri/LuCLI`

---

### Task 1: `{project}` Placeholder Resolution in CFConfig

This is the highest-impact change. When LuCLI writes `lucee.json`'s `configuration` block to `.CFConfig.json`, it needs to replace `{project}` with the absolute project directory path. This unblocks SQLite datasource paths like `jdbc:sqlite:{project}/db/development.db`.

**Files:**
- Modify: `src/main/java/org/lucee/lucli/server/LuceeServerConfig.java`
- Test: `src/test/java/org/lucee/lucli/server/LuceeServerConfigTest.java`

- [ ] **Step 1: Write the failing test**

Add to `src/test/java/org/lucee/lucli/server/LuceeServerConfigTest.java`:

```java
@Test
void resolveConfigurationNode_replacesProjectPlaceholder() throws Exception {
    // Build a minimal ServerConfig with a datasource containing {project}
    ObjectMapper mapper = new ObjectMapper();
    String configJson = """
        {
            "datasources": {
                "mydb": {
                    "dsn": "jdbc:sqlite:{project}/db/development.db",
                    "class": "org.sqlite.JDBC"
                }
            },
            "mappings": {
                "/app": "{project}/app"
            }
        }
        """;
    JsonNode configNode = mapper.readTree(configJson);

    Path projectDir = Path.of("/Users/test/myproject");

    // Use reflection or make method package-private to test
    // resolveConfigurationNode is private — test via resolveEffectiveCfConfigForContext
    // or extract the placeholder logic into a testable static method
    JsonNode resolved = LuceeServerConfig.resolveProjectPlaceholders(configNode, projectDir);

    assertEquals(
        "jdbc:sqlite:/Users/test/myproject/db/development.db",
        resolved.get("datasources").get("mydb").get("dsn").asText()
    );
    assertEquals(
        "/Users/test/myproject/app",
        resolved.get("mappings").get("/app").asText()
    );
}

@Test
void resolveConfigurationNode_leavesStringsWithoutPlaceholder() throws Exception {
    ObjectMapper mapper = new ObjectMapper();
    String configJson = """
        {
            "datasources": {
                "mydb": {
                    "dsn": "jdbc:h2:mem:testdb",
                    "class": "org.h2.Driver"
                }
            }
        }
        """;
    JsonNode configNode = mapper.readTree(configJson);
    Path projectDir = Path.of("/Users/test/myproject");

    JsonNode resolved = LuceeServerConfig.resolveProjectPlaceholders(configNode, projectDir);

    assertEquals(
        "jdbc:h2:mem:testdb",
        resolved.get("datasources").get("mydb").get("dsn").asText()
    );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/peter/GitHub/bpamiri/LuCLI && mvn test -pl . -Dtest="LuceeServerConfigTest#resolveConfigurationNode_replacesProjectPlaceholder" -DfailIfNoTests=false`
Expected: FAIL — `resolveProjectPlaceholders` method doesn't exist yet.

- [ ] **Step 3: Implement `resolveProjectPlaceholders` method**

Add to `src/main/java/org/lucee/lucli/server/LuceeServerConfig.java`, near the existing `replaceLucliVarsInJsonNode` method (around line 1344):

```java
/**
 * Recursively replace {project} placeholders in a JsonNode tree with
 * the absolute path of the project directory. This enables portable
 * datasource DSN strings like jdbc:sqlite:{project}/db/development.db.
 *
 * @param node       The JsonNode to process (typically the "configuration" block)
 * @param projectDir The project root directory
 * @return A new JsonNode with all {project} occurrences replaced
 */
public static JsonNode resolveProjectPlaceholders(JsonNode node, Path projectDir) {
    if (node == null || projectDir == null) {
        return node;
    }
    String projectPath = projectDir.toAbsolutePath().toString();
    return replaceInJsonNode(node, "{project}", projectPath);
}

/**
 * Recursively replace all occurrences of a literal string in text values
 * within a JsonNode tree.
 */
private static JsonNode replaceInJsonNode(JsonNode node, String target, String replacement) {
    ObjectMapper mapper = new ObjectMapper();
    if (node.isTextual()) {
        String value = node.asText();
        if (value.contains(target)) {
            return mapper.getNodeFactory().textNode(value.replace(target, replacement));
        }
        return node;
    }
    if (node.isArray()) {
        ArrayNode result = mapper.createArrayNode();
        for (JsonNode element : node) {
            result.add(replaceInJsonNode(element, target, replacement));
        }
        return result;
    }
    if (node.isObject()) {
        ObjectNode result = mapper.createObjectNode();
        Iterator<Map.Entry<String, JsonNode>> fields = node.fields();
        while (fields.hasNext()) {
            Map.Entry<String, JsonNode> field = fields.next();
            result.set(field.getKey(), replaceInJsonNode(field.getValue(), target, replacement));
        }
        return result;
    }
    return node;
}
```

Add required imports if not already present:

```java
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/peter/GitHub/bpamiri/LuCLI && mvn test -pl . -Dtest="LuceeServerConfigTest#resolveConfigurationNode_replacesProjectPlaceholder+resolveConfigurationNode_leavesStringsWithoutPlaceholder" -DfailIfNoTests=false`
Expected: PASS

- [ ] **Step 5: Wire into the config resolution pipeline**

In `LuceeServerConfig.java`, find `resolveConfigurationNode` method (around line 1891). At the end of the method, before returning, add the `{project}` resolution:

```java
// Resolve {project} placeholder to actual project directory path.
// This enables portable datasource DSN strings like:
// jdbc:sqlite:{project}/db/development.db
if (result != null && projectDir != null) {
    result = resolveProjectPlaceholders(result, projectDir);
}
```

Also, in the `substituteEnvironmentVariables` method (around line 921), add `{project}` resolution after the existing `replaceLucliVarsInJsonNode` call. Since `substituteEnvironmentVariables` doesn't have `projectDir`, the resolution in `resolveConfigurationNode` is the right place. Verify the call chain:

- `writeCfConfigIfPresent(config, projectDir, serverInstanceDir)` on line 2386
  - calls `resolveEffectiveCfConfigForContext(config, projectDir, ...)` on line 2388
    - calls `resolveConfigurationNode(config, projectDir)` on line 2342
      - **our change resolves `{project}` here**

- [ ] **Step 6: Write integration test**

Add to `LuceeServerConfigTest.java`:

```java
@Test
void writeCfConfig_resolvesProjectPlaceholderInDatasourceDsn(@TempDir Path tempDir) throws Exception {
    // Create a minimal lucee.json with {project} in datasource DSN
    Path projectDir = tempDir.resolve("myproject");
    Files.createDirectories(projectDir);

    String luceeJson = """
        {
            "name": "test",
            "port": 8080,
            "webroot": "./public",
            "configuration": {
                "datasources": {
                    "testdb": {
                        "class": "org.sqlite.JDBC",
                        "dsn": "jdbc:sqlite:{project}/db/test.db"
                    }
                }
            }
        }
        """;
    Files.writeString(projectDir.resolve("lucee.json"), luceeJson);

    // Load config
    LuceeServerConfig.ServerConfig config = LuceeServerConfig.loadConfig(projectDir);

    // Create a fake server instance dir with Lucee context structure
    Path serverInstanceDir = tempDir.resolve("server-instance");
    Path luceeContext = serverInstanceDir.resolve("lucee-server/context");
    Files.createDirectories(luceeContext);

    // Write CFConfig
    LuceeServerConfig.writeCfConfigIfPresent(config, projectDir, serverInstanceDir);

    // Verify the .CFConfig.json has resolved paths
    Path cfConfigPath = luceeContext.resolve(".CFConfig.json");
    assertTrue(Files.exists(cfConfigPath), ".CFConfig.json should be created");

    ObjectMapper mapper = new ObjectMapper();
    JsonNode cfConfig = mapper.readTree(Files.readString(cfConfigPath));

    String dsn = cfConfig.get("datasources").get("testdb").get("dsn").asText();
    assertFalse(dsn.contains("{project}"), "DSN should not contain {project} placeholder");
    assertTrue(dsn.contains(projectDir.toAbsolutePath().toString()),
        "DSN should contain absolute project path. Got: " + dsn);
}
```

- [ ] **Step 7: Run full test suite**

Run: `cd /Users/peter/GitHub/bpamiri/LuCLI && mvn test`
Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
cd /Users/peter/GitHub/bpamiri/LuCLI
git checkout -b peter/resolve-project-placeholder
git add src/main/java/org/lucee/lucli/server/LuceeServerConfig.java \
        src/test/java/org/lucee/lucli/server/LuceeServerConfigTest.java
git commit -m "feat: resolve {project} placeholder in CFConfig datasource paths

Enables portable datasource DSN strings in lucee.json like:
jdbc:sqlite:{project}/db/development.db

LuCLI now resolves {project} to the absolute project directory path
when writing .CFConfig.json. This is done in resolveConfigurationNode()
which already has access to projectDir.

Follows the same recursive JsonNode processing pattern used by
replaceLucliVarsInJsonNode for #env:VAR# placeholders."
```

---

### Task 2: Binary Name Detection — Profile & Branding

LuCLI already has `prependBinaryNameIfAliased()` which detects the binary name via `-Dlucli.binary.name` system property. We extend this so that when the binary is `wheels`:
1. The cache/home directory changes to `~/.wheels/`
2. The banner shows Wheels branding
3. The prompt prefix changes

**Files:**
- Modify: `src/main/java/org/lucee/lucli/LuCLI.java`
- Modify: `src/main/java/org/lucee/lucli/paths/LucliPaths.java`
- Create: `src/main/java/org/lucee/lucli/profile/CliProfile.java`
- Create: `src/main/java/org/lucee/lucli/profile/DefaultProfile.java`
- Create: `src/main/java/org/lucee/lucli/profile/WheelsProfile.java`
- Test: `src/test/java/org/lucee/lucli/profile/CliProfileTest.java`

- [ ] **Step 1: Write the failing test**

Create `src/test/java/org/lucee/lucli/profile/CliProfileTest.java`:

```java
package org.lucee.lucli.profile;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class CliProfileTest {

    @Test
    void forBinaryName_returnsWheelsProfileForWheels() {
        CliProfile profile = CliProfile.forBinaryName("wheels");
        assertEquals("wheels", profile.name());
        assertEquals(".wheels", profile.homeDirName());
        assertTrue(profile.bannerText().contains("Wheels"));
    }

    @Test
    void forBinaryName_returnsDefaultProfileForLucli() {
        CliProfile profile = CliProfile.forBinaryName("lucli");
        assertEquals("lucli", profile.name());
        assertEquals(".lucli", profile.homeDirName());
        assertTrue(profile.bannerText().contains("LuCLI"));
    }

    @Test
    void forBinaryName_returnsDefaultProfileForNull() {
        CliProfile profile = CliProfile.forBinaryName(null);
        assertEquals("lucli", profile.name());
    }

    @Test
    void forBinaryName_returnsDefaultProfileForUnknown() {
        CliProfile profile = CliProfile.forBinaryName("somecli");
        assertEquals("lucli", profile.name());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/peter/GitHub/bpamiri/LuCLI && mvn test -pl . -Dtest="CliProfileTest" -DfailIfNoTests=false`
Expected: FAIL — classes don't exist yet.

- [ ] **Step 3: Implement CliProfile interface and profiles**

Create `src/main/java/org/lucee/lucli/profile/CliProfile.java`:

```java
package org.lucee.lucli.profile;

/**
 * Defines CLI identity based on binary name. When LuCLI is distributed
 * as a renamed binary (e.g., "wheels"), the profile controls branding,
 * home directory, and default behaviors.
 */
public interface CliProfile {

    /** The profile name (e.g., "lucli", "wheels"). */
    String name();

    /** The home directory name under user home (e.g., ".lucli", ".wheels"). */
    String homeDirName();

    /** The ASCII banner text shown on --version. */
    String bannerText();

    /** The REPL prompt prefix. */
    String promptPrefix();

    /** Resolve the active profile for a given binary name. */
    static CliProfile forBinaryName(String binaryName) {
        if (binaryName != null && binaryName.equalsIgnoreCase("wheels")) {
            return new WheelsProfile();
        }
        return new DefaultProfile();
    }
}
```

Create `src/main/java/org/lucee/lucli/profile/DefaultProfile.java`:

```java
package org.lucee.lucli.profile;

public class DefaultProfile implements CliProfile {
    @Override public String name() { return "lucli"; }
    @Override public String homeDirName() { return ".lucli"; }
    @Override public String promptPrefix() { return "cfml"; }
    @Override
    public String bannerText() {
        return """
             _           ____ _     ___\s
            | |   _   _ / ___| |   |_ _|
            | |  | | | | |   | |    | |\s
            | |__| |_| | |___| |___ | |\s
            |_____\\__,_|\\____|_____|___|
            """;
    }
}
```

Create `src/main/java/org/lucee/lucli/profile/WheelsProfile.java`:

```java
package org.lucee.lucli.profile;

public class WheelsProfile implements CliProfile {
    @Override public String name() { return "wheels"; }
    @Override public String homeDirName() { return ".wheels"; }
    @Override public String promptPrefix() { return "wheels"; }
    @Override
    public String bannerText() {
        return """
            __        ___               _    \s
            \\ \\      / / |__   ___  ___| |___
             \\ \\ /\\ / /| '_ \\ / _ \\/ _ \\ / __|
              \\ V  V / | | | |  __/  __/ \\__ \\
               \\_/\\_/  |_| |_|\\___|\\___|_|___/
            """;
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/peter/GitHub/bpamiri/LuCLI && mvn test -pl . -Dtest="CliProfileTest" -DfailIfNoTests=false`
Expected: PASS

- [ ] **Step 5: Wire profile into LuCLI.java**

In `LuCLI.java`, add a static profile field and resolve it in `main()`:

```java
// Near top of class (around line 55)
private static CliProfile activeProfile = new DefaultProfile();

public static CliProfile getActiveProfile() {
    return activeProfile;
}
```

In `main()` method (around line 487), after `prependBinaryNameIfAliased`:

```java
// Resolve CLI profile from binary name
String binaryName = System.getProperty("lucli.binary.name", "lucli");
activeProfile = CliProfile.forBinaryName(binaryName);
```

In `getBannerString()` (around line 975), replace the hardcoded ASCII art:

```java
// Replace hardcoded banner with profile-driven banner
sb.append(activeProfile.bannerText());
```

Add import:

```java
import org.lucee.lucli.profile.CliProfile;
import org.lucee.lucli.profile.DefaultProfile;
```

- [ ] **Step 6: Wire profile into LucliPaths.java**

In `LucliPaths.java`, modify `resolve()` (around line 29) to use the profile's home dir:

```java
public static Path resolve() {
    // Check system property first
    String sysProp = System.getProperty("lucli.home");
    if (sysProp != null && !sysProp.isBlank()) {
        return Path.of(sysProp);
    }
    // Check environment variable
    String envVar = System.getenv("LUCLI_HOME");
    if (envVar != null && !envVar.isBlank()) {
        return Path.of(envVar);
    }
    // Default: use active profile's home dir name
    String homeDirName = LuCLI.getActiveProfile().homeDirName();
    return Path.of(System.getProperty("user.home"), homeDirName);
}
```

Add import:

```java
import org.lucee.lucli.LuCLI;
```

- [ ] **Step 7: Run full test suite**

Run: `cd /Users/peter/GitHub/bpamiri/LuCLI && mvn test`
Expected: All tests pass. Existing tests use `~/.lucli` (default profile) so no breakage.

- [ ] **Step 8: Commit**

```bash
cd /Users/peter/GitHub/bpamiri/LuCLI
git checkout -b peter/binary-name-profiles
git add src/main/java/org/lucee/lucli/profile/ \
        src/test/java/org/lucee/lucli/profile/ \
        src/main/java/org/lucee/lucli/LuCLI.java \
        src/main/java/org/lucee/lucli/paths/LucliPaths.java
git commit -m "feat: add CLI profile system for binary-name-based branding

When LuCLI is distributed as a renamed binary (e.g., 'wheels'),
the profile system controls branding (banner), home directory
(~/.wheels/ vs ~/.lucli/), and REPL prompt prefix.

Profile is resolved from the -Dlucli.binary.name system property
which is already set by the existing prependBinaryNameIfAliased()
mechanism. Third-party frameworks can create their own CliProfile
implementation to customize their CLI identity."
```

---

### Task 3: SQLite JDBC Auto-Install

When a datasource in `.CFConfig.json` uses `org.sqlite.JDBC` and the SQLite JDBC driver is not present in the Lucee Express `lib/ext/` directory, LuCLI should automatically download and install it.

**Files:**
- Modify: `src/main/java/org/lucee/lucli/server/LuceeServerManager.java`
- Create: `src/main/java/org/lucee/lucli/server/JdbcDriverManager.java`
- Test: `src/test/java/org/lucee/lucli/server/JdbcDriverManagerTest.java`

- [ ] **Step 1: Write the failing test**

Create `src/test/java/org/lucee/lucli/server/JdbcDriverManagerTest.java`:

```java
package org.lucee.lucli.server;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import static org.junit.jupiter.api.Assertions.*;

import java.nio.file.Files;
import java.nio.file.Path;

class JdbcDriverManagerTest {

    @Test
    void detectsRequiredDrivers_fromCfConfig() throws Exception {
        String cfConfig = """
            {
                "datasources": {
                    "mydb": {
                        "class": "org.sqlite.JDBC",
                        "dsn": "jdbc:sqlite:/tmp/test.db"
                    },
                    "otherdb": {
                        "class": "org.h2.Driver",
                        "dsn": "jdbc:h2:mem:test"
                    }
                }
            }
            """;

        var required = JdbcDriverManager.detectRequiredDrivers(cfConfig);

        assertTrue(required.containsKey("sqlite"), "Should detect SQLite driver requirement");
        assertFalse(required.containsKey("h2"), "H2 is bundled with Lucee, should not be required");
    }

    @Test
    void isSqliteDriverInstalled_falseWhenMissing(@TempDir Path tempDir) {
        Path libExt = tempDir.resolve("lib/ext");
        assertFalse(JdbcDriverManager.isDriverInstalled(libExt, "sqlite"));
    }

    @Test
    void isSqliteDriverInstalled_trueWhenPresent(@TempDir Path tempDir) throws Exception {
        Path libExt = tempDir.resolve("lib/ext");
        Files.createDirectories(libExt);
        Files.writeString(libExt.resolve("sqlite-jdbc-3.49.1.0.jar"), "fake");
        assertTrue(JdbcDriverManager.isDriverInstalled(libExt, "sqlite"));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/peter/GitHub/bpamiri/LuCLI && mvn test -pl . -Dtest="JdbcDriverManagerTest" -DfailIfNoTests=false`
Expected: FAIL — class doesn't exist.

- [ ] **Step 3: Implement JdbcDriverManager**

Create `src/main/java/org/lucee/lucli/server/JdbcDriverManager.java`:

```java
package org.lucee.lucli.server;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Manages automatic detection and installation of JDBC drivers required
 * by datasources defined in .CFConfig.json.
 */
public class JdbcDriverManager {

    /** Known JDBC drivers that can be auto-installed. */
    private static final Map<String, DriverInfo> KNOWN_DRIVERS = Map.of(
        "sqlite", new DriverInfo(
            "org.sqlite.JDBC",
            "sqlite-jdbc",
            "https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.49.1.0/sqlite-jdbc-3.49.1.0.jar",
            "sqlite-jdbc-3.49.1.0.jar"
        )
    );

    public record DriverInfo(String className, String filePrefix, String downloadUrl, String fileName) {}

    /**
     * Scan a CFConfig JSON string for datasources that require drivers
     * not bundled with Lucee Express.
     *
     * @return Map of driver key to DriverInfo for required drivers
     */
    public static Map<String, DriverInfo> detectRequiredDrivers(String cfConfigJson) throws IOException {
        Map<String, DriverInfo> required = new LinkedHashMap<>();
        ObjectMapper mapper = new ObjectMapper();
        JsonNode root = mapper.readTree(cfConfigJson);
        JsonNode datasources = root.get("datasources");
        if (datasources == null || !datasources.isObject()) {
            return required;
        }
        var fields = datasources.fields();
        while (fields.hasNext()) {
            var entry = fields.next();
            JsonNode ds = entry.getValue();
            JsonNode classNode = ds.get("class");
            if (classNode != null && classNode.isTextual()) {
                String className = classNode.asText();
                for (var known : KNOWN_DRIVERS.entrySet()) {
                    if (known.getValue().className().equals(className)) {
                        required.put(known.getKey(), known.getValue());
                    }
                }
            }
        }
        return required;
    }

    /**
     * Check if a driver's JAR is already installed in the given lib/ext directory.
     */
    public static boolean isDriverInstalled(Path libExtDir, String driverKey) {
        DriverInfo info = KNOWN_DRIVERS.get(driverKey);
        if (info == null || !Files.isDirectory(libExtDir)) {
            return false;
        }
        try (DirectoryStream<Path> stream = Files.newDirectoryStream(libExtDir, info.filePrefix() + "*.jar")) {
            return stream.iterator().hasNext();
        } catch (IOException e) {
            return false;
        }
    }

    /**
     * Download and install a JDBC driver into the lib/ext directory.
     */
    public static void installDriver(Path libExtDir, String driverKey) throws IOException {
        DriverInfo info = KNOWN_DRIVERS.get(driverKey);
        if (info == null) {
            throw new IllegalArgumentException("Unknown driver: " + driverKey);
        }
        Files.createDirectories(libExtDir);
        Path target = libExtDir.resolve(info.fileName());
        System.out.println("Downloading " + info.filePrefix() + " JDBC driver...");
        try (InputStream in = URI.create(info.downloadUrl()).toURL().openStream()) {
            Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
        }
        System.out.println("Installed: " + target);
    }

    /**
     * Ensure all required JDBC drivers are installed for the given CFConfig.
     * Downloads missing drivers automatically.
     *
     * @return true if any drivers were installed (server restart needed)
     */
    public static boolean ensureDrivers(Path libExtDir, String cfConfigJson) throws IOException {
        Map<String, DriverInfo> required = detectRequiredDrivers(cfConfigJson);
        boolean installed = false;
        for (var entry : required.entrySet()) {
            if (!isDriverInstalled(libExtDir, entry.getKey())) {
                installDriver(libExtDir, entry.getKey());
                installed = true;
            }
        }
        return installed;
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/peter/GitHub/bpamiri/LuCLI && mvn test -pl . -Dtest="JdbcDriverManagerTest" -DfailIfNoTests=false`
Expected: PASS

- [ ] **Step 5: Wire into server startup**

In `LuceeServerManager.java`, find the `startServerInternal` method. After the CFConfig is written (after `writeCfConfigIfPresent`) and before the server process starts, add driver detection:

Find the call to `LuceeServerConfig.writeCfConfigIfPresent` in the `LuceeExpressRuntimeProvider.java` `start()` method (around line 59). After that line, add:

```java
// Auto-install JDBC drivers required by datasources in CFConfig
Path cfConfigPath = LuceeServerConfig.resolveCfConfigPath(catalinaBase);
if (Files.exists(cfConfigPath)) {
    String cfConfigJson = Files.readString(cfConfigPath);
    Path libExtDir = catalinaHome.resolve("lib/ext");
    boolean driversInstalled = JdbcDriverManager.ensureDrivers(libExtDir, cfConfigJson);
    if (driversInstalled) {
        System.out.println("JDBC drivers installed. They will be available on next server start.");
    }
}
```

Add import:

```java
import org.lucee.lucli.server.JdbcDriverManager;
```

Note: `resolveCfConfigPath` may need to be extracted or the path computed inline as:
```java
Path cfConfigPath = catalinaBase.resolve("lucee-server/context/.CFConfig.json");
```

- [ ] **Step 6: Run full test suite**

Run: `cd /Users/peter/GitHub/bpamiri/LuCLI && mvn test`
Expected: All tests pass.

- [ ] **Step 7: Commit**

```bash
cd /Users/peter/GitHub/bpamiri/LuCLI
git checkout -b peter/auto-install-jdbc-drivers
git add src/main/java/org/lucee/lucli/server/JdbcDriverManager.java \
        src/test/java/org/lucee/lucli/server/JdbcDriverManagerTest.java \
        src/main/java/org/lucee/lucli/server/runtime/LuceeExpressRuntimeProvider.java
git commit -m "feat: auto-detect and install JDBC drivers required by CFConfig datasources

When a datasource in .CFConfig.json references a JDBC driver class
that isn't bundled with Lucee Express (e.g., org.sqlite.JDBC), LuCLI
now automatically downloads and installs the driver JAR to lib/ext/
on server startup.

Currently supports SQLite JDBC (sqlite-jdbc-3.49.1.0.jar from Maven
Central). The KNOWN_DRIVERS registry can be extended for other drivers.

This eliminates the manual 'copy SQLite JDBC to lib/ext' step that
was required for SQLite-based development."
```

---

### Task 4: Validate End-to-End with Wheels

After all three PRs land, validate the full local testing workflow.

**Files:**
- Modify: `/Users/peter/GitHub/wheels-dev/wheels/lucee.json`

- [ ] **Step 1: Build LuCLI locally with all changes**

```bash
cd /Users/peter/GitHub/bpamiri/LuCLI
# Merge all three branches (or cherry-pick)
git checkout main
git merge peter/resolve-project-placeholder peter/binary-name-profiles peter/auto-install-jdbc-drivers
mvn package -DskipTests
# Install the built binary
cp target/lucli /Users/peter/bin/lucli
```

- [ ] **Step 2: Update Wheels lucee.json to use {project} paths**

Update `/Users/peter/GitHub/wheels-dev/wheels/lucee.json` to include SQLite datasources with `{project}` placeholder:

```json
{
  "name": "wheels",
  "lucee": {
    "version": "7.0.0.395"
  },
  "port": 8080,
  "shutdownPort": 8081,
  "webroot": "./public",
  "openBrowser": false,
  "jvm": {
    "maxMemory": "512m",
    "minMemory": "128m"
  },
  "urlRewrite": {
    "enabled": true,
    "routerFile": "index.cfm"
  },
  "admin": {
    "enabled": true,
    "password": "wheels"
  },
  "enableLucee": true,
  "enableREST": false,
  "configuration": {
    "datasources": {
      "wheelstestdb_sqlite": {
        "class": "org.sqlite.JDBC",
        "database": "wheelstestdb",
        "dbdriver": "Other",
        "dsn": "jdbc:sqlite:{project}/wheelstestdb.db",
        "host": "",
        "password": "",
        "username": ""
      },
      "wheelstestdb_sqlite_tenant_b": {
        "class": "org.sqlite.JDBC",
        "database": "wheelstestdb_tenant_b",
        "dbdriver": "Other",
        "dsn": "jdbc:sqlite:{project}/wheelstestdb_tenant_b.db",
        "host": "",
        "password": "",
        "username": ""
      }
    },
    "mappings": {
      "/wheels": "../vendor/wheels",
      "/app": "../app",
      "/config": "../config",
      "/tests": "../tests"
    }
  }
}
```

- [ ] **Step 3: Create SQLite databases and start server**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels
sqlite3 wheelstestdb.db "SELECT 1;"
sqlite3 wheelstestdb_tenant_b.db "SELECT 1;"
lucli server run --port=8080 --force
```

Expected: Server starts, SQLite JDBC auto-downloaded, datasources configured with absolute paths.

- [ ] **Step 4: Run test suite**

```bash
curl -s "http://localhost:8080/?reload=true&password=wheels"
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json" -o /tmp/e2e-results.json
python3 -c "import json; d=json.load(open('/tmp/e2e-results.json')); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')"
```

Expected: `2624 pass, 0 fail, 0 error` (or similar — all green).

- [ ] **Step 5: Test binary name branding**

```bash
# Symlink to test wheels branding
ln -sf /Users/peter/bin/lucli /Users/peter/bin/wheels
wheels --version
```

Expected: Shows Wheels ASCII banner instead of LuCLI banner.

- [ ] **Step 6: Commit Wheels lucee.json update**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels
git add lucee.json
git commit -m "config: add SQLite datasources to lucee.json with {project} placeholder

Enables zero-config local development and testing with LuCLI.
The {project} placeholder is resolved by LuCLI to the absolute
project directory when writing .CFConfig.json."
```
