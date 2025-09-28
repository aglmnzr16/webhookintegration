import { NextRequest, NextResponse } from 'next/server';
import { readJson } from '@/lib/storage';
import { sendDiscordLog, formatRupiah } from '@/lib/discord';

export const runtime = 'nodejs';

type Donation = {
  id: string;
  ts: number;
  donor: string;
  amount: number;
  message?: string;
  matchedUsername?: string;
  raw: any;
};

// GET endpoint untuk kirim statistik donasi ke Discord
export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const period = searchParams.get('period') || '24h'; // 24h, 7d, 30d

    const donations = await readJson<Donation[]>('donations.json', []);
    
    // Calculate time range
    const now = Date.now();
    let timeRange: number;
    let periodText: string;

    switch (period) {
      case '1h':
        timeRange = 60 * 60 * 1000;
        periodText = '1 Jam Terakhir';
        break;
      case '24h':
        timeRange = 24 * 60 * 60 * 1000;
        periodText = '24 Jam Terakhir';
        break;
      case '7d':
        timeRange = 7 * 24 * 60 * 60 * 1000;
        periodText = '7 Hari Terakhir';
        break;
      case '30d':
        timeRange = 30 * 24 * 60 * 60 * 1000;
        periodText = '30 Hari Terakhir';
        break;
      default:
        timeRange = 24 * 60 * 60 * 1000;
        periodText = '24 Jam Terakhir';
    }

    // Filter donations by time range
    const filteredDonations = donations.filter(d => now - d.ts <= timeRange);
    
    // Calculate statistics
    const totalDonations = filteredDonations.length;
    const totalAmount = filteredDonations.reduce((sum, d) => sum + d.amount, 0);
    const matchedDonations = filteredDonations.filter(d => d.matchedUsername).length;
    const matchRate = totalDonations > 0 ? (matchedDonations / totalDonations * 100).toFixed(1) : '0';

    // Top donors
    const donorStats = filteredDonations.reduce((acc, d) => {
      acc[d.donor] = (acc[d.donor] || 0) + d.amount;
      return acc;
    }, {} as Record<string, number>);

    const topDonors = Object.entries(donorStats)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 5)
      .map(([donor, amount]) => `**${donor}**: ${formatRupiah(amount)}`)
      .join('\n') || 'Belum ada donasi';

    // Top recipients
    const recipientStats = filteredDonations
      .filter(d => d.matchedUsername)
      .reduce((acc, d) => {
        acc[d.matchedUsername!] = (acc[d.matchedUsername!] || 0) + d.amount;
        return acc;
      }, {} as Record<string, number>);

    const topRecipients = Object.entries(recipientStats)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 5)
      .map(([recipient, amount]) => `**${recipient}**: ${formatRupiah(amount)}`)
      .join('\n') || 'Belum ada donasi matched';

    // Create Discord embed
    const embed = {
      title: `📊 STATISTIK DONASI - ${periodText.toUpperCase()}`,
      description: `Laporan aktivitas donasi BagiBagi`,
      color: 0x3498db,
      fields: [
        {
          name: '💰 Total Donasi',
          value: `${totalDonations} donasi\n${formatRupiah(totalAmount)}`,
          inline: true,
        },
        {
          name: '🎯 Match Rate',
          value: `${matchedDonations}/${totalDonations} (${matchRate}%)`,
          inline: true,
        },
        {
          name: '⭐ Rata-rata',
          value: totalDonations > 0 ? formatRupiah(totalAmount / totalDonations) : formatRupiah(0),
          inline: true,
        },
        {
          name: '🏆 Top Donors',
          value: topDonors,
          inline: true,
        },
        {
          name: '🎮 Top Recipients',
          value: topRecipients,
          inline: true,
        },
        {
          name: '📈 Trend',
          value: totalDonations > 0 ? '📈 Aktif' : '📉 Sepi',
          inline: true,
        },
      ],
      footer: {
        text: 'BagiBagi Analytics',
      },
      timestamp: new Date().toISOString(),
    };

    const success = await sendDiscordLog({
      embeds: [embed],
      username: 'Analytics Bot',
    });

    if (success) {
      return NextResponse.json({ 
        ok: true, 
        message: 'Statistics sent to Discord successfully',
        stats: {
          period: periodText,
          totalDonations,
          totalAmount,
          matchedDonations,
          matchRate: parseFloat(matchRate),
        }
      });
    } else {
      return NextResponse.json({ 
        ok: false, 
        error: 'Failed to send statistics to Discord' 
      }, { status: 500 });
    }
  } catch (error) {
    console.error('❌ Discord stats error:', error);
    return NextResponse.json({ 
      ok: false, 
      error: 'Internal server error',
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}
