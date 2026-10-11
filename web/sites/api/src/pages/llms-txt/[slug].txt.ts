/** /llms-txt/<version>.txt: every page of one docs version as Markdown, in one file. */
import type { APIRoute, GetStaticPaths } from 'astro';
import { getCollection } from 'astro:content';
import type { VersionMeta } from '@wheels-dev/ui/data/versions';
import { API_VERSIONS } from '@wheels-dev/ui/data/versions';
import { docsOfVersion, llmsBundle, setSlug, TEXT_HEADERS } from '@wheels-dev/ui/data/llms';

export const prerender = true;

export const getStaticPaths = (() =>
	API_VERSIONS.map((version) => ({
		params: { slug: setSlug(version) },
		props: { version },
	}))) satisfies GetStaticPaths;

export const GET: APIRoute<{ version: VersionMeta }> = async ({ props }) => {
	const docs = docsOfVersion(await getCollection('docs'), props.version.slug);
	const heading = `Wheels API Reference for Wheels ${props.version.label}`;
	return new Response(llmsBundle('api', heading, docs), { headers: TEXT_HEADERS });
};
