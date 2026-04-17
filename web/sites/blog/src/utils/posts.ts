import { getCollection, type CollectionEntry } from 'astro:content';

export type Post = CollectionEntry<'posts'>;

export async function getAllPosts(): Promise<Post[]> {
  const posts = await getCollection('posts');
  return posts.sort(
    (a, b) => b.data.publishedAt.getTime() - a.data.publishedAt.getTime()
  );
}

export async function getAllTags(): Promise<Map<string, number>> {
  const posts = await getAllPosts();
  const counts = new Map<string, number>();
  for (const p of posts) {
    for (const tag of p.data.tags) {
      counts.set(tag, (counts.get(tag) ?? 0) + 1);
    }
  }
  return counts;
}

export async function getPostsByTag(tag: string): Promise<Post[]> {
  const posts = await getAllPosts();
  return posts.filter((p) => p.data.tags.includes(tag));
}

export function formatDate(d: Date): string {
  return d.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}
