# Operations Runbook

## Purpose

This runbook describes day-to-day production operations, monitoring, and incident response for Student Financial OS.

## Key runtime components

- Flutter client applications
- Firestore database and security rules
- Cloud Functions (callable, scheduled, trigger-based)
- Firebase Authentication

## Monitoring priorities

- Function invocation failures and latency
- Firestore permission-denied rates
- Authentication failure spikes
- Notification generation health

## Daily checks

- Review Cloud Functions error logs.
- Review failed auth and OTP verification patterns.
- Validate scheduled jobs ran as expected.
- Spot-check dashboard load and transaction write from a test account.

## Incident response flow

1. Triage
   - Confirm user impact scope and affected feature.
2. Stabilize
   - Pause risky deployments and isolate failing component.
3. Mitigate
   - Apply rollback or hotfix path.
4. Recover
   - Validate core journeys after mitigation.
5. Review
   - Document root cause and preventive actions.

## Common incident playbooks

## 1) Budget alerts not appearing

- Check budgetAlertOnExpense logs in Cloud Functions.
- Confirm notification_preferences/budget_alert has enabled=true and monthlyLimit > 0.
- Confirm transaction type is expense and transactionAt is valid timestamp.

## 2) OTP verification failures surge

- Validate requestEmailOtp and verifyEmailOtp logs.
- Check for invalid payload patterns and abuse traffic.
- Confirm otpSessions writes and expiry are functioning.
- Consider temporary rate limiting or challenge controls.

## 3) Dashboard data mismatch

- Verify transactions and account balances under same UID.
- Check for failed writes around transaction creation.
- Validate no stale app build with outdated model mapping.

## 4) Seeding caused unexpected balances

- See DATA_SEEDING.md for seeding guard behavior.
- Confirm latest seeding logic skips unaffordable expenses.
- Repair affected data through controlled admin adjustment process.

## Change management

- Every production deployment must include:
  - Deployment note
  - Rollback note
  - Owner and approver
- Prefer small, reversible releases.

## On-call readiness

- Maintain an owner list for app and backend.
- Keep this runbook versioned with the codebase.
- Review after each Sev 1 or Sev 2 incident.
