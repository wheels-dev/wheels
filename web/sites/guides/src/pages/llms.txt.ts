/** /llms.txt: the plain-text index for language models (see @wheels-dev/ui/data/llms). */
import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { GUIDES_VERSIONS } from '@wheels-dev/ui/data/versions';
import { llmsIndex, TEXT_HEADERS } from '@wheels-dev/ui/data/llms';

export const prerender = true;

export const GET: APIRoute = async () =>
	new Response(llmsIndex('guides', GUIDES_VERSIONS, await getCollection('docs')), {
		headers: TEXT_HEADERS,
	});
