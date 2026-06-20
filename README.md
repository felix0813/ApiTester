# API Tester

A powerful HTTP API testing tool built with Flutter.

## Required Environment Variables

All environment variables **must** be provided via `--dart-define` flags. The app
will crash immediately at startup if any are missing, with a clear error message
listing what's absent.

| Variable | Description | Example |
|---|---|---|
| `SUPABASE_URL` | Your Supabase project URL | `https://abcdefghijklm.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase publishable (anon) key | `sb_publishable_xxxxxxxxxxxx` |
| `OAUTH_REDIRECT_SCHEME` | OAuth redirect URL scheme | `io.supabase.api-tester` |

### Where to find these values

1. **SUPABASE_URL** & **SUPABASE_ANON_KEY**: Go to your
   [Supabase Dashboard](https://supabase.com/dashboard) → select your project →
   **Settings** → **API**. Copy the **Project URL** and **anon public** key.

2. **OAUTH_REDIRECT_SCHEME**: This must match the custom URL scheme registered
   in your Android `AndroidManifest.xml` and iOS `Info.plist`. The app appends
   `://login-callback/` to this scheme for Supabase OAuth redirects.

## Running the App

If Flutter exits with `Target file "" not found`, the run configuration is
passing an empty Dart entrypoint (for example `-t ""`). In Android Studio, open
**Run > Edit Configurations...** and make sure:

- **Dart entrypoint** is `lib/main.dart`
- **Additional run args** contains only the `--dart-define` values, for example:

```text
--dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_YOUR_ANON_KEY --dart-define=OAUTH_REDIRECT_SCHEME=io.supabase.api-tester
```

### Debug mode

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_YOUR_ANON_KEY \
  --dart-define=OAUTH_REDIRECT_SCHEME=io.supabase.api-tester
```

### Release build

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_YOUR_ANON_KEY \
  --dart-define=OAUTH_REDIRECT_SCHEME=io.supabase.api-tester
```

### Run on Windows (desktop)

```bash
flutter run -d windows \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_YOUR_ANON_KEY \
  --dart-define=OAUTH_REDIRECT_SCHEME=io.supabase.api-tester
```

## Features

- **Request Builder** — Compose HTTP requests with headers, query params, body
  (JSON / form-data), and authentication (Bearer, Basic, API Key)
- **Collections** — Organize requests into folders, run entire collections
- **Environments** — Manage variables across different environments
- **Cloud Sync** — Sign in to sync your data across devices via Supabase
- **Import** — Import collections from Postman or OpenAPI specs

## Tech Stack

- Flutter 3.22+
- Dart 3.4+
- Supabase (auth, database)
- Riverpod (state management)
- GoRouter (navigation)
- Hive (local storage)
- Dio (HTTP client)
