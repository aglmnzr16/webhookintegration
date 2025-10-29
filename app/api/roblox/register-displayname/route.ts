import { NextRequest, NextResponse } from 'next/server';
import { readJson, writeJson } from '@/lib/storage';

export const runtime = 'nodejs';

// POST /api/roblox/register-displayname
// Register display name mapping untuk username
// Body: { username: string, displayName: string }

type DisplayNameMap = Record<string, string>; // username -> displayName

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { username, displayName } = body;
    
    if (!username || !displayName) {
      return NextResponse.json({
        ok: false,
        error: 'Username and displayName required'
      }, { status: 400 });
    }
    
    console.log(`📝 Registering display name: ${username} -> ${displayName}`);
    
    // Load existing mappings
    const displayNames = await readJson<DisplayNameMap>('displaynames.json', {});
    
    // Add or update mapping
    displayNames[username] = displayName;
    
    // Save back
    await writeJson('displaynames.json', displayNames);
    
    console.log(`✅ Display name registered: ${username} (${displayName})`);
    console.log(`📊 Total mappings: ${Object.keys(displayNames).length}`);
    
    return NextResponse.json({
      ok: true,
      username,
      displayName,
      message: 'Display name registered successfully'
    });
    
  } catch (error) {
    console.error('❌ Failed to register display name:', error);
    return NextResponse.json({
      ok: false,
      error: String(error)
    }, { status: 500 });
  }
}

// GET /api/roblox/register-displayname?username=moonzet16
// Get display name for a username

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const username = searchParams.get('username');
  
  if (!username) {
    // Return all mappings if no username specified
    const displayNames = await readJson<DisplayNameMap>('displaynames.json', {});
    return NextResponse.json({
      ok: true,
      displayNames,
      count: Object.keys(displayNames).length
    });
  }
  
  // Get specific display name
  const displayNames = await readJson<DisplayNameMap>('displaynames.json', {});
  const displayName = displayNames[username];
  
  if (displayName) {
    return NextResponse.json({
      ok: true,
      username,
      displayName
    });
  } else {
    return NextResponse.json({
      ok: false,
      error: 'Display name not found for username'
    }, { status: 404 });
  }
}
