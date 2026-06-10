import Link from 'next/link';
import { ArrowRight, KeyRound, Paintbrush, RefreshCw, ServerCog, Terminal } from 'lucide-react';
import { EnjabByline } from '@/components/enjab-byline';

const cards = [
  {
    href: '/docs/get-started',
    icon: Terminal,
    title: 'Get started',
    desc: 'What Enjab is, how the tools fit together, and the fastest path to your first integration.',
  },
  {
    href: '/docs/sign-in-with-enjab',
    icon: KeyRound,
    title: 'Sign in with Enjab Auth',
    desc: 'Add Enjab as your identity provider. OAuth2 authorization-code flow, roles, and access control.',
  },
  {
    href: '/docs/enjab-ui',
    icon: Paintbrush,
    title: 'Enjab UI',
    desc: 'The Enjab design system. Install themed components from the registry and ship on-brand fast.',
  },
  {
    href: '/docs/standards',
    icon: ServerCog,
    title: 'Engineering Standards',
    desc: 'Infrastructure rules and general guidelines (security, deployment, pipeline) every tool must meet.',
  },
  {
    href: '/docs/update-an-existing-tool',
    icon: RefreshCw,
    title: 'Update an existing tool',
    desc: 'Bring an existing app up to the latest Enjab standards. Hand the steps straight to an agent.',
  },
];

export default function HomePage() {
  return (
    <main className="flex flex-1 flex-col">
      <section className="mx-auto w-full max-w-5xl px-6 pt-20 pb-12 text-center">
        <span
          className="mx-auto flex size-16 items-center justify-center rounded-[25%] text-white"
          style={{ background: 'linear-gradient(135deg, var(--color-teal) 0%, var(--color-navy) 100%)' }}
        >
          <Terminal className="size-8" strokeWidth={2} />
        </span>
        <h1
          className="mt-6 text-4xl font-bold tracking-tight sm:text-5xl"
          style={{ color: 'var(--color-navy)' }}
        >
          Build with Enjab
        </h1>
        <p className="mx-auto mt-4 max-w-2xl text-base text-fd-muted-foreground sm:text-lg">
          One place to learn every Enjab tool, written for both humans and coding agents. Point your
          agent at the docs and it reads them as raw markdown.
        </p>
        <div className="mt-7 flex flex-wrap items-center justify-center gap-3">
          <Link
            href="/docs"
            className="inline-flex items-center gap-2 rounded-lg bg-fd-primary px-5 py-2.5 text-sm font-semibold text-fd-primary-foreground transition-opacity hover:opacity-90"
          >
            Get started <ArrowRight className="size-4" />
          </Link>
          <Link
            href="/llms.txt"
            className="inline-flex items-center gap-2 rounded-lg border border-fd-border bg-fd-card px-5 py-2.5 font-mono text-[13px] text-fd-foreground transition-colors hover:bg-fd-accent"
          >
            /llms.txt
          </Link>
        </div>
      </section>

      <section className="mx-auto grid w-full max-w-5xl gap-4 px-6 pb-16 sm:grid-cols-2">
        {cards.map(({ href, icon: Icon, title, desc }) => (
          <Link
            key={href}
            href={href}
            className="group rounded-2xl border border-fd-border bg-fd-card p-6 transition-colors hover:border-fd-primary/40"
          >
            <span className="flex size-10 items-center justify-center rounded-lg bg-fd-accent text-fd-primary">
              <Icon className="size-5" />
            </span>
            <h2 className="mt-4 flex items-center gap-1.5 text-lg font-semibold" style={{ color: 'var(--color-navy)' }}>
              {title}
              <ArrowRight className="size-4 -translate-x-1 opacity-0 transition-all group-hover:translate-x-0 group-hover:opacity-100" />
            </h2>
            <p className="mt-1.5 text-sm text-fd-muted-foreground">{desc}</p>
          </Link>
        ))}
      </section>

      <section className="mx-auto w-full max-w-5xl px-6 pb-20">
        <div className="rounded-2xl border border-fd-border bg-fd-card p-6 sm:p-8">
          <h2 className="font-mono text-xs uppercase tracking-[0.14em] text-fd-muted-foreground">
            For coding agents
          </h2>
          <p className="mt-3 text-sm text-fd-foreground sm:text-base">
            Every page is a normal markdown file. Agents can fetch any page raw, or read the whole
            index at once:
          </p>
          <ul className="mt-4 grid gap-2 font-mono text-[13px]">
            <li className="text-fd-muted-foreground">
              <span className="text-fd-primary">/llms.txt</span> - the full index of pages
            </li>
            <li className="text-fd-muted-foreground">
              <span className="text-fd-primary">/llms-full.txt</span> - every page, concatenated
            </li>
            <li className="text-fd-muted-foreground">
              <span className="text-fd-primary">/llms.mdx/docs/&lt;path&gt;/content.md</span> - one page, raw
            </li>
          </ul>
        </div>
      </section>

      <footer className="mt-auto border-t border-fd-border py-6">
        <EnjabByline />
      </footer>
    </main>
  );
}
