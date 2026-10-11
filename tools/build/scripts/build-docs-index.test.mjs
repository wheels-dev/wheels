// node --test tools/build/scripts/build-docs-index.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
	baseVersion,
	buildIndex,
	guidePath,
	guidesSlugFor,
	headingAnchor,
	htmlToText,
	parseFrontMatter,
	resolveSources,
	splitSections,
} from './build-docs-index.mjs';

const API = {
	sections: [],
	functions: [
		{
			name: 'findAll',
			slug: 'model.findAll',
			availableIn: ['model'],
			returntype: 'any',
			hint: 'Returns records; use the <code>where</code> argument.',
			parameters: [
				{ name: 'where', type: 'string', required: false, default: '', hint: 'The <code>WHERE</code> clause.' },
				{ name: '$limit', type: 'numeric', required: false, default: 0, hint: '' },
			],
			extended: { hasExtended: true, docs: "<pre><code>users = model(&quot;User&quot;).findAll(where=&quot;active=1&quot;);</code></pre>" },
			tags: { section: 'Model Class', category: 'Read Functions' },
		},
		{
			name: 'delete',
			slug: 'mapper.delete',
			availableIn: ['mapper'],
			returntype: 'struct',
			hint: 'A DELETE route.',
			parameters: [],
			tags: { section: 'Configuration', category: 'Routing' },
		},
	],
};

const ROUTING = `---
title: Routing
description: Routes.
---
import { Aside } from '@astrojs/starlight/components';

Intro text about routes.

## Nested resources

<Aside type="tip">Use the callback form.</Aside>

\`\`\`cfm
## not a heading inside code
.resources(name="posts", callback=function(map) { map.resources("comments"); })
\`\`\`

### Shallow \`nesting\`

Shallow text.

## Nested resources

Second section with the same heading.
`;

function makeRepo({ api = { 'v4.2.0.json': API }, trees = { 'v4-2-0': { 'basics/routing.mdx': ROUTING, 'index.mdx': '---\ntitle: Home\n---\nWelcome.' } } } = {}) {
	const repo = mkdtempSync(join(tmpdir(), 'docs-index-'));
	mkdirSync(join(repo, 'docs/api'), { recursive: true });
	for (const [name, json] of Object.entries(api)) writeFileSync(join(repo, 'docs/api', name), JSON.stringify(json));
	for (const [slug, files] of Object.entries(trees)) {
		for (const [rel, body] of Object.entries(files)) {
			const full = join(repo, 'web/sites/guides/src/content/docs', slug, rel);
			mkdirSync(join(full, '..'), { recursive: true });
			writeFileSync(full, body);
		}
	}
	return repo;
}

test('version helpers', () => {
	assert.equal(baseVersion('4.2.0-snapshot.2867'), '4.2.0');
	assert.equal(guidesSlugFor('4.2.0-snapshot.2867'), 'v4-2-0');
	assert.equal(headingAnchor('Shallow nesting'), 'shallow-nesting');
	assert.equal(headingAnchor('What’s new? (4.2)'), 'whats-new-42');
});

test('htmlToText decodes entities and drops tags', () => {
	assert.equal(htmlToText('<pre><code>a = &quot;x&quot; &amp;&amp; b &lt; 2;</code></pre>'), 'a = "x" && b < 2;');
	// A bare < in prose stays: the where hint lists `<`, `<=` and `>` as operators.
	assert.equal(htmlToText('Operators: `<>`, `<`, `<=`, `>`. Use <code>IN</code>.'), 'Operators: `<>`, `<`, `<=`, `>`. Use IN.');
});

test('front matter and guide paths', () => {
	const { data, body } = parseFrontMatter('---\ntitle: "Routing"\ndescription: x\n---\nBody');
	assert.equal(data.title, 'Routing');
	assert.equal(body, 'Body');
	assert.equal(guidePath('/t/basics/routing.mdx', '/t'), 'basics/routing');
	assert.equal(guidePath('/t/basics/index.mdx', '/t'), 'basics');
	assert.equal(guidePath('/t/index.mdx', '/t'), '');
});

test('splitSections splits on ## and ### outside code fences, strips MDX, dedupes anchors', () => {
	const { body } = parseFrontMatter(ROUTING);
	const s = splitSections(body, 'Routing');
	assert.deepEqual(s.map((x) => [x.heading, x.anchor]), [
		['Routing', ''],
		['Nested resources', 'nested-resources'],
		['Shallow nesting', 'shallow-nesting'],
		['Nested resources', 'nested-resources-1'],
	]);
	assert.ok(!s[0].text.includes('import'));
	assert.ok(s[1].text.includes('Use the callback form.'));
	assert.ok(!s[1].text.includes('<Aside'));
	assert.ok(s[1].text.includes('## not a heading inside code'));
});

test('buildIndex: API entries with plain-text hints and examples, guide sections with URLs', () => {
	const repo = makeRepo();
	try {
		const index = buildIndex({ repo, version: '4.2.0', strict: true });
		assert.equal(index.apiSource, 'v4.2.0.json');
		assert.equal(index.guidesSlug, 'v4-2-0');
		const findAll = index.entries.find((e) => e.id === 'api:model.findAll');
		assert.equal(findAll.hint, 'Returns records; use the where argument.');
		assert.equal(findAll.params[0].hint, 'The WHERE clause.');
		assert.deepEqual(findAll.params.map((p) => p.name), ['where']);
		assert.equal(findAll.example, 'users = model("User").findAll(where="active=1");');
		assert.equal(findAll.url, 'https://api.wheels.dev/v4-2-0/model-class/findall/');
		const nested = index.entries.find((e) => e.id === 'guides:basics/routing#nested-resources');
		assert.equal(nested.url, 'https://guides.wheels.dev/v4-2-0/basics/routing/#nested-resources');
		assert.equal(nested.page, 'Routing');
		assert.ok(index.entries.find((e) => e.id === 'guides:index'));
	} finally {
		rmSync(repo, { recursive: true, force: true });
	}
});

test('a snapshot version reads the snapshot API JSON and links to its api tree', () => {
	const repo = makeRepo({ api: { 'v4.2.0-snapshot.json': API } });
	try {
		const index = buildIndex({ repo, version: '4.2.0-snapshot.99', strict: true });
		assert.equal(index.apiSource, 'v4.2.0-snapshot.json');
		assert.equal(index.frameworkVersion, '4.2.0-snapshot.99');
		assert.ok(index.entries.find((e) => e.id === 'api:model.findAll').url.startsWith('https://api.wheels.dev/v4-2-0-snapshot/'));
	} finally {
		rmSync(repo, { recursive: true, force: true });
	}
});

test('--strict refuses a version whose API JSON or guides tree is missing', () => {
	const repo = makeRepo({ api: { 'v4.1.0.json': API }, trees: { 'v4-1-0': { 'index.mdx': 'x' } } });
	try {
		assert.throws(() => resolveSources({ repo, version: '4.2.0', strict: true }), /v4\.2\.0\.json is missing/);
		assert.throws(() => resolveSources({ repo, version: '4.1.0-snapshot.5', strict: true }), /v4\.1\.0-snapshot\.json is missing/);
	} finally {
		rmSync(repo, { recursive: true, force: true });
	}
});

test('without --strict it falls back to the newest API JSON and guides tree, and says which', () => {
	const repo = makeRepo({
		api: { 'v4.0.0.json': API, 'v4.1.0.json': API, 'v3.9.9.json': API },
		trees: { 'v4-0-0': { 'index.mdx': 'x' }, 'v4-1-0': { 'index.mdx': 'y' } },
	});
	try {
		const src = resolveSources({ repo, version: '4.2.0', strict: false });
		assert.equal(src.apiFile, 'v4.1.0.json');
		assert.equal(src.guidesSlug, 'v4-1-0');
	} finally {
		rmSync(repo, { recursive: true, force: true });
	}
});
