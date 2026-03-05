import { NextResponse } from "next/server";

const API_BASE = process.env.BLOCNET_API_URL ?? "http://localhost:3080/api";

export async function POST(request: Request) {
  const body = await request.json().catch(() => ({}));
  const email = typeof body?.email === "string" ? body.email.trim() : "";

  if (!email) {
    return NextResponse.json(
      { message: "Email is required" },
      { status: 400 },
    );
  }

  try {
    const response = await fetch(`${API_BASE}/public/closed-alpha/join`, {
      method: "POST",
      cache: "no-store",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email }),
    });
    const payload = await response.json().catch(() => ({}));

    if (!response.ok) {
      return NextResponse.json(
        {
          message:
            typeof payload?.message === "string"
              ? payload.message
              : "Unable to join closed alpha at this time",
        },
        { status: response.status },
      );
    }

    return NextResponse.json(
      {
        ok: true,
        message: "Email submitted. You are on the closed alpha allowlist.",
      },
      { status: 200 },
    );
  } catch {
    return NextResponse.json(
      { message: "Unable to submit right now. Please try again." },
      { status: 503 },
    );
  }
}
