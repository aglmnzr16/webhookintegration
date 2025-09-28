import { NextRequest, NextResponse } from 'next/server';
import { readJson } from '@/lib/storage';
import type { Donation } from '@/app/api/webhooks/bagibagi/route';

export const runtime = 'nodejs';

// GET /api/roblox/donations?username=<robloxName>&since=<ms>
// Returns recent donations, optionally filtered by matchedUsername if provided.

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const username = (searchParams.get('username') || '').trim();
  const since = Number(searchParams.get('since') || 0);
  const limit = Math.min(50, Math.max(1, Number(searchParams.get('limit') || 25)));

  const donations = await readJson<Donation[]>('donations.json', []);

  let filtered = donations;
  if (username) {
    const u = username.toLowerCase();
    filtered = filtered.filter((d) => (d.matchedUsername || '').toLowerCase() === u);
  }
  if (!Number.isNaN(since) && since > 0) {
    filtered = filtered.filter((d) => d.ts > since);
  }

  // return newest first
  filtered = filtered.sort((a, b) => b.ts - a.ts).slice(0, limit);

  return NextResponse.json({ ok: true, donations: filtered });
}
