/**
 * Plain-text docs for language models on the guides and API sites (https://llmstxt.org):
 *
 * - /llms.txt: an index (what Wheels is, the documentation sets, and every current-version
 *   page with a link to its Markdown);
 * - /llms-full.txt: every current-version page as Markdown, in one file;
 * - /llms-small.txt: an outline of the current version (each page's title, Markdown link,
 *   description and section headings), sized for an assistant's context;
 * - /llms-txt/<version>.txt: one file per docs version, current or not;
 * - <page URL>.md: one page as Markdown.
 *
 * The current version is the `current` entry in versions.ts, so a version flip moves all of this
 * with no edit here. Each site's src/pages/ holds thin endpoints that call these functions with
 * its content collection.
 */
import type { VersionMeta } from './versions';

export type LlmsSite = 'guides' | 'api';

/** The fields of a docs collection entry these functions read. */
export interface LlmsDoc {
	id: string;
	body?: string;
	data: {
		title: string;
		description?: string;
		draft?: boolean;
		pagefind?: boolean;
		sidebar?: { hidden?: boolean };
	};
}

const SITE_TEXT: Record<LlmsSite, { name: string; what: string; origin: string }> = {
	guides: {
		name: 'Wheels Guides',
		what: 'narrative guides: installation, the tutorial, models, controllers, views, routing, migrations, testing and deployment',
		origin: 'https://guides.wheels.dev',
	},
	api: {
		name: 'Wheels API Reference',
		what: 'the function reference: every framework function with its signature, parameters, return type and examples where present',
		origin: 'https://api.wheels.dev',
	},
};

const DETAILS = [
	'Wheels is an open-source MVC framework for CFML (Lucee, Adobe ColdFusion, BoxLang and RustCFML), inspired by Ruby on Rails.',
	'Code examples are CFML, not Ruby: models extend "Model", controllers extend "Controller", and model associations, validations and callbacks are declared in a config() method.',
	'Wheels functions take either all positional or all named arguments, never a mix.',
	'Model finders return query objects by default, not arrays.',
];

const IMPORT_LINE = /^import\s.+\sfrom\s+['"][^'"]+['"];?\s*$/;

export function currentVersion(versions: VersionMeta[]): VersionMeta {
	const current = versions.find((v) => v.status === 'current');
	if (!current) {
		throw new Error(
			'versions.ts has no `current` entry; llms.txt needs one to choose its version.'
		);
	}
	return current;
}

/** The docs version a collection entry belongs to (its first path segment), or "" for the site root. */
export function docVersion(id: string): string {
	const slash = id.indexOf('/');
	return slash === -1 ? (id === 'index' ? '' : id) : id.slice(0, slash);
}

/**
 * Whether a page belongs in llms.txt and the bundles: not a draft, and not unlisted (hidden from the
 * sidebar, or left out of search with `pagefind: false`).
 */
export function isListed(doc: LlmsDoc): boolean {
	return !doc.data.draft && doc.data.pagefind !== false && doc.data.sidebar?.hidden !== true;
}

/** Listed entries of one version, in a stable order (the version's landing page first). */
export function docsOfVersion<T extends LlmsDoc>(docs: T[], slug: string): T[] {
	return docs
		.filter((doc) => isListed(doc) && docVersion(doc.id) === slug)
		.sort((a, b) => (a.id === slug ? -1 : b.id === slug ? 1 : a.id.localeCompare(b.id)));
}

function versionLabel(version: VersionMeta): string {
	if (version.status === 'current') return `Wheels ${version.label} (current)`;
	if (version.status === 'snapshot') return `Wheels ${version.label} (in development)`;
	return `Wheels ${version.label}`;
}

/** The URL slug of a version's set: /llms-txt/<slug>.txt. */
export function setSlug(version: VersionMeta): string {
	return version.slug;
}

/** Page source without MDX import lines. */
function pageSource(body: string | undefined): string {
	return (body ?? '')
		.split('\n')
		.filter((line) => !IMPORT_LINE.test(line))
		.join('\n')
		.replace(/\n{3,}/g, '\n\n')
		.trim();
}

/** A page's level-2 and level-3 headings as an indented list, skipping fenced code. */
function pageOutline(body: string | undefined): string[] {
	const out: string[] = [];
	let fence = '';
	for (const line of (body ?? '').split('\n')) {
		const marker = /^\s*(`{3,}|~{3,})/.exec(line);
		if (marker) {
			if (!fence) fence = marker[1];
			else if (marker[1].startsWith(fence)) fence = '';
			continue;
		}
		if (fence) continue;
		const heading = /^(#{2,3})\s+(.+?)\s*#*\s*$/.exec(line);
		if (heading) out.push(`${heading[1].length === 3 ? '  ' : ''}- ${heading[2]}`);
	}
	return out;
}

/**
 * The Markdown served at `<page URL>.md`: the page's title and description, then its source.
 * MDX import lines are dropped; components such as <Aside> stay as written.
 */
export function markdownTwin(
	title: string,
	description: string | undefined,
	body: string | undefined
): string {
	const head = [`# ${title}`];
	if (description) head.push('', `> ${description}`);
	return `${head.join('\n')}\n\n${pageSource(body)}\n`;
}

function pageUrl(site: LlmsSite, id: string): string {
	return `${SITE_TEXT[site].origin}/${id}/`;
}

/** Many pages as one Markdown document (llms-full.txt and the version sets). */
export function llmsBundle(site: LlmsSite, heading: string, docs: LlmsDoc[]): string {
	const parts = [`# ${heading}`, '', `> ${SITE_TEXT[site].name}. ${DETAILS[0]}`];
	for (const doc of docs) {
		parts.push('', '---', '', `# ${doc.data.title}`, '', `Source: ${pageUrl(site, doc.id)}`);
		if (doc.data.description) parts.push('', `> ${doc.data.description}`);
		const source = pageSource(doc.body);
		if (source) parts.push('', source);
	}
	return parts.join('\n') + '\n';
}

/** llms-small.txt: an outline of the pages, with a link to each page's Markdown. */
export function llmsOutline(site: LlmsSite, heading: string, docs: LlmsDoc[]): string {
	const origin = SITE_TEXT[site].origin;
	const parts = [
		`# ${heading}`,
		'',
		`> ${SITE_TEXT[site].name}, abridged: each page's title, description and section headings. Fetch a page's full text from its Markdown link.`,
		'',
		DETAILS.join('\n\n'),
	];
	for (const doc of docs) {
		parts.push('', `## [${doc.data.title}](${origin}/${doc.id}.md)`);
		if (doc.data.description) parts.push('', doc.data.description);
		const outline = pageOutline(doc.body);
		if (outline.length) parts.push('', ...outline);
	}
	return parts.join('\n') + '\n';
}

/** /llms.txt: the index. */
export function llmsIndex(site: LlmsSite, versions: VersionMeta[], docs: LlmsDoc[]): string {
	const text = SITE_TEXT[site];
	const current = currentVersion(versions);
	const other: LlmsSite = site === 'guides' ? 'api' : 'guides';
	const lines = [
		`# ${text.name}`,
		'',
		`> ${text.name} for Wheels ${current.label}: ${text.what}.`,
		'',
		DETAILS.join('\n\n'),
		'',
		'Every page is also available as Markdown: append ".md" to its URL (without the trailing slash).',
		'',
		'## Documentation sets',
		'',
		`- [Complete documentation](${text.origin}/llms-full.txt): every Wheels ${current.label} page, as Markdown`,
		`- [Abridged documentation](${text.origin}/llms-small.txt): an outline of every Wheels ${current.label} page, with section headings`,
		...versions.map(
			(v) =>
				`- [${versionLabel(v)}](${text.origin}/llms-txt/${setSlug(v)}.txt): every page for that version`
		),
		'',
		`## Wheels ${current.label} pages`,
		'',
		...docsOfVersion(docs, current.slug).map((doc) => {
			const desc = doc.data.description ? `: ${doc.data.description}` : '';
			return `- [${doc.data.title}](${text.origin}/${doc.id}.md)${desc}`;
		}),
		'',
		'## Optional',
		'',
		`- [${SITE_TEXT[other].name}](${SITE_TEXT[other].origin}/llms.txt): ${SITE_TEXT[other].what}`,
		'- [Wheels blog](https://blog.wheels.dev/): release notes and tutorials',
		'- [Wheels packages](https://packages.wheels.dev/): first-party and community packages',
	];
	return lines.join('\n') + '\n';
}

export const TEXT_HEADERS = { 'Content-Type': 'text/plain; charset=utf-8' };
export const MARKDOWN_HEADERS = { 'Content-Type': 'text/markdown; charset=utf-8' };
