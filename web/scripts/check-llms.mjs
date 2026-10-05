#!/usr/bin/env node
/**
 * Checks a built guides or API site's llms files (see packages/ui/src/data/llms.ts):
 *
 * - llms.txt, llms-full.txt and llms-small.txt exist and aren't empty;
 * - every link in llms.txt to this site resolves to a built file;
 * - llms-full.txt and llms-small.txt hold only the CURRENT version's pages (the `current` entry in
 *   packages/ui/src/data/versions.ts): a page from any other version fails the check;
 * - every built docs page has its .md, and every .md has its page.
 *
 *   node scripts/check-llms.mjs <dist dir> <guides|api>
 *
 * Exits 1 and lists every problem when a check fails.
 */
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const ORIGINS = { guides: 'https://guides.wheels.dev', api: 'https://api.wheels.dev' };
const LISTS = { guides: 'GUIDES_VERSIONS', api: 'API_VERSIONS' };

/** The version slugs and the current one, read from versions.ts (same parse as build-docs.sh). */
export function readVersions(versionsSource, site) {
	const block = versionsSource.match(
		new RegExp(`${LISTS[site]}[\\s\\S]*?=\\s*\\[([\\s\\S]*?)\\];`)
	);
	if (!block) throw new Error(`versions.ts has no ${LISTS[site]} list`);
	const entries = [...block[1].matchAll(/\{[^}]*\}/g)].map((m) => m[0]);
	const slugs = entries.map((e) => /slug:\s*'([^']+)'/.exec(e)?.[1]).filter(Boolean);
	const current = entries.find((e) => /status:\s*'current'/.test(e));
	const currentSlug = current && /slug:\s*'([^']+)'/.exec(current)?.[1];
	if (!currentSlug) throw new Error(`${LISTS[site]} has no 'current' entry`);
	return { slugs, currentSlug };
}

function walk(dir) {
	const out = [];
	for (const name of readdirSync(dir)) {
		const path = join(dir, name);
		if (statSync(path).isDirectory()) out.push(...walk(path));
		else out.push(path);
	}
	return out;
}

/** The version slug a URL path under the site origin belongs to ("" when none). */
function slugOfPath(path, slugs) {
	const first = path.replace(/^\/+/, '').split('/')[0].replace(/\.md$/, '');
	return slugs.includes(first) ? first : '';
}

export function checkLlms({ distDir, site, slugs, currentSlug }) {
	const errors = [];
	const origin = ORIGINS[site];
	const read = (name) => {
		const path = join(distDir, name);
		if (!existsSync(path)) {
			errors.push(`${name} is missing`);
			return '';
		}
		const text = readFileSync(path, 'utf8');
		if (!text.trim()) errors.push(`${name} is empty`);
		return text;
	};
	const index = read('llms.txt');
	const full = read('llms-full.txt');
	const small = read('llms-small.txt');

	// Every link in llms.txt to this site resolves to a built file.
	for (const [, url] of index.matchAll(/\]\((https?:[^)\s]+)\)/g)) {
		if (!url.startsWith(origin + '/')) continue;
		const path = url.slice(origin.length);
		const file = path.endsWith('/') ? join(distDir, path, 'index.html') : join(distDir, path);
		if (!existsSync(file)) errors.push(`llms.txt links to ${url}, which isn't in the build`);
	}

	// llms-full.txt and llms-small.txt hold only the current version.
	const pagesIn = (text, pattern) => [...text.matchAll(pattern)].map((m) => m[1]);
	const fullPages = pagesIn(full, new RegExp(`^Source: ${origin}(/[^\\s]*)`, 'gm'));
	const smallPages = pagesIn(small, new RegExp(`\\]\\(${origin}(/[^)\\s]+\\.md)\\)`, 'g'));
	for (const [name, pages] of [
		['llms-full.txt', fullPages],
		['llms-small.txt', smallPages],
	]) {
		if (!pages.length && errors.every((e) => !e.startsWith(name)))
			errors.push(`${name} lists no pages`);
		for (const page of pages) {
			const slug = slugOfPath(page, slugs);
			if (slug !== currentSlug) {
				errors.push(`${name} includes ${page}, which isn't the current version (${currentSlug})`);
			}
		}
	}

	// Every built docs page has its .md, and every .md its page. Redirect stubs (a meta refresh) have no page of their own.
	for (const file of walk(distDir)) {
		const rel = relative(distDir, file).split(sep).join('/');
		if (!slugs.includes(rel.split('/')[0])) continue;
		if (rel.endsWith('/index.html')) {
			if (/http-equiv=["']?refresh/i.test(readFileSync(file, 'utf8'))) continue;
			const twin = join(distDir, rel.slice(0, -'/index.html'.length) + '.md');
			if (!existsSync(twin)) errors.push(`${rel} has no .md`);
		} else if (rel.endsWith('.md')) {
			const page = join(distDir, rel.slice(0, -'.md'.length), 'index.html');
			if (!existsSync(page)) errors.push(`${rel} has no page`);
		}
	}
	return errors;
}

const isMain = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
	const [distArg, site] = process.argv.slice(2);
	if (!distArg || !ORIGINS[site]) {
		console.error('usage: node scripts/check-llms.mjs <dist dir> <guides|api>');
		process.exit(2);
	}
	const here = dirname(fileURLToPath(import.meta.url));
	const versionsSource = readFileSync(resolve(here, '../packages/ui/src/data/versions.ts'), 'utf8');
	const { slugs, currentSlug } = readVersions(versionsSource, site);
	const errors = checkLlms({ distDir: resolve(distArg), site, slugs, currentSlug });
	if (errors.length) {
		console.error(`llms check failed for ${site} (${errors.length}):`);
		for (const e of errors.slice(0, 50)) console.error(`  - ${e}`);
		if (errors.length > 50) console.error(`  … and ${errors.length - 50} more`);
		process.exit(1);
	}
	console.log(`llms check passed for ${site}: current version ${currentSlug}`);
}
