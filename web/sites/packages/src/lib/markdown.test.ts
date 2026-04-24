import { describe, expect, it } from 'vitest';

describe('renderMarkdown', () => {
  it('renders basic markdown to HTML', async () => {
    const { renderMarkdown } = await import('./markdown');
    const html = await renderMarkdown('# Hello\n\nparagraph');
    expect(html).toContain('<h1>Hello</h1>');
    expect(html).toContain('<p>paragraph</p>');
  });

  it('strips <script> tags (rehype-sanitize)', async () => {
    const { renderMarkdown } = await import('./markdown');
    const html = await renderMarkdown('ok\n\n<script>alert(1)</script>');
    expect(html).not.toContain('<script>');
    expect(html).not.toContain('alert(1)');
  });

  it('strips javascript: URLs from links', async () => {
    const { renderMarkdown } = await import('./markdown');
    const html = await renderMarkdown('[click](javascript:alert(1))');
    expect(html).not.toContain('javascript:');
  });

  it('supports GitHub-flavored markdown (tables)', async () => {
    const { renderMarkdown } = await import('./markdown');
    const html = await renderMarkdown('| a | b |\n|---|---|\n| 1 | 2 |');
    expect(html).toContain('<table>');
    expect(html).toContain('<td>1</td>');
  });

  it('highlights fenced code blocks via shiki', async () => {
    const { renderMarkdown } = await import('./markdown');
    const html = await renderMarkdown('```js\nconst x = 1;\n```');
    expect(html).toMatch(/<pre[^>]*class="[^"]*shiki/);
  });
});
