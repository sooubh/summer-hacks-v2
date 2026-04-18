# Testing and QA

## Quality objectives

- Ensure financial consistency in balance updates.
- Prevent regressions in auth, dashboard, and assistant flows.
- Detect permission and rule failures before release.

## Test layers

## 1) Static quality gates

- flutter analyze
- npm run lint (inside functions)
- npm run build (inside functions)

## 2) Unit tests

Focus areas:

- Transaction delta logic for income and expense
- Category inference and parser helpers
- Savings contribution calculations
- Split net balance computations

## 3) Widget tests

Focus areas:

- Dashboard rendering with empty and populated states
- Assistant UI interactions
- Form validation for transaction and savings inputs

## 4) Integration tests

Priority end-to-end scenarios:

- Sign in and starter data bootstrap
- Add expense and verify account balance mutation
- Savings goal contribution flow
- Budget alert trigger flow
- Assistant-driven task creation

## 5) Rules and backend validation

- Validate Firestore rules with Emulator Suite.
- Validate callable function failure and success paths.
- Test OTP expiry and max-attempt behavior.

## Suggested release gate

A release should be blocked unless all conditions pass:

- flutter analyze passes
- flutter test passes
- functions lint and build pass
- smoke run on target platform passes
- critical user journeys manually verified

## Manual QA checklist

- Auth:
  - Google and OTP sign-in success
- Dashboard:
  - Loads without blank/exception states
  - Charts and drill-downs open correctly
- Transactions:
  - Manual add and seeded add behavior
  - No negative amount creation
- Assistant:
  - Chat response and task execution
  - Voice connect, listen, and stop behavior
- Notifications:
  - Read/unread update behavior

## Defect severity rubric

- Sev 1:
  - Data loss, corrupted balances, auth lockout
- Sev 2:
  - Core flow blocked without workaround
- Sev 3:
  - Non-critical functionality degraded
- Sev 4:
  - Cosmetic or minor text issues
