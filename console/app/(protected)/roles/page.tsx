import type { Metadata } from "next";
import PageClient from "@/components/features/roles/_components/PageClient";

export const metadata: Metadata = {
  title: "Roles | Blocnet Admin Console",
  description: "Manage and review admin role matrix and role capabilities.",
};

export default function Page() {
  return <PageClient />;
}
