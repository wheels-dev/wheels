# CI Engine-Grouped Testing Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the GitHub Actions test matrix from 42 independent jobs (cfengine x dbengine) to 8 engine-grouped jobs that start each CF engine once and run all database test suites sequentially, reducing total CI compute by ~75% while maintaining full test coverage.

**Architecture:** Each of the 8 CF engines gets one job. That job starts the engine + all compatible databases simultaneously, waits for readiness, then loops through each database running the test suite via the `?db=` URL parameter with a `?reload=true` between switches to clear cached model metadata. JUnit XML artifacts are uploaded per engine-database pair, and a summary job renders an engine x database grid via `$GITHUB_STEP_SUMMARY` plus detailed PR annotations via `EnricoMi/publish-unit-test-result-action@v2`.

**Tech Stack:** GitHub Actions, Docker Compose, CFML (Wheels test runner), JUnit XML, `EnricoMi/publish-unit-test-result-action@v2`

---

## Background & Rationale

### Current State
- `tests.yml` is a reusable workflow called by `pr.yml` (PRs to develop) and `snapshot.yml` (push to develop)
- Matrix: 8 cfengines x 6 dbengines = 48 combinations minus exclusions = ~42 jobs
- Each job independently: builds/pulls CF engine image, starts engine, waits for readiness, installs CFPM (Adobe), starts 1 database, runs tests (~1 min), tears down
- Infrastructure setup per job: 10-20 minutes. Actual test execution: ~1 minute.
- Adobe engines pay CFPM install cost (5-10 min) once per job = 6x for 6 databases
- Oracle has a hardcoded `sleep 120` per job = 8 engine jobs x 2 min = 16 min total

### Proposed State
- 8 jobs (one per CF engine), each running all compatible databases sequentially
- CF engine starts once, CFPM installs once, databases start in parallel with engine warmup
- Oracle `sleep 120` replaced with health-check loop (saves ~90s per Oracle occurrence)
- SQL Server memory reduced from 4GB to 2GB (sufficient for tiny test dataset)
- JUnit XML output enables rich test reporting on PRs

### Database Exclusions Per Engine
These exclusions must be preserved in the loop logic:

| Engine | Excluded DBs |
|--------|-------------|
| adobe2018 | sqlite, h2 |
| adobe2021 | h2 |
| adobe2023 | h2 |
| adobe2025 | h2 |
| boxlang | h2 |
| lucee5 | (none) |
| lucee6 | (none) |
| lucee7 | (none) |

### Memory Budget (GitHub runner: 7GB)
All databases run simultaneously:
- CF Engine: ~1.5GB
- MySQL: ~500MB
- PostgreSQL: ~300MB
- SQL Server: 2GB (reduced from 4GB)
- Oracle: 1.5GB (reduced from 2GB)
- H2/SQLite: minimal
- **Total: ~5.8GB** — fits in 7GB with headroom

### Key Technical Insight
The `db` URL parameter (runner.cfm:70-75) simply switches `application.wheels.dataSourceName` to a pre-configured datasource. ALL datasources are baked into each engine's CFConfig.json at build time. No engine restart needed to switch databases.

However, Wheels caches model instances in `application.wheels.models` (Global.cfc:828-846). Switching datasources without clearing this cache causes stale column metadata. Solution: pass `?reload=true` on the first test request for each database, which triggers a full Wheels reinit and clears all caches.

### Callers of tests.yml
- `pr.yml` — PRs targeting develop (also has `label` job and needs `checks: write` permission added)
- `snapshot.yml` — push to develop (triggers build after tests pass)
- Both pass `SLACK_WEBHOOK_URL` secret. No other callers.

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `.github/workflows/tests.yml` | **Rewrite** | Core change: engine-grouped matrix, sequential DB loop, JUnit output, summary jobs |
| `.github/workflows/pr.yml` | **Modify** | Add `checks: write` permission for test reporter |
| `.github/workflows/snapshot.yml` | **Modify** | Add `checks: write` permission for test reporter |
| `compose.yml` | **Modify** | Reduce SQL Server/Oracle memory, re-enable BoxLang volumes |
| `vendor/wheels/tests/runner.cfm` | **No change** | Already supports `?reload=true` via Wheels reinit and `?db=` switching |

---

## Chunk 1: Docker Compose Fixes

### Task 1: Reduce SQL Server Memory Limits

**Files:**
- Modify: `compose.yml:314-319`

- [ ] **Step 1: Edit compose.yml SQL Server memory**

Change the `deploy.resources` block for the `sqlserver` service:

```yaml
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 512M
```

Also change `MSSQL_MEMORY_LIMIT_MB` environment variable to match:

```yaml
      MSSQL_MEMORY_LIMIT_MB: 2048
```

- [ ] **Step 2: Commit**

```bash
git add compose.yml
git commit -m "ci: reduce SQL Server memory from 4GB to 2GB for CI

The test dataset is tiny (5 users, 8 authors, 40 photos). 4GB was excessive
and prevents running all databases simultaneously on a 7GB GitHub runner."
```

### Task 2: Reduce Oracle Memory Limits

**Files:**
- Modify: `compose.yml:341-346`

- [ ] **Step 1: Edit compose.yml Oracle memory**

Change the `deploy.resources` block for the `oracle` service:

```yaml
    deploy:
      resources:
        limits:
          memory: 1536M
        reservations:
          memory: 512M
```

- [ ] **Step 2: Commit**

```bash
git add compose.yml
git commit -m "ci: reduce Oracle memory from 2GB to 1.5GB for CI

Allows running all databases simultaneously within 7GB GitHub runner budget."
```

### Task 3: Re-enable BoxLang Volume Mounts

**Files:**
- Modify: `compose.yml:224-249`

- [ ] **Step 1: Understand the issue**

The BoxLang Dockerfile (tools/docker/boxlang/Dockerfile) COPYs all code at build time, unlike other engines which only copy box.json/CFConfig.json and rely on volume mounts for app code. The compose.yml volumes were commented out in commit 9790880f5.

Re-enabling volumes restores local dev parity with other engines. Docker gives volumes precedence over COPY, so the Dockerfile still works — volumes just override the baked-in code at runtime.

- [ ] **Step 2: Uncomment BoxLang volumes in compose.yml**

Uncomment the volumes section for the boxlang service to match the pattern used by other engines:

```yaml
  boxlang:
    build:
      context: ./
      dockerfile: ./tools/docker/boxlang/Dockerfile
    image: wheels-test-boxlang:v1.0.0
    tty: true
    stdin_open: true
    volumes:
      - ./:/wheels-test-suite
      - type: bind
        source: ./tools/docker/boxlang/server.json
        target: /wheels-test-suite/server.json
      - type: bind
        source: ./tools/docker/boxlang/settings.cfm
        target: /wheels-test-suite/config/settings.cfm
      - type: bind
        source: ./tools/docker/boxlang/box.json
        target: /wheels-test-suite/box.json
      - type: bind
        source: ./tools/docker/boxlang/CFConfig.json
        target: /wheels-test-suite/CFConfig.json
    ports:
      - "60001:60001"
    networks:
      - wheels-network
```

- [ ] **Step 3: Commit**

```bash
git add compose.yml
git commit -m "fix: re-enable BoxLang volume mounts for local dev parity

Volumes were commented out in 9790880f5 when Dockerfile was changed to COPY
all code at build time. This broke local dev (code changes required rebuild).
Re-enabling volumes restores live-reload behavior matching other CF engines.
Docker gives volumes precedence over COPY, so CI still works correctly."
```

---

## Chunk 2: Rewrite tests.yml — Engine-Grouped Matrix

### Task 4: Rewrite the tests job in tests.yml

**Files:**
- Rewrite: `.github/workflows/tests.yml`

This is the core change. The entire `tests` job is rewritten from a `cfengine x dbengine` matrix to a `cfengine`-only matrix with a sequential database loop.

- [ ] **Step 1: Write the new tests.yml**

The complete new file structure:

```yaml
# This is a reusable workflow that is called from the pr, snapshot, and release workflows
# This workflow runs the complete Wheels Framework Test Suites
name: Wheels Test Suites
# We are a reusable Workflow only
on:
  workflow_call:
    secrets:
      SLACK_WEBHOOK_URL:
        required: true
jobs:
  tests:
    name: "${{ matrix.cfengine }}"
    runs-on: ubuntu-latest
    continue-on-error: ${{ matrix.experimental }}
    strategy:
      fail-fast: false
      matrix:
        cfengine:
          ["lucee5", "lucee6", "lucee7", "adobe2018", "adobe2021", "adobe2023", "adobe2025", "boxlang"]
        experimental: [false]
    env:
      PORT_lucee5: 60005
      PORT_lucee6: 60006
      PORT_lucee7: 60007
      PORT_adobe2018: 62018
      PORT_adobe2021: 62021
      PORT_adobe2023: 62023
      PORT_adobe2025: 62025
      PORT_boxlang: 60001
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Determine databases for this engine
        id: db-list
        run: |
          # Every engine gets these databases
          DATABASES="mysql,postgres,sqlserver,oracle,sqlite"

          # Add h2 only for engines that support it (Lucee only)
          case "${{ matrix.cfengine }}" in
            lucee5|lucee6|lucee7)
              DATABASES="mysql,postgres,sqlserver,h2,oracle,sqlite"
              ;;
            adobe2018)
              # adobe2018 also excludes sqlite
              DATABASES="mysql,postgres,sqlserver,oracle"
              ;;
          esac

          echo "databases=${DATABASES}" >> $GITHUB_OUTPUT
          echo "Databases for ${{ matrix.cfengine }}: ${DATABASES}"

      - name: Download ojdbc10 for Adobe engines
        if: ${{ startsWith(matrix.cfengine, 'adobe') }}
        run: |
          mkdir -p ./.engine/${{ matrix.cfengine }}/WEB-INF/lib
          wget -q https://download.oracle.com/otn-pub/otn_software/jdbc/1927/ojdbc10.jar \
            -O ./.engine/${{ matrix.cfengine }}/WEB-INF/lib/ojdbc10.jar

      - name: Start CF engine
        run: docker compose up -d ${{ matrix.cfengine }}

      - name: Start all databases
        run: |
          IFS=',' read -ra DBS <<< "${{ steps.db-list.outputs.databases }}"
          EXTERNAL_DBS=""
          for db in "${DBS[@]}"; do
            if [ "$db" != "h2" ] && [ "$db" != "sqlite" ]; then
              EXTERNAL_DBS="$EXTERNAL_DBS $db"
            fi
          done
          if [ -n "$EXTERNAL_DBS" ]; then
            echo "Starting external databases:${EXTERNAL_DBS}"
            docker compose up -d ${EXTERNAL_DBS}
          fi

      - name: Wait for CF engine to be ready
        run: |
          PORT_VAR="PORT_${{ matrix.cfengine }}"
          PORT="${!PORT_VAR}"

          echo "Waiting for ${{ matrix.cfengine }} on port ${PORT}..."

          # Wait for container to be running
          timeout 150 bash -c 'until docker ps --filter "name=${{ matrix.cfengine }}" | grep -q "${{ matrix.cfengine }}"; do
            echo "Waiting for container to start..."
            sleep 2
          done'

          # Wait for HTTP response
          MAX_WAIT=60
          WAIT_COUNT=0
          while [ "$WAIT_COUNT" -lt "$MAX_WAIT" ]; do
            WAIT_COUNT=$((WAIT_COUNT + 1))
            if curl -s -o /dev/null --connect-timeout 2 --max-time 5 -w "%{http_code}" "http://localhost:${PORT}/" | grep -q "200\|404\|302"; then
              echo "CF engine is ready!"
              break
            fi
            if [ "$WAIT_COUNT" -lt "$MAX_WAIT" ]; then
              sleep 5
            fi
          done

          if [ "$WAIT_COUNT" -ge "$MAX_WAIT" ]; then
            echo "Warning: CF engine may not be fully ready after ${MAX_WAIT} attempts"
          fi

      - name: Patch Adobe CF serialfilter.txt for Oracle JDBC
        if: ${{ (matrix.cfengine == 'adobe2023' || matrix.cfengine == 'adobe2025') }}
        run: |
          docker exec wheels-${{ matrix.cfengine }}-1 sh -c \
            "echo ';oracle.sql.converter.**;oracle.sql.**;oracle.jdbc.**' >> /wheels-test-suite/.engine/${{ matrix.cfengine }}/WEB-INF/cfusion/lib/serialfilter.txt"
          docker restart wheels-${{ matrix.cfengine }}-1

          # Wait for engine to come back up after restart
          PORT_VAR="PORT_${{ matrix.cfengine }}"
          PORT="${!PORT_VAR}"
          MAX_WAIT=30
          WAIT_COUNT=0
          while [ "$WAIT_COUNT" -lt "$MAX_WAIT" ]; do
            WAIT_COUNT=$((WAIT_COUNT + 1))
            if curl -s -o /dev/null --connect-timeout 2 --max-time 5 -w "%{http_code}" "http://localhost:${PORT}/" | grep -q "200\|404\|302"; then
              echo "CF engine back up after restart"
              break
            fi
            sleep 5
          done

      - name: Install CFPM packages (Adobe 2021/2023/2025)
        if: ${{ matrix.cfengine == 'adobe2021' || matrix.cfengine == 'adobe2023' || matrix.cfengine == 'adobe2025' }}
        run: |
          MAX_RETRIES=3
          RETRY_COUNT=0

          while [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; do
            RETRY_COUNT=$((RETRY_COUNT + 1))
            echo "Attempt $RETRY_COUNT of $MAX_RETRIES: Installing CFPM packages..."

            if docker exec wheels-${{ matrix.cfengine }}-1 box cfpm install image,mail,zip,debugger,caching,mysql,postgresql,sqlserver,oracle; then
              echo "CFPM packages installed successfully"
              exit 0
            else
              echo "CFPM installation failed on attempt $RETRY_COUNT"
              if [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; then
                echo "Waiting 10 seconds before retry..."
                sleep 10
                docker exec wheels-${{ matrix.cfengine }}-1 box server restart || true
                sleep 10
              fi
            fi
          done

          echo "Failed to install CFPM packages after $MAX_RETRIES attempts"
          exit 1

      - name: Wait for Oracle to be ready
        if: ${{ contains(steps.db-list.outputs.databases, 'oracle') }}
        run: |
          echo "Waiting for Oracle to accept connections..."
          MAX_WAIT=60
          WAIT_COUNT=0
          while [ "$WAIT_COUNT" -lt "$MAX_WAIT" ]; do
            WAIT_COUNT=$((WAIT_COUNT + 1))
            if docker exec wheels-oracle-1 sqlplus -S wheelstestdb/wheelstestdb@localhost:1521/wheelstestdb <<< "SELECT 1 FROM DUAL; EXIT;" > /dev/null 2>&1; then
              echo "Oracle is ready! (attempt ${WAIT_COUNT})"
              exit 0
            fi
            echo "Oracle not ready yet (attempt ${WAIT_COUNT}/${MAX_WAIT})..."
            sleep 5
          done
          echo "Warning: Oracle may not be fully ready after ${MAX_WAIT} attempts"

      - name: Wait for other databases to be ready
        run: |
          IFS=',' read -ra DBS <<< "${{ steps.db-list.outputs.databases }}"
          for db in "${DBS[@]}"; do
            case "$db" in
              mysql)
                echo "Waiting for MySQL..."
                timeout 60 bash -c 'until docker exec wheels-mysql-1 mysqladmin ping -h localhost -u root -pwheelstestdb --silent 2>/dev/null; do sleep 2; done'
                echo "MySQL is ready"
                ;;
              postgres)
                echo "Waiting for PostgreSQL..."
                timeout 60 bash -c 'until docker exec wheels-postgres-1 pg_isready -U wheelstestdb 2>/dev/null; do sleep 2; done'
                echo "PostgreSQL is ready"
                ;;
              sqlserver)
                echo "Waiting for SQL Server..."
                timeout 120 bash -c 'until docker exec wheels-sqlserver-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "x!bsT8t60yo0cTVTPq" -Q "SELECT 1" -C 2>/dev/null | grep -q "1"; do sleep 5; done'
                echo "SQL Server is ready"
                ;;
              h2|sqlite)
                echo "$db requires no external container"
                ;;
              oracle)
                echo "Oracle readiness already checked above"
                ;;
            esac
          done

      - name: Run test suites for all databases
        id: run-tests
        run: |
          PORT_VAR="PORT_${{ matrix.cfengine }}"
          PORT="${!PORT_VAR}"
          BASE_URL="http://localhost:${PORT}/wheels/core/tests"

          IFS=',' read -ra DBS <<< "${{ steps.db-list.outputs.databases }}"

          OVERALL_STATUS=0
          RESULTS_JSON="{"
          FIRST=true

          mkdir -p /tmp/test-results
          mkdir -p /tmp/junit-results

          for db in "${DBS[@]}"; do
            echo ""
            echo "=============================================="
            echo "Running tests: ${{ matrix.cfengine }} + ${db}"
            echo "=============================================="

            # Use format=json WITHOUT only=failure,error to get clean, full JSON
            # (the only= param produces text output, not parseable JSON)
            RELOAD_URL="${BASE_URL}?db=${db}&reload=true&format=json"
            JSON_URL="${BASE_URL}?db=${db}&format=json"

            RESULT_FILE="/tmp/test-results/${{ matrix.cfengine }}-${db}-result.txt"
            JUNIT_FILE="/tmp/junit-results/${{ matrix.cfengine }}-${db}-junit.xml"

            # Run tests with reload (clears model cache for clean DB switch)
            MAX_RETRIES=3
            RETRY_COUNT=0
            HTTP_CODE="000"

            while [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ] && [ "$HTTP_CODE" = "000" ]; do
              RETRY_COUNT=$((RETRY_COUNT + 1))
              echo "Test attempt ${RETRY_COUNT} of ${MAX_RETRIES}..."

              # Use reload URL on first attempt, plain URL on retries
              if [ "$RETRY_COUNT" -eq 1 ]; then
                TEST_URL="$RELOAD_URL"
              else
                TEST_URL="$JSON_URL"
              fi

              HTTP_CODE=$(curl -s -o "$RESULT_FILE" \
                --max-time 900 \
                --write-out "%{http_code}" \
                "$TEST_URL" || echo "000")

              echo "HTTP Code: ${HTTP_CODE}"

              if [ "$HTTP_CODE" = "000" ] && [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; then
                echo "Connection failed, waiting 10 seconds before retry..."
                sleep 10
              fi
            done

            # Convert JSON results to JUnit XML locally (avoids a second HTTP
            # request which would re-run the entire test suite — runner.cfm
            # does not cache results between requests)
            if [ -f "$RESULT_FILE" ]; then
              python3 -c "
          import json, sys
          from xml.etree.ElementTree import Element, SubElement, tostring

          try:
              d = json.load(open('$RESULT_FILE'))
          except:
              sys.exit(0)

          def process_suite(parent_el, suite):
              \"\"\"Recursively process suites (TestBox suites can be nested).\"\"\"
              for sp in suite.get('specStats', []):
                  tc = SubElement(parent_el, 'testcase',
                      name=sp.get('name', ''),
                      classname=suite.get('name', ''),
                      time=str(sp.get('totalDuration', 0) / 1000))
                  if sp.get('status') == 'Failed':
                      f = SubElement(tc, 'failure', message=sp.get('failMessage', ''))
                      f.text = sp.get('failDetail', '')
                  elif sp.get('status') == 'Error':
                      e = SubElement(tc, 'error', message=sp.get('failMessage', ''))
                      e.text = sp.get('failDetail', '')
                  elif sp.get('status') == 'Skipped':
                      SubElement(tc, 'skipped')
              # Recurse into child suites
              for child in suite.get('suiteStats', []):
                  process_suite(parent_el, child)

          root = Element('testsuites',
              tests=str(d.get('totalSpecs', 0)),
              failures=str(d.get('totalFail', 0)),
              errors=str(d.get('totalError', 0)),
              time=str(d.get('totalDuration', 0) / 1000))

          for b in d.get('bundleStats', []):
              ts = SubElement(root, 'testsuite',
                  name=b.get('name', ''),
                  tests=str(b.get('totalSpecs', 0)),
                  failures=str(b.get('totalFail', 0)),
                  errors=str(b.get('totalError', 0)),
                  time=str(b.get('totalDuration', 0) / 1000))
              for s in b.get('suiteStats', []):
                  process_suite(ts, s)

          with open('$JUNIT_FILE', 'wb') as f:
              f.write(b'<?xml version=\"1.0\" encoding=\"UTF-8\"?>')
              f.write(tostring(root))
          " || echo "JUnit conversion failed for ${db} (non-fatal)"
            fi

            # Track per-database result
            if [ "$HTTP_CODE" = "200" ]; then
              echo "PASSED: ${{ matrix.cfengine }} + ${db}"
              DB_STATUS="pass"
            else
              echo "FAILED: ${{ matrix.cfengine }} + ${db} (HTTP ${HTTP_CODE})"
              DB_STATUS="fail"
              OVERALL_STATUS=1
            fi

            # Build JSON summary for matrix display
            if [ "$FIRST" = true ]; then
              FIRST=false
            else
              RESULTS_JSON="${RESULTS_JSON},"
            fi
            RESULTS_JSON="${RESULTS_JSON}\"${db}\":\"${DB_STATUS}\""

          done

          RESULTS_JSON="${RESULTS_JSON}}"
          echo "results_json=${RESULTS_JSON}" >> $GITHUB_OUTPUT
          echo ""
          echo "=============================================="
          echo "All database suites complete for ${{ matrix.cfengine }}"
          echo "Results: ${RESULTS_JSON}"
          echo "=============================================="

          # Exit with failure if any database failed, but after running ALL databases
          if [ "$OVERALL_STATUS" -ne 0 ]; then
            echo "One or more database suites failed"
            exit 1
          fi

      - name: Generate per-engine summary
        if: always()
        run: |
          echo "### ${{ matrix.cfengine }} Test Results" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Database | Result |" >> $GITHUB_STEP_SUMMARY
          echo "|----------|--------|" >> $GITHUB_STEP_SUMMARY

          IFS=',' read -ra DBS <<< "${{ steps.db-list.outputs.databases }}"
          for db in "${DBS[@]}"; do
            RESULT_FILE="/tmp/test-results/${{ matrix.cfengine }}-${db}-result.txt"
            if [ -f "$RESULT_FILE" ]; then
              # Check JSON for failures
              FAIL_COUNT=$(python3 -c "
          import json, sys
          try:
              d = json.load(open('$RESULT_FILE'))
              print(d.get('totalFail', 0) + d.get('totalError', 0))
          except:
              print(-1)
          " 2>/dev/null || echo "-1")

              if [ "$FAIL_COUNT" = "0" ]; then
                echo "| ${db} | :white_check_mark: Pass |" >> $GITHUB_STEP_SUMMARY
              elif [ "$FAIL_COUNT" = "-1" ]; then
                echo "| ${db} | :warning: Error |" >> $GITHUB_STEP_SUMMARY
              else
                echo "| ${db} | :x: ${FAIL_COUNT} failures |" >> $GITHUB_STEP_SUMMARY
              fi
            else
              echo "| ${db} | :grey_question: No result |" >> $GITHUB_STEP_SUMMARY
            fi
          done

      - name: Debug information
        if: failure()
        run: |
          echo "=== Docker Container Status ==="
          docker ps -a

          echo -e "\n=== CF Engine Logs ==="
          docker logs $(docker ps -aq -f "name=${{ matrix.cfengine }}") 2>&1 | tail -100 || echo "Could not get logs"

          echo -e "\n=== Database Container Logs ==="
          for container in mysql postgres sqlserver oracle; do
            if docker ps -aq -f "name=${container}" | grep -q .; then
              echo "--- ${container} ---"
              docker logs $(docker ps -aq -f "name=${container}") 2>&1 | tail -30 || true
            fi
          done

      - name: Upload test result artifacts
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results-${{ matrix.cfengine }}
          path: /tmp/test-results/

      - name: Upload JUnit XML artifacts
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: junit-${{ matrix.cfengine }}
          path: /tmp/junit-results/

  #############################################
  # Publish Test Results to PR
  #############################################
  publish-results:
    name: Publish Test Results
    needs: tests
    if: always()
    runs-on: ubuntu-latest
    permissions:
      checks: write
      pull-requests: write
    steps:
      - name: Download JUnit artifacts
        uses: actions/download-artifact@v4
        with:
          pattern: junit-*
          path: junit-results/

      - name: Publish Unit Test Results
        uses: EnricoMi/publish-unit-test-result-action@v2
        with:
          files: junit-results/**/*.xml
          check_name: "Wheels Test Results"
          comment_title: "Wheels Test Results"
          report_individual_runs: true

  #############################################
  # Test Matrix Summary Grid
  #############################################
  test-matrix-summary:
    name: Test Matrix Summary
    needs: tests
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Download all test result artifacts
        uses: actions/download-artifact@v4
        with:
          pattern: test-results-*
          path: results/

      - name: Generate matrix grid
        run: |
          cat >> $GITHUB_STEP_SUMMARY << 'HEADER'
          ## Wheels Test Matrix

          | Engine | MySQL | PostgreSQL | SQL Server | H2 | Oracle | SQLite |
          |--------|:-----:|:----------:|:----------:|:--:|:------:|:------:|
          HEADER

          for engine in lucee5 lucee6 lucee7 adobe2018 adobe2021 adobe2023 adobe2025 boxlang; do
            ROW="| **${engine}** |"
            for db in mysql postgres sqlserver h2 oracle sqlite; do
              FILE="results/test-results-${engine}/${engine}-${db}-result.txt"
              if [ -f "$FILE" ]; then
                FAIL=$(python3 -c "
          import json, sys
          try:
              d = json.load(open('$FILE'))
              print(d.get('totalFail', 0) + d.get('totalError', 0))
          except:
              print(-1)
          " 2>/dev/null || echo "-1")
                if [ "$FAIL" = "0" ]; then
                  ROW="${ROW} :white_check_mark: |"
                elif [ "$FAIL" = "-1" ]; then
                  ROW="${ROW} :warning: |"
                else
                  ROW="${ROW} :x: |"
                fi
              else
                ROW="${ROW} -- |"
              fi
            done
            echo "$ROW" >> $GITHUB_STEP_SUMMARY
          done
```

**Important notes for the implementer:**
- The `reload=true` parameter is appended to the FIRST test request for each database. This triggers a full Wheels reinit (clears `application.wheels.models` cache). The Wheels app already handles `?reload=true` natively — no runner.cfm changes needed.
- The test loop continues even if one database fails (`OVERALL_STATUS` tracks failures, `exit 1` only after all databases run).
- JUnit XML is generated by converting the JSON result locally with Python — NOT by making a second HTTP request. The Wheels test runner (runner.cfm) does NOT cache results between requests; a `format=junit` request would re-execute the entire test suite, doubling execution time.
- Test URLs use `format=json` WITHOUT `only=failure,error`. The `only` parameter produces formatted text output (not parseable JSON), so we fetch the full clean JSON and parse it ourselves.
- Oracle health check uses `sqlplus` inside the container instead of the previous hardcoded `sleep 120`.
- The `commandbox_version` and `jdkVersion` matrix parameters from the old workflow were only used in the include blocks — they're no longer needed since we're not doing cross-product.

- [ ] **Step 1: Write the complete new tests.yml file**

Use the YAML above as the complete file content. Verify the YAML is valid.

- [ ] **Step 2: Verify YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/tests.yml'))"`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/tests.yml
git commit -m "ci: restructure test matrix from 42 jobs to 8 engine-grouped jobs

Replaces cfengine x dbengine matrix (42 jobs) with cfengine-only matrix (8 jobs).
Each job starts one CF engine + all databases, runs test suites sequentially.

Key changes:
- CF engine starts once per job instead of 6x (saves 5 startups per engine)
- CFPM install runs once per Adobe engine instead of 6x (saves ~50 min compute)
- Oracle sleep 120 replaced with sqlplus health check loop
- All databases start in parallel during engine warmup
- Tests continue after individual database failures (all DBs always run)
- JUnit XML output uploaded for each engine-database pair
- Summary jobs render engine x database grid on workflow run page
- PR annotations via EnricoMi/publish-unit-test-result-action

Total compute reduction: ~75% (from ~840 min to ~200 min)"
```

---

## Chunk 3: Caller Workflow Permissions & Verification

### Task 5: Add permissions to pr.yml

**Files:**
- Modify: `.github/workflows/pr.yml`

The `publish-results` job in tests.yml needs `checks: write` and `pull-requests: write`. Since tests.yml is a reusable workflow called by pr.yml, the caller must grant these permissions at the **workflow level**. GitHub Actions does NOT allow `permissions` on a job that uses `uses:` (workflow_call) — only workflow-level permissions are inherited by reusable workflows.

- [ ] **Step 1: Add workflow-level permissions to pr.yml**

Add a top-level `permissions` block. Do NOT add `permissions` to the `tests:` job (invalid on `uses:` jobs):

```yaml
name: Wheels Pull Requests

on:
  pull_request:
    branches:
      - develop

permissions:
  contents: read
  pull-requests: write
  checks: write

jobs:
  label:
    name: Auto-Label PR
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/labeler@v5
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}

  tests:
    uses: ./.github/workflows/tests.yml
    secrets:
      SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/pr.yml
git commit -m "ci: add checks and pull-requests write permissions for test reporting

Required by EnricoMi/publish-unit-test-result-action to post test
result annotations and PR comments."
```

### Task 6: Add permissions to snapshot.yml

**Files:**
- Modify: `.github/workflows/snapshot.yml`

Same as pr.yml — add workflow-level permissions. Do NOT add `permissions` to the `tests:` job.

- [ ] **Step 1: Add workflow-level permissions to snapshot.yml**

Add a top-level `permissions` block (between `on:` and `env:`):

```yaml
name: Wheels Snapshots

on:
  push:
    branches:
      - develop

permissions:
  contents: read
  checks: write
  pull-requests: write

env:
  WHEELS_PRERELEASE: true

jobs:
  tests:
    uses: ./.github/workflows/tests.yml
    secrets:
      SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/snapshot.yml
git commit -m "ci: add permissions to snapshot workflow for test reporting"
```

### Task 7: Verify complete workflow with dry-run analysis

- [ ] **Step 1: Validate all YAML files**

```bash
for f in .github/workflows/tests.yml .github/workflows/pr.yml .github/workflows/snapshot.yml; do
  echo "Validating $f..."
  python3 -c "import yaml; yaml.safe_load(open('$f')); print('  OK')"
done
```

- [ ] **Step 2: Review the database exclusion logic**

Verify that the `db-list` step correctly handles exclusions:

| Engine | Expected databases |
|--------|-------------------|
| lucee5 | mysql,postgres,sqlserver,h2,oracle,sqlite |
| lucee6 | mysql,postgres,sqlserver,h2,oracle,sqlite |
| lucee7 | mysql,postgres,sqlserver,h2,oracle,sqlite |
| adobe2018 | mysql,postgres,sqlserver,oracle |
| adobe2021 | mysql,postgres,sqlserver,oracle,sqlite |
| adobe2023 | mysql,postgres,sqlserver,oracle,sqlite |
| adobe2025 | mysql,postgres,sqlserver,oracle,sqlite |
| boxlang | mysql,postgres,sqlserver,oracle,sqlite |

- [ ] **Step 3: Push branch and create PR**

```bash
git push -u origin peter/ci-engine-grouped-testing
gh pr create --title "Optimize CI: engine-grouped testing (42 jobs → 8)" --body "..."
```

- [ ] **Step 4: Monitor first CI run**

Watch the PR's Actions tab. Key things to verify:
1. Each of the 8 engine jobs starts correctly
2. All databases start within the engine job
3. The `reload=true` parameter successfully clears model cache between DB switches
4. Oracle health check loop works (no hardcoded sleep)
5. JUnit XML artifacts are uploaded
6. The `publish-results` job creates a test results check on the PR
7. The `test-matrix-summary` job renders the engine x database grid

---

## Chunk 4: Troubleshooting Guide

### Known Risks & Mitigations

**Risk 1: Memory pressure with all DBs running simultaneously**
- Mitigation: Reduced SQL Server (4G→2G) and Oracle (2G→1.5G). Total ~5.8GB fits in 7GB runner.
- If OOM: Further reduce SQL Server to 1.5G, or start databases in waves (lightweight first, then heavy).

**Risk 2: JUnit XML conversion fidelity**
- JUnit XML is generated by converting JSON results locally with Python (not via a second HTTP request, which would re-run all tests).
- The conversion handles `Failed`, `Error`, and `Skipped` statuses. If the JSON schema changes in future TestBox versions, the conversion may need updating.
- If `EnricoMi/publish-unit-test-result-action` reports parsing errors, check the generated XML files in the `junit-*` artifacts.

**Risk 3: Oracle container name is `wheels-oracle-1` not just `oracle`**
- Docker Compose names containers as `<project>-<service>-<number>`. In CI the project defaults to the directory name (`wheels`).
- The health check uses `docker exec wheels-oracle-1 sqlplus ...`. Verify this matches.

**Risk 4: `reload=true` adds significant time per database switch**
- A Wheels reinit typically takes 5-15 seconds depending on engine.
- With 6 databases: 5 switches x ~10s = ~50s overhead. Acceptable.
- If it's too slow, switch to calling `$clearModelInitializationCache()` directly (requires runner.cfm change).

**Risk 5: Tests leave state that affects subsequent database runs**
- The test runner resets `application.wheels` from backup after each run (runner.cfm:218).
- Each database gets its own `populate.cfm` run that drops/recreates all test tables.
- Risk is low, but if we see cross-database contamination, add explicit cleanup between runs.

---

## Summary of Changes

| File | Lines Changed | Nature |
|------|--------------|--------|
| `compose.yml` | ~15 | Memory reduction + BoxLang volumes |
| `.github/workflows/tests.yml` | ~300 (full rewrite) | Engine-grouped matrix + summary jobs |
| `.github/workflows/pr.yml` | ~8 | Add permissions |
| `.github/workflows/snapshot.yml` | ~4 | Add permissions |

**Total: 4 files, ~327 lines changed**

No changes to the Wheels framework source code (`vendor/wheels/`). The `?reload=true` URL parameter already works natively.
