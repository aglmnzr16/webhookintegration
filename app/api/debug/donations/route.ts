import { NextRequest, NextResponse } from 'next/server';
import { readJson } from '@/lib/storage';
import type { Donation } from '@/app/api/webhooks/bagibagi/route';

export const runtime = 'nodejs';

// GET /api/debug/donations
// Debug endpoint untuk cek donations data

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const limit = Math.min(100, Math.max(1, Number(searchParams.get('limit') || 20)));
  
  const donations = await readJson<Donation[]>('donations.json', []);
  
  // Get latest donations
  const latest = donations.slice(-limit).reverse();
  
  // Aggregate stats
  const withUsername = donations.filter(d => d.matchedUsername).length;
  const withoutUsername = donations.filter(d => !d.matchedUsername).length;
  
  // Top spenders calculation
  const spenderMap = new Map<string, { total: number, count: number }>();
  
  for (const donation of donations) {
    if (donation.matchedUsername) {
      const current = spenderMap.get(donation.matchedUsername) || { total: 0, count: 0 };
      spenderMap.set(donation.matchedUsername, {
        total: current.total + donation.amount,
        count: current.count + 1
      });
    }
  }
  
  const topSpenders = Array.from(spenderMap.entries())
    .map(([username, data]) => ({
      username,
      totalAmount: data.total,
      donationCount: data.count
    }))
    .sort((a, b) => b.totalAmount - a.totalAmount);
  
  return NextResponse.json({
    ok: true,
    stats: {
      total: donations.length,
      withMatchedUsername: withUsername,
      withoutMatchedUsername: withoutUsername,
      uniqueSpenders: topSpenders.length
    },
    topSpenders: topSpenders.slice(0, 10),
    latestDonations: latest.map(d => ({
      donor: d.donor,
      amount: d.amount,
      matchedUsername: d.matchedUsername,
      message: d.message,
      timestamp: new Date(d.ts).toISOString()
    }))
  });
}
