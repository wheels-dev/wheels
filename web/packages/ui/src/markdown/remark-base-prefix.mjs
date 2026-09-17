/**
 * Prefix root-absolute `href`/`src` attributes on MDX JSX elements with Astro's
 * configured base.
 *
 * The companion rehype plugin only sees HTML produced from markdown, so it
 * cannot reach MDX components — `<LinkCard href="/v4-0-0/basics/routing/" />`
 * is compiled by the MDX pipeline, and Starlight renders the `href` verbatim.
 * Starlight's `components` override map covers layout components (Header,
 * Footer, …) but not content components like LinkCard, so this has to happen at
 * the mdast level instead. 128 such cards live in the guides content.
 *
 * No-op when `base` is unset or '/', which is the website build.
 */
export function remarkBasePrefix(options = {}) {
	const base = (options.base ?? '/').replace(/\/+$/, '');

	const prefix = (value) => {
		if (!base || typeof value !== 'string') return value;
		if (!value.startsWith('/')) return value; // relative, anchor, mailto:
		if (value.startsWith('//')) return value; // protocol-relative
		// Paths already rooted at the app's own /wheels/ namespace (e.g. guide
		// images served by the framework's wheelsGuideImage route) are not
		// docs-site paths and must not gain the docs base.
		if (value.startsWith('/wheels/')) return value;
		if (value === base || value.startsWith(base + '/')) return value; // already done
		return base + value;
	};

	return (tree) => {
		if (!base) return;

		const visit = (node) => {
			// MDX JSX elements carry `attributes` as an array of mdxJsxAttribute.
			if (node?.attributes && Array.isArray(node.attributes)) {
				for (const attr of node.attributes) {
					if (attr?.type !== 'mdxJsxAttribute') continue;
					if (attr.name !== 'href' && attr.name !== 'src') continue;
					attr.value = prefix(attr.value);
				}
			}
			for (const child of node?.children ?? []) visit(child);
		};

		visit(tree);
	};
}

export default remarkBasePrefix;
