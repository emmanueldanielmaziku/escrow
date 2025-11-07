# 🔔 Google Cloud Console - FCM Configuration Guide

## Project: mai-escrow

### Step 1: Enable Required APIs
Visit: https://console.cloud.google.com/apis/library?project=mai-escrow

**Required APIs to Enable:**
1. ✓ Firebase Cloud Messaging API
2. ✓ Cloud Messaging API (V1) 
3. ✓ Cloud Resource Manager API
4. ✓ Identity and Access Management (IAM) API

---

### Step 2: Service Account Permissions
Visit: https://console.cloud.google.com/iam-admin/iam?project=mai-escrow

**Service Account to Check:**
- `firebase-adminsdk-fbsvc@mai-escrow.iam.gserviceaccount.com`

**Required Roles:**
- ✓ Firebase Cloud Messaging Admin
- ✓ Firebase Admin SDK Administrator Service Agent
- ✓ Service Account User

**How to Add Role:**
1. Find your service account in the list
2. Click the pencil icon (Edit)
3. Click "ADD ANOTHER ROLE"
4. Add: "Firebase Cloud Messaging Admin"
5. Save

---

### Step 3: Firebase Console Setup
Visit: https://console.firebase.google.com/project/mai-escrow/settings/cloudmessaging/

**What to Check:**
1. **Cloud Messaging API (Legacy)** - Should show "Enabled" or has a server key
2. **Cloud Messaging API (V1)** - Should be enabled
3. **Apple Platform** - If using iOS, ensure APNs is configured

---

### Step 4: Test Notification
Visit: https://console.firebase.google.com/project/mai-escrow/messaging

**How to Test:**
1. Click "Send your first message"
2. Enter notification title: "Test Notification"
3. Enter notification text: "Testing FCM"
4. Click "Send test message"
5. You'll need an FCM token from your app

**To Get FCM Token:**
- Run your Flutter app
- Check debug logs for: `🔑 FCM Token: [token-here]`
- Copy that token and use it in Firebase Console

---

### Step 5: Verify Your Code Changes

Your notification service is configured to use:
- **Project ID**: `mai-escrow` ✅
- **Service Account**: `firebase-adminsdk-fbsvc@mai-escrow.iam.gserviceaccount.com`

---

## Common Issues & Solutions

### Issue: "Permission denied" or "403 Forbidden"
**Solution**: 
- Check Step 2 above
- Ensure service account has "Firebase Cloud Messaging Admin" role

### Issue: "API not enabled"
**Solution**: 
- Complete Step 1 above
- Enable all listed APIs

### Issue: "Invalid token" or "404 Not Found"
**Solution**:
- Token may be expired
- Reinstall app to get fresh token
- Check token is being saved to Firestore

### Issue: "Billing required"
**Solution**:
- Firebase free tier should be sufficient
- Check billing account is enabled (even if free)
- Visit: https://console.cloud.google.com/billing

---

## Debugging Checklist

```bash
# 1. Run app and check logs
flutter run --debug

# 2. Look for these logs:
# - 🔑 FCM Token: [your-token]
# - 🔔 Notifications enabled
# - 📨 V1 FCM response: 200

# 3. Send test from Firebase Console
# 4. Check if notification arrives
```

---

## Quick Links

- **Google Cloud Console**: https://console.cloud.google.com/?project=mai-escrow
- **Firebase Console**: https://console.firebase.google.com/project/mai-escrow
- **Enable APIs**: https://console.cloud.google.com/apis/library?project=mai-escrow
- **IAM Settings**: https://console.cloud.google.com/iam-admin/iam?project=mai-escrow
- **FCM Settings**: https://console.firebase.google.com/project/mai-escrow/settings/cloudmessaging/
- **Send Test**: https://console.firebase.google.com/project/mai-escrow/messaging

---

## Expected Behavior After Configuration

1. ✅ APIs enabled in Google Cloud Console
2. ✅ Service account has FCM Admin role
3. ✅ App generates FCM token on startup
4. ✅ Test notification can be sent from Firebase Console
5. ✅ Notifications arrive on device (foreground & background)

---

## Need Help?

If notifications still don't work after these steps:
1. Check device notification permissions (Settings → Apps → Escrow)
2. Verify app is running latest code changes
3. Check device logs for specific error messages
4. Try uninstall and reinstall app to refresh token

