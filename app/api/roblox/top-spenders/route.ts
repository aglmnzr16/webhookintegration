import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export const runtime = 'nodejs';

// GET /api/roblox/top-spenders?source=<bagibagi|saweria>&limit=10
// Returns top spenders from specified platform
// Supports dual platform: BagiBagi and Saweria

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const source = (searchParams.get('source') || 'bagibagi').toLowerCase();
  const limit = Math.min(50, Math.max(1, Number(searchParams.get('limit') || 10)));

  try {
    // Query from appropriate table based on source
    let topSpenders;
    
    if (source === 'saweria') {
      topSpenders = await prisma.saweriaTopSpender.findMany({
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
    } else {
      // Default to BagiBagi
      topSpenders = await prisma.bagiBagiTopSpender.findMany({
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
    }

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
      count: formattedSpenders.length,
      source 
    });
  } catch (error) {
    console.error(`❌ Database error fetching ${source} top spenders:`, error);
    return NextResponse.json(
      { ok: false, error: 'Database error' },
      { status: 500 }
    );
  }
}
