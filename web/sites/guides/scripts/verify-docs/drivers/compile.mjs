import { runExec } from '../lib/exec.mjs';

// Cache the *promise*, not the resolved value, so concurrent callers
// (e.g. Promise.all over many compile blocks) share one probe.
let _modePromise = null;

export function detectMode() {
  if (_modePromise) return _modePromise;
  _modePromise = runExec('wheels', ['cfml', 'throw(message="probe")'])
    .then((probe) => (probe.code === 0 ? 'fallback' : 'native'));
  return _modePromise;
}

function balanced(body) {
  const pairs = { '(': ')', '{': '}', '[': ']' };
  const closers = new Set(Object.values(pairs));
  const stack = [];
  let inStr = false;
  let strCh = '';
  let inLineComment = false;
  let inBlockComment = false;
  for (let i = 0; i < body.length; i++) {
    const c = body[i];
    const nx = body[i + 1];
    if (inLineComment) {
      if (c === '\n') inLineComment = false;
      continue;
    }
    if (inBlockComment) {
      if (c === '*' && nx === '/') { inBlockComment = false; i++; }
      continue;
    }
    if (inStr) {
      if (c === '\\') { i++; continue; }
      if (c === strCh) inStr = false;
      continue;
    }
    if (c === '"' || c === "'") { inStr = true; strCh = c; continue; }
    if (c === '/' && nx === '/') { inLineComment = true; i++; continue; }
    if (c === '/' && nx === '*') { inBlockComment = true; i++; continue; }
    if (pairs[c]) stack.push(pairs[c]);
    else if (closers.has(c)) {
      if (stack.pop() !== c) return false;
    }
  }
  return stack.length === 0;
}

async function runNative(body) {
  const direct = await runExec('wheels', ['cfml', body]);
  if (direct.code === 0) return { ok: true };
  return {
    ok: false,
    message: `wheels cfml exited ${direct.code}\n--- stderr ---\n${direct.stderr}\n--- stdout ---\n${direct.stdout}`,
  };
}

function runFallback(body) {
  if (!balanced(body)) {
    return { ok: false, message: 'fallback: unbalanced brackets/braces/parens' };
  }
  return { ok: true };
}

export async function runCompile(example) {
  const mode = await detectMode();
  if (mode === 'native') return await runNative(example.body);
  return runFallback(example.body);
}
