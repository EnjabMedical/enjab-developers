import type { Metadata } from 'next';
import { RootProvider } from 'fumadocs-ui/provider/next';
import './global.css';
import { Inter, Fragment_Mono } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
});

const fragmentMono = Fragment_Mono({
  subsets: ['latin'],
  weight: '400',
  variable: '--font-fragment-mono',
});

export const metadata: Metadata = {
  title: {
    default: 'Enjab Developers',
    template: '%s — Enjab Developers',
  },
  description:
    'Build with Enjab. Documentation for Enjab tools, written for both humans and coding agents: Sign in with Enjab, the Enjab UI design system, and more.',
};

export default function Layout({ children }: LayoutProps<'/'>) {
  return (
    <html
      lang="en"
      className={`${inter.variable} ${fragmentMono.variable}`}
      suppressHydrationWarning
    >
      <body className="flex flex-col min-h-screen font-sans">
        {/* Enjab is light mode only by design — no dark palette exists. */}
        <RootProvider theme={{ enabled: false }}>{children}</RootProvider>
      </body>
    </html>
  );
}
