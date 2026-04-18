# Architecture

## System overview

Student Financial OS is a Flutter app backed by Firebase services.

- Client:
  - Flutter UI for Android, iOS, and Web.
  - Riverpod manages state and dependency injection.
- Backend:
  - Firebase Authentication for identity.
  - Firestore for user-scoped domain data.
  - Cloud Functions for OTP, alerts, summaries, and automations.
  - Firebase Storage for user-owned uploads.

## High-level module map

- Authentication:
  - providers/auth_providers.dart
  - services/auth_service.dart
  - functions/src/index.ts
- Finance core:
  - services/account_service.dart
  - services/transaction_service.dart
  - services/savings_service.dart
  - models/*
- Dashboard and analytics:
  - providers/dashboard_providers.dart
  - features/dashboard/ui/dashboard_screen.dart
- Assistant:
  - features/assistant/ui/*
  - providers/assistant_providers.dart
  - services/assistant_service.dart
- Splits and collaboration:
  - services/split_service.dart
  - features/splits/ui/*

## Data ownership model

- Each authenticated user owns all data under users/{uid}.
- Firestore rules enforce request.auth.uid == userId.
- Server-only OTP sessions are isolated in otpSessions and inaccessible from client SDKs.

## Runtime flows

## 1) Sign-in and bootstrap

1. User signs in with Google or OTP flow.
2. App resolves UID and triggers seedStarterData for first-time setup.
3. Accounts, transactions, preferences, and goals are initialized when missing.

## 2) Transaction write path

1. UI creates FinanceTransaction model.
2. transaction_service.createTransaction runs a Firestore transaction.
3. Account balance and transaction list references are updated atomically.
4. Firestore trigger can create budget alerts when thresholds are exceeded.

## 3) Assistant path

1. User sends chat or voice prompt.
2. assistant_service orchestrates model request.
3. assistant_providers parse task directives.
4. Valid tasks call domain services to mutate data.

## Design principles

- Feature-first folder structure for maintainability.
- Transactional writes for financial consistency.
- Least-privilege security rules with strict field checks.
- Idempotent and bounded seeding behavior.
- Readability-first UI state handling.

## Non-functional goals

- Reliability:
  - Prevent balance drift via atomic account updates.
- Security:
  - No client access to OTP session store.
- Operability:
  - Scheduled functions and notifications are observable.
- Performance:
  - Dashboard reads use provider-level stream composition.
