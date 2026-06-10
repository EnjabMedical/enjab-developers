import Link from "next/link";
import { TerminalGlyph } from "@/components/terminal-glyph";
import { EnjabByline } from "@/components/enjab-byline";

export const metadata = { title: "Page not found" };

export default function NotFound() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center px-6 py-24 text-center">
      <span
        className="flex size-14 items-center justify-center rounded-[25%] text-white"
        style={{ background: "linear-gradient(135deg, var(--color-teal) 0%, var(--color-navy) 100%)" }}
      >
        <TerminalGlyph className="size-7" />
      </span>
      <p className="mt-6 font-mono text-sm uppercase tracking-[0.2em] text-fd-muted-foreground">404</p>
      <h1 className="mt-2 text-2xl font-bold tracking-tight sm:text-3xl" style={{ color: "var(--color-navy)" }}>
        Page not found
      </h1>
      <p className="mt-2 max-w-sm text-fd-muted-foreground">
        This page doesn&apos;t exist or has moved. The docs are the place to start.
      </p>
      <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
        <Link
          href="/docs"
          className="inline-flex items-center gap-2 rounded-lg bg-fd-primary px-5 py-2.5 text-sm font-semibold text-fd-primary-foreground transition-opacity hover:opacity-90"
        >
          Read the docs
        </Link>
        <Link
          href="/"
          className="inline-flex items-center gap-2 rounded-lg border border-fd-border bg-fd-card px-5 py-2.5 text-sm font-semibold text-fd-foreground transition-colors hover:bg-fd-accent"
        >
          Home
        </Link>
      </div>
      <EnjabByline className="mt-10" />
    </main>
  );
}
