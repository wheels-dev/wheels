import { readFile } from 'node:fs/promises';

// Fence regex: optional leading whitespace (capture in group 1), opening ```<lang>
// followed by meta, newline, body, newline, and closing fence at the same indent.
// The backreference \1 ensures we don't cross fence boundaries when fences are
// at different indent levels.
const FENCE_RE = /^([ \t]*)```(\w+)([^\n]*)\n([\s\S]*?)\n\1```$/gm;

function parseMeta(meta) {
  const m = meta.match(/\{test:(\w+)\s*([^}]*)\}/);
  if (!m) return null;
  const kind = m[1];
  const rest = m[2].trim();
  const attrs = {};
  // Value forms:
  //   "..."  — quoted; supports backslash escapes for quotes and backslashes
  //   bare   — non-whitespace run
  const ATTR_RE = /(\w[\w-]*)=(?:"((?:\\.|[^"\\])*)"|(\S+))/g;
  let am;
  while ((am = ATTR_RE.exec(rest)) !== null) {
    const raw = am[2] !== undefined ? am[2] : am[3];
    attrs[am[1]] = am[2] !== undefined ? raw.replace(/\\(["\\])/g, '$1') : raw;
  }
  return { kind, attrs };
}

function lineAt(content, offset) {
  let line = 1;
  for (let i = 0; i < offset && i < content.length; i++) {
    if (content.charCodeAt(i) === 10) line++;
  }
  return line;
}

/**
 * Strips the fence's leading indent from every line of the body.
 * Lines that don't start with the indent (e.g., blank lines with no leading
 * whitespace) are left alone — MDX allows this inside a list-item fence.
 */
function stripIndent(body, indent) {
  if (indent === '') return body;
  return body
    .split('\n')
    .map((line) => (line.startsWith(indent) ? line.slice(indent.length) : line))
    .join('\n');
}

export async function extractExamples(files) {
  const out = [];
  for (const file of files) {
    const content = await readFile(file, 'utf8');
    FENCE_RE.lastIndex = 0;
    let m;
    while ((m = FENCE_RE.exec(content)) !== null) {
      const [, indent, language, meta, rawBody] = m;
      const parsed = parseMeta(meta);
      if (!parsed) continue;
      out.push({
        file,
        line: lineAt(content, m.index),
        language,
        kind: parsed.kind,
        attrs: parsed.attrs,
        body: stripIndent(rawBody, indent),
      });
    }
  }
  return out;
}
