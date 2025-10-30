import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export const runtime = 'nodejs';

// GET /api/roblox/top-spenders?limit=10
// Returns top spenders aggregated by robloxUsername
// Now using Prisma database with pre-aggregated TopSpender table

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const limit = Math.min(50, Math.max(1, Number(searchParams.get('limit') || 10)));

  try {
    // Query pre-aggregated TopSpender table (FAST!)
    const topSpenders = await prisma.topSpender.findMany({
      select: {
        robloxUsername: true,
        totalAmount: true,
        donationCount: true,
        lastDonation: true,
      },
      orderBy: {
        totalAmount: 'desc',
      },
      take: limit,
    });

    // Format response to match expected format
    const formattedSpenders = topSpenders.map(spender => ({
      username: spender.robloxUsername,
      totalAmount: spender.totalAmount,
      donationCount: spender.donationCount,
      lastDonation: spender.lastDonation.toISOString(),
    }));

    return NextResponse.json({ 
      ok: true, 
      topSpenders: formattedSpenders,
      count: formattedSpenders.length 
    });
  } catch (error) {
    console.error('❌ Database error fetching top spenders:', error);
    return NextResponse.json(
      { ok: false, error: 'Database error' },
      { status: 500 }
    );
  }
}
