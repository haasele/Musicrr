import React from "react";

export function AppShell(
  props: React.PropsWithChildren<{
    title: string;
    /** Placed to the left of the title (e.g. back navigation). */
    headerLeft?: React.ReactNode;
    headerRight?: React.ReactNode;
    hideHeader?: boolean;
  }>
) {
  return (
    <div className="min-h-screen bg-[radial-gradient(1200px_500px_at_5%_-10%,#4f378b33,transparent),radial-gradient(1000px_450px_at_95%_0%,#7d526033,transparent),#141218] text-[#f5eff7]">
      {!props.hideHeader ? (
        <header className="sticky top-0 z-50 border-b border-[#49454f66] bg-[#211f26cc] px-4 py-4 backdrop-blur">
          <div className="mx-auto flex max-w-7xl items-center justify-between gap-3">
            <div className="flex min-w-0 flex-1 items-center gap-2 sm:gap-3">
              {props.headerLeft ? <div className="shrink-0">{props.headerLeft}</div> : null}
              <h1 className="min-w-0 truncate text-lg font-semibold tracking-wide">{props.title}</h1>
            </div>
            {props.headerRight ? <div className="flex shrink-0 items-center">{props.headerRight}</div> : null}
          </div>
        </header>
      ) : null}
      <main className="mx-auto max-w-7xl p-4 md:p-6">{props.children}</main>
    </div>
  );
}

export function NeonLoader() {
  return (
    <div className="inline-flex items-center gap-2 rounded-full border border-[#4a4458] bg-[#2b2930] px-3 py-1">
      <span className="h-2 w-2 animate-pulse rounded-full bg-[#d0bcff]" />
      <span className="h-2 w-2 animate-pulse rounded-full bg-[#ccc2dc] [animation-delay:120ms]" />
      <span className="h-2 w-2 animate-pulse rounded-full bg-[#e8def8] [animation-delay:240ms]" />
      <span className="text-xs text-[#e6e0e9]">Loading</span>
    </div>
  );
}
