import { NextRequest, NextResponse } from 'next/server';
import { readJson, writeJson } from '@/lib/storage';

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
  console.log('🔔 Webhook received from BagiBagi');
  
  // Read body as JSON (BagiBagi should POST JSON). If not JSON, try text->JSON parse.
  let body: any;
  const contentType = req.headers.get('content-type') || '';
  try {
    if (contentType.includes('application/json')) {
      body = await req.json();
    } else {
      const text = await req.text();
      try { body = JSON.parse(text); } catch { body = { raw: text }; }
    }
    console.log('📦 Webhook body:', JSON.stringify(body, null, 2));
  } catch (e) {
    console.error('❌ Failed to parse webhook body:', e);
    return NextResponse.json({ ok: false, error: 'Failed to parse body' }, { status: 400 });
  }

  // Verify BagiBagi webhook token (disabled for testing)
  const expected = process.env.WEBHOOK_TOKEN;
  const got = req.headers.get('x-webhook-token') || 
             req.headers.get('authorization')?.replace('Bearer ', '') ||
             body?.token; // BagiBagi might send token in body
  console.log('🔐 Token check - Expected:', expected, 'Got:', got);
  
  // Temporarily disabled for testing
  // if (expected && got !== expected) {
  //   console.log('❌ Webhook auth failed');
  //   return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });
  // }

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

  // METODE 2: Direct name matching dari field "Nama" BagiBagi
  if ((!matchedUsername || matchedUsername === '') && donor) {
    console.log('🔍 Attempting direct name matching for donor:', donor);
    
    // Normalize nama untuk matching (lowercase, remove spaces)
    const normalizedDonorName = donor.toLowerCase().replace(/\s+/g, '');
    
    // Check existing registrations untuk direct match
    const registrations = await readJson<Record<string, string>>('registrations.json', {});
    console.log('📋 Available registrations:', Object.keys(registrations));
    
    for (const username of Object.keys(registrations)) {
      const normalizedUsername = username.toLowerCase().replace(/\s+/g, '');
      
      // Exact match atau partial match
      if (normalizedUsername === normalizedDonorName || 
          normalizedUsername.includes(normalizedDonorName) ||
          normalizedDonorName.includes(normalizedUsername)) {
        matchedUsername = username;
        console.log('✅ Direct name matched:', donor, '→', username);
        break;
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

  const donations = await readJson<DonationsFile>('donations.json', []);
  donations.push(donation);
  // Keep only last 500
  while (donations.length > 500) donations.shift();
  await writeJson('donations.json', donations);

  return NextResponse.json({ ok: true, donation });
}
