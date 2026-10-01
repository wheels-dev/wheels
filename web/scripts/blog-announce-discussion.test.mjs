import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
	extractAnnouncement,
	extractBlogUrls,
	extractSlug,
	findExistingDiscussion,
	listCategoryDiscussions,
	pickExistingDiscussion,
	slugMarker,
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

// The categories lookup and the category listing, the two read calls
// announceFiles makes before deciding. `listed` is what the category holds.
function readMock(listed, onOther = null) {
	return async (_token, query, variables) => {
		if (query.includes('discussionCategories')) {
			return {
				repository: {
					id: 'repo1',
					discussionCategories: { nodes: [{ id: 'cat1', name: 'Announcements' }] },
				},
			};
		}
		if (query.includes('discussions(categoryId')) {
			assert.equal(variables.categoryId, 'cat1');
			return { repository: { discussions: { pageInfo: { hasNextPage: false, endCursor: null }, nodes: listed } } };
		}
		if (onOther) return onOther(query, variables);
		throw new Error(`unexpected query: ${query}`);
	};
}

test('findExistingDiscussion lists the category directly, with no search call', async () => {
	const calls = [];
	const gqlFn = async (_token, query, variables) => {
		calls.push({ query, variables });
		return {
			repository: {
				discussions: {
					pageInfo: { hasNextPage: false, endCursor: null },
					nodes: [
						{
							title: 'Pretty URLs with bindBy',
							url: 'https://github.com/wheels-dev/wheels/discussions/1',
							body: 'https://blog.wheels.dev/blog/pretty-urls-with-route-bindby',
							category: { name: 'Announcements' },
						},
					],
				},
			},
		};
	};

	const found = await findExistingDiscussion(
		'token',
		{
			owner: 'wheels-dev',
			name: 'wheels',
			categoryId: 'cat1',
			category: 'Announcements',
			title: 'Pretty URLs with bindBy',
			urls: ['https://blog.wheels.dev/blog/pretty-urls-with-route-bindby'],
			slug: 'pretty-urls-with-route-bindby',
		},
		gqlFn,
	);

	assert.equal(found.url, 'https://github.com/wheels-dev/wheels/discussions/1');
	assert.equal(calls.length, 1);
	assert.match(calls[0].query, /discussions\(categoryId: \$categoryId/);
	assert.doesNotMatch(calls[0].query, /search\(/);
	assert.equal(calls[0].variables.categoryId, 'cat1');
});

test('listCategoryDiscussions follows pagination until hasNextPage is false', async () => {
	const pages = [
		{ pageInfo: { hasNextPage: true, endCursor: 'c1' }, nodes: [{ title: 'a', url: 'u1' }] },
		{ pageInfo: { hasNextPage: false, endCursor: 'c2' }, nodes: [{ title: 'b', url: 'u2' }] },
	];
	const afters = [];
	const gqlFn = async (_token, _query, variables) => {
		afters.push(variables.after);
		return { repository: { discussions: pages[afters.length - 1] } };
	};
	const nodes = await listCategoryDiscussions('t', { owner: 'o', name: 'n', categoryId: 'c' }, gqlFn);
	assert.deepEqual(nodes.map((n) => n.url), ['u1', 'u2']);
	assert.deepEqual(afters, [null, 'c1']);
});

test('pickExistingDiscussion matches the slug marker even when the title changed', () => {
	const found = pickExistingDiscussion(
		[
			{
				title: 'A retitled announcement',
				url: 'https://github.com/wheels-dev/wheels/discussions/7',
				body: `Some text\n\n${slugMarker('pretty-urls-with-route-bindby')}`,
				category: { name: 'Announcements' },
			},
		],
		{ title: 'Pretty URLs with bindBy', urls: [], category: 'Announcements', slug: 'pretty-urls-with-route-bindby' },
	);
	assert.equal(found.url, 'https://github.com/wheels-dev/wheels/discussions/7');
});

test('pickExistingDiscussion does not match another post\'s slug marker', () => {
	const found = pickExistingDiscussion(
		[{ title: 'Other', url: 'u', body: slugMarker('pretty-urls-with-route-bindby-2'), category: { name: 'Announcements' } }],
		{ title: 'Pretty URLs with bindBy', urls: [], category: 'Announcements', slug: 'pretty-urls-with-route-bindby' },
	);
	assert.equal(found, null);
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
		if (query.includes('discussions(categoryId')) {
			return {
				repository: {
					discussions: {
						pageInfo: { hasNextPage: false, endCursor: null },
						nodes: [
							{
								title: 'Pretty URLs with bindBy',
								url: 'https://github.com/wheels-dev/wheels/discussions/3475',
								body: 'https://blog.wheels.dev/blog/pretty-urls-with-route-bindby',
								category: { name: 'Announcements' },
							},
						],
					},
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
			if (query.includes('createDiscussion') || query.includes('discussions(categoryId')) {
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

test('announceFiles creates only when the category has no match, and tags the body with the slug marker', async () => {
	const dir = await mkdtemp(join(tmpdir(), 'blog-announce-'));
	const file = join(dir, 'pretty-urls-with-route-bindby.md');
	await writeFile(file, SAMPLE_POST, 'utf8');
	const calls = [];
	let createdBody = '';

	const gqlFn = readMock([], (query, variables) => {
		if (query.includes('createDiscussion')) {
			calls.push('create');
			createdBody = variables.body;
			return { createDiscussion: { discussion: { url: 'https://github.com/wheels-dev/wheels/discussions/new' } } };
		}
		throw new Error(`unexpected query: ${query}`);
	});

	try {
		const posted = await announceFiles([file], { token: 'x', gqlFn });
		assert.equal(posted, 1);
		assert.deepEqual(calls, ['create']);
		assert.ok(createdBody.endsWith(slugMarker('pretty-urls-with-route-bindby')));
		const updated = extractAnnouncement(splitFrontmatter(await readFile(file, 'utf8')).fm);
		assert.equal(updated.discussionUrl, 'https://github.com/wheels-dev/wheels/discussions/new');
	} finally {
		await rm(dir, { recursive: true, force: true });
	}
});

// The Sep 2026 failure mode: the post was announced by an earlier run, but its
// discussionUrl writeback never landed, so the next run saw the post as new.
test('a second run for a post whose writeback never landed links the first discussion instead of creating', async () => {
	const dir = await mkdtemp(join(tmpdir(), 'blog-announce-'));
	const file = join(dir, 'pretty-urls-with-route-bindby.md');
	await writeFile(file, SAMPLE_POST, 'utf8');
	const listed = [];
	let creates = 0;
	const gqlFn = readMock(listed, (query, variables) => {
		if (query.includes('createDiscussion')) {
			creates++;
			listed.push({
				title: variables.title,
				url: 'https://github.com/wheels-dev/wheels/discussions/3500',
				body: variables.body,
				category: { name: 'Announcements' },
			});
			return { createDiscussion: { discussion: { url: 'https://github.com/wheels-dev/wheels/discussions/3500' } } };
		}
		throw new Error(`unexpected query: ${query}`);
	});

	try {
		await announceFiles([file], { token: 'x', gqlFn });
		await writeFile(file, SAMPLE_POST, 'utf8'); // the writeback is lost
		await announceFiles([file], { token: 'x', gqlFn });
		await writeFile(file, SAMPLE_POST, 'utf8');
		await announceFiles([file], { token: 'x', gqlFn });
		assert.equal(creates, 1);
		const updated = extractAnnouncement(splitFrontmatter(await readFile(file, 'utf8')).fm);
		assert.equal(updated.discussionUrl, 'https://github.com/wheels-dev/wheels/discussions/3500');
	} finally {
		await rm(dir, { recursive: true, force: true });
	}
});

test('a dry run with a token does the read-only lookup and never writes or creates', async () => {
	const dir = await mkdtemp(join(tmpdir(), 'blog-announce-'));
	const file = join(dir, 'pretty-urls-with-route-bindby.md');
	await writeFile(file, SAMPLE_POST, 'utf8');
	const gqlFn = readMock(
		[{ title: 'Pretty URLs with bindBy', url: 'https://github.com/wheels-dev/wheels/discussions/3500', body: '', category: { name: 'Announcements' } }],
		() => {
			throw new Error('a dry run must not create');
		},
	);
	try {
		const posted = await announceFiles([file], { dryRun: true, token: 'x', gqlFn });
		assert.equal(posted, 0);
		assert.equal(await readFile(file, 'utf8'), SAMPLE_POST);
	} finally {
		await rm(dir, { recursive: true, force: true });
	}
});

test('listCategoryDiscussions throws instead of returning a partial list when pages run out', async () => {
	const gqlFn = async () => ({
		repository: { discussions: { pageInfo: { hasNextPage: true, endCursor: 'c' }, nodes: [{ title: 'a', url: 'u' }] } },
	});
	await assert.rejects(
		listCategoryDiscussions('t', { owner: 'o', name: 'n', categoryId: 'c', maxPages: 2 }, gqlFn),
		/refusing to create without checking them all/,
	);
});

test('listCategoryDiscussions throws when the listing is missing', async () => {
	const gqlFn = async () => ({ repository: null });
	await assert.rejects(
		listCategoryDiscussions('t', { owner: 'o', name: 'n', categoryId: 'c' }, gqlFn),
		/could not list existing discussions/,
	);
});

test('announceFiles does not create when the listing cannot be read', async () => {
	const dir = await mkdtemp(join(tmpdir(), 'blog-announce-'));
	const file = join(dir, 'pretty-urls-with-route-bindby.md');
	await writeFile(file, SAMPLE_POST, 'utf8');
	let creates = 0;
	const gqlFn = async (_token, query) => {
		if (query.includes('discussionCategories')) {
			return { repository: { id: 'repo1', discussionCategories: { nodes: [{ id: 'cat1', name: 'Announcements' }] } } };
		}
		if (query.includes('createDiscussion')) {
			creates++;
			return { createDiscussion: { discussion: { url: 'x' } } };
		}
		return { repository: { discussions: null } };
	};
	try {
		await assert.rejects(announceFiles([file], { token: 'x', gqlFn }), /could not list existing discussions/);
		assert.equal(creates, 0);
		assert.equal(await readFile(file, 'utf8'), SAMPLE_POST);
	} finally {
		await rm(dir, { recursive: true, force: true });
	}
});
