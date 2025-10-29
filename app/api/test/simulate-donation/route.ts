import { NextRequest, NextResponse } from 'next/server';

export const runtime = 'nodejs';

// GET /api/test/simulate-donation?donor=moonzet16&amount=2000
// Test endpoint untuk simulate donation (for debugging)

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const donor = searchParams.get('donor') || 'TestDonor';
  const amount = Number(searchParams.get('amount')) || 1000;
  const message = searchParams.get('message') || 'Test donation';
  
  // Simulate webhook POST request
  const webhookUrl = new URL('/api/webhooks/bagibagi', req.url);
  
  const testPayload = {
    donor: donor,
    amount: amount,
    message: message,
    timestamp: Date.now()
  };
  
  console.log('🧪 Simulating donation:', testPayload);
  
  try {
    const response = await fetch(webhookUrl.toString(), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(testPayload)
    });
    
    const result = await response.json();
    
    return NextResponse.json({
      ok: true,
      message: 'Test donation sent to webhook',
      payload: testPayload,
      webhookResponse: result
    });
  } catch (error) {
    console.error('❌ Failed to simulate donation:', error);
    return NextResponse.json({
      ok: false,
      error: String(error)
    }, { status: 500 });
  }
}
