/** /llms.txt: the plain-text index for language models (see @wheels-dev/ui/data/llms). */
import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { API_VERSIONS } from '@wheels-dev/ui/data/versions';
import { llmsIndex, TEXT_HEADERS } from '@wheels-dev/ui/data/llms';

export const prerender = true;

export const GET: APIRoute = async () =>
	new Response(llmsIndex('api', API_VERSIONS, await getCollection('docs')), {
		headers: TEXT_HEADERS,
	});
