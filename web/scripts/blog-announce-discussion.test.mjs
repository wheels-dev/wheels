import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
	buildDiscussionSearchQuery,
	extractAnnouncement,
	extractBlogUrls,
	extractSlug,
	findExistingDiscussion,
	pickExistingDiscussion,
	quoteSearchTerm,
	splitFrontmatter,
	writeDiscussionUrl,
	announceFiles,
} from './blog-announce-discussion.mjs';

const SAMPLE_FM = `title: 'Pretty URLs with bindBy: the unshareable link'
slug: pretty-urls-with-route-bindby
announcement:
  title: 'Pretty URLs with bindBy'
  body: |
    New post: **[Pretty URLs with bindBy](https://blog.wheels.dev/blog/pretty-urls-with-route-bindby)** — bind a resource.
`;

const SAMPLE_POST = `---
${SAMPLE_FM}---
The support conversation goes like this.
`;

test('extractAnnouncement reads title, body, and discussionUrl', () => {
	const announcement = extractAnnouncement(`${SAMPLE_FM}  discussionUrl: 'https://example.test/d/1'\n`);
	assert.equal(announcement.title, 'Pretty URLs with bindBy');
	assert.match(announcement.body, /blog\.wheels\.dev\/blog\/pretty-urls-with-route-bindby/);
	assert.equal(announcement.discussionUrl, 'https://example.test/d/1');
});

test('extractAnnouncement returns null when the block is missing', () => {
	assert.equal(extractAnnouncement('title: hello\n'), null);
});

test('extractSlug reads an unquoted slug', () => {
	assert.equal(extractSlug(SAMPLE_FM), 'pretty-urls-with-route-bindby');
});

test('extractBlogUrls prefers body links and always adds /blog/<slug>', () => {
	const urls = extractBlogUrls({
		body: 'See https://blog.wheels.dev/posts/legacy-slug and https://blog.wheels.dev/blog/pretty-urls-with-route-bindby',
		slug: 'pretty-urls-with-route-bindby',
	});
	assert.deepEqual(
		[...urls].sort(),
		[
			'https://blog.wheels.dev/blog/pretty-urls-with-route-bindby',
			'https://blog.wheels.dev/posts/legacy-slug',
		],
	);
});

test('extractBlogUrls falls back to the filename slug', () => {
	const urls = extractBlogUrls({
		body: 'no links here',
		file: '/tmp/cli-workflow-upgrades-migrate-diff-dry-run-offline.md',
	});
	assert.deepEqual(urls, [
		'https://blog.wheels.dev/blog/cli-workflow-upgrades-migrate-diff-dry-run-offline',
	]);
});

test('quoteSearchTerm escapes quotes and backslashes', () => {
	assert.equal(quoteSearchTerm('say "hi"'), '"say \\"hi\\""');
	assert.equal(quoteSearchTerm('a\\b'), '"a\\\\b"');
});

test('buildDiscussionSearchQuery ORs exact title and blog URL clauses', () => {
	const query = buildDiscussionSearchQuery({
		owner: 'wheels-dev',
		name: 'wheels',
		category: 'Announcements',
		title: 'Pretty URLs with bindBy',
		urls: ['https://blog.wheels.dev/blog/pretty-urls-with-route-bindby'],
	});
	assert.equal(
		query,
		'repo:wheels-dev/wheels category:"Announcements" (in:title "Pretty URLs with bindBy" OR in:body "https://blog.wheels.dev/blog/pretty-urls-with-route-bindby")',
	);
});

test('pickExistingDiscussion matches an exact title in the category', () => {
	const hit = pickExistingDiscussion(
		[
			{
				title: 'Pretty URLs with bindBy',
				url: 'https://github.com/wheels-dev/wheels/discussions/1',
				body: 'unrelated',
				category: { name: 'Announcements' },
			},
		],
		{
			title: 'Pretty URLs with bindBy',
			urls: ['https://blog.wheels.dev/blog/pretty-urls-with-route-bindby'],
			category: 'Announcements',
		},
	);
	assert.equal(hit.url, 'https://github.com/wheels-dev/wheels/discussions/1');
});

test('pickExistingDiscussion matches a body that contains the blog URL', () => {
	const hit = pickExistingDiscussion(
		[
			{
				title: 'A slightly different title',
				url: 'https://github.com/wheels-dev/wheels/discussions/2',
				body: 'New post: https://blog.wheels.dev/blog/pretty-urls-with-route-bindby',
				category: { name: 'Announcements' },
			},
		],
		{
			title: 'Pretty URLs with bindBy',
			urls: ['https://blog.wheels.dev/blog/pretty-urls-with-route-bindby'],
			category: 'Announcements',
		},
	);
	assert.equal(hit.url, 'https://github.com/wheels-dev/wheels/discussions/2');
});

test('pickExistingDiscussion ignores a substring title hit', () => {
	const hit = pickExistingDiscussion(
		[
			{
				title: 'Pretty URLs with bindBy and more',
				url: 'https://github.com/wheels-dev/wheels/discussions/3',
				body: 'no blog url',
				category: { name: 'Announcements' },
			},
		],
		{
			title: 'Pretty URLs with bindBy',
			urls: ['https://blog.wheels.dev/blog/pretty-urls-with-route-bindby'],
			category: 'Announcements',
		},
	);
	assert.equal(hit, null);
});

test('pickExistingDiscussion ignores a hit from another category', () => {
	const hit = pickExistingDiscussion(
		[
			{
				title: 'Pretty URLs with bindBy',
				url: 'https://github.com/wheels-dev/wheels/discussions/4',
				body: 'https://blog.wheels.dev/blog/pretty-urls-with-route-bindby',
				category: { name: 'Ideas' },
			},
		],
		{
			title: 'Pretty URLs with bindBy',
			urls: ['https://blog.wheels.dev/blog/pretty-urls-with-route-bindby'],
			category: 'Announcements',
		},
	);
	assert.equal(hit, null);
});

test('writeDiscussionUrl inserts discussionUrl under announcement', () => {
	const next = writeDiscussionUrl(SAMPLE_POST, 'https://github.com/wheels-dev/wheels/discussions/9');
	const { fm } = splitFrontmatter(next);
	assert.match(fm, /^announcement:\n  discussionUrl: 'https:\/\/github.com\/wheels-dev\/wheels\/discussions\/9'/m);
	assert.equal(extractAnnouncement(fm).discussionUrl, 'https://github.com/wheels-dev/wheels/discussions/9');
});

test('findExistingDiscussion issues a DISCUSSION search and exact-filters', async () => {
	const calls = [];
	const gqlFn = async (_token, query, variables) => {
		calls.push({ query, variables });
		return {
			search: {
				nodes: [
					{
						title: 'Pretty URLs with bindBy',
						url: 'https://github.com/wheels-dev/wheels/discussions/1',
						body: 'https://blog.wheels.dev/blog/pretty-urls-with-route-bindby',
						category: { name: 'Announcements' },
					},
				],
			},
		};
	};

	const found = await findExistingDiscussion(
		'token',
		{
			owner: 'wheels-dev',
			name: 'wheels',
			category: 'Announcements',
			title: 'Pretty URLs with bindBy',
			urls: ['https://blog.wheels.dev/blog/pretty-urls-with-route-bindby'],
		},
		gqlFn,
	);

	assert.equal(found.url, 'https://github.com/wheels-dev/wheels/discussions/1');
	assert.equal(calls.length, 1);
	assert.match(calls[0].query, /type: DISCUSSION/);
	assert.equal(
		calls[0].variables.query,
		'repo:wheels-dev/wheels category:"Announcements" (in:title "Pretty URLs with bindBy" OR in:body "https://blog.wheels.dev/blog/pretty-urls-with-route-bindby")',
	);
});

test('announceFiles skips when discussionUrl is already set and does not search', async () => {
	const dir = await mkdtemp(join(tmpdir(), 'blog-announce-'));
	const file = join(dir, 'already.md');
	await writeFile(
		file,
		`---
slug: already
announcement:
  discussionUrl: 'https://github.com/wheels-dev/wheels/discussions/99'
  title: 'Already posted'
  body: |
    https://blog.wheels.dev/blog/already
---
body
`,
		'utf8',
	);

	const calls = [];
	const gqlFn = async () => {
		calls.push('gql');
		throw new Error('should not be called');
	};

	try {
		const posted = await announceFiles([file], { dryRun: true, token: 'x', gqlFn });
		assert.equal(posted, 0);
		assert.equal(calls.length, 0);
		const kept = await readFile(file, 'utf8');
		assert.match(kept, /discussionUrl: 'https:\/\/github.com\/wheels-dev\/wheels\/discussions\/99'/);
	} finally {
		await rm(dir, { recursive: true, force: true });
	}
});

test('announceFiles writes the existing discussion URL and does not create', async () => {
	const dir = await mkdtemp(join(tmpdir(), 'blog-announce-'));
	const file = join(dir, 'pretty-urls-with-route-bindby.md');
	await writeFile(file, SAMPLE_POST, 'utf8');

	const gqlFn = async (_token, query) => {
		if (query.includes('discussionCategories')) {
			return {
				repository: {
					id: 'repo1',
					discussionCategories: { nodes: [{ id: 'cat1', name: 'Announcements' }] },
				},
			};
		}
		if (query.includes('type: DISCUSSION')) {
			return {
				search: {
					nodes: [
						{
							title: 'Pretty URLs with bindBy',
							url: 'https://github.com/wheels-dev/wheels/discussions/3475',
							body: 'https://blog.wheels.dev/blog/pretty-urls-with-route-bindby',
							category: { name: 'Announcements' },
						},
					],
				},
			};
		}
		if (query.includes('createDiscussion')) {
			throw new Error('createDiscussion must not run when a match exists');
		}
		throw new Error(`unexpected query: ${query}`);
	};

	try {
		const posted = await announceFiles([file], { token: 'x', gqlFn });
		assert.equal(posted, 0);
		const updated = extractAnnouncement(splitFrontmatter(await readFile(file, 'utf8')).fm);
		assert.equal(updated.discussionUrl, 'https://github.com/wheels-dev/wheels/discussions/3475');

		const gqlFnSecond = async (_token, query) => {
			if (query.includes('createDiscussion') || query.includes('type: DISCUSSION')) {
				throw new Error('second announce must be a no-op after discussionUrl is written');
			}
			return {
				repository: {
					id: 'repo1',
					discussionCategories: { nodes: [{ id: 'cat1', name: 'Announcements' }] },
				},
			};
		};
		const postedAgain = await announceFiles([file], { token: 'x', gqlFn: gqlFnSecond });
		assert.equal(postedAgain, 0);
	} finally {
		await rm(dir, { recursive: true, force: true });
	}
});

test('announceFiles creates only when search finds no match', async () => {
	const dir = await mkdtemp(join(tmpdir(), 'blog-announce-'));
	const file = join(dir, 'pretty-urls-with-route-bindby.md');
	await writeFile(file, SAMPLE_POST, 'utf8');
	const calls = [];

	const gqlFn = async (_token, query) => {
		if (query.includes('discussionCategories')) {
			return {
				repository: {
					id: 'repo1',
					discussionCategories: { nodes: [{ id: 'cat1', name: 'Announcements' }] },
				},
			};
		}
		if (query.includes('type: DISCUSSION')) {
			calls.push('search');
			return { search: { nodes: [] } };
		}
		if (query.includes('createDiscussion')) {
			calls.push('create');
			return { createDiscussion: { discussion: { url: 'https://github.com/wheels-dev/wheels/discussions/new' } } };
		}
		throw new Error(`unexpected query: ${query}`);
	};

	try {
		const posted = await announceFiles([file], { token: 'x', gqlFn });
		assert.equal(posted, 1);
		assert.deepEqual(calls, ['search', 'create']);
		const updated = extractAnnouncement(splitFrontmatter(await readFile(file, 'utf8')).fm);
		assert.equal(updated.discussionUrl, 'https://github.com/wheels-dev/wheels/discussions/new');
	} finally {
		await rm(dir, { recursive: true, force: true });
	}
});
