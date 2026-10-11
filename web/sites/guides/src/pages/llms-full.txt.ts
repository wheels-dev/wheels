/** /llms-full.txt: every current-version page as Markdown, in one file. */
import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { GUIDES_VERSIONS } from '@wheels-dev/ui/data/versions';
import { currentVersion, docsOfVersion, llmsBundle, TEXT_HEADERS } from '@wheels-dev/ui/data/llms';

export const prerender = true;

export const GET: APIRoute = async () => {
	const current = currentVersion(GUIDES_VERSIONS);
	const docs = docsOfVersion(await getCollection('docs'), current.slug);
	const heading = `Wheels Guides for Wheels ${current.label}`;
	return new Response(llmsBundle('guides', heading, docs), { headers: TEXT_HEADERS });
};
