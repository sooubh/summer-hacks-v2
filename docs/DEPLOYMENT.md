# Deployment

## Release environments

Recommended environment separation:

- Development Firebase project
- Staging Firebase project
- Production Firebase project

Use flutterfire configure for each target environment and validate generated firebase options per platform.

## Deployment prerequisites

- Firebase project access with deploy permissions
- Correct Google services config files
- Verified .env values for production models
- Successful flutter analyze and flutter test

## Deployment order

1. Firestore and storage security artifacts:
   - firebase deploy --only firestore:rules,firestore:indexes,storage
2. Cloud Functions:
   - cd functions
   - npm install
   - npm run build
   - firebase deploy --only functions
3. Flutter app binaries:
   - Build and publish per platform channel

## Cloud Functions notes

- Runtime is nodejs20.
- Region configured in source is asia-south1.
- Schedules are configured in function definitions and execute in Asia/Kolkata timezone for reminder jobs.

## Pre-release checklist

- All critical user journeys tested:
  - Auth
  - Add transaction
  - Dashboard load
  - Savings goals update
  - Assistant action write
- Firestore rules deployed and validated
- Required indexes deployed
- Function logs clean during smoke tests
- Notification jobs verified

## Post-release checklist

- Validate key metrics:
  - Auth success rate
  - Transaction write success
  - Function invocation errors
- Verify generated notifications and insights
- Confirm no permission-denied spikes in Firestore logs

## Rollback strategy

- Keep previous app artifact for emergency rollback.
- Roll back functions using previous source revision and redeploy.
- Re-deploy last known-good Firestore rules and indexes.
- For data migration issues, pause scheduled jobs and restore from backups where available.

## Production hardening recommendations

- Enforce App Check across app and functions.
- Integrate real OTP email provider and remove non-production fallback behavior.
- Configure alerting for function error rates and Firestore permission failures.
- Use staged rollout for Android releases.
