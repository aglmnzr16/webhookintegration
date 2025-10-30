# 🔄 Saweria vs BagiBagi Webhook Comparison

## 📊 Key Differences

### BagiBagi Webhook:
```
✅ Custom header support (X-Webhook-Token)
✅ Token authentication
✅ Complex payload structure
✅ Code-based matching (#ABC123)
```

### Saweria Webhook:
```
⚠️ NO custom headers
⚠️ NO token in headers
✅ Simple JSON POST
✅ Minimal setup (just URL)
```

---

## 🌐 Saweria Webhook Setup

### Dashboard Configuration:

**Screenshot yang Anda kirim menunjukkan:**
```
┌─────────────────────────────────────┐
│ Webhook                             │
├─────────────────────────────────────┤
│ Nyalakan: [Toggle ON/OFF]          │
│                                     │
│ Webhook URL:                        │
│ https://yourcallbackdestination.com│
│                                     │
│ Hitungan Gagal: 0                   │
│                                     │
│ [Simpan] [Munculkan Notifikasi]    │
└─────────────────────────────────────┘
```

**Yang Perlu Anda Isi:**
1. ✅ Toggle "Nyalakan" ke **ON**
2. ✅ Webhook URL: `https://your-domain.com/api/webhooks/saweria`
3. ✅ Klik **Simpan**

**Tidak perlu:**
- ❌ Custom headers
- ❌ Authentication token
- ❌ API key

---

## 📦 Webhook Payload Structure

### Saweria Expected Payload:

```json
{
  "donor": "John Doe",
  "name": "John Doe",
  "amount": 50000,
  "message": "Test donation for moonzet16",
  "created_at": "2024-01-01T12:00:00Z"
}
```

**Possible field names:**
- `donor` or `name` - Donor name
- `amount` or `nominal` - Donation amount (Rupiah)
- `message` or `note` - Custom message

### BagiBagi Payload (for comparison):

```json
{
  "donor": "John Doe",
  "amount": 50000,
  "message": "Test #ABC123",
  "timestamp": 1234567890
}
```

**Plus header:**
```
X-Webhook-Token: your_token_here
```

---

## 🔒 Security Comparison

### BagiBagi:
```typescript
// Strong authentication with token
const token = req.headers.get('x-webhook-token');
if (token !== process.env.BAGIBAGI_WEBHOOK_TOKEN) {
  return 401 Unauthorized;
}
```

### Saweria:
```typescript
// NO authentication by default
// Optional: IP whitelist or signature verification

// Log request source
const ip = req.headers.get('x-forwarded-for');
console.log('Request from IP:', ip);

// Optional token (if Saweria adds support)
if (env.SAWERIA_WEBHOOK_TOKEN && body.token) {
  // Validate token
}
```

---

## ⚙️ Configuration Updates

### Environment Variables:

**Before (Only BagiBagi):**
```env
WEBHOOK_TOKEN="your_bagibagi_token"
```

**After (Both Platforms):**
```env
# BagiBagi (required - with header auth)
BAGIBAGI_WEBHOOK_TOKEN="your_bagibagi_token"

# Saweria (optional - no header auth by default)
SAWERIA_WEBHOOK_TOKEN="optional_if_saweria_adds_support"

# Legacy fallback
WEBHOOK_TOKEN="legacy_token"
```

---

## 🧪 Testing

### Test BagiBagi (with token):
```bash
curl -X POST https://your-domain.com/api/webhooks/bagibagi \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Token: your_token" \
  -d '{"donor":"Test","amount":50000,"message":"Test #ABC123"}'
```

### Test Saweria (no token needed):
```bash
curl -X POST https://your-domain.com/api/webhooks/saweria \
  -H "Content-Type: application/json" \
  -d '{"donor":"Test","name":"Test","amount":50000,"message":"Test donation"}'
```

**Notice:** Saweria test **tidak perlu** header `X-Webhook-Token`!

---

## 🛡️ Security Recommendations

### For Saweria (since no token):

1. **IP Whitelist** (if Saweria provides static IPs):
   ```typescript
   const allowedIPs = ['saweria.ip.1', 'saweria.ip.2'];
   const requestIP = req.headers.get('x-forwarded-for');
   if (!allowedIPs.includes(requestIP)) {
     return 401;
   }
   ```

2. **Rate Limiting**:
   ```typescript
   // Limit requests per IP
   import rateLimit from 'express-rate-limit';
   ```

3. **Payload Validation**:
   ```typescript
   // Validate required fields
   if (!body.donor || !body.amount) {
     return 400 Bad Request;
   }
   ```

4. **Signature Verification** (if Saweria adds it):
   ```typescript
   const signature = req.headers.get('x-saweria-signature');
   const expectedSig = generateHMAC(body, secret);
   if (signature !== expectedSig) {
     return 401;
   }
   ```

---

## 📋 Setup Checklist

### Saweria Webhook:
- [ ] Go to saweria.co/admin/integrations
- [ ] Toggle "Nyalakan" to **ON**
- [ ] Enter webhook URL: `https://your-domain.com/api/webhooks/saweria`
- [ ] Click **Simpan**
- [ ] Test with "Munculkan Notifikasi" button
- [ ] Verify webhook receives POST request
- [ ] Check database for new donation entry

### BagiBagi Webhook:
- [ ] Go to BagiBagi dashboard
- [ ] Enter webhook URL: `https://your-domain.com/api/webhooks/bagibagi`
- [ ] Enter token: Your `BAGIBAGI_WEBHOOK_TOKEN`
- [ ] Save settings
- [ ] Test donation
- [ ] Verify webhook receives POST with token header

---

## 🔍 Debugging

### Saweria Not Sending Webhooks?

**Check:**
1. ✅ Toggle "Nyalakan" is **ON**
2. ✅ Webhook URL is correct (no typos)
3. ✅ URL is **HTTPS** (not HTTP)
4. ✅ Server is accessible publicly
5. ✅ Click "Munculkan Notifikasi" to test
6. ✅ Check "Hitungan Gagal" (should be 0)

**Common Issues:**
- ❌ URL returns 404 → Check deployment
- ❌ URL returns 500 → Check server logs
- ❌ URL times out → Check CORS/firewall
- ❌ "Hitungan Gagal" > 0 → Webhook failing

### Check Logs:

```bash
# Vercel logs
vercel logs

# Railway logs  
railway logs

# Local testing
npm run dev
# Watch console for webhook POST
```

---

## 📊 Payload Field Mapping

### What Saweria Sends:

Based on common Saweria webhook implementations:

```json
{
  "id": "unique_donation_id",
  "donor": "Donor Name",
  "amount": 50000,
  "message": "Optional message",
  "created_at": "2024-01-01T12:00:00Z",
  "type": "donation"
}
```

### Our Code Handles Multiple Field Names:

```typescript
// We check multiple possible field names
const donor = body.donor || body.name || body.donator || 'Anonymous';
const amount = body.amount || body.nominal || body.total || 0;
const message = body.message || body.note || body.memo || '';
```

**This makes our webhook flexible!** ✅

---

## 🎯 Summary

| Feature | BagiBagi | Saweria |
|---------|----------|---------|
| **Token Header** | ✅ Required | ❌ Not supported |
| **Setup** | Medium | ✅ Very easy |
| **Security** | ✅ Strong | ⚠️ Basic |
| **Fields** | Standard | Flexible |
| **Testing** | Need token | ✅ Simple curl |

**Recommendation:**
- ✅ Use Saweria's simple setup (just URL)
- ✅ Add IP validation if needed
- ✅ Monitor "Hitungan Gagal" counter
- ✅ Test with "Munculkan Notifikasi" button

---

## 🚀 Quick Start (Saweria)

1. **Copy webhook URL:**
   ```
   https://your-domain.com/api/webhooks/saweria
   ```

2. **Paste ke Saweria dashboard**

3. **Toggle ON**

4. **Klik Simpan**

5. **Test dengan button "Munculkan Notifikasi"**

6. **Done!** ✅

**No token needed, no complex setup!** 🎉

---

## 📝 Notes

- Saweria mungkin tidak mengirim `X-Webhook-Token` header
- Validasi bisa dilakukan via IP whitelist atau payload structure
- Environment variable `SAWERIA_WEBHOOK_TOKEN` adalah **optional**
- Sistem tetap aman karena database validation dan Discord logging

**Jika Saweria menambahkan token support di masa depan, tinggal uncomment validation di code!**
