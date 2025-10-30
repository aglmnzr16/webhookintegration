import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export const runtime = 'nodejs';

// GET /api/roblox/donations?source=<bagibagi|saweria>&username=<robloxName>&since=<timestamp>
// Returns recent donations from specified platform
// Supports dual platform: BagiBagi and Saweria

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const source = (searchParams.get('source') || 'bagibagi').toLowerCase();
  const username = (searchParams.get('username') || '').trim();
  const sinceParam = searchParams.get('since') || '';
  const limit = Math.min(50, Math.max(1, Number(searchParams.get('limit') || 25)));

  try {
    // Build query filters
    const where: any = {};
    
    if (username) {
      where.robloxUsername = {
        equals: username,
        mode: 'insensitive', // Case-insensitive matching
      };
    }
    
    if (sinceParam) {
      const since = Number(sinceParam);
      if (!Number.isNaN(since) && since > 0) {
        where.createdAt = {
          gte: new Date(since),
        };
      }
    }

    // Query from appropriate table based on source
    let dbDonations;
    
    if (source === 'saweria') {
      dbDonations = await prisma.saweriaDonation.findMany({
        where,
        select: {
          id: true,
          donationId: true,
          donorName: true,
          robloxUsername: true,
          amount: true,
          message: true,
          createdAt: true,
        },
        orderBy: {
          createdAt: 'desc',
        },
        take: limit,
      });
    } else {
      // Default to BagiBagi
      dbDonations = await prisma.bagiBagiDonation.findMany({
        where,
        select: {
          id: true,
          donationId: true,
          donorName: true,
          robloxUsername: true,
          amount: true,
          message: true,
          createdAt: true,
        },
        orderBy: {
          createdAt: 'desc',
        },
        take: limit,
      });
    }

    // Format to match original response format
    const donations = dbDonations.map(d => ({
      id: d.donationId,
      ts: d.createdAt.getTime(),
      donor: d.donorName,
      amount: d.amount,
      message: d.message,
      matchedUsername: d.robloxUsername,
      source: source, // Include source in response
    }));

    return NextResponse.json({ ok: true, donations, source });
  } catch (error) {
    console.error(`❌ Database error fetching ${source} donations:`, error);
    return NextResponse.json(
      { ok: false, error: 'Database error' },
      { status: 500 }
    );
  }
}
