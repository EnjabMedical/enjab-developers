import { TerminalGlyph } from './terminal-glyph';

/**
 * Enjab Developers brand mark for the docs nav: the gradient `>_` square + the name.
 * Mirrors the @enjab-ui AppMark pattern (a tool's OWN mark, not the Enjab logo). The
 * Enjab parent logo appears only in the "an Enjab product" byline.
 */
export function NavMark() {
  return (
    <span className="flex items-center gap-2.5">
      <span
        className="flex size-7 shrink-0 items-center justify-center rounded-[25%] text-white"
        style={{ background: 'linear-gradient(135deg, #057C8B 0%, #1B3766 100%)' }}
      >
        <TerminalGlyph className="size-[55%]" />
      </span>
      <span className="font-semibold tracking-tight" style={{ color: '#1B3766' }}>
        Enjab Developers
      </span>
    </span>
  );
}
