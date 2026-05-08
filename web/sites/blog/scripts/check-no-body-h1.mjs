#!/usr/bin/env node
// Build-time guard for issue #2436: blog posts must not contain a
// top-level (`# ...`) heading inside their body.
//
// PostLayout.astro auto-renders an `<h1>{data.title}</h1>` from the
// frontmatter title on every post. Any body H1 produces a second H1
// on the rendered page, which hurts SEO (multiple H1s on one page)
// and reads as a structural mistake in the document outline.
//
// This script scans every post under web/content/blog/posts/, ignores
// `#`-prefixed lines inside fenced code blocks (``` or ~~~), and exits
// non-zero if any real body H1 is found. Wire into CI alongside
// `pnpm --filter @wheels-dev/site-blog build`.
//
// Run from repo root or from web/sites/blog/. Resolves the posts dir
// relative to this script's location.

import { readdirSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const postsDir = resolve(here, '../../../content/blog/posts');

function bodyH1Count(text) {
	const m = text.match(/^---\n[\s\S]*?\n---\n([\s\S]*)$/);
	const body = m ? m[1] : text;
	let inFence = false;
	let fenceMarker = null;
	let count = 0;
	for (const line of body.split('\n')) {
		const stripped = line.replace(/\s+$/, '');
		if (!inFence) {
			if (/^```/.test(stripped) || /^~~~/.test(stripped)) {
				inFence = true;
				fenceMarker = stripped.slice(0, 3);
				continue;
			}
			if (/^# /.test(line)) {
				count++;
			}
		} else if (stripped.startsWith(fenceMarker)) {
			inFence = false;
		}
	}
	return count;
}

const offenders = [];
for (const name of readdirSync(postsDir).sort()) {
	if (!name.endsWith('.md')) continue;
	const path = join(postsDir, name);
	const text = readFileSync(path, 'utf8');
	const n = bodyH1Count(text);
	if (n > 0) offenders.push({ name, count: n });
}

if (offenders.length === 0) {
	console.log(`✓ ${readdirSync(postsDir).filter((n) => n.endsWith('.md')).length} blog posts: no body H1s.`);
	process.exit(0);
}

console.error('Body H1 violations found (issue #2436):');
console.error('PostLayout already renders an H1 from frontmatter; body H1s create duplicates.');
console.error('Downgrade body H1s to H2 (and shift nested levels accordingly), or remove a leading H1 that just repeats the title.');
console.error('');
for (const { name, count } of offenders) {
	console.error(`  ${name}: ${count} body H1${count === 1 ? '' : 's'}`);
}
process.exit(1);
