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

/**
 * Skips leading whitespace and comments (script `//` and starred blocks plus
 * CFML tag comments) so wrap-kind sniffing sees the first meaningful token.
 */
function skipLeadingTrivia(body) {
  let i = 0;
  for (;;) {
    while (i < body.length && /\s/.test(body[i])) i++;
    if (body.startsWith('//', i)) {
      const nl = body.indexOf('\n', i);
      if (nl === -1) return '';
      i = nl + 1;
    } else if (body.startsWith('/*', i)) {
      const end = body.indexOf('*/', i + 2);
      if (end === -1) return body.slice(i); // unterminated — let the engine complain
      i = end + 2;
    } else if (body.startsWith('<!---', i)) {
      const end = body.indexOf('--->', i + 5);
      if (end === -1) return body.slice(i);
      i = end + 4;
    } else {
      return body.slice(i);
    }
  }
}

/**
 * Classifies a `{test:compile}` body into one of the three wrap kinds the
 * native driver knows how to parse-check:
 *
 *   component — script-syntax `component` / `interface` declaration(s)
 *   tag       — tag/template syntax (starts with `<` after comments)
 *   script    — everything else: config fragments, spec fragments, plain script
 */
export function sniffKind(body) {
  const rest = skipLeadingTrivia(body);
  if (rest.startsWith('<')) return 'tag';
  if (/^(abstract\s+|final\s+)*(component|interface)\b/i.test(rest)) return 'component';
  return 'script';
}

/**
 * Finds top-level script-syntax `component` / `interface` declarations and
 * returns their inner bodies (the text between the outermost braces).
 * Comment- and string-aware; CFML strings escape quotes by doubling them.
 * Returns null if a declaration's braces never close.
 */
function extractDeclarationInners(body) {
  const inners = [];
  let i = 0;
  let depth = 0;
  let pendingDecl = false;
  let blockStart = -1;
  let blockDepth = 0;
  const isWord = (c) => /[A-Za-z0-9_$]/.test(c || '');
  while (i < body.length) {
    const c = body[i];
    const nx = body[i + 1];
    // comments
    if (c === '/' && nx === '/') {
      const nl = body.indexOf('\n', i);
      i = nl === -1 ? body.length : nl + 1;
      continue;
    }
    if (c === '/' && nx === '*') {
      const end = body.indexOf('*/', i + 2);
      i = end === -1 ? body.length : end + 2;
      continue;
    }
    if (body.startsWith('<!---', i)) {
      const end = body.indexOf('--->', i + 5);
      i = end === -1 ? body.length : end + 4;
      continue;
    }
    // strings (CFML escapes quotes by doubling)
    if (c === '"' || c === "'") {
      let j = i + 1;
      while (j < body.length) {
        if (body[j] === c) {
          if (body[j + 1] === c) { j += 2; continue; }
          break;
        }
        j++;
      }
      i = j + 1;
      continue;
    }
    if (c === '{') {
      if (pendingDecl && blockStart === -1) {
        blockStart = i + 1;
        blockDepth = depth;
        pendingDecl = false;
      }
      depth++;
      i++;
      continue;
    }
    if (c === '}') {
      depth--;
      if (blockStart !== -1 && depth === blockDepth) {
        inners.push(body.slice(blockStart, i));
        blockStart = -1;
      }
      i++;
      continue;
    }
    // keyword detection at top level, outside any declaration block
    if (depth === 0 && blockStart === -1 && isWord(c) && !isWord(body[i - 1])) {
      const m = body.slice(i).match(/^(component|interface)\b/i);
      if (m) {
        pendingDecl = true;
        i += m[0].length;
        continue;
      }
      while (i < body.length && isWord(body[i])) i++;
      continue;
    }
    i++;
  }
  if (blockStart !== -1 || pendingDecl) return null; // unbalanced / no body
  return inners;
}

/**
 * `property name="x" ...;` declarations are only legal at component top
 * level — inside the function shell they would be false parse errors.
 * Zero live-tree blocks use them today; neutralize defensively.
 */
function neutralizeComponentOnlyStatements(inner) {
  return inner.replace(
    /^([ \t]*)property\b[^;\n]*;?[ \t]*$/gim,
    '$1// [verify-docs] property declaration neutralized for parse check',
  );
}

/**
 * Builds the exact CFML program handed to `wheels cfml` for a block body.
 * The contract is PARSE/COMPILE, never execute:
 *
 *   script    — body becomes the body of a function that is declared but
 *               never invoked. The engine compiles the whole script before
 *               executing, so syntax errors fail while undefined framework
 *               functions (set, mapper, describe, ...) never resolve.
 *   component — `component X {...}` cannot be evaluated inline and the
 *               script engine has no component-path context to load a .cfc
 *               from disk (getComponentMetadata/new both die on
 *               "searchLocal is null"). Instead the declaration header is
 *               stripped and each declaration's inner body is wrapped in its
 *               own never-invoked function shell. Limitation: typos in the
 *               header itself (e.g. extends targets) are not checked.
 *   tag       — the engine wraps inline code in <cfscript>...</cfscript>.
 *               Tag bodies therefore close that wrapper, emit the body
 *               inside <cfif false> (compiled, never executed), and reopen
 *               a trailing <cfscript> to balance the engine's suffix.
 *
 * Returns { kind, program } or { kind, error } when the body cannot be
 * wrapped (e.g. unbalanced component braces).
 */
export function buildNativeProgram(body) {
  const kind = sniffKind(body);
  if (kind === 'tag') {
    return { kind, program: `</cfscript><cfif false>\n${body}\n</cfif><cfscript>` };
  }
  if (kind === 'component') {
    const inners = extractDeclarationInners(body);
    if (inners === null) {
      return { kind, error: 'component/interface declaration has unbalanced braces or no body' };
    }
    if (inners.length === 0) {
      return { kind, error: 'no component/interface declaration found' };
    }
    const program = inners
      .map((inner, idx) => `function __verifyDocsComponent${idx + 1}__() {\n${neutralizeComponentOnlyStatements(inner)}\n}`)
      .join('\n');
    return { kind, program };
  }
  return { kind, program: `function __verifyDocsSnippet__() {\n${body}\n}` };
}

async function runNative(body) {
  const { kind, program, error } = buildNativeProgram(body);
  if (error) {
    return { ok: false, message: `native(${kind}): ${error}` };
  }
  const direct = await runExec('wheels', ['cfml', program]);
  if (direct.code === 0) return { ok: true };
  return {
    ok: false,
    message:
      `native(${kind} wrap): wheels cfml exited ${direct.code}\n` +
      `--- stderr ---\n${direct.stderr}\n--- stdout ---\n${direct.stdout}`,
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
