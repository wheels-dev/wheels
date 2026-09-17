#!/usr/bin/env node
/**
 * Post the `announcement` frontmatter of one or more blog posts to the repo's
 * GitHub Discussions board, then write the resulting discussion URL back into
 * the post's frontmatter so the next run is a no-op.
 *
 * Used by the scheduled blog publisher (blog-publish-scheduled.sh): after the
 * publisher moves a post from scheduled/ into posts/, it calls this script with
 * the moved file paths. A post without an `announcement` block, or one whose
 * `announcement.discussionUrl` is already set, is skipped.
 *
 * Before creating a discussion the script GraphQL-searches the repo's
 * Announcements (or `announcement.category`) for an exact title match and/or
 * a body that already contains the post's blog URL. A hit is treated as a
 * prior announce: the existing URL is written back and create is skipped.
 *
 * Usage:
 *   node web/scripts/blog-announce-discussion.mjs <post.md> [<post.md> ...]
 *   node web/scripts/blog-announce-discussion.mjs --dry-run <post.md> ...
 *
 * Env: GH_TOKEN (or GITHUB_TOKEN) — a token with discussion write access.
 *      Runs with Node's built-ins only (node:fs, node:child_process, fetch).
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { basename, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';

const BLOG_ORIGIN = 'https://blog.wheels.dev';
const BLOG_URL_RE = /https:\/\/blog\.wheels\.dev\/(?:blog|posts)\/[A-Za-z0-9._-]+/g;

// ---------------------------------------------------------------------------
// Frontmatter parsing — just the `announcement:` block. The rest of the
// frontmatter is opaque to this script; it only reads and writes this one
// nested object, so it never needs a full YAML parser.
// ---------------------------------------------------------------------------

export function splitFrontmatter(content) {
	const m = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
	if (!m) throw new Error('no frontmatter found');
	return { fm: m[1], rest: content.slice(m[0].length) };
}

/**
 * Extract { title, body, category, discussionUrl } from an `announcement:`
 * block, or return null when the post has none.
 *
 * Expected shape (2-space nesting; body is a `|` literal block at 4-space
 * content indent):
 *
 *   announcement:
 *     title: '...'
 *     body: |
 *       line one
 *       line two
 *     discussionUrl: 'https://...'
 */
export function extractAnnouncement(fm) {
	const lines = fm.split('\n');
	const start = lines.findIndex((l) => /^announcement:\s*$/.test(l));
	if (start === -1) return null;

	const out = {};
	let i = start + 1;
	while (i < lines.length) {
		const line = lines[i];
		if (/^\S/.test(line)) break; // a top-level key ends the block

		const keyMatch = line.match(/^ {2}([A-Za-z0-9_]+):(.*)$/);
		if (!keyMatch) {
			i++;
			continue;
		}
		const key = keyMatch[1];
		const raw = keyMatch[2].trim();

		if (key === 'body' && (raw === '|' || raw === '|-')) {
			const bodyLines = [];
			i++;
			while (i < lines.length && (lines[i] === '' || /^ {3,}/.test(lines[i]))) {
				bodyLines.push(lines[i].replace(/^ {4}/, ''));
				i++;
			}
			while (bodyLines.length && bodyLines[bodyLines.length - 1] === '') bodyLines.pop();
			out.body = bodyLines.join('\n');
			continue;
		}

		if (raw !== '') {
			out[key] = raw.replace(/^'(.*)'$/, '$1').replace(/^"(.*)"$/, '$1');
		}
		i++;
	}

	if (!out.title || out.body == null) return null;
	return out;
}

export function extractSlug(fm) {
	const m = fm.match(/^slug:\s*(?:'([^']*)'|"([^"]*)"|(\S+))\s*$/m);
	if (!m) return '';
	return m[1] || m[2] || m[3] || '';
}

/**
 * Blog URLs used for Discussion-body dedupe. Prefer URLs already written in
 * the announcement body; always include the canonical /blog/<slug> URL when
 * a slug is known (frontmatter or filename).
 */
export function extractBlogUrls({ body = '', slug = '', file = '' } = {}) {
	const urls = new Set();
	const matches = String(body).match(BLOG_URL_RE) || [];
	for (const url of matches) urls.add(url);
	const resolvedSlug = slug || (file ? basename(file).replace(/\.mdx?$/i, '') : '');
	if (resolvedSlug) urls.add(`${BLOG_ORIGIN}/blog/${resolvedSlug}`);
	return [...urls];
}

export function writeDiscussionUrl(content, url) {
	const { fm, rest } = splitFrontmatter(content);
	const next = fm.replace(/^announcement:\s*$/m, `announcement:\n  discussionUrl: '${url}'`);
	return `---\n${next}\n---\n${rest}`;
}

// ---------------------------------------------------------------------------
// GitHub Discussions GraphQL
// ---------------------------------------------------------------------------

export function quoteSearchTerm(value) {
	return `"${String(value).replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
}

/**
 * GitHub search syntax for Discussions in one category. Title and URL clauses
 * are OR'd so a single GraphQL `search` covers both signals; callers still
 * exact-match client-side because `in:title` is substring, not equality.
 */
export function buildDiscussionSearchQuery({ owner, name, category, title, urls = [] } = {}) {
	if (!owner || !name || !category) {
		throw new Error('owner, name, and category are required to search discussions');
	}
	const clauses = [];
	if (title) clauses.push(`in:title ${quoteSearchTerm(title)}`);
	for (const url of urls) {
		if (url) clauses.push(`in:body ${quoteSearchTerm(url)}`);
	}
	if (!clauses.length) return '';
	const inner = clauses.length === 1 ? clauses[0] : `(${clauses.join(' OR ')})`;
	return `repo:${owner}/${name} category:${quoteSearchTerm(category)} ${inner}`;
}

/**
 * Pick a prior announcement from GraphQL search nodes. Requires an exact
 * title match and/or a body that contains one of the post's blog URLs, and
 * ignores hits from a different category when the node reports one.
 */
export function pickExistingDiscussion(nodes, { title, urls = [], category } = {}) {
	const wantedUrls = new Set((urls || []).filter(Boolean));
	for (const node of nodes || []) {
		if (!node || !node.url) continue;
		if (category && node.category?.name && node.category.name !== category) continue;
		if (title && node.title === title) return node;
		const body = node.body || '';
		for (const url of wantedUrls) {
			if (body.includes(url)) return node;
		}
	}
	return null;
}

export function repoOwnerName() {
	let url = '';
	try {
		url = execFileSync('git', ['config', '--get', 'remote.origin.url'], {
			encoding: 'utf8',
			stdio: ['ignore', 'pipe', 'ignore'],
		}).trim();
	} catch {
		// fall through
	}
	const m = url.match(/github\.com[:/]([^/]+)\/([^/.]+?)(?:\.git)?$/);
	if (!m) throw new Error(`could not derive owner/repo from git remote: ${url || '(none)'}`);
	return { owner: m[1], name: m[2] };
}

export async function gql(token, query, variables = {}) {
	const res = await fetch('https://api.github.com/graphql', {
		method: 'POST',
		headers: {
			Authorization: `Bearer ${token}`,
			'Content-Type': 'application/json',
			'User-Agent': 'wheels-blog-publisher',
		},
		body: JSON.stringify({ query, variables }),
	});
	const payload = await res.json();
	if (payload.errors && payload.errors.length) {
		throw new Error(`GraphQL error: ${payload.errors.map((e) => e.message).join('; ')}`);
	}
	return payload.data;
}

export async function resolveRepoAndCategories(token, gqlFn = gql) {
	const { owner, name } = repoOwnerName();
	const data = await gqlFn(
		token,
		`query($owner: String!, $name: String!) {
			repository(owner: $owner, name: $name) {
				id
				discussionCategories(first: 50) {
					nodes { id name }
				}
			}
		}`,
		{ owner, name },
	);
	const categories = new Map(
		data.repository.discussionCategories.nodes.map((c) => [c.name, c.id]),
	);
	return { repositoryId: data.repository.id, categories, owner, name };
}

export async function searchDiscussions(token, query, gqlFn = gql) {
	if (!query) return [];
	const data = await gqlFn(
		token,
		`query($query: String!) {
			search(query: $query, type: DISCUSSION, first: 20) {
				nodes {
					... on Discussion {
						title
						url
						body
						category { name }
					}
				}
			}
		}`,
		{ query },
	);
	return (data.search?.nodes || []).filter(Boolean);
}

export async function findExistingDiscussion(
	token,
	{ owner, name, category, title, urls },
	gqlFn = gql,
) {
	const query = buildDiscussionSearchQuery({ owner, name, category, title, urls });
	const nodes = await searchDiscussions(token, query, gqlFn);
	return pickExistingDiscussion(nodes, { title, urls, category });
}

export async function createDiscussion(token, repositoryId, categoryId, title, body, gqlFn = gql) {
	const data = await gqlFn(
		token,
		`mutation($repositoryId: ID!, $categoryId: ID!, $title: String!, $body: String!) {
			createDiscussion(input: {
				repositoryId: $repositoryId,
				categoryId: $categoryId,
				title: $title,
				body: $body
			}) {
				discussion { url }
			}
		}`,
		{ repositoryId, categoryId, title, body },
	);
	return data.createDiscussion.discussion.url;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

export async function announceFiles(files, { dryRun = false, token, gqlFn = gql } = {}) {
	let ctx = null;
	if (!dryRun) {
		ctx = await resolveRepoAndCategories(token, gqlFn);
	}

	let posted = 0;
	for (const file of files) {
		const content = readFileSync(file, 'utf8');
		let fm;
		try {
			fm = splitFrontmatter(content).fm;
		} catch {
			console.log(`skip (no frontmatter): ${file}`);
			continue;
		}
		const announcement = extractAnnouncement(fm);

		if (!announcement) {
			console.log(`skip (no announcement): ${file}`);
			continue;
		}
		if (announcement.discussionUrl) {
			console.log(`skip (already posted): ${file} -> ${announcement.discussionUrl}`);
			continue;
		}

		const category = announcement.category || 'Announcements';
		const slug = extractSlug(fm);
		const urls = extractBlogUrls({ body: announcement.body, slug, file });

		if (dryRun) {
			const searchQuery = buildDiscussionSearchQuery({
				owner: 'OWNER',
				name: 'REPO',
				category,
				title: announcement.title,
				urls,
			}).replace('repo:OWNER/REPO ', '');
			console.log(
				`[dry-run] would search ${category} then post if no match:\n  search: ${searchQuery}\n  title: ${announcement.title}\n  body: ${announcement.body.split('\n').join('\n        ')}`,
			);
			continue;
		}

		if (!ctx) throw new Error('discussion context missing');

		const existing = await findExistingDiscussion(
			token,
			{
				owner: ctx.owner,
				name: ctx.name,
				category,
				title: announcement.title,
				urls,
			},
			gqlFn,
		);
		if (existing) {
			writeFileSync(file, writeDiscussionUrl(content, existing.url), 'utf8');
			console.log(`skip (existing discussion): ${file} -> ${existing.url}`);
			continue;
		}

		const categoryId = ctx.categories.get(category);
		if (!categoryId) {
			throw new Error(
				`discussion category "${category}" not found. Available: ${[...ctx.categories.keys()].join(', ')}`,
			);
		}

		const url = await createDiscussion(
			token,
			ctx.repositoryId,
			categoryId,
			announcement.title,
			announcement.body,
			gqlFn,
		);
		writeFileSync(file, writeDiscussionUrl(content, url), 'utf8');
		console.log(`posted: ${file} -> ${url}`);
		posted++;
	}

	console.log(`Done. Posted ${posted} announcement(s).`);
	return posted;
}

export async function main(argv = process.argv.slice(2), env = process.env) {
	const dryRun = argv.includes('--dry-run');
	const files = argv.filter((a) => a !== '--dry-run');
	const token = env.GH_TOKEN || env.GITHUB_TOKEN;
	if (!token && !dryRun) {
		console.error('GH_TOKEN (or GITHUB_TOKEN) is not set.');
		process.exitCode = 1;
		return;
	}
	await announceFiles(files, { dryRun, token });
}

const isDirectRun =
	Boolean(process.argv[1]) && import.meta.url === pathToFileURL(resolve(process.argv[1])).href;

if (isDirectRun) {
	await main();
}
