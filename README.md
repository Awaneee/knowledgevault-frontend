# KnowledgeVault — Flutter mobile client

**Cross-platform mobile app for KnowledgeVault**, an AI-powered personal knowledge base. Capture notes and files on the go, ask questions across your vault in natural language, and watch AI auto-organise everything into categories.

- **Backend** (FastAPI + pgvector + LLM chain) — https://github.com/Awaneee/knowledgevault-backend
- **Live API** — https://knowledgevault-production-8903.up.railway.app
- **Stack** — Flutter (Material 3) · Riverpod · go_router · Dio · drift · flutter_markdown

---

## Highlights

- **Streaming markdown answers with tappable citations.** SSE token stream renders as proper markdown (headings, code, bullets) via `flutter_markdown`. Inline `[N]` refs auto-rewrite to markdown links; tapping opens the source note in a bottom sheet.
- **Offline-first cache with optimistic UI.** Notes and categories cached in a `drift` (SQLite) local database — the app opens instantly with last-known data while a network refresh runs in the background. Category changes and deletes update state immediately, roll back on failure.
- **Live categorisation status.** Dashboard shows recent notes with per-note status chips (`Organizing…` / category name / `Failed`). Auto-polls the backend every 4 s while any note is still processing, then stops.
- **Manual category override.** Long-press or tap the category row on a note to open a searchable picker; typing a novel name reveals a **Create "…"** button. Every override is sent to the backend and logged as classifier feedback.
- **Full auth flow.** Register → login → JWT-secured requests via a Dio interceptor. Forgot-password uses a 6-digit code emailed by the backend, entered in-app, no deep-linking required.
- **Robust error surfacing.** Typed exception hierarchy (`UnauthorizedException`, `RateLimitException`, `NetworkException`, `ValidationException`, ...) mapped from Dio errors, so screens render specific messages instead of generic failures.

---

## Screens

| | |
|---|---|
| **Dashboard** | Greeting + quick actions (New note / Ask AI) → recent notes with live status chips → category groups |
| **Notes** | List, create (text or file upload), detail (content · category picker · related notes · attachments) |
| **Ask AI** | Streaming or full-response modes · markdown output · copy · stop · regenerate · inline citations |
| **Conversations** | Chat sessions with markdown-rendered assistant replies + source chips |
| **Categories / Intents** | Aggregated bucket views for browsing organised notes |
| **Auth** | Register · login · forgot-password (6-digit code flow) |
| **Profile / Settings** | Account info, theme, sign-out |

---

## Architecture

```
UI (features/*/ui)
    │  Riverpod providers (features/*/providers)
    ▼
Repository layer (features/*/data)
    │  Dio + AuthInterceptor + ErrorHandler
    ▼
REST API  ←→  drift local cache (offline reads, optimistic writes)
```

- **Riverpod** for reactive state (AsyncNotifier + families for `noteDetail(id)`, `relatedNotes(id)`).
- **go_router** for navigation with a global auth-status redirect (`splash → login → dashboard` transitions).
- **drift** wraps SQLite for typed local caches keyed by user session.
- **flutter_secure_storage** persists the JWT (EncryptedSharedPreferences on Android).
- **Dio interceptor** attaches the JWT and expires the session on 401.

---

## Getting started

Requires Flutter 3.10+.

```bash
flutter pub get

# Android emulator against a local backend (localhost = 10.0.2.2 for the emulator):
flutter run --dart-define=FLAVOR=dev

# Physical device against a LAN-hosted backend:
flutter run --dart-define=FLAVOR=dev --dart-define=BASE_URL=http://192.168.1.x:8000

# Anyone against the deployed Railway backend:
flutter run --dart-define=FLAVOR=prod
```

**Release APK** pointing at the deployed backend:

```bash
flutter build apk --release --dart-define=FLAVOR=prod
# → build/app/outputs/flutter-apk/app-release.apk  (~57 MB)
```

The signing config in `android/app/build.gradle.kts` falls back to debug keys for convenience — swap in a real keystore before publishing.

---

## Configuration

All build-time config lives in `lib/core/config/app_config.dart` and is injected via `--dart-define`:

| Flag | Values | Effect |
|---|---|---|
| `FLAVOR` | `dev` \| `staging` \| `prod` | picks the default `BASE_URL` |
| `BASE_URL` | any URL | explicit override (wins over `FLAVOR` default) |

Prod points at `https://knowledgevault-production-8903.up.railway.app`. Dev defaults to the Android-emulator localhost bridge (`10.0.2.2:8000`) or `localhost:8000` on desktop.

---

## Layout

```
lib/
├─ app.dart                    Root MaterialApp + router
├─ core/
│  ├─ api/                     Dio client + auth interceptor + typed exceptions
│  ├─ auth/                    JWT storage + auth-status provider
│  ├─ cache/                   drift database (offline note + category cache)
│  ├─ config/                  FLAVOR / BASE_URL resolution
│  ├─ router/                  go_router setup + redirect guard
│  └─ theme/                   Material 3 theming + colours
└─ features/
   ├─ ask/                     Ask AI screen (streaming + full) + citation sheet
   ├─ attachments/             File upload + attachment list
   ├─ auth/                    Login, register, forgot-password
   ├─ categories/              Categories CRUD
   ├─ conversations/           Multi-turn chat sessions
   ├─ dashboard/               Home: recent notes + status polling + category groups
   ├─ intents/                 Intent-aware category views
   ├─ notes/                   List, detail (category picker + related), create
   ├─ profile/                 Account screen
   ├─ search/                  Full-text + semantic search
   ├─ settings/                Theme, preferences
   └─ topics/                  Topic browsing
```

---

## Notable implementation details

- **In-place status polling** — the dashboard spawns a `Timer.periodic(4s)` only while at least one note is still `pending`/`processing`, and auto-cancels once everything's `organized`. No polling burn when the UI is idle.
- **Optimistic category swaps** — `NotesNotifier.updateCategory` mutates local state first, then patches the backend; on failure it rolls the state back and shows a snackbar. Detail screen re-invalidates its `noteDetail(id)` provider so the source of truth converges.
- **Markdown streaming** — `StreamAnswerView` feeds partial tokens into `MarkdownBody` on every rebuild. Works out-of-the-box even for mid-stream unterminated markdown (e.g. an open `**bold`).
- **Citation link handler** — inline `[N]` refs in the LLM answer are regex-rewritten to markdown links `[\[N\]](cite://N)` before rendering, and `MarkdownBody.onTapLink` opens the corresponding `Citation` in a bottom sheet.

---

## License

MIT.
