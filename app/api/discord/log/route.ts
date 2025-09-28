import { NextRequest, NextResponse } from 'next/server';
import { sendDiscordLog, createSystemEmbed } from '@/lib/discord';

export const runtime = 'nodejs';

// API endpoint untuk manual Discord logging
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { type = 'info', title, description, content } = body;

    // Validate required fields
    if (!title && !content) {
      return NextResponse.json({ 
        ok: false, 
        error: 'Either title or content is required' 
      }, { status: 400 });
    }

    let payload;

    if (title && description) {
      // Send as embed
      const embed = createSystemEmbed(title, description, type);
      payload = {
        embeds: [embed],
        username: 'System Monitor',
      };
    } else {
      // Send as simple message
      payload = {
        content: content || `**${title}**`,
        username: 'System Monitor',
      };
    }

    const success = await sendDiscordLog(payload);

    if (success) {
      return NextResponse.json({ ok: true, message: 'Discord log sent successfully' });
    } else {
      return NextResponse.json({ 
        ok: false, 
        error: 'Failed to send Discord log' 
      }, { status: 500 });
    }
  } catch (error) {
    console.error('❌ Discord log API error:', error);
    return NextResponse.json({ 
      ok: false, 
      error: 'Internal server error',
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

// GET endpoint untuk test Discord webhook
export async function GET() {
  try {
    const embed = createSystemEmbed(
      'System Test',
      'Discord webhook integration is working correctly! 🎉',
      'success'
    );

    const success = await sendDiscordLog({
      embeds: [embed],
      username: 'System Test',
    });

    if (success) {
      return NextResponse.json({ 
        ok: true, 
        message: 'Test message sent to Discord successfully' 
      });
    } else {
      return NextResponse.json({ 
        ok: false, 
        error: 'Failed to send test message to Discord' 
      }, { status: 500 });
    }
  } catch (error) {
    console.error('❌ Discord test error:', error);
    return NextResponse.json({ 
      ok: false, 
      error: 'Internal server error',
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}
