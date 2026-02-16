import { cookies } from "next/headers";
import { redirect } from "next/navigation";

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
      path: "/"
    });
    store.set("admin_role", "admin", {
      httpOnly: true,
      sameSite: "lax",
      path: "/"
    });

    redirect(nextPath.startsWith("/") ? nextPath : "/dashboard");
  }

  return (
    <div className="signin-wrap">
      <form action={mockSignIn} className="signin-card">
        <h2>Blocnet Admin Sign In</h2>
        <p className="muted">Shell auth only. Replace with backend auth next.</p>
        <div className="field">
          <label htmlFor="email">Email</label>
          <input id="email" name="email" type="email" required />
        </div>
        <div className="field">
          <label htmlFor="password">Password</label>
          <input id="password" name="password" type="password" required />
        </div>
        <input name="next" type="hidden" value="/dashboard" />
        <div style={{ marginTop: 14 }}>
          <button className="button" type="submit">
            Sign In
          </button>
        </div>
      </form>
    </div>
  );
}
