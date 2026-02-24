# Google Sign-In Setup Guide

This guide explains how to configure native Google Sign-In for the Blocnet mobile app.

## Overview

The app now uses **native Google Sign-In** instead of OAuth redirects. Users will see a native Google account picker that integrates seamlessly with their device's Google accounts.

## Prerequisites

You need the following from your Supabase project:

1. **Supabase URL** - Your project URL (e.g., `https://xxxxx.supabase.co`)
2. **Supabase Anon Key** - Your public anon/publishable key
3. **Google Web Client ID** - From your Google Cloud Console OAuth 2.0 credentials

## Step 1: Get Google Web Client ID

### If you already have Google OAuth configured in Supabase:

1. Go to your [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to **APIs & Services** → **Credentials**
4. Find your OAuth 2.0 Client ID for **Web application** (not Android or iOS)
5. Copy the **Client ID** (it ends with `.apps.googleusercontent.com`)

### If you don't have Google OAuth configured:

1. Follow [Supabase's Google OAuth setup guide](https://supabase.com/docs/guides/auth/social-login/auth-google)
2. Make sure to create **both**:
   - A Web application OAuth client (for the Web Client ID)
   - An Android OAuth client (for Android native sign-in)
3. For Android OAuth client, use SHA-1 from your debug keystore:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

## Step 2: Configure Android (Required)

### Add SHA-1 fingerprint to Google Cloud Console:

1. Get your debug SHA-1:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. In Google Cloud Console → Credentials → Create OAuth Client ID → Android:
   - **Package name:** `io.blocnet.app`
   - **SHA-1:** Paste the fingerprint from step 1

3. For production, repeat with release keystore SHA-1

## Step 3: Run the App with Configuration

Use `--dart-define` to pass configuration:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=PUBLISHABLE_KEY=YOUR_ANON_KEY \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

### For API configuration (if backend is not on localhost):

```bash
flutter run \
  --dart-define=API_BASE_URL=http://YOUR_IP:3080/api \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=PUBLISHABLE_KEY=YOUR_ANON_KEY \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

## Step 4: Verify Setup

1. **Build and run** the app
2. On the sign-in screen, tap **"Continue with Google"**
3. You should see:
   - Native Google account picker (not a browser redirect)
   - Your device's Google accounts listed
   - Ability to add a new account

## Troubleshooting

### Error: "Unsupported provider"
- Make sure Google provider is enabled in Supabase Dashboard → Authentication → Providers
- Verify the Web Client ID is correct

### Error: "API not enabled"
- Enable Google Sign-In API in Google Cloud Console
- Go to APIs & Services → Enable APIs and Services
- Search for "Google Sign-In API" and enable it

### Error: "Invalid client"
- Verify SHA-1 fingerprint matches your debug keystore
- Ensure package name is exactly `io.blocnet.app`
- For production builds, add your release SHA-1

### Sign-in works but user not created in backend
- Check backend logs for errors
- Verify the backend can decode the Supabase JWT token
- Ensure `SUPABASE_JWT_SECRET` or `SUPABASE_JWKS_URL` is configured in backend

### Error: "Google sign-in was cancelled"
- User tapped outside the account picker
- User pressed back button
- This is normal user behavior, not an error

## Production Configuration

For production builds, you should:

1. **Use environment-specific config files** (not command-line flags)
2. **Add release SHA-1** to Google Cloud Console
3. **Configure proper redirect URIs** in Supabase Dashboard
4. **Update API_BASE_URL** to production backend URL

## Architecture Notes

### Flow:

1. User taps "Continue with Google"
2. App launches native Google Sign-In SDK
3. User selects account from device
4. App receives Google ID token
5. App exchanges token with Supabase (`signInWithIdToken`)
6. Supabase returns session with access token
7. App verifies token with backend (`/auth/session/verify`)
8. Backend creates/updates user profile
9. User is signed in

### Key Files:

- **mobile/lib/services/auth_store.dart:300** - `signInWithGoogle()` method
- **mobile/lib/app/config.dart:30** - Google Client ID configuration
- **backend/src/auth/auth.service.ts:37** - Token verification

### Dependencies:

- `google_sign_in: ^6.2.2` - Native Google Sign-In SDK
- `supabase_flutter: ^2.10.2` - Supabase client with `signInWithIdToken`

## Support

If you encounter issues:

1. Check Supabase logs in Dashboard → Authentication → Logs
2. Check backend logs for JWT verification errors
3. Verify all configuration values are correct
4. Ensure Google OAuth is enabled in both Google Cloud and Supabase

## References

- [Supabase Google Auth Docs](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Google Sign-In Flutter Package](https://pub.dev/packages/google_sign_in)
- [Flutter Google Sign-In Guide](https://firebase.google.com/docs/auth/flutter/federated-auth)
