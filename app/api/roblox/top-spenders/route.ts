import { NextRequest, NextResponse } from 'next/server';
import { readJson } from '@/lib/storage';
import type { Donation } from '@/app/api/webhooks/bagibagi/route';

export const runtime = 'nodejs';

// GET /api/roblox/top-spenders?limit=10
// Returns top spenders aggregated by matchedUsername

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const limit = Math.min(50, Math.max(1, Number(searchParams.get('limit') || 10)));

  const donations = await readJson<Donation[]>('donations.json', []);

  // Aggregate donations by matchedUsername
  const spenderMap = new Map<string, number>();

  for (const donation of donations) {
    if (donation.matchedUsername) {
      const currentTotal = spenderMap.get(donation.matchedUsername) || 0;
      spenderMap.set(donation.matchedUsername, currentTotal + donation.amount);
    }
  }

  // Convert to array and sort by total amount
  const topSpenders = Array.from(spenderMap.entries())
    .map(([username, totalAmount]) => ({
      username,
      totalAmount
    }))
    .sort((a, b) => b.totalAmount - a.totalAmount)
    .slice(0, limit);

  return NextResponse.json({ 
    ok: true, 
    topSpenders,
    count: topSpenders.length 
  });
}
