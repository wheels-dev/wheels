/**
 * Pretty-prints harness results. Returns the count of HARD failures (i.e.
 * excluding allowlisted expected failures) so the entrypoint can exit with
 * a non-zero status.
 */
export function printReport(results, warnings = []) {
  let pass = 0;
  let fail = 0;
  const failures = [];
  const expected = [];
  for (const r of results) {
    if (r.ok) pass++;
    else if (r.expected) expected.push(r);
    else {
      fail++;
      failures.push(r);
    }
  }
  if (fail > 0) {
    console.log('\n--- Failures ---');
    for (const f of failures) {
      console.log(`\n[${f.kind}] ${f.file}:${f.line}${f.bodyHash ? ` (body-sha256: ${f.bodyHash})` : ''}`);
      console.log(f.message);
    }
  }
  if (expected.length > 0) {
    console.log('\n--- Expected failures (allowlisted) ---');
    for (const f of expected) {
      const e = f.allowlistEntry;
      console.log(`[${f.kind}] ${f.file}:${f.line} — ${e.reason} (${e.issue})`);
    }
  }
  if (warnings.length > 0) {
    console.log('\n--- Allowlist warnings ---');
    for (const w of warnings) console.log(`! ${w}`);
  }
  const expectedNote = expected.length > 0 ? `, ${expected.length} expected failure(s)` : '';
  console.log(`\n${pass} passed, ${fail} failed${expectedNote}`);
  return fail;
}
