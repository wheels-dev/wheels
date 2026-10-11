/**
 * Every docs page as Markdown at `<page URL>.md` (for example /v4-1-0/basics/routing.md), for
 * language models and other tools that read plain text. Listed in /llms.txt.
 */
import type { APIRoute, GetStaticPaths } from 'astro';
import { getCollection, type CollectionEntry } from 'astro:content';
import { markdownTwin, MARKDOWN_HEADERS } from '@wheels-dev/ui/data/llms';

export const prerender = true;

export const getStaticPaths = (async () => {
	const docs = await getCollection('docs', (doc) => !doc.data.draft);
	return docs.map((doc) => ({ params: { slug: doc.id }, props: { doc } }));
}) satisfies GetStaticPaths;

export const GET: APIRoute<{ doc: CollectionEntry<'docs'> }> = ({ props }) => {
	const { doc } = props;
	return new Response(markdownTwin(doc.data.title, doc.data.description, doc.body), {
		headers: MARKDOWN_HEADERS,
	});
};
