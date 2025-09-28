import { NextRequest, NextResponse } from 'next/server';
import { readJson, writeJson } from '@/lib/storage';

export const runtime = 'nodejs';

// Stores mapping between a short code and a Roblox username.
// Players will input username on website, receive a code to put in donation note (#CODE)
// or the Roblox game can tell the backend their username and receive a code.

type UsernameMap = Record<string, string>; // code -> username

function makeCode(): string {
  return Math.random().toString(36).slice(2, 8).toUpperCase();
}

export async function POST(req: NextRequest) {
  const contentType = req.headers.get('content-type') || '';
  let body: any = {};
  if (contentType.includes('application/json')) body = await req.json();
  else {
    const text = await req.text();
    try { body = JSON.parse(text); } catch {}
  }

  const username = (body?.username || body?.robloxUsername || '').trim();
  if (!username) {
    return NextResponse.json({ ok: false, error: 'username required' }, { status: 400 });
  }

  const map = await readJson<UsernameMap>('usernameMap.json', {});

  // Reuse code if the username already exists
  let code = Object.keys(map).find((k) => map[k].toLowerCase() === username.toLowerCase());
  if (!code) {
    do { code = makeCode(); } while (map[code]);
    map[code] = username;
    await writeJson('usernameMap.json', map);
  }

  return NextResponse.json({ ok: true, code, username });
}

export async function GET() {
  // Not exposing entire map; just to check server health
  return NextResponse.json({ ok: true });
}
