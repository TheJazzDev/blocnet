export const dynamic = "force-dynamic";

import { headers } from "next/headers";
import Image from "next/image";
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
// import { EnvironmentWatermark } from "@/components/environment-watermark";

export default async function SignInPage() {
  const headerStore = await headers();
  const host = headerStore.get("x-forwarded-host") ?? headerStore.get("host");
  const environment = resolveAdminEnvironmentFromHost(host);
  const environmentLabel = getAdminEnvironmentLabel(environment);
  const hostName = (host ?? "unknown-host").toLowerCase();

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-background p-4">
      {/* <EnvironmentWatermark text={environmentLabel} /> */}

      <div className="relative z-10 w-full max-w-sm">
        <div className="mb-8 flex flex-col items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center overflow-hidden rounded-xl">
            <Image src="/logo2.png" alt="Blocnet" width={48} height={48} priority />
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
              Use your credentials to access the admin panel.
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
