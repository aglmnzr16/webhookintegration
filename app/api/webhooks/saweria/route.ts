import { NextRequest, NextResponse } from 'next/server';
import { readJson, writeJson } from '@/lib/storage';
import { sendDiscordLog, createDonationEmbed, createSystemEmbed } from '@/lib/discord';
import { prisma } from '@/lib/prisma';

export const runtime = 'nodejs';

// Types for stored donations
export type Donation = {
  id: string;
  ts: number;
  donor: string;
  amount: number;
  message?: string;
  matchedUsername?: string;
  raw: any;
};

type DonationsFile = Donation[];

type UsernameMap = Record<string, string>; // code -> robloxUsername

function pickAmount(body: any): number {
  const candidates = [
    body?.amount,
    body?.nominal,
    body?.total,
    body?.value,
  ];
  for (const v of candidates) {
    const n = Number(v);
    if (!Number.isNaN(n) && n >= 0) return n;
  }
  return 0;
}

function pickDonor(body: any): string {
  return (
    body?.donor ||
    body?.donator ||
    body?.name ||
    body?.username ||
    'Anonymous'
  );
}

function pickMessage(body: any): string | undefined {
  return body?.message ?? body?.note ?? body?.memo ?? undefined;
}

function extractCodeFromMessage(msg?: string): string | undefined {
  if (!msg) return undefined;
  // Look for token-like code of 4-24 alphanum/underscore prefixed by # or CODE:
  const m = msg.match(/(?:#|code[:=]\s*)([A-Za-z0-9_\-]{4,24})/i);
  return m?.[1];
}

export async function POST(req: NextRequest) {
  console.log('🔔 Webhook received from Saweria');
  
  // Read body as JSON (Saweria should POST JSON). If not JSON, try text->JSON parse.
  let body: any;
  try {
    if (req.headers.get('content-type')?.includes('application/json')) {
      body = await req.json();
    } else {
      const text = await req.text();
      try { body = JSON.parse(text); } catch { body = { raw: text }; }
    }
    
    // ========== DEBUG: PRINT RAW SAWERIA DATA ==========
    console.log('🔍 ========== SAWERIA RAW DATA START ==========');
    console.log('📦 Full Body:', JSON.stringify(body, null, 2));
    console.log('📊 Body Keys:', Object.keys(body));
    console.log('💰 Amount field:', body.amount, '(type:', typeof body.amount, ')');
    console.log('👤 Donor field:', body.donor, '(type:', typeof body.donor, ')');
    console.log('👤 Name field:', body.name, '(type:', typeof body.name, ')');
    console.log('💬 Message field:', body.message);
    console.log('🔍 ========== SAWERIA RAW DATA END ==========');
  } catch (e) {
    console.error('❌ Failed to parse webhook body:', e);
    return NextResponse.json({ ok: false, error: 'Failed to parse body' }, { status: 400 });
  }

  // Saweria webhook verification (OPTIONAL - Saweria tidak kirim token di header)
  // Saweria hanya kirim POST request dengan JSON body
  // Untuk security, bisa validate source IP atau webhook signature (jika ada)
  
  // Optional: Check if request from Saweria IP (if known)
  const forwardedFor = req.headers.get('x-forwarded-for');
  const realIp = req.headers.get('x-real-ip');
  console.log('🌐 Request from IP:', realIp || forwardedFor || 'unknown');
  
  // Optional: Token validation (if Saweria adds support later)
  const expectedToken = process.env.SAWERIA_WEBHOOK_TOKEN;
  const gotToken = req.headers.get('x-webhook-token') || body?.token;
  
  if (expectedToken && gotToken && gotToken !== expectedToken) {
    console.log('❌ Saweria webhook token mismatch');
    return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });
  }

  // Extract donation data from webhook body
  const donor = body.donor || body.name || 'Anonymous';
  const amount = body.amount || 0;
  const message = body.message || '';

  console.log('💰 Processing donation:', { donor, amount, message });

  // METODE 1: Extract username from message using code pattern (backward compatibility)
  let matchedUsername = null;
  console.log('🔍 Initial matchedUsername:', matchedUsername);
  if (body.message) {
    const codeMatch = body.message.match(/#([A-Z0-9]{6})/);
    if (codeMatch) {
      const code = codeMatch[1];
      console.log('🔍 Found code in message:', code);
      
      // Look up username by code
      const registrations = await readJson<Record<string, string>>('registrations.json', {});
      for (const [username, userCode] of Object.entries(registrations)) {
        if (userCode === code) {
          matchedUsername = username;
          console.log('✅ Code matched to username:', username);
          break;
        }
      }
      
      if (!matchedUsername) {
        console.log('❌ Code not found in registrations');
      }
    } else {
      console.log('ℹ️ No code pattern found in message');
    }
  }

  console.log('🔍 Before direct matching - matchedUsername:', matchedUsername, 'donor:', donor);

  // METODE 2: Direct name matching dari field "Nama" Saweria
  if ((!matchedUsername || matchedUsername === '') && donor) {
    console.log('🔍 Attempting direct name matching for donor:', donor);
    
    // Normalize nama untuk matching (lowercase, remove spaces)
    const normalizedDonorName = donor.toLowerCase().replace(/\s+/g, '');
    
    // Check existing registrations untuk direct match
    const registrations = await readJson<Record<string, string>>('registrations.json', {});
    console.log('📋 Available registrations:', Object.keys(registrations));
    
    // Try username match first
    for (const username of Object.keys(registrations)) {
      const normalizedUsername = username.toLowerCase().replace(/\s+/g, '');
      
      // Exact match atau partial match dengan username
      if (normalizedUsername === normalizedDonorName || 
          normalizedUsername.includes(normalizedDonorName) ||
          normalizedDonorName.includes(normalizedUsername)) {
        matchedUsername = username;
        console.log('✅ Direct username matched:', donor, '→', username);
        break;
      }
    }
    
    // METODE 2.5: Display name matching
    // If no username match, check if donor name matches a registered display name
    if (!matchedUsername || matchedUsername === '') {
      console.log('🔍 Attempting display name matching for donor:', donor);
      
      // Load display name mappings (username -> displayName)
      const displayNames = await readJson<Record<string, string>>('displaynames.json', {});
      console.log('📋 Available display names:', Object.keys(displayNames).length);
      
      // Match donor name against display names
      for (const [username, displayName] of Object.entries(displayNames)) {
        const normalizedDisplayName = displayName.toLowerCase().replace(/\s+/g, '');
        
        // Check for exact or partial match with display name
        if (normalizedDisplayName === normalizedDonorName || 
            normalizedDisplayName.includes(normalizedDonorName) ||
            normalizedDonorName.includes(normalizedDisplayName)) {
          matchedUsername = username;
          console.log('✅ Display name matched:', donor, '→', displayName, '(username:', username + ')');
          break;
        }
      }
    }
    
    // METODE 3: Auto-assume donor name = Roblox username (fallback)
    if (!matchedUsername || matchedUsername === '') {
      console.log('🔄 Auto-assuming donor name as Roblox username:', donor);
      matchedUsername = donor; // Direct assumption
      console.log('✅ Auto-matched:', donor, '→', matchedUsername);
    }
  }
  
  // FORCE SET untuk testing (temporary)
  if (!matchedUsername || matchedUsername === '') {
    console.log('🚨 FORCE SETTING matchedUsername to donor name for testing');
    matchedUsername = donor;
  }

  const donation: Donation = {
    id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    ts: Date.now(),
    donor: String(donor),
    amount: Number(amount),
    message: message || undefined,
    matchedUsername: matchedUsername || undefined,
    raw: body,
  };

  console.log('📋 Final donation object:', JSON.stringify(donation, null, 2));

  // Save to separate Saweria donations file
  const donations = await readJson<DonationsFile>('saweria-donations.json', []);
  donations.push(donation);
  // Keep only last 500
  while (donations.length > 500) donations.shift();
  await writeJson('saweria-donations.json', donations);

  console.log('💾 Donation saved to saweria-donations.json');
  console.log('📊 Total donations in file:', donations.length);
  console.log('🔍 Donations with matchedUsername:', donations.filter(d => d.matchedUsername).length);

  // 💾 SAVE TO DATABASE with atomic increment for SaweriaTopSpender
  try {
    // Save donation to Saweria database table
    await prisma.saweriaDonation.create({
      data: {
        donationId: donation.id,
        donorName: donation.donor,
        robloxUsername: donation.matchedUsername,
        amount: donation.amount,
        message: donation.message,
        rawData: donation.raw,
        createdAt: new Date(donation.ts),
      },
    });
    console.log('✅ Saweria donation saved to database:', donation.id);

    // Update or create SaweriaTopSpender with atomic increment
    if (donation.matchedUsername) {
      await prisma.saweriaTopSpender.upsert({
        where: { robloxUsername: donation.matchedUsername },
        update: {
          totalAmount: {
            increment: donation.amount,
          },
          donationCount: {
            increment: 1,
          },
          lastDonation: new Date(donation.ts),
        },
        create: {
          robloxUsername: donation.matchedUsername,
          totalAmount: donation.amount,
          donationCount: 1,
          lastDonation: new Date(donation.ts),
        },
      });
      console.log('✅ SaweriaTopSpender updated for:', donation.matchedUsername);
    }
  } catch (dbError) {
    console.error('❌ Database error:', dbError);
    // Don't fail the webhook if database fails - JSON backup still works
  }

  // 📢 DISCORD LOGGING
  try {
    const embed = createDonationEmbed({
      donor: donation.donor,
      amount: donation.amount,
      message: donation.message,
      matchedUsername: donation.matchedUsername,
    });

    await sendDiscordLog({
      embeds: [embed],
      username: 'Saweria Bot',
      avatar_url: 'https://cdn.discordapp.com/attachments/1234567890/saweria-icon.png', // Optional: Saweria logo
    });

    console.log('✅ Discord notification sent for donation:', donation.id);
  } catch (error) {
    console.error('❌ Failed to send Discord notification:', error);
    // Don't fail the webhook if Discord fails
  }

  return NextResponse.json({ ok: true, donation });
}
