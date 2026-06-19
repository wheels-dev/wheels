import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';

/**
 * Expected-failure allowlist for verify-docs.
 *
 * File shape (scripts/verify-docs/expected-failures.json by default;
 * override with VERIFY_DOCS_ALLOWLIST):
 *
 *   {
 *     "entries": [
 *       {
 *         "file": "src/content/docs/v4-0-0/basics/routing.mdx",
 *         "bodySha256": "0123abcd4567",
 *         "reason": "why this block is allowed to fail",
 *         "issue": "#3041"
 *       }
 *     ]
 *   }
 *
 * Matching is (file path suffix) AND (first 12 hex chars of the sha256 of
 * the block body). Keying on the body hash instead of a line number keeps
 * entries stable across unrelated edits to the same page, and forces
 * re-verification the moment the block content changes. The harness prints
 * the hash for every failing block so entries are copy-pasteable.
 *
 * `reason` (non-empty) and `issue` (#NNNN or a GitHub issue/PR URL) are
 * mandatory so every masked failure stays attributable.
 */

const ISSUE_RE = /^(#\d+|https:\/\/github\.com\/[^\s]+\/(issues|pull)\/\d+)$/;

export function bodyHash(body) {
  return createHash('sha256').update(body, 'utf8').digest('hex').slice(0, 12);
}

export async function loadAllowlist(file) {
  let raw;
  try {
    raw = await readFile(file, 'utf8');
  } catch (err) {
    if (err.code === 'ENOENT') return [];
    throw err;
  }
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (err) {
    throw new Error(`allowlist ${file}: invalid JSON — ${err.message}`);
  }
  if (!parsed || !Array.isArray(parsed.entries)) {
    throw new Error(`allowlist ${file}: top-level "entries" must be an array`);
  }
  parsed.entries.forEach((entry, idx) => {
    const at = `allowlist ${file} entry ${idx + 1}`;
    if (typeof entry.file !== 'string' || entry.file.trim() === '') {
      throw new Error(`${at}: "file" is required`);
    }
    if (typeof entry.bodySha256 !== 'string' || !/^[0-9a-f]{12}$/.test(entry.bodySha256)) {
      throw new Error(`${at}: "bodySha256" must be the first 12 hex chars of the body sha256`);
    }
    if (typeof entry.reason !== 'string' || entry.reason.trim() === '') {
      throw new Error(`${at}: "reason" is required and must be non-empty`);
    }
    if (typeof entry.issue !== 'string' || !ISSUE_RE.test(entry.issue)) {
      throw new Error(`${at}: "issue" must be "#NNNN" or a GitHub issue/PR URL`);
    }
  });
  return parsed.entries;
}

function matches(entry, result) {
  const hash = result.bodyHash ?? (typeof result.body === 'string' ? bodyHash(result.body) : undefined);
  if (hash !== entry.bodySha256) return false;
  const f = result.file.replace(/\\/g, '/');
  const e = entry.file.replace(/\\/g, '/');
  return f === e || f.endsWith(`/${e}`);
}

/**
 * Annotates failing results that match an allowlist entry with
 * `expected: true` (and the entry itself as `allowlistEntry`). Returns
 * `{ warnings }`:
 *   - an entry matching a PASSING block → stale-entry warning
 *   - an entry matching no block at all → orphan warning (only when
 *     `checkOrphans` is set — partial-tree runs would false-positive)
 */
export function applyAllowlist(results, entries, { checkOrphans = false } = {}) {
  const warnings = [];
  for (const entry of entries) {
    const hits = results.filter((r) => matches(entry, r));
    if (hits.length === 0) {
      if (checkOrphans) {
        warnings.push(
          `allowlist entry for ${entry.file} (${entry.bodySha256}) matched no block — remove it or update bodySha256`,
        );
      }
      continue;
    }
    for (const hit of hits) {
      if (hit.ok) {
        warnings.push(
          `allowlist entry for ${entry.file} (${entry.bodySha256}) now passes — remove it (reason was: ${entry.reason})`,
        );
      } else {
        hit.expected = true;
        hit.allowlistEntry = entry;
      }
    }
  }
  return { warnings };
}
