import { source } from '@/lib/source';
import { llms } from 'fumadocs-core/source';

export const revalidate = false;

// Agent-first entry point. We replace Fumadocs' generic "# Docs" heading with a branded
// header that tells an agent how to fetch raw markdown, then list every page.
export function GET() {
  const list = llms(source).index().replace(/^#[^\n]*\n+/, '');

  const header = `# Enjab Developers

> Documentation for building on Enjab, for humans and coding agents. Every page below is
> also raw-fetchable markdown: fetch /llms.mdx/docs/<path>/content.md for a single page's
> source, or /llms-full.txt for every page concatenated into one document.

## Pages
`;

  return new Response(`${header}\n${list}\n`, {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
}
