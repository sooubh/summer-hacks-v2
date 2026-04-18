# Troubleshooting

## Flutter and build issues

## Problem: parser errors after editing Dart files

Symptoms:

- Errors like Directives must appear before declarations.
- Missing type errors that appear unrelated.

Fix:

- Inspect import section for typos or stray text.
- Ensure all imports are at top of file.
- Run flutter analyze on the affected file.

## Problem: app runs but dashboard behavior is stale

Fix:

- Perform hot restart, not only hot reload.
- Re-run seeding action if dummy grouping logic changed.

## Firebase and data issues

## Problem: starter seeding does not run for existing user

Cause:

- Seeding only populates collections when they are empty.
- dummyBankSeedVersion may indicate user already seeded.

Fix:

- Follow reset steps in DATA_SEEDING.md.

## Problem: permission denied on Firestore writes

Fix:

- Confirm authenticated user context exists.
- Verify write path is under users/{uid} with matching uid.
- Validate payload fields satisfy firestore.rules constraints.

## Assistant and AI issues

## Problem: assistant has no response or fails to connect

Fix:

- Check .env values and API key presence.
- Confirm model names are valid for your provider.
- Verify internet connectivity and websocket availability.

## Functions issues

## Problem: functions deploy fails

Fix:

- cd functions
- npm install
- npm run lint
- npm run build
- Retry firebase deploy --only functions

## Problem: scheduled notifications not generated

Fix:

- Verify function deployment region and schedule.
- Check Cloud Functions logs for runtime exceptions.
- Confirm required Firestore preference docs exist.

## Last-resort diagnostics

- flutter clean
- flutter pub get
- flutter analyze
- flutter test
- Rebuild functions and redeploy
