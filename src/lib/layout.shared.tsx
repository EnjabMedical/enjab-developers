import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';
import { NavMark } from '@/components/nav-mark';
import { gitConfig } from './shared';

export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      title: <NavMark />,
    },
    // Enjab is light mode only — no theme toggle.
    themeSwitch: { enabled: false },
    githubUrl: `https://github.com/${gitConfig.user}/${gitConfig.repo}`,
  };
}
