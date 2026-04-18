# Folder Structure

The project uses a feature-first Flutter structure with Firebase backend assets and Cloud Functions.

## Top level

```text
summer-hacks-v2/
  android/                       Android host project
  ios/                           iOS host project
  web/                           Web host files
  assets/                        Static assets and mock seed data
  firebase/                      Firestore and Storage rules/indexes
  functions/                     Cloud Functions (TypeScript)
  lib/                           Flutter source
  docs/                          Project and production documentation
  test/                          Flutter tests
  pubspec.yaml                   Flutter package manifest
  firebase.json                  Firebase project config
  README.md                      Root project entry documentation
```

## Flutter app structure

```text
lib/
  app/                           App bootstrap and app-level composition
  core/                          Cross-cutting utils, theme, routing, shared widgets
  data/                          Data adapters and mock seed loader
  features/                      Feature modules grouped by business capability
    assistant/                   AI chat and voice assistant UI
    auth/
    cashflow/
    dashboard/
    insights/
    rewards/
    savings/
    shell/
    splits/
    transactions/
  l10n/                          Localization setup
  models/                        Domain models and serialization
  providers/                     Riverpod providers/controllers
  services/                      Firestore/Auth/Function service layer
  firebase_options.dart          Generated FlutterFire bindings
  main.dart                      App entry point
```

## Backend structure

```text
functions/
  src/
    index.ts                     Callable, scheduled, and trigger functions
  lib/                           Compiled JavaScript output
  package.json                   Scripts and dependencies
  tsconfig.json                  TypeScript configuration
```

## Documentation structure

```text
docs/
  README.md                      Documentation hub
  ARCHITECTURE.md                System architecture
  LOCAL_DEVELOPMENT.md           Local setup and workflows
  DEPLOYMENT.md                  Release and rollout guide
  SECURITY.md                    Security model and hardening
  TESTING_AND_QA.md              Quality strategy
  OPERATIONS_RUNBOOK.md          Runtime operations and incidents
  TROUBLESHOOTING.md             Common failures and fixes
  DATA_SEEDING.md                Starter and dummy data seeding behavior
  FIREBASE_SCHEMA.md             Firestore schema and field reference
  FOLDER_STRUCTURE.md            This file
  IMPLEMENTATION_GUIDE.md        Implementation and delivery roadmap
```
