# Student Financial OS Implementation Guide

## Step 1: Project setup

1. Install Flutter 3.35+ and Firebase CLI.
2. Run:
   - `flutter create --platforms=android,ios,web --project-name student_fin_os .`
   - `flutter pub get`
3. Create a Firebase project and enable:
   - Authentication (Google + Email)
   - Firestore
   - Storage
   - Functions
4. Configure FlutterFire:
   - `dart pub global activate flutterfire_cli`
   - `flutterfire configure`
5. Replace placeholder values in `lib/firebase_options.dart` with generated values (or overwrite file from flutterfire).

## Step 2: Authentication module

1. Deploy callable functions in `functions/src/index.ts`.
2. Wire Firebase Authentication in Console:
   - Enable Google provider.
   - For OTP flow, use callable functions: `requestEmailOtp` and `verifyEmailOtp`.
3. Use `AuthService` and `AuthController` to drive `LoginScreen`.

## Step 3: Core data models

Models are in `lib/models` and mapped to Firestore through `toMap` / `fromMap`.

- User: `app_user.dart`
- Money sources: `account.dart`
- Transactions: `finance_transaction.dart`
- Splits: `split_group.dart`, `split_expense.dart`
- Savings: `savings_goal.dart`
- Insights/Cash-flow: `ai_insight.dart`, `cash_flow_point.dart`, `dashboard_snapshot.dart`

## Step 4: Dashboard-first UI

1. Open app shell route `/app`.
2. Use `DashboardScreen` as default tab.
3. Display:
   - Unified total balance
   - Safe-to-spend
   - Weekly spend
   - Burn rate
   - Category chart

## Step 5: Transaction system

1. Use `TransactionService.createTransaction` for writes.
2. It updates account balance atomically in a Firestore transaction.
3. UI supports:
   - Manual entry
   - Simulated QR scan flow
   - Category/tagging

## Step 6: Split system

1. Create groups in `split_groups`.
2. Add expenses in `split_expenses` with `owedBy` map.
3. Compute net balance matrix via `SplitService.netBalances`.

## Step 7: Savings engine

1. Create `savings_goals` with target/deadline/priority.
2. Use `SavingsService.recommendedMonthlyContribution`.
3. Safe-to-spend = total balance - reserve - monthly goal contribution.

## Step 8: Rule-based AI insights

1. Use `InsightsService.generateRuleBasedInsights` from recent transaction data.
2. Trigger insight generation:
   - Manual refresh from UI
   - Scheduled monthly function
   - Budget overrun function trigger

## Step 9: Notifications and reminders

1. Save preferences in `notification_preferences`.
2. Cloud scheduler functions create `notifications` docs:
   - Daily reminder
   - Budget alert
   - Monthly summary

## Step 10: Testing and optimization

1. Run `flutter analyze` and `flutter test`.
2. Validate auth + Firestore rules in Firebase Emulator Suite.
3. Add integration tests for:
   - OTP success/failure
   - Transaction balance consistency
   - Split settlements
   - Safe-to-spend logic
4. Add App Check and rate limiting for callable functions.

## Release checklist

1. Harden `firebase/firestore.rules` and deploy rules.
2. Set strict CORS/app check for callable functions.
3. Add crash/error monitoring.
4. Create production indexes from `firebase/firestore.indexes.json`.
5. Use staged rollouts for Android/Web.
