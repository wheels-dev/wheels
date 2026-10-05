#!/usr/bin/env node
/**
 * Builds the offline docs index `wheels lookup` reads: cli/lucli/data/docs-index.json.
 *
 * One file, shipped inside the CLI module, so the lookup works with no network
 * and no download (the HTML bundle `wheels docs fetch` downloads is ~35 MB).
 * It holds two kinds of entries:
 *
 *   - api: one per function in docs/api/v<version>.json (the JSON the framework
 *     emits from /wheels/api?format=json), with signature, parameters, hint and
 *     example text;
 *   - guides: one per section of the guides tree for that version
 *     (web/sites/guides/src/content/docs/v<major>-<minor>-0/), split on ## and
 *     ### headings, as plain text with code blocks kept.
 *
 * The index must describe the CLI's own framework version, so the release and
 * snapshot builds run this with --strict: the version's API JSON and guides tree
 * must exist or the build fails. Without --strict (a developer running the CLI
 * from a source checkout) it falls back to the newest API JSON and guides tree
 * there are, and records which ones it used; `wheels lookup` prints them.
 *
 * Usage:
 *   node tools/build/scripts/build-docs-index.mjs [--version <v>] [--strict] [--out <file>] [--repo <dir>]
 *
 * --version defaults to wheels.json's version. A snapshot version
 * (4.2.0-snapshot.123) reads docs/api/v4.2.0-snapshot.json, which the snapshot
 * workflow generates from the running framework; any other reads v4.2.0.json.
 *
 * No dependencies beyond Node itself, so it runs before `pnpm install`.
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

export const INDEX_FORMAT = 1;
const SECTION_TEXT_LIMIT = 12000;

// --- helpers (exported for build-docs-index.test.mjs) ---

/** The api site's slug rule (web/scripts/generate-api-docs.mjs). */
export function slugify(str) {
	return String(str)
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, '-')
		.replace(/(^-|-$)/g, '');
}

/** A heading anchor the way Starlight (github-slugger) makes one. */
export function headingAnchor(text) {
	return String(text)
		.trim()
		.toLowerCase()
		.replace(/[^\p{L}\p{N}\s_-]/gu, '')
		.replace(/\s/g, '-');
}

/** major.minor.patch with any pre-release suffix dropped. */
export function baseVersion(version) {
	const m = String(version).match(/^(\d+)\.(\d+)\.(\d+)/);
	return m ? `${m[1]}.${m[2]}.${m[3]}` : '';
}

export function isSnapshot(version) {
	return /-snapshot/i.test(String(version));
}

/** The guides tree for a version: 4.2.x -> v4-2-0. */
export function guidesSlugFor(version) {
	const m = String(version).match(/^(\d+)\.(\d+)/);
	return m ? `v${m[1]}-${m[2]}-0` : '';
}

const ENTITIES = { '&quot;': '"', '&#39;': "'", '&apos;': "'", '&lt;': '<', '&gt;': '>', '&nbsp;': ' ', '&amp;': '&' };

/** The API JSON's example HTML (<pre><code>…</code></pre>) as plain text. */
export function htmlToText(html) {
	if (!html) return '';
	return String(html)
		.replace(/<br\s*\/?>/gi, '\n')
		.replace(/<\/(p|pre|div|li|h\d)>/gi, '\n')
		// Only real tags: a bare < in prose (`<`, `<=`) is text, not markup.
		.replace(/<\/?[a-zA-Z][a-zA-Z0-9-]*(\s[^<>]*)?\/?>/g, '')
		.replace(/&(quot|#39|apos|lt|gt|nbsp|amp);/g, (e) => ENTITIES[e])
		.replace(/\n{3,}/g, '\n\n')
		.trim();
}

/** Front matter fields we use (title, description) from an .md/.mdx file. */
export function parseFrontMatter(source) {
	const m = source.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?/);
	if (!m) return { data: {}, body: source };
	const data = {};
	for (const line of m[1].split(/\r?\n/)) {
		const kv = line.match(/^(title|description):\s*(.*)$/);
		if (kv) data[kv[1]] = kv[2].trim().replace(/^(['"])(.*)\1$/, '$2');
	}
	return { data, body: source.slice(m[0].length) };
}

/**
 * Split a guide page body into sections on ## and ### headings, outside code
 * fences, as plain text: imports, MDX comments and JSX component tags go
 * (their inner text stays), code blocks are kept.
 */
export function splitSections(body, pageTitle) {
	const sections = [];
	const seen = new Map();
	let current = { heading: '', level: 1, lines: [] };
	let fence = null;

	const flush = () => {
		const text = current.lines.join('\n').replace(/\n{3,}/g, '\n\n').trim();
		if (text || current.heading) {
			let anchor = '';
			if (current.heading) {
				const base = headingAnchor(current.heading);
				const n = seen.get(base) || 0;
				seen.set(base, n + 1);
				anchor = n ? `${base}-${n}` : base;
			}
			sections.push({
				heading: current.heading || pageTitle,
				anchor,
				text: text.length > SECTION_TEXT_LIMIT ? `${text.slice(0, SECTION_TEXT_LIMIT)}\n…` : text,
			});
		}
	};

	for (const raw of body.split(/\r?\n/)) {
		const fenceMatch = raw.match(/^\s*(```+|~~~+)/);
		if (fence) {
			current.lines.push(raw);
			if (fenceMatch && raw.trim().startsWith(fence)) fence = null;
			continue;
		}
		if (fenceMatch) {
			fence = fenceMatch[1];
			current.lines.push(raw);
			continue;
		}
		if (/^import\s.+from\s+['"].+['"];?\s*$/.test(raw)) continue;
		const h = raw.match(/^(#{2,3})\s+(.+?)\s*#*\s*$/);
		if (h) {
			flush();
			current = { heading: stripInline(h[2]), level: h[1].length, lines: [] };
			continue;
		}
		const line = raw
			.replace(/\{\/\*[\s\S]*?\*\/\}/g, '')
			.replace(/<\/?[A-Z][A-Za-z0-9.]*(\s[^>]*)?\/?>/g, '')
			.replace(/<!--[\s\S]*?-->/g, '');
		current.lines.push(line);
	}
	flush();
	return sections;
}

function stripInline(text) {
	return text
		.replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
		.replace(/[`*_]/g, '')
		.trim();
}

function walk(dir) {
	const out = [];
	for (const name of readdirSync(dir)) {
		const full = join(dir, name);
		if (statSync(full).isDirectory()) out.push(...walk(full));
		else if (/\.mdx?$/.test(name)) out.push(full);
	}
	return out.sort();
}

/** The site path for a guide file: basics/routing.mdx -> basics/routing, x/index.mdx -> x. */
export function guidePath(file, treeRoot) {
	let rel = relative(treeRoot, file).split(sep).join('/').replace(/\.mdx?$/, '');
	if (rel === 'index') return '';
	rel = rel.replace(/\/index$/, '');
	return rel.toLowerCase();
}

export function apiEntries(apiJson, apiSlug) {
	const entries = [];
	for (const fn of apiJson.functions || []) {
		const section = fn.tags?.section || 'Miscellaneous';
		const scopes = Array.isArray(fn.availableIn) ? fn.availableIn : [];
		// $-prefixed parameters are framework-internal; they aren't part of the documented call.
		const params = (fn.parameters || []).filter((p) => !String(p.name || '').startsWith('$')).map((p) => ({
			name: p.name || '',
			type: p.type || 'any',
			required: !!p.required,
			default: p.default === undefined || p.default === null ? '' : String(p.default),
			hint: htmlToText(p.hint).replace(/\s+/g, ' ').trim(),
		}));
		entries.push({
			id: `api:${fn.slug || `${scopes[0] || 'global'}.${fn.name}`}`,
			kind: 'api',
			name: fn.name,
			scopes,
			section,
			category: fn.tags?.category || '',
			returns: fn.returntype || 'any',
			hint: htmlToText(fn.hint),
			params,
			example: fn.extended?.hasExtended ? htmlToText(fn.extended.docs) : '',
			url: `https://api.wheels.dev/v${apiSlug}/${slugify(section)}/${slugify(fn.name)}/`,
		});
	}
	return entries;
}

export function guideEntries(treeRoot, guidesSlug) {
	const entries = [];
	for (const file of walk(treeRoot)) {
		const { data, body } = parseFrontMatter(readFileSync(file, 'utf8'));
		const path = guidePath(file, treeRoot);
		const pageTitle = data.title || path.split('/').pop() || 'Guides';
		const pageUrl = `https://guides.wheels.dev/${guidesSlug}/${path ? `${path}/` : ''}`;
		for (const s of splitSections(body, pageTitle)) {
			if (!s.text) continue;
			entries.push({
				id: `guides:${path || 'index'}${s.anchor ? `#${s.anchor}` : ''}`,
				kind: 'guides',
				page: pageTitle,
				heading: s.heading,
				text: s.text,
				url: s.anchor ? `${pageUrl}#${s.anchor}` : pageUrl,
			});
		}
	}
	return entries;
}

/** Newest file/dir name by numeric version, e.g. v4.1.0.json over v4.0.0.json. */
function newestByVersion(names, pattern) {
	return names
		.map((n) => ({ n, m: n.match(pattern) }))
		.filter((x) => x.m)
		.sort((a, b) => {
			for (let i = 1; i <= 3; i++) {
				const d = Number(b.m[i]) - Number(a.m[i]);
				if (d) return d;
			}
			return 0;
		})
		.map((x) => x.n)[0];
}

export function resolveSources({ repo, version, strict }) {
	const base = baseVersion(version);
	if (!base) throw new Error(`Not a framework version: "${version}"`);

	const apiDir = join(repo, 'docs/api');
	const wanted = isSnapshot(version) ? `v${base}-snapshot.json` : `v${base}.json`;
	let apiFile = wanted;
	if (!existsSync(join(apiDir, wanted))) {
		if (strict) {
			throw new Error(
				`docs/api/${wanted} is missing, so the index can't describe Wheels ${version}. ` +
				(isSnapshot(version)
					? 'The snapshot workflow generates it from /wheels/api?format=json; download its api-docs-snapshot artifact first.'
					: 'Commit the version\'s API JSON (generated from /wheels/api?format=json&type=core) before the release.'),
			);
		}
		apiFile = newestByVersion(readdirSync(apiDir), /^v(\d+)\.(\d+)\.(\d+)(?:-snapshot)?\.json$/);
		if (!apiFile) throw new Error('No API JSON under docs/api/.');
	}

	const guidesRoot = join(repo, 'web/sites/guides/src/content/docs');
	let guidesSlug = guidesSlugFor(version);
	if (!existsSync(join(guidesRoot, guidesSlug))) {
		if (strict) throw new Error(`The guides tree ${guidesSlug} is missing under web/sites/guides/src/content/docs/.`);
		guidesSlug = newestByVersion(readdirSync(guidesRoot), /^v(\d+)-(\d+)-(\d+)$/);
		if (!guidesSlug) throw new Error('No guides tree under web/sites/guides/src/content/docs/.');
	}

	return { apiFile, apiPath: join(apiDir, apiFile), guidesSlug, guidesPath: join(guidesRoot, guidesSlug) };
}

export function buildIndex({ repo, version, strict = false }) {
	const src = resolveSources({ repo, version, strict });
	const apiJson = JSON.parse(readFileSync(src.apiPath, 'utf8'));
	// v4.2.0-snapshot.json -> 4-2-0-snapshot, the api site's version slug.
	const apiSlug = src.apiFile.replace(/^v/, '').replace(/\.json$/, '').replace(/\./g, '-');
	const entries = [...apiEntries(apiJson, apiSlug), ...guideEntries(src.guidesPath, src.guidesSlug)];
	return {
		format: INDEX_FORMAT,
		frameworkVersion: version,
		apiSource: src.apiFile,
		guidesSlug: src.guidesSlug,
		builtAt: new Date().toISOString(),
		entries,
	};
}

function parseArgs(argv) {
	const opts = { strict: false };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		const take = () => {
			const eq = a.indexOf('=');
			return eq > -1 ? a.slice(eq + 1) : argv[++i];
		};
		if (a === '--strict') opts.strict = true;
		else if (a.startsWith('--version')) opts.version = take();
		else if (a.startsWith('--out')) opts.out = take();
		else if (a.startsWith('--repo')) opts.repo = take();
		else throw new Error(`Unknown argument: ${a}`);
	}
	return opts;
}

function main() {
	const here = dirname(fileURLToPath(import.meta.url));
	const opts = parseArgs(process.argv.slice(2));
	const repo = resolve(opts.repo || join(here, '../../..'));
	const version = opts.version || JSON.parse(readFileSync(join(repo, 'wheels.json'), 'utf8')).version;
	const out = resolve(opts.out || join(repo, 'cli/lucli/data/docs-index.json'));
	const index = buildIndex({ repo, version, strict: opts.strict });
	mkdirSync(dirname(out), { recursive: true });
	writeFileSync(out, JSON.stringify(index));
	const api = index.entries.filter((e) => e.kind === 'api').length;
	console.log(
		`Wrote ${relative(process.cwd(), out)}: ${api} API entries (${index.apiSource}), ` +
		`${index.entries.length - api} guide sections (${index.guidesSlug}), ${(statSync(out).size / 1024).toFixed(0)} KB, for Wheels ${version}`,
	);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
	try {
		main();
	} catch (e) {
		console.error(`build-docs-index: ${e.message}`);
		process.exit(1);
	}
}
