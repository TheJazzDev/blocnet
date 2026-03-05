import { NextResponse } from 'next/server';

const API_BASE = process.env.BLOCNET_API_URL ?? 'http://localhost:3080/api';

export async function GET() {
  try {
    const response = await fetch(`${API_BASE}/users/public-stats`, {
      method: 'GET',
      cache: 'no-store',
    });

    const payload = await response.json().catch(() => ({}));

    if (!response.ok) {
      return NextResponse.json(
        {
          activeUsers: 0,
          projectsTracked: 0,
          totalUpdates: 0,
          totalCommunityPosts: 0,
          error: 'Failed to load stats',
        },
        { status: 200 },
      );
    }

    return NextResponse.json(payload, {
      status: 200,
    });
  } catch {
    return NextResponse.json(
      {
        activeUsers: 0,
        projectsTracked: 0,
        totalUpdates: 0,
        totalCommunityPosts: 0,
      },
      { status: 200 },
    );
  }
}
