# Security

## Security model summary

- Authentication is mandatory for user data access.
- Firestore access is user-scoped via UID ownership checks.
- Sensitive OTP session data is server-only.
- Storage paths are restricted to user-owned prefixes.

## Identity and access

- Firebase Authentication providers:
  - Google sign-in
  - Email OTP custom flow via callable functions
- Firestore rules enforce request.auth.uid == userId for user documents and subcollections.

## Firestore protections

Implemented in firebase/firestore.rules:

- Strict type and enum validation for key collections.
- Positive amount checks for transactions and split expenses.
- Immutability checks for userId fields on updates.
- Denied direct client create for server-managed collections like insights and notifications.
- Full deny on otpSessions for client reads and writes.

## Storage protections

Implemented in firebase/storage.rules:

- Read and write only under users/{userId}/** for owner.
- Global deny for all non-owned paths.

## Cloud Functions security controls

- OTP verification limits:
  - Expiration window
  - Max attempts
- OTP session hash keys and hashed OTP storage.
- Server-side token generation for successful OTP verification.

## Secrets management

- Do not hardcode API keys in source.
- Keep runtime secrets in environment configuration.
- Ensure .env is not committed.
- Rotate keys regularly and after any exposure risk.

## Production hardening checklist

- Enable Firebase App Check for app and callable functions.
- Add abuse protection and request throttling for OTP callable endpoints.
- Integrate secure email/SMS provider for OTP delivery.
- Configure monitoring alerts for permission-denied and function failures.
- Review Firestore indexes and rules before every release.
- Conduct periodic access review for project IAM roles.

## Compliance notes

This app handles personal financial data and should be treated as sensitive data processing.

- Minimize retained personal data.
- Define retention policy for logs and notifications.
- Add user-facing privacy policy and terms in production builds.
