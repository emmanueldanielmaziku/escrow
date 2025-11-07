# ✅ Firebase Cloud Messaging - Verification Checklist

## Your Current Configuration ✅

✅ **Service Account**: `firebase-adminsdk-fbsvc@mai-escrow.iam.gserviceaccount.com`
✅ **Key ID**: `e94b2cae922154b1dd6bf447cc59f4a3ccc0c673` (Oct 23, 2025)
✅ **Project ID**: `mai-escrow`
✅ **Service Account Key**: Present in `/assets/env/service-account-key.json`
✅ **Android Permissions**: All configured correctly
✅ **Firebase Messaging Service**: Declared in AndroidManifest

## What You Need to Check in Google Cloud Console

### 1. Enable APIs (CRITICAL)
Visit: https://console.cloud.google.com/apis/library?project=mai-escrow

Check if these are enabled:
- [ ] **Firebase Cloud Messaging API** (Status must be "Enabled")
- [ ] **Cloud Messaging API (V1)** (Status must be "Enabled")
- [ ] **Cloud Resource Manager API** (Status must be "Enabled")

**How to Enable:**
1. Click on each API
2. If it says "API not enabled" → Click "ENABLE" button
3. Wait for it to show "API Enabled"

---

### 2. Check Service Account Permissions
Visit: https://console.cloud.google.com/iam-admin/iam?project=mai-escrow

Find: `firebase-adminsdk-fbsvc@mai-escrow.iam.gserviceaccount.com`

**Required Role:**
- [ ] **Firebase Cloud Messaging Admin**

If missing:
1. Click the pencil icon (✏️) next to the service account
2. Click "ADD ANOTHER ROLE"
3. Type: "Firebase Cloud Messaging Admin"
4. Select it from the dropdown
5. Click "SAVE"

---

### 3. Test Notification from Firebase Console
Visit: https://console.firebase.google.com/project/mai-escrow/messaging

**Steps:**
1. Click "Send your first message"
2. Enter notification title
3. Enter notification text
4. Click "Send test message"
5. Paste your FCM token (get from app debug logs)

**To Get FCM Token:**
```bash
flutter run --debug
# Look for: 🔑 FCM Token: [your-token-here]
```

---

## Quick Diagnostic Commands

```bash
# 1. Run your app in debug mode
flutter run --debug

# 2. Look for these logs in console:
# ✅ Success indicators:
# - "🔑 FCM Token: [token]" 
# - "🔔 Notifications enabled"
# - "📨 V1 FCM response: 200"

# ❌ Error indicators:
# - "404" or "403" or "Permission denied"
# - "API not enabled"
# - "Service account not found"
```

---

## Most Likely Issues (In Order of Probability)

### 1. ⚠️ API Not Enabled (90% likely)
**Symptom**: 404 Not Found or "API not enabled"
**Fix**: Enable APIs from Step 1 above

### 2. ⚠️ Missing IAM Role (5% likely)
**Symptom**: 403 Forbidden or Permission denied
**Fix**: Add IAM role from Step 2 above

### 3. ⚠️ Invalid Token (3% likely)
**Symptom**: UNREGISTERED token error
**Fix**: Reinstall app to get fresh token

### 4. ⚠️ Billing/Quota Issue (2% likely)
**Symptom**: Rate limit or quota exceeded
**Fix**: Check billing account in Cloud Console

---

## After Making Changes

1. **Rebuild your app**:
   ```bash
   flutter clean
   flutter pub get
   flutter run --debug
   ```

2. **Check logs** for FCM token generation
3. **Test notification** from Firebase Console
4. **Verify** notification arrives on device

---

## Need Immediate Help?

If notifications still don't work after enabling APIs:

1. **Copy the exact error message** from debug logs
2. **Check** which specific API call is failing
3. **Verify** API is actually enabled (refresh Google Cloud Console)
4. **Try** sending a test notification from Firebase Console first

The most common issue is simply that the APIs are not enabled in Google Cloud Console - this is a one-time setup that many developers miss!

