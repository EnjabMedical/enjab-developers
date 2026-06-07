/**
 * "an Enjab product" byline. The Enjab parent logo lives ONLY here (each tool shows
 * its own mark elsewhere). The logo loads from the hosted URL, so no local asset is
 * needed. Fixed size and weight on purpose — do not restyle.
 */
export function EnjabByline({ className }: { className?: string }) {
  return (
    <div
      className={`flex items-center justify-center gap-2 text-[11px] text-fd-muted-foreground ${className ?? ''}`}
    >
      an
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="https://ui.enjab.ae/enjab-logo.png" alt="Enjab" className="h-6 w-auto" />
      product
    </div>
  );
}
