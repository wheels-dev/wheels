/**
 * /llms-small.txt: an outline of the current version (each page's title, Markdown link, description
 * and section headings), sized for an assistant's context.
 */
import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { GUIDES_VERSIONS } from '@wheels-dev/ui/data/versions';
import { currentVersion, docsOfVersion, llmsOutline, TEXT_HEADERS } from '@wheels-dev/ui/data/llms';

export const prerender = true;

export const GET: APIRoute = async () => {
	const current = currentVersion(GUIDES_VERSIONS);
	const docs = docsOfVersion(await getCollection('docs'), current.slug);
	const heading = `Wheels Guides for Wheels ${current.label} (abridged)`;
	return new Response(llmsOutline('guides', heading, docs), { headers: TEXT_HEADERS });
};
