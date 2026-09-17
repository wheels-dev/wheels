/**
 * Prefix root-absolute URLs in rendered markdown with Astro's configured base.
 *
 * Astro's `base` rewrites the URLs Astro generates — its own assets and
 * Starlight's sidebar — but a link authored as `/v4-0-0/basics/associations/`
 * in content is emitted verbatim. That is correct when the site is served from
 * its own domain root, and broken when the same content is built for the local
 * docs bundle and served from `/wheels/guides/`: every such link points at the
 * app root instead. There are ~1000 of them in the guides content alone, so
 * rewriting at build time is the only sane approach.
 *
 * No-op when `base` is unset or '/', which is the website build.
 */
export function rehypeBasePrefix(options = {}) {
	const base = (options.base ?? '/').replace(/\/+$/, '');

	return (tree) => {
		if (!base) return;

		const visit = (node) => {
			if (node && node.type === 'element' && node.properties) {
				for (const attr of ['href', 'src']) {
					const value = node.properties[attr];
					if (typeof value !== 'string') continue;
					if (!value.startsWith('/')) continue; // relative, anchor, mailto:
					if (value.startsWith('//')) continue; // protocol-relative
					// Paths already rooted at the app's own /wheels/ namespace
					// (e.g. guide images served by wheelsGuideImage) are not
					// docs-site paths and must not gain the docs base.
					if (value.startsWith('/wheels/')) continue;
					if (value === base || value.startsWith(base + '/')) continue; // already done
					node.properties[attr] = base + value;
				}
			}
			for (const child of node?.children ?? []) visit(child);
		};

		visit(tree);
	};
}

export default rehypeBasePrefix;
