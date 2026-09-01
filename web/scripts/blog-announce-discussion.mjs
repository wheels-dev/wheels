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
 * Usage:
 *   node web/scripts/blog-announce-discussion.mjs <post.md> [<post.md> ...]
 *   node web/scripts/blog-announce-discussion.mjs --dry-run <post.md> ...
 *
 * Env: GH_TOKEN (or GITHUB_TOKEN) — a token with discussion write access.
 *      Runs with Node's built-ins only (node:fs, node:child_process, fetch).
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const files = args.filter((a) => a !== '--dry-run');

// ---------------------------------------------------------------------------
// Frontmatter parsing — just the `announcement:` block. The rest of the
// frontmatter is opaque to this script; it only reads and writes this one
// nested object, so it never needs a full YAML parser.
// ---------------------------------------------------------------------------

function splitFrontmatter(content) {
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
function extractAnnouncement(fm) {
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

function writeDiscussionUrl(content, url) {
	const { fm, rest } = splitFrontmatter(content);
	const next = fm.replace(/^announcement:\s*$/m, `announcement:\n  discussionUrl: '${url}'`);
	return `---\n${next}\n---\n${rest}`;
}

// ---------------------------------------------------------------------------
// GitHub Discussions GraphQL
// ---------------------------------------------------------------------------

function repoOwnerName() {
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

async function gql(token, query, variables = {}) {
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

async function resolveRepoAndCategories(token) {
	const { owner, name } = repoOwnerName();
	const data = await gql(
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
	return { repositoryId: data.repository.id, categories };
}

async function createDiscussion(token, repositoryId, categoryId, title, body) {
	const data = await gql(
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

const token = process.env.GH_TOKEN || process.env.GITHUB_TOKEN;
if (!token && !dryRun) {
	console.error('GH_TOKEN (or GITHUB_TOKEN) is not set.');
	process.exit(1);
}

let ctx = null;
if (!dryRun) {
	ctx = await resolveRepoAndCategories(token);
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
	if (!ctx && !dryRun) throw new Error('discussion context missing');

	if (dryRun) {
		console.log(`[dry-run] would post to ${category}:\n  title: ${announcement.title}\n  body: ${announcement.body.split('\n').join('\n        ')}`);
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
	);
	writeFileSync(file, writeDiscussionUrl(content, url), 'utf8');
	console.log(`posted: ${file} -> ${url}`);
	posted++;
}

console.log(`Done. Posted ${posted} announcement(s).`);
