/**
 * Wrap every markdown-rendered `<table>` in an accessible horizontal-scroll
 * container, so a wide table stays inside the page while the `<table>` keeps
 * its native semantics. This replaces the `display: block` stopgap on
 * `.prose table`, which scrolled but dropped the implicit table role in
 * Safari + VoiceOver (#4575).
 *
 * Wrapper shape (the standard scrollable-region pattern):
 *
 *   <div class="table-scroll" role="region" aria-label="Table" tabindex="0">
 *
 * A table already inside a `div.table-scroll` is left alone, so the transform
 * is idempotent. No-op for anything that is not a table; plain hast recursion,
 * no dependencies. Companion to rehype-base-prefix.mjs.
 */

const WRAPPER_CLASS = 'table-scroll';

function isTableScrollWrapper(node) {
	return (
		node?.type === 'element' &&
		node.tagName === 'div' &&
		Array.isArray(node.properties?.className) &&
		node.properties.className.includes(WRAPPER_CLASS)
	);
}

export function rehypeTableScroll() {
	return (tree) => {
		const visit = (node) => {
			if (!node || !Array.isArray(node.children)) return;

			node.children = node.children.map((child) => {
				if (child?.type === 'element' && child.tagName === 'table' && !isTableScrollWrapper(node)) {
					// Recurse first, then wrap this table exactly once. `node` is the
					// table's parent, so this is where an existing wrapper is detected.
					visit(child);
					return {
						type: 'element',
						tagName: 'div',
						properties: {
							className: [WRAPPER_CLASS],
							role: 'region',
							ariaLabel: 'Table',
							tabIndex: 0,
						},
						children: [child],
					};
				}
				visit(child);
				return child;
			});
		};

		visit(tree);
	};
}

export default rehypeTableScroll;
