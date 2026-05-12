import { unified } from 'unified';
import remarkParse from 'remark-parse';
import remarkGfm from 'remark-gfm';
import remarkRehype from 'remark-rehype';
import rehypeSanitize, { defaultSchema } from 'rehype-sanitize';
import rehypeShiki from '@shikijs/rehype';
import rehypeStringify from 'rehype-stringify';

// Relax the sanitizer schema to keep shiki's syntax-highlighting
// class names (which default-schema would strip from <pre>/<code>/<span>).
// Sanitizer runs BEFORE shiki in the pipeline, so untrusted markdown HTML
// is stripped first; shiki's own output is then allowed through.
const schema = {
  ...defaultSchema,
  attributes: {
    ...defaultSchema.attributes,
    pre: [...(defaultSchema.attributes?.pre ?? []), 'className', 'style'],
    code: [...(defaultSchema.attributes?.code ?? []), 'className', 'style'],
    span: [...(defaultSchema.attributes?.span ?? []), 'className', 'style'],
  },
};

export async function renderMarkdown(src: string): Promise<string> {
  const file = await unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(remarkRehype, { allowDangerousHtml: false })
    .use(rehypeSanitize, schema)
    .use(rehypeShiki, { themes: { light: 'github-light', dark: 'github-dark' } })
    .use(rehypeStringify)
    .process(src);
  return String(file);
}
