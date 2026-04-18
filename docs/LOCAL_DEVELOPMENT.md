# Local Development

## Prerequisites

- Flutter SDK (stable channel)
- Dart SDK compatible with pubspec constraints
- Node.js 20 or later
- Firebase CLI
- FlutterFire CLI
- Android Studio or VS Code

## Initial setup

1. Install app dependencies:
   - flutter pub get
2. Configure Firebase project bindings:
   - flutterfire configure
3. Create local environment file:
   - Copy .env.example to .env
4. Fill .env values:
   - AI_API_KEY
   - AI_CHAT_FAST_MODEL
   - AI_CHAT_DEEP_MODEL
   - AI_VOICE_MODEL
   - Optional live audio settings

## Backend setup

1. Install function dependencies:
   - cd functions
   - npm install
2. Build functions:
   - npm run build
3. Return to root project for app operations.

## Run commands

- Static checks:
  - flutter analyze
- Unit/widget tests:
  - flutter test
- Android run:
  - flutter run -d android
- Web run:
  - flutter run -d chrome

## Firebase resources

Deploy security artifacts before running full flows:

- firebase deploy --only firestore:rules,firestore:indexes,storage

Deploy functions after build:

- cd functions
- npm run deploy

## Developer workflow recommendations

- Keep feature branches small and scoped.
- Run flutter analyze before every commit.
- Add or update docs when behavior changes.
- Prefer explicit typing and immutable models.

## Environment variables reference

Root .env supports:

- AI_API_KEY
- AI_CHAT_FAST_MODEL
- AI_CHAT_DEEP_MODEL
- AI_VOICE_MODEL
- AI_LIVE_VOICE_NAME
- AI_LIVE_INPUT_SAMPLE_RATE
- AI_LIVE_OUTPUT_SAMPLE_RATE

## Common local pitfalls

- Missing firebase_options.dart bindings after switching Firebase project.
- Not deploying rules/indexes, leading to runtime query failures.
- Functions built from stale TypeScript output if npm run build is skipped.
