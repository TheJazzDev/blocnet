export const dynamic = "force-dynamic";

import { headers } from "next/headers";
import { Hexagon } from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { SignInForm } from "./sign-in-form";
import {
  getAdminEnvironmentLabel,
  resolveAdminEnvironmentFromHost,
} from "@/lib/environment";

export default async function SignInPage() {
  const headerStore = await headers();
  const host = headerStore.get("x-forwarded-host") ?? headerStore.get("host");
  const environment = resolveAdminEnvironmentFromHost(host);
  const environmentLabel = getAdminEnvironmentLabel(environment);
  const hostName = (host ?? "unknown-host").toLowerCase();
  const watermarkEnv = environmentLabel.toUpperCase();

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-background p-4">
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0 overflow-hidden"
      >
        <div className="absolute left-1/2 top-1/2 w-[220vmax] -translate-x-1/2 -translate-y-1/2 -rotate-[14deg]">
          <p
            className="select-none whitespace-nowrap text-center text-[clamp(2.8rem,8vw,7.5rem)] font-black uppercase tracking-[0.14em] text-primary/15"
          >
            {watermarkEnv} · {watermarkEnv} · {watermarkEnv}
          </p>
          <p className="mt-2 select-none whitespace-nowrap text-center text-[clamp(0.7rem,1.4vw,1.1rem)] font-semibold tracking-[0.12em] text-primary/35">
            {hostName} · {hostName} · {hostName}
          </p>
        </div>
      </div>

      <div className="relative z-10 w-full max-w-sm">
        <div className="mb-8 flex flex-col items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary">
            <Hexagon className="h-6 w-6 text-primary-foreground" />
          </div>
          <div className="text-center">
            <h1 className="text-xl font-bold tracking-tight">
              Blocnet Admin {environmentLabel}
            </h1>
            <p className="mt-1 text-sm text-muted-foreground">
              Sign in to manage the platform.
            </p>
            <p className="mt-1 text-xs text-muted-foreground">
              {hostName}
            </p>
          </div>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Sign In</CardTitle>
            <CardDescription>
              Use your Supabase credentials to access the admin panel.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <SignInForm />
          </CardContent>
        </Card>

        <p className="mt-4 text-center text-xs text-muted-foreground">
          Only users with <strong>owner</strong>, <strong>admin</strong>, or{" "}
          <strong>moderator</strong> roles can access this panel.
        </p>
      </div>
    </div>
  );
}
