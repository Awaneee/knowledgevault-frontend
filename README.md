# KnowledgeVault — Flutter Frontend

Mobile client for KnowledgeVault, an AI-powered personal knowledge base. Users can capture notes, upload files, ask questions across their vault, and let the AI auto-organize everything into categories.

Backend: https://github.com/Awaneee/knowledgevault-backend

## Stack

- Flutter 3.x (Material 3)
- Riverpod for state
- go_router for navigation
- Dio for HTTP
- drift + sqlite3_flutter_libs for offline cache
- flutter_secure_storage for JWT
- flutter_markdown for LLM answer rendering

## Getting started

```bash
flutter pub get
flutter run --dart-define=FLAVOR=dev
```

By default, dev builds talk to `http://10.0.2.2:8000` on the Android emulator (i.e. localhost on the host). For a physical device, override the URL:

```bash
flutter run --dart-define=FLAVOR=dev --dart-define=BASE_URL=http://192.168.1.x:8000
```

## Production build

```bash
flutter build apk --release --dart-define=FLAVOR=prod
```

Produces `build/app/outputs/flutter-apk/app-release.apk` pointing at the Railway-hosted backend.

## Configuration

`lib/core/config/app_config.dart` — `FLAVOR` (`dev` / `staging` / `prod`) and optional `BASE_URL` override.

## Layout

```
lib/
├─ app.dart               # Root MaterialApp + router
├─ core/                  # api client, auth, router, theme, cache
├─ features/
│  ├─ ask/                # Ask AI screen (streaming + full)
│  ├─ auth/               # Login, register, forgot-password
│  ├─ categories/         # Category CRUD
│  ├─ conversations/      # Chat sessions with the AI
│  ├─ dashboard/          # Home: recent notes + categories
│  ├─ intents/            # Intent-based categorization
│  ├─ notes/              # Note list, detail, create
│  └─ ...
└─ shared/                # widgets, utilities
```
