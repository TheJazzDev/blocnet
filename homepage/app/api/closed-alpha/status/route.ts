import { NextResponse } from "next/server";

const API_BASE = process.env.BLOCNET_API_URL ?? "http://localhost:3080/api";

export async function GET() {
  try {
    const response = await fetch(`${API_BASE}/public/closed-alpha/status`, {
      method: "GET",
      cache: "no-store",
      headers: { "Content-Type": "application/json" },
    });

    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      return NextResponse.json(
        { enabled: false, message: "Closed alpha status unavailable" },
        { status: 200 },
      );
    }

    return NextResponse.json(
      { enabled: payload?.enabled === true },
      { status: 200 },
    );
  } catch {
    return NextResponse.json(
      { enabled: false, message: "Closed alpha status unavailable" },
      { status: 200 },
    );
  }
}
