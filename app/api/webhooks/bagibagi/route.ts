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

  // Verify BagiBagi webhook token (optional for now)
  const expected = process.env.WEBHOOK_TOKEN;
  const got = req.headers.get('x-webhook-token') || 
             req.headers.get('authorization')?.replace('Bearer ', '') ||
             body?.token; // BagiBagi might send token in body
  
  console.log('🔐 Token check - Expected:', expected, 'Got:', got);
  
  if (expected && got !== expected) {
    console.log('❌ Webhook auth failed');
    return NextResponse.json({ ok: false, error: 'Unauthorized' }, { status: 401 });
  }

  const amount = pickAmount(body);
  const donor = pickDonor(body);
  const message = pickMessage(body);

  const usernameMap = await readJson<UsernameMap>('usernameMap.json', {});
  const explicitUsername: string | undefined = body?.roblox_username || body?.robloxUsername;
  let matchedUsername: string | undefined = explicitUsername;

  if (!matchedUsername) {
    const codeFromMessage = extractCodeFromMessage(message);
    if (codeFromMessage && usernameMap[codeFromMessage]) {
      matchedUsername = usernameMap[codeFromMessage];
    }
  }

  const donation: Donation = {
    id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    ts: Date.now(),
    donor,
    amount,
    message,
    matchedUsername,
    raw: body,
  };

  const donations = await readJson<DonationsFile>('donations.json', []);
  donations.push(donation);
  // Keep only last 500
  while (donations.length > 500) donations.shift();
  await writeJson('donations.json', donations);

  return NextResponse.json({ ok: true, donation });
}
