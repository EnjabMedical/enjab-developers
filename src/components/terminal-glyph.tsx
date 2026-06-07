// The `>_` terminal glyph for the Enjab Developers brand mark. currentColor, so it
// inherits white inside the gradient square. Keep these paths identical to
// app/icon.tsx so the browser-tab favicon and the on-screen mark never drift.
export function TerminalGlyph({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
    >
      <polyline points="4 17 10 11 4 5" />
      <line x1="12" x2="20" y1="19" y2="19" />
    </svg>
  );
}
