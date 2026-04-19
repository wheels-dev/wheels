import { readFile } from 'node:fs/promises';

const FM_RE = /^---\n([\s\S]*?)\n---/;
const ORDER_RE = /sidebar:\s*\n\s*order:\s*(\d+)/;

export async function readSidebarOrder(file) {
  let content;
  try {
    content = await readFile(file, 'utf8');
  } catch {
    return 999;
  }
  const fm = content.match(FM_RE);
  if (!fm) return 999;
  const ord = fm[1].match(ORDER_RE);
  if (!ord) return 999;
  return Number(ord[1]);
}

export async function enrichWithSidebarOrder(examples) {
  const cache = new Map();
  for (const ex of examples) {
    if (!cache.has(ex.file)) {
      cache.set(ex.file, await readSidebarOrder(ex.file));
    }
    ex.sidebarOrder = cache.get(ex.file);
  }
  return examples;
}

export function partitionAndOrder(examples) {
  const cumulative = [];
  const perBlock = [];
  for (const ex of examples) {
    const step = ex.attrs.step;
    if (ex.kind === 'tutorial' || (ex.kind === 'cli' && step !== undefined)) {
      cumulative.push(ex);
    } else {
      perBlock.push(ex);
    }
  }
  cumulative.sort((a, b) => {
    const so = (a.sidebarOrder ?? 999) - (b.sidebarOrder ?? 999);
    if (so !== 0) return so;
    const sa = Number(a.attrs.step ?? 0);
    const sb = Number(b.attrs.step ?? 0);
    if (sa !== sb) return sa - sb;
    return a.line - b.line;
  });
  perBlock.sort((a, b) => {
    const so = (a.sidebarOrder ?? 999) - (b.sidebarOrder ?? 999);
    if (so !== 0) return so;
    return a.line - b.line;
  });
  return { perBlock, cumulative };
}
