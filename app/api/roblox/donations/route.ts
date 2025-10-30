import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export const runtime = 'nodejs';

// GET /api/roblox/donations?username=<robloxName>&since=<timestamp>
// Returns recent donations, optionally filtered by robloxUsername if provided.
// Now using Prisma database

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
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

    // Query donations from database
    const dbDonations = await prisma.donation.findMany({
      where,
      select: {
        id: true,
        donationId: true,
        donorName: true,
        robloxUsername: true,
        amount: true,
        message: true,
        source: true,
        createdAt: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: limit,
    });

    // Format to match original response format
    const donations = dbDonations.map(d => ({
      id: d.donationId,
      ts: d.createdAt.getTime(),
      donor: d.donorName,
      amount: d.amount,
      message: d.message,
      matchedUsername: d.robloxUsername,
      source: d.source,
    }));

    return NextResponse.json({ ok: true, donations });
  } catch (error) {
    console.error('❌ Database error fetching donations:', error);
    return NextResponse.json(
      { ok: false, error: 'Database error' },
      { status: 500 }
    );
  }
}
