# Data Seeding

## Seeding paths in this project

There are two seeding mechanisms:

- Starter seeding:
  - Executed by mock_bank_service.seedStarterData on auth bootstrap.
  - Populates starter accounts, transactions, goals, and preferences when missing.
- Manual dummy transaction seeding:
  - Triggered from Dashboard action button.
  - Injects larger transaction samples for demos.

## Starter seeding behavior

- Controlled by users/{uid}.dummyBankSeedVersion.
- Seeding is defensive and skips already-populated collections.
- Source data is loaded from assets/mock/mock_data.json.

## Manual dummy seeding behavior

- Uses generated dummy templates from core/utils/dummy_data.dart.
- Amounts are forced positive.
- Seeder attempts channel-appropriate account selection.
- Expense inserts are skipped if insufficient balance to avoid negative runaway balance.
- User receives summary feedback on seeded and skipped records.

## How to reseed existing user data

Use this process when you need a fresh seeded state:

1. In Firestore, open users/{uid}.
2. Remove subcollections you want regenerated:
   - accounts
   - transactions
   - savings_goals
   - notification_preferences
3. Reset or remove dummyBankSeedVersion field.
4. Sign out and sign in again.

## Safe seeding rules for production-like demos

- Never seed against real user production data.
- Seed only in dedicated test/staging projects.
- Keep seed payload amounts realistic and positive.
- Validate account balances after large seed operations.

## Seed data extension policy

When adding new payment methods or categories:

- Add source and channel values consistently.
- Keep category naming aligned with dashboard grouping.
- Include at least one income source in every realistic seed set.
- Run flutter analyze after updates.
