import { source } from '@/lib/source';
import { DocsLayout } from 'fumadocs-ui/layouts/docs';
import { baseOptions } from '@/lib/layout.shared';
import { EnjabByline } from '@/components/enjab-byline';

export default function Layout({ children }: LayoutProps<'/docs'>) {
  return (
    <DocsLayout
      tree={source.getPageTree()}
      sidebar={{ footer: <EnjabByline className="py-2" /> }}
      {...baseOptions()}
    >
      {children}
    </DocsLayout>
  );
}
