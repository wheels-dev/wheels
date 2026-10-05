/**
 * /llms-small.txt: an outline of the current version (each page's title, Markdown link, description
 * and section headings), sized for an assistant's context.
 */
import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { API_VERSIONS } from '@wheels-dev/ui/data/versions';
import { currentVersion, docsOfVersion, llmsOutline, TEXT_HEADERS } from '@wheels-dev/ui/data/llms';

export const prerender = true;

export const GET: APIRoute = async () => {
	const current = currentVersion(API_VERSIONS);
	const docs = docsOfVersion(await getCollection('docs'), current.slug);
	const heading = `Wheels API Reference for Wheels ${current.label} (abridged)`;
	return new Response(llmsOutline('api', heading, docs), { headers: TEXT_HEADERS });
};
