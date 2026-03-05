import type { Metadata } from "next";
import ClosedAlphaPageClient from "@/components/features/closed-alpha/_components/PageClient";

export const metadata: Metadata = {
  title: "Closed Alpha | Blocnet Console",
  description:
    "Manage closed alpha tester allowlist emails and admission state.",
};

export default function ClosedAlphaPage() {
  return <ClosedAlphaPageClient />;
}
