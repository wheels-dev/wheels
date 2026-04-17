import rss from '@astrojs/rss';
import { getAllPosts } from '../utils/posts.ts';

export async function GET(context) {
  const posts = await getAllPosts();
  return rss({
    title: 'Wheels Blog',
    description: 'News, tutorials, and release announcements for Wheels.',
    site: context.site,
    items: posts.map((post) => ({
      title: post.data.title,
      pubDate: post.data.publishedAt,
      description: post.data.excerpt,
      link: `/posts/${post.data.slug}/`,
      author: post.data.author,
      categories: post.data.tags,
    })),
    customData: '<language>en-us</language>',
  });
}
