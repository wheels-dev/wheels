/**
 * Shared version metadata for the Starlight sites (guides + api) and the
 * VersionSwitcher component. Kept as a single source of truth so the
 * sidebar in each site's astro.config.mjs and the header switcher don't
 * drift apart.
 *
 * STATUS semantics:
 *   - 'current'   → stable, recommended reading
 *   - 'snapshot'  → pre-release / in-development
 *   - 'archived'  → older major or minor release still served for continuity
 */

export type VersionStatus = 'current' | 'snapshot' | 'archived';

export interface VersionMeta {
	/** URL-safe slug (no dots — e.g. 'v3-0-0'). */
	slug: string;
	/** Human-facing label (e.g. 'v3.0.0'). */
	label: string;
	/** Default collapsed state in the sidebar. */
	collapsed: boolean;
	/** Release-channel indicator. */
	status: VersionStatus;
}

/** Wheels Guides — the narrative docs at guides.wheels.dev. */
export const GUIDES_VERSIONS: VersionMeta[] = [
	{ slug: 'v4-0-0-snapshot', label: 'v4.0.0-SNAPSHOT', collapsed: false, status: 'snapshot' },
	{ slug: 'v3-0-0', label: 'v3.0.0', collapsed: true, status: 'current' },
	{ slug: 'v2-5-0', label: 'v2.5.0', collapsed: true, status: 'archived' },
];

/** Wheels API Reference — function-level docs at api.wheels.dev. */
export const API_VERSIONS: VersionMeta[] = [
	{ slug: 'v4-0-0-snapshot', label: 'v4.0.0-SNAPSHOT', collapsed: false, status: 'snapshot' },
	{ slug: 'v3-0-0', label: 'v3.0.0', collapsed: true, status: 'current' },
	{ slug: 'v2-5-0', label: 'v2.5.0', collapsed: true, status: 'archived' },
	{ slug: 'v2-4-0', label: 'v2.4.0', collapsed: true, status: 'archived' },
	{ slug: 'v2-3-0', label: 'v2.3.0', collapsed: true, status: 'archived' },
	{ slug: 'v2-2-0', label: 'v2.2.0', collapsed: true, status: 'archived' },
	{ slug: 'v2-1-0', label: 'v2.1.0', collapsed: true, status: 'archived' },
	{ slug: 'v2-0-0', label: 'v2.0.0', collapsed: true, status: 'archived' },
	{ slug: 'v1-4-5', label: 'v1.4.5', collapsed: true, status: 'archived' },
];

/**
 * Pick the version list for the site whose hostname is `hostname`.
 * Returns an empty array for non-Starlight sites so the switcher
 * renders no options and bails out quietly.
 */
export function versionsForHostname(hostname: string | undefined): VersionMeta[] {
	if (!hostname) return [];
	if (hostname.startsWith('guides')) return GUIDES_VERSIONS;
	if (hostname.startsWith('api')) return API_VERSIONS;
	return [];
}

/**
 * Find the equivalent slug in a target version, given the current
 * within-version path. Locked behavior per the Phase 3 spec:
 *   1. Exact match in the target version → use it
 *   2. Fuzzy match on the final 2 path segments → use it
 *   3. Fuzzy match on the final 1 path segment → use it
 *   4. No match → return null (caller should fall back to the target
 *      version's root URL)
 *
 * `targetEntries` is the set of within-version paths present in the
 * target version (one entry per generated page, without file extension).
 */
export function findEquivalentPath(
	currentRelativePath: string,
	targetEntries: Set<string>
): string | null {
	// Normalize: strip leading/trailing slashes.
	const needle = currentRelativePath.replace(/^\/+|\/+$/g, '');
	if (!needle) return null;

	// 1. Exact match
	if (targetEntries.has(needle)) return needle;

	const segments = needle.split('/').filter(Boolean);

	// 2. Fuzzy on final 2 segments
	if (segments.length >= 2) {
		const last2 = segments.slice(-2).join('/');
		for (const entry of targetEntries) {
			if (entry === last2 || entry.endsWith('/' + last2)) return entry;
		}
	}

	// 3. Fuzzy on final 1 segment
	const last1 = segments[segments.length - 1];
	if (last1) {
		for (const entry of targetEntries) {
			if (entry === last1 || entry.endsWith('/' + last1)) return entry;
		}
	}

	// 4. No match
	return null;
}

/**
 * Version option enriched with per-page navigation info. Produced by
 * computeVersionOptions() and consumed by the VersionSwitcher component.
 */
export interface VersionOption extends VersionMeta {
	url: string;
	isCurrent: boolean;
}

interface CollectionEntry {
	id: string;
}

/**
 * Compute the list of version options for the current page. Walks the
 * Starlight docs collection, groups entries by version slug, then for
 * each version computes the equivalent URL using findEquivalentPath().
 *
 * Caller provides `entries` from `await getCollection('docs')` so this
 * function stays framework-agnostic and testable. `entryId` is the
 * current route's entry id (e.g., 'v4-0-0-snapshot/introduction/readme/
 * beginner-tutorial-hello-world').
 *
 * Returns { options, currentVersion } or null if we couldn't resolve
 * (non-Starlight site or no version metadata for this hostname).
 */
export function computeVersionOptions(
	entries: CollectionEntry[],
	entryId: string,
	hostname: string | undefined
): { options: VersionOption[]; currentVersion: VersionOption | null } | null {
	const versions = versionsForHostname(hostname);
	if (versions.length === 0 || !entryId) return null;

	const [currentSlug, ...rest] = entryId.split('/');
	const currentRelativePath = rest.join('/');

	// Group entries by version for O(1) set lookups during fuzzy match.
	const entriesByVersion = new Map<string, Set<string>>();
	for (const entry of entries) {
		const [v, ...p] = entry.id.split('/');
		if (!v) continue;
		if (!entriesByVersion.has(v)) entriesByVersion.set(v, new Set<string>());
		const pathWithinVersion = p.join('/');
		if (pathWithinVersion) entriesByVersion.get(v)!.add(pathWithinVersion);
	}

	const options: VersionOption[] = versions.map((v) => {
		const isCurrent = v.slug === currentSlug;
		const targetEntries = entriesByVersion.get(v.slug) ?? new Set<string>();
		const equivalent = isCurrent
			? currentRelativePath
			: (findEquivalentPath(currentRelativePath, targetEntries) ?? null);
		const url = equivalent ? `/${v.slug}/${equivalent}/` : `/${v.slug}/`;
		return { ...v, url, isCurrent };
	});

	const currentVersion = options.find((o) => o.isCurrent) ?? null;
	return { options, currentVersion };
}
