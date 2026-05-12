#!/usr/bin/env node
/**
 * Wayback Machine image recovery for migrated blog posts.
 *
 * The legacy blog posts reference images at https://cfwheels.org/... URLs
 * which now 301-redirect to https://wheels.dev/ (the content there is
 * unrelated). For every unique cfwheels.org image URL in web/content/blog/posts/,
 * query the Wayback Machine for the closest snapshot, download it locally,
 * and rewrite the markdown to point at /blog-images/<hash>.<ext>.
 *
 * Rate-limited to ~1 request per second against Wayback (their implicit
 * guideline). Run takes roughly 1 second per unique URL.
 *
 * Usage:  node web/scripts/recover-blog-images.mjs
 *         node web/scripts/recover-blog-images.mjs --dry-run
 */
import { readFileSync, writeFileSync, mkdirSync, readdirSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { resolve, join, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../..');

const POSTS_DIR = join(REPO_ROOT, 'web/content/blog/posts');
const IMAGES_DIR = join(REPO_ROOT, 'web/sites/blog/public/blog-images');
const LOG_PATH = join(REPO_ROOT, 'web/scripts/.wayback-log.json');

const DRY_RUN = process.argv.includes('--dry-run');
const REQUEST_DELAY_MS = 1100;

function urlToFilename(url) {
  const hash = createHash('sha1').update(url).digest('hex').slice(0, 12);
  let ext;
  try {
    ext = extname(new URL(url).pathname).toLowerCase();
  } catch {
    ext = '';
  }
  if (!ext || ext.length > 5) ext = '.jpg';
  return `${hash}${ext}`;
}

async function getWaybackSnapshot(url) {
  const api = `https://archive.org/wayback/available?url=${encodeURIComponent(url)}`;
  const res = await fetch(api);
  if (!res.ok) throw new Error(`Wayback API ${res.status}`);
  const data = await res.json();
  return data.archived_snapshots?.closest?.url || null;
}

async function downloadImage(snapshotUrl, outPath) {
  // Wayback serves snapshots at /web/{timestamp}/{url}. To get the raw image
  // without the Wayback toolbar/frame, insert 'im_' after the timestamp:
  // /web/{timestamp}im_/{url}
  const rawUrl = snapshotUrl.replace(/\/web\/(\d+)\//, '/web/$1im_/');
  const res = await fetch(rawUrl);
  if (!res.ok) throw new Error(`download ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  writeFileSync(outPath, buf);
  return buf.length;
}

// ---- collect unique URLs ----
const posts = readdirSync(POSTS_DIR).filter((f) => f.endsWith('.md'));
const urlOccurrences = new Map(); // url -> Set<filename>
const imagePattern = /!\[[^\]]*\]\((https?:\/\/cfwheels\.org\/[^)]+)\)/g;

for (const f of posts) {
  const content = readFileSync(join(POSTS_DIR, f), 'utf8');
  for (const m of content.matchAll(imagePattern)) {
    const url = m[1];
    if (!urlOccurrences.has(url)) urlOccurrences.set(url, new Set());
    urlOccurrences.get(url).add(f);
  }
}

console.error(`Found ${urlOccurrences.size} unique cfwheels.org image URLs across ${posts.length} posts`);

if (DRY_RUN) {
  console.error('\n--dry-run specified; exiting without fetches\n');
  for (const [url, files] of urlOccurrences) {
    console.error(`  ${url} (${files.size} posts)`);
  }
  process.exit(0);
}

mkdirSync(IMAGES_DIR, { recursive: true });

// Load prior log to resume / skip already-recovered URLs
let log = { recovered: {}, failed: {} };
if (existsSync(LOG_PATH)) {
  try {
    log = JSON.parse(readFileSync(LOG_PATH, 'utf8'));
  } catch {
    // reset on parse failure
  }
}

let recovered = 0, skipped = 0, failed = 0;
let i = 0;
for (const url of urlOccurrences.keys()) {
  i++;
  if (log.recovered[url]) {
    skipped++;
    continue;
  }
  if (log.failed[url]) {
    // Retry previously-failed URLs on re-run
  }

  const filename = urlToFilename(url);
  const outPath = join(IMAGES_DIR, filename);

  try {
    const snapshotUrl = await getWaybackSnapshot(url);
    if (!snapshotUrl) {
      console.warn(`[${i}/${urlOccurrences.size}] NO SNAPSHOT ${url}`);
      log.failed[url] = { reason: 'no snapshot', at: new Date().toISOString() };
      failed++;
      continue;
    }
    const size = await downloadImage(snapshotUrl, outPath);
    log.recovered[url] = { filename, size, snapshotUrl, at: new Date().toISOString() };
    recovered++;
    console.error(`[${i}/${urlOccurrences.size}] ${size}b ${filename}  <- ${url}`);
    await new Promise((r) => setTimeout(r, REQUEST_DELAY_MS));
  } catch (err) {
    console.warn(`[${i}/${urlOccurrences.size}] FAIL ${url}: ${err.message}`);
    log.failed[url] = { reason: err.message, at: new Date().toISOString() };
    failed++;
    await new Promise((r) => setTimeout(r, REQUEST_DELAY_MS));
  }

  // Persist log every 10 URLs in case of interruption
  if (i % 10 === 0) {
    writeFileSync(LOG_PATH, JSON.stringify(log, null, 2));
  }
}

writeFileSync(LOG_PATH, JSON.stringify(log, null, 2));
console.error(`\nRecovered: ${recovered}, skipped (already done): ${skipped}, failed: ${failed}`);

// ---- rewrite post markdown ----
let rewrittenPosts = 0;
for (const f of posts) {
  const path = join(POSTS_DIR, f);
  let content = readFileSync(path, 'utf8');
  let modified = false;
  for (const [url, meta] of Object.entries(log.recovered)) {
    if (content.includes(url)) {
      content = content.split(url).join(`/blog-images/${meta.filename}`);
      modified = true;
    }
  }
  if (modified) {
    writeFileSync(path, content);
    rewrittenPosts++;
  }
}

console.error(`Rewrote ${rewrittenPosts} post files with recovered image paths.`);
console.error(`Log saved to ${LOG_PATH}`);
