/**
 * Pretty-prints harness results. Returns the count of failures so the
 * entrypoint can exit with a non-zero status.
 */
export function printReport(results) {
  let pass = 0;
  let fail = 0;
  const failures = [];
  for (const r of results) {
    if (r.ok) pass++;
    else {
      fail++;
      failures.push(r);
    }
  }
  if (fail > 0) {
    console.log('\n--- Failures ---');
    for (const f of failures) {
      console.log(`\n[${f.kind}] ${f.file}:${f.line}`);
      console.log(f.message);
    }
  }
  console.log(`\n${pass} passed, ${fail} failed`);
  return fail;
}
