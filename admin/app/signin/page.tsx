import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { Hexagon } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export default function SignInPage() {
  async function mockSignIn(formData: FormData) {
    "use server";

    const email = String(formData.get("email") ?? "");
    const password = String(formData.get("password") ?? "");
    const nextPath = String(formData.get("next") ?? "/dashboard");

    if (!email || !password) {
      redirect("/signin?error=missing_credentials");
    }

    const store = await cookies();
    store.set("admin_session", "shell-session", {
      httpOnly: true,
      sameSite: "lax",
      path: "/",
    });
    store.set("admin_role", "admin", {
      httpOnly: true,
      sameSite: "lax",
      path: "/",
    });

    redirect(nextPath.startsWith("/") ? nextPath : "/dashboard");
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-background p-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 flex flex-col items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary">
            <Hexagon className="h-6 w-6 text-primary-foreground" />
          </div>
          <div className="text-center">
            <h1 className="text-xl font-bold tracking-tight">Blocnet Admin</h1>
            <p className="mt-1 text-sm text-muted-foreground">
              Sign in to manage the platform.
            </p>
          </div>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Sign In</CardTitle>
            <CardDescription>
              Shell auth only. Connect backend to enable real authentication.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form action={mockSignIn} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  name="email"
                  type="email"
                  placeholder="admin@blocnet.io"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="password">Password</Label>
                <Input
                  id="password"
                  name="password"
                  type="password"
                  placeholder="Enter your password"
                  required
                />
              </div>
              <input name="next" type="hidden" value="/dashboard" />
              <Button type="submit" className="w-full">
                Sign In
              </Button>
            </form>
          </CardContent>
        </Card>

        <p className="mt-4 text-center text-xs text-muted-foreground">
          Only users with <strong>owner</strong> or <strong>admin</strong> roles can access this panel.
        </p>
      </div>
    </div>
  );
}
