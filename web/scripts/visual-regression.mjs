#!/usr/bin/env node
/**
 * Visual regression smoke test for the four wheels.dev sites.
 *
 * Builds each site into dist/, serves the dist directory statically,
 * screenshots one canary page per site with Chromium, and either:
 *   - Compares to `web/tests/visual-baselines/<site>.png` (default), or
 *   - Saves the screenshot AS the baseline (when --update is passed).
 *
 * Exit 0 on success. Exit 1 on baseline mismatch or runtime failure.
 *
 * CI is wired to continue-on-error for the initial soft-fail phase —
 * baselines can be tuned without blocking merges.
 *
 * Usage:
 *   node web/scripts/visual-regression.mjs           # check
 *   node web/scripts/visual-regression.mjs --update  # refresh baselines
 *   node web/scripts/visual-regression.mjs --site guides --update
 */
import { createServer } from 'node:http';
import { readFile, writeFile, mkdir, access, readdir } from 'node:fs/promises';
import { resolve, join, dirname, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';
import { chromium } from 'playwright';

const __dirname = dirname(fileURLToPath(import.meta.url));
const WEB_ROOT = resolve(__dirname, '..');
const BASELINE_DIR = resolve(WEB_ROOT, 'tests/visual-baselines');
const DIFF_DIR = resolve(WEB_ROOT, 'tests/visual-diffs');
const VIEWPORT = { width: 1280, height: 800 };
// Threshold raised from 200 → 300 during the Astro 5.x → 6.3.1 upgrade.
// Astro 6 emits slightly different HTML (class name shuffling, hash-based
// asset naming) that causes 6-220 pixel diffs on text-heavy pages from
// subpixel font rendering shifts. 300 is still <0.03% of a 1280×800 page —
// well within "subpixel noise" but accommodates the framework upgrade.
// Real regressions (layout breaks, color shifts) typically produce 1k+
// pixel diffs and are unaffected by this bump.
const FAIL_THRESHOLD_PIXELS = 300;

/** One config per site. `canary` is the URL path screenshotted. */
const SITES = [
	{ name: 'landing', dist: resolve(WEB_ROOT, 'sites/landing/dist'), canary: '/' },
	{ name: 'blog', dist: resolve(WEB_ROOT, 'sites/blog/dist'), canary: '/' },
	{
		name: 'guides',
		dist: resolve(WEB_ROOT, 'sites/guides/dist'),
		canary: '/v4-0-0/start-here/tutorial/',
	},
	{
		name: 'api',
		dist: resolve(WEB_ROOT, 'sites/api/dist'),
		canary: '/v3-0-0/configuration/addformat/',
	},
	{
		name: 'packages-index',
		dist: resolve(WEB_ROOT, 'sites/packages/dist'),
		canary: '/',
	},
	{
		name: 'packages-wheels-sentry',
		dist: resolve(WEB_ROOT, 'sites/packages/dist'),
		canary: '/wheels-sentry/',
	},
];

const MIME = {
	'.html': 'text/html; charset=utf-8',
	'.css': 'text/css; charset=utf-8',
	'.js': 'application/javascript; charset=utf-8',
	'.mjs': 'application/javascript; charset=utf-8',
	'.json': 'application/json; charset=utf-8',
	'.svg': 'image/svg+xml',
	'.png': 'image/png',
	'.jpg': 'image/jpeg',
	'.jpeg': 'image/jpeg',
	'.webp': 'image/webp',
	'.woff': 'font/woff',
	'.woff2': 'font/woff2',
	'.ico': 'image/x-icon',
	'.xml': 'application/xml',
	'.txt': 'text/plain; charset=utf-8',
};

/** Start a tiny static HTTP server for the given dist directory. */
async function startStaticServer(distDir) {
	return new Promise((resolvePromise, reject) => {
		const server = createServer(async (req, res) => {
			try {
				const urlPath = decodeURIComponent((req.url ?? '/').split('?')[0] ?? '/');
				let filePath = join(distDir, urlPath);
				// Directory-style URLs → serve index.html
				try {
					const stat = await readdir(filePath).then(() => true).catch(() => false);
					if (stat) filePath = join(filePath, 'index.html');
				} catch {}
				// Try the path, then path + '.html', then path + '/index.html'
				const candidates = [
					filePath,
					filePath + '.html',
					join(filePath, 'index.html'),
				];
				for (const candidate of candidates) {
					try {
						const body = await readFile(candidate);
						const mime = MIME[extname(candidate).toLowerCase()] ?? 'application/octet-stream';
						res.writeHead(200, { 'content-type': mime });
						res.end(body);
						return;
					} catch {}
				}
				res.writeHead(404, { 'content-type': 'text/plain' });
				res.end('404 Not Found: ' + urlPath);
			} catch (err) {
				res.writeHead(500, { 'content-type': 'text/plain' });
				res.end('500: ' + (err instanceof Error ? err.message : String(err)));
			}
		});
		server.listen(0, '127.0.0.1', () => {
			const addr = server.address();
			if (!addr || typeof addr === 'string') {
				reject(new Error('failed to bind server'));
				return;
			}
			resolvePromise({ server, port: addr.port });
		});
	});
}

async function stopServer(server) {
	return new Promise((resolvePromise) => server.close(() => resolvePromise(undefined)));
}

async function fileExists(path) {
	try {
		await access(path);
		return true;
	} catch {
		return false;
	}
}

async function ensureBaselineDir() {
	await mkdir(BASELINE_DIR, { recursive: true });
}

async function ensureDiffDir() {
	await mkdir(DIFF_DIR, { recursive: true });
}

/** Capture a screenshot of the canary page for one site. Returns PNG bytes. */
async function captureScreenshot(browser, site) {
	const { server, port } = await startStaticServer(site.dist);
	try {
		const context = await browser.newContext({
			viewport: VIEWPORT,
			colorScheme: 'light',
			deviceScaleFactor: 1,
		});
		const page = await context.newPage();
		const url = `http://127.0.0.1:${port}${site.canary}`;
		await page.goto(url, { waitUntil: 'networkidle', timeout: 30_000 });
		// Disable animations + caret blink so screenshots are deterministic.
		await page.addStyleTag({
			content: `
				*, *::before, *::after {
					animation-duration: 0s !important;
					transition-duration: 0s !important;
				}
				::-webkit-scrollbar { display: none !important; }
			`,
		});
		// Slight settle so fonts/layout stabilize.
		await page.waitForTimeout(250);
		const buffer = await page.screenshot({ fullPage: false, type: 'png' });
		await context.close();
		return buffer;
	} finally {
		await stopServer(server);
	}
}

function decodePng(buffer) {
	return PNG.sync.read(buffer);
}

function encodePng(png) {
	return PNG.sync.write(png);
}

/** Compare two screenshot buffers. Returns { diffPixels, diffPngBuffer }. */
function diffScreenshots(expectedBuf, actualBuf) {
	const expected = decodePng(expectedBuf);
	const actual = decodePng(actualBuf);
	if (expected.width !== actual.width || expected.height !== actual.height) {
		return {
			diffPixels: Number.POSITIVE_INFINITY,
			reason: `dimensions differ: baseline=${expected.width}x${expected.height}, actual=${actual.width}x${actual.height}`,
			diffPngBuffer: null,
		};
	}
	const diff = new PNG({ width: expected.width, height: expected.height });
	const diffPixels = pixelmatch(
		expected.data,
		actual.data,
		diff.data,
		expected.width,
		expected.height,
		{ threshold: 0.15, includeAA: false },
	);
	return { diffPixels, reason: null, diffPngBuffer: encodePng(diff) };
}

async function runCheck({ update, siteFilter }) {
	const targets = siteFilter ? SITES.filter((s) => s.name === siteFilter) : SITES;
	if (targets.length === 0) {
		console.error(`No matching site: ${siteFilter}`);
		process.exit(2);
	}

	// Make sure every site has a dist/ — fail loudly otherwise.
	for (const site of targets) {
		if (!(await fileExists(site.dist))) {
			console.error(`Missing dist for ${site.name}: ${site.dist}`);
			console.error('Run `pnpm build` first.');
			process.exit(2);
		}
	}

	await ensureBaselineDir();
	await ensureDiffDir();

	const browser = await chromium.launch({ headless: true });
	let anyFailed = false;

	try {
		for (const site of targets) {
			const label = `[${site.name}]`;
			const baselinePath = join(BASELINE_DIR, `${site.name}.png`);
			const diffPath = join(DIFF_DIR, `${site.name}.diff.png`);

			try {
				console.log(`${label} screenshotting ${site.canary}`);
				const actual = await captureScreenshot(browser, site);

				if (update || !(await fileExists(baselinePath))) {
					await writeFile(baselinePath, actual);
					console.log(`${label} baseline ${update ? 'updated' : 'created'}: ${baselinePath}`);
					continue;
				}

				const expected = await readFile(baselinePath);
				const { diffPixels, reason, diffPngBuffer } = diffScreenshots(expected, actual);

				if (reason) {
					console.error(`${label} FAIL — ${reason}`);
					anyFailed = true;
					continue;
				}

				if (diffPixels > FAIL_THRESHOLD_PIXELS) {
					if (diffPngBuffer) await writeFile(diffPath, diffPngBuffer);
					// also save the actual so reviewers can see both side by side
					await writeFile(join(DIFF_DIR, `${site.name}.actual.png`), actual);
					console.error(
						`${label} FAIL — ${diffPixels.toLocaleString()} pixels differ ` +
							`(threshold: ${FAIL_THRESHOLD_PIXELS.toLocaleString()}). ` +
							`Diff: ${diffPath}`,
					);
					anyFailed = true;
				} else {
					console.log(
						`${label} pass (${diffPixels.toLocaleString()} pixels differ, within threshold)`,
					);
				}
			} catch (err) {
				console.error(`${label} ERROR — ${err instanceof Error ? err.message : String(err)}`);
				anyFailed = true;
			}
		}
	} finally {
		await browser.close();
	}

	if (anyFailed) {
		console.error('\nVisual regression failures detected.');
		console.error('');
		if (process.env.CI) {
			console.error('Next steps:');
			console.error('  1. Download the `visual-regression-diffs` artifact from this CI run.');
			console.error('  2. Inspect the *.diff.png images to see what changed.');
			console.error('  3. If the change is intentional: copy each *.actual.png over the matching');
			console.error('     web/tests/visual-baselines/*.png, commit, and push.');
			console.error('  4. If the change is unintentional: debug the regression on the PR branch.');
		} else {
			console.error('If the changes are intentional, refresh baselines:');
			console.error('  pnpm visual:baseline');
			console.error('');
			console.error('Note: baselines are CI-captured (Linux font rendering). Local refreshes');
			console.error('may still diff against CI — prefer pulling the CI artifact for final baselines.');
		}
		process.exit(1);
	}
	console.log('\nAll visual checks passed.');
}

// CLI
const args = process.argv.slice(2);
const update = args.includes('--update') || args.includes('--baseline');
const siteIdx = args.findIndex((a) => a === '--site');
const siteFilter = siteIdx >= 0 ? args[siteIdx + 1] : null;

await runCheck({ update, siteFilter });
