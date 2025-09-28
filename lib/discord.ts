// Discord webhook logging utility
export interface DiscordEmbed {
  title?: string;
  description?: string;
  color?: number;
  fields?: Array<{
    name: string;
    value: string;
    inline?: boolean;
  }>;
  footer?: {
    text: string;
  };
  timestamp?: string;
}

export interface DiscordWebhookPayload {
  content?: string;
  embeds?: DiscordEmbed[];
  username?: string;
  avatar_url?: string;
}

export async function sendDiscordLog(payload: DiscordWebhookPayload): Promise<boolean> {
  const webhookUrl = process.env.DISCORD_WEBHOOK_URL;
  
  if (!webhookUrl) {
    console.warn('⚠️ Discord webhook URL not configured');
    return false;
  }

  try {
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      console.error('❌ Discord webhook failed:', response.status, response.statusText);
      return false;
    }

    console.log('✅ Discord log sent successfully');
    return true;
  } catch (error) {
    console.error('❌ Discord webhook error:', error);
    return false;
  }
}

// Helper function untuk format Rupiah
export function formatRupiah(amount: number): string {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0,
  }).format(amount);
}

// Helper function untuk donation embed
export function createDonationEmbed(donation: {
  donor: string;
  amount: number;
  message?: string;
  matchedUsername?: string;
}): DiscordEmbed {
  const isMatched = !!donation.matchedUsername;
  
  return {
    title: isMatched ? '🎉 DONASI BARU - MATCHED!' : '💰 DONASI BARU',
    description: isMatched 
      ? `**${donation.donor}** mendonasi untuk **${donation.matchedUsername}**!`
      : `**${donation.donor}** mendonasi tanpa target spesifik`,
    color: isMatched ? 0x00ff00 : 0xffa500, // Green if matched, orange if not
    fields: [
      {
        name: '💵 Jumlah',
        value: formatRupiah(donation.amount),
        inline: true,
      },
      {
        name: '👤 Donor',
        value: donation.donor,
        inline: true,
      },
      ...(donation.matchedUsername ? [{
        name: '🎮 Target Roblox',
        value: donation.matchedUsername,
        inline: true,
      }] : []),
      ...(donation.message ? [{
        name: '💬 Pesan',
        value: donation.message.substring(0, 1000), // Discord field limit
        inline: false,
      }] : []),
    ],
    footer: {
      text: 'BagiBagi Webhook Integration',
    },
    timestamp: new Date().toISOString(),
  };
}

// Helper function untuk system logs
export function createSystemEmbed(
  title: string, 
  description: string, 
  type: 'info' | 'success' | 'warning' | 'error' = 'info'
): DiscordEmbed {
  const colors = {
    info: 0x3498db,     // Blue
    success: 0x2ecc71,  // Green
    warning: 0xf39c12,  // Orange
    error: 0xe74c3c,    // Red
  };

  const icons = {
    info: 'ℹ️',
    success: '✅',
    warning: '⚠️',
    error: '❌',
  };

  return {
    title: `${icons[type]} ${title}`,
    description,
    color: colors[type],
    footer: {
      text: 'Webhook Integration System',
    },
    timestamp: new Date().toISOString(),
  };
}
