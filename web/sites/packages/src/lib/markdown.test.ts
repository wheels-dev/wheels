import { describe, expect, it } from 'vitest';

describe('renderMarkdown', () => {
  it('renders basic markdown to HTML', async () => {
    const { renderMarkdown } = await import('./markdown');
    const html = await renderMarkdown('# Hello\n\nparagraph');
    expect(html).toContain('<h1>Hello</h1>');
    expect(html).toContain('<p>paragraph</p>');
  });

  it('drops raw HTML (remark-rehype allowDangerousHtml:false)', async () => {
    const { renderMarkdown } = await import('./markdown');
    const html = await renderMarkdown('ok\n\n<script>alert(1)</script>');
    expect(html).not.toContain('<script>');
    expect(html).not.toContain('alert(1)');
  });

  it('strips dangerous attributes via rehype-sanitize (defense-in-depth)', async () => {
    // rehype-sanitize's defaultSchema doesn't allow `onclick` on anchor tags.
    // remark-rehype produces real anchor nodes from [text](url) markdown;
    // the sanitizer is the layer enforcing the attribute allowlist.
    // Construct a custom tree to verify the sanitizer is present in the pipeline.
    const { renderMarkdown } = await import('./markdown');
    // Links in markdown only get href, so use a title-attribute attack vector
    // which also flows through to the output:
    const html = await renderMarkdown('[link](http://example.com "safe title")');
    // Confirm baseline: title SHOULD be present (defaultSchema allows it on anchors)
    expect(html).toContain('title="safe title"');
    // Now verify the sanitizer is enforcing by picking an attribute it strips.
    // The cleanest portable check: verify the sanitizer's own presence by
    // asserting javascript: protocol is stripped from href (which requires
    // rehype-sanitize's defaultSchema.protocols check — remark-rehype doesn't
    // filter protocols).
    const html2 = await renderMarkdown('[click](javascript:alert(1))');
    // remark-rehype passes javascript: URLs through unchanged to hast.
    // Only rehype-sanitize enforces the http/https/mailto allowlist on href.
    expect(html2).not.toContain('javascript:');
    expect(html2).not.toContain('alert(1)');
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

  it('returns empty string for empty input (callers show a placeholder)', async () => {
    const { renderMarkdown } = await import('./markdown');
    const html = await renderMarkdown('');
    expect(html.trim()).toBe('');
  });
});
