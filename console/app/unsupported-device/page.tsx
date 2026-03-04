import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Desktop Required | Blocnet Console",
  description: "Blocnet Console is available on desktop and tablet browsers.",
};

export default function UnsupportedDevicePage() {
  return (
    <main className="min-h-screen bg-background text-foreground">
      <div className="mx-auto flex min-h-screen w-full max-w-xl flex-col items-center justify-center px-6 text-center">
        <h1 className="text-2xl font-semibold tracking-tight">
          Desktop Browser Required
        </h1>
        <p className="mt-3 text-sm text-muted-foreground">
          For security and usability, Blocnet Console is blocked on phone
          browsers. Please use a desktop or tablet browser.
        </p>
        <div className="mt-6">
          <Link
            href="/signin"
            className="inline-flex items-center rounded-md border border-border px-4 py-2 text-sm font-medium transition hover:bg-muted"
          >
            Go To Sign In
          </Link>
        </div>
      </div>
    </main>
  );
}
