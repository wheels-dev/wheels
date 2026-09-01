import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const posts = defineCollection({
	loader: glob({
		base: '../../content/blog/posts',
		pattern: '**/[^_]*.md',
	}),
	schema: z.object({
		title: z.string(),
		slug: z.string(),
		publishedAt: z.coerce.date(),
		updatedAt: z.coerce.date().nullable().optional(),
		author: z.string(),
		tags: z.array(z.string()).default([]),
		categories: z.array(z.string()).default([]),
		excerpt: z.string().default(''),
		coverImage: z.string().nullable().optional(),
		legacyId: z.string().optional(),
		// Discussion announcement posted to the repo's Discussions board when
		// the post is published. `discussionUrl` is written back by the
		// scheduler after the discussion is created (idempotency marker).
		announcement: z
			.object({
				title: z.string(),
				body: z.string(),
				category: z.string().default('Announcements'),
				discussionUrl: z.string().nullable().optional(),
			})
			.nullable()
			.optional(),
	}),
});

export const collections = { posts };
