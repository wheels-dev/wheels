import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { checkLlms, readVersions } from './check-llms.mjs';

const O = 'https://guides.wheels.dev';
const SLUGS = ['v4-2-0', 'v4-1-0', 'v4-0-0'];

/** A minimal built guides site whose llms files cover v4-1-0 only. */
function fixture(overrides = {}) {
	const dir = mkdtempSync(join(tmpdir(), 'llms-check-'));
	const files = {
		'llms.txt': `# Wheels Guides\n\n- [Complete](${O}/llms-full.txt)\n- [v4.0](${O}/llms-txt/v4-0-0.txt)\n- [Routing](${O}/v4-1-0/basics/routing.md)\n- [API](https://api.wheels.dev/llms.txt)\n`,
		'llms-full.txt': `# Guides\n\n---\n\n# Routing\n\nSource: ${O}/v4-1-0/basics/routing/\n`,
		'llms-small.txt': `# Guides\n\n## [Routing](${O}/v4-1-0/basics/routing.md)\n`,
		'llms-txt/v4-0-0.txt': '# v4.0\n',
		'v4-1-0/basics/routing/index.html': '<html>routing</html>',
		'v4-1-0/basics/routing.md': '# Routing\n',
		'v4-0-0/basics/routing/index.html': '<html>old routing</html>',
		'v4-0-0/basics/routing.md': '# Routing\n',
		'v4-0-0-snapshot/index.html': '<meta http-equiv="refresh" content="0;url=/v4-0-0/">',
		...overrides,
	};
	for (const [name, body] of Object.entries(files)) {
		if (body === null) continue;
		const path = join(dir, name);
		mkdirSync(dirname(path), { recursive: true });
		writeFileSync(path, body);
	}
	return dir;
}

function run(overrides) {
	const distDir = fixture(overrides);
	try {
		return checkLlms({ distDir, site: 'guides', slugs: SLUGS, currentSlug: 'v4-1-0' });
	} finally {
		rmSync(distDir, { recursive: true, force: true });
	}
}

test('a consistent build passes', () => {
	assert.deepEqual(run(), []);
});

test('a non-current version in llms-full.txt fails', () => {
	const errors = run({
		'llms-full.txt': `# Guides\n\nSource: ${O}/v4-1-0/basics/routing/\n\nSource: ${O}/v4-0-0/basics/routing/\n`,
	});
	assert.ok(
		errors.some((e) => e.includes('llms-full.txt includes /v4-0-0/basics/routing/')),
		errors.join('\n')
	);
});

test('a non-current version in llms-small.txt fails', () => {
	const errors = run({
		'llms-small.txt': `## [Routing](${O}/v4-1-0/basics/routing.md)\n## [Routing](${O}/v4-2-0/basics/routing.md)\n`,
	});
	assert.ok(
		errors.some((e) => e.includes('llms-small.txt includes /v4-2-0/basics/routing.md')),
		errors.join('\n')
	);
});

test('a link in llms.txt to a file that was not built fails', () => {
	const errors = run({ 'llms.txt': `# Wheels Guides\n\n- [Gone](${O}/v4-1-0/gone.md)\n` });
	assert.ok(
		errors.some((e) => e.includes('links to https://guides.wheels.dev/v4-1-0/gone.md')),
		errors.join('\n')
	);
});

test('a page without its .md, and a .md without its page, fail', () => {
	const errors = run({ 'v4-1-0/basics/routing.md': null, 'v4-0-0/orphan.md': '# x\n' });
	assert.ok(errors.includes('v4-1-0/basics/routing/index.html has no .md'), errors.join('\n'));
	assert.ok(errors.includes('v4-0-0/orphan.md has no page'), errors.join('\n'));
});

test('a missing or empty llms file fails', () => {
	const errors = run({ 'llms-small.txt': null, 'llms-full.txt': '  \n' });
	assert.ok(errors.includes('llms-small.txt is missing'), errors.join('\n'));
	assert.ok(errors.includes('llms-full.txt is empty'), errors.join('\n'));
});

test('readVersions finds the slugs and the current entry', () => {
	const src = `export const GUIDES_VERSIONS: VersionMeta[] = [
	{ slug: 'v4-2-0', label: 'v4.2', status: 'snapshot' },
	{ slug: 'v4-1-0', label: 'v4.1', status: 'current' },
];
export const API_VERSIONS: VersionMeta[] = [
	{ slug: 'v4-1-0', label: 'v4.1', status: 'current' },
];`;
	assert.deepEqual(readVersions(src, 'guides'), {
		slugs: ['v4-2-0', 'v4-1-0'],
		currentSlug: 'v4-1-0',
	});
	assert.deepEqual(readVersions(src, 'api'), { slugs: ['v4-1-0'], currentSlug: 'v4-1-0' });
	assert.throws(
		() => readVersions(src.replace(/'current'/g, "'archived'"), 'guides'),
		/no 'current' entry/
	);
});
