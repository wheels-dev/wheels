import { readFile } from 'node:fs/promises';

const FENCE_RE = /^```(\w+)([^\n]*)\n([\s\S]*?)\n```$/gm;

function parseMeta(meta) {
  const m = meta.match(/\{test:(\w+)\s*([^}]*)\}/);
  if (!m) return null;
  const kind = m[1];
  const rest = m[2].trim();
  const attrs = {};
  const ATTR_RE = /(\w[\w-]*)=(?:"([^"]*)"|(\S+))/g;
  let am;
  while ((am = ATTR_RE.exec(rest)) !== null) {
    attrs[am[1]] = am[2] !== undefined ? am[2] : am[3];
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

export async function extractExamples(files) {
  const out = [];
  for (const file of files) {
    const content = await readFile(file, 'utf8');
    FENCE_RE.lastIndex = 0;
    let m;
    while ((m = FENCE_RE.exec(content)) !== null) {
      const [, language, meta, body] = m;
      const parsed = parseMeta(meta);
      if (!parsed) continue;
      out.push({
        file,
        line: lineAt(content, m.index),
        language,
        kind: parsed.kind,
        attrs: parsed.attrs,
        body,
      });
    }
  }
  return out;
}
