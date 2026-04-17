# Student Financial OS (Flutter + Firebase)

Production-ready blueprint and scaffold for a personal finance app focused on Indian college students.

## Product goals

- Handle irregular income (stipends, freelancing, pocket money)
- Track money across multiple sources (bank, UPI, cash)
- Support split expenses and settlements
- Build discipline via savings goals and safe-to-spend
- Provide actionable insights without heavy complexity

## Tech stack

- Frontend: Flutter (Android + iOS + Web)
- State management: Riverpod
- Backend: Firebase Auth, Firestore, Storage, Cloud Functions
- Architecture: Feature-based clean modular design

## Key implemented modules

- Authentication (Google + callable OTP flow)
- Unified account balance tracking
- Transaction tracking (manual + QR simulation)
- Dashboard analytics and burn rate
- Split groups and split expenses
- Goal-based savings and safe-to-spend
- Rule-based AI insights
- Cash-flow projection and low-balance prediction
- Notification preference system + backend reminder automation
- Gemini chat assistant with fast/deep model routing, context-aware replies, and prompt suggestions
- Gemini voice assistant with microphone input, speech responses, stateful voice UX, and barge-in

## Start locally

1. Install dependencies:
	- `flutter pub get`
2. Configure Firebase app values:
	- `flutterfire configure`
	- Regenerate or replace `lib/firebase_options.dart`
3. Deploy rules/indexes:
	- `firebase deploy --only firestore:rules,firestore:indexes,storage`
4. Deploy functions:
	- `cd functions`
	- `npm install`
	- `npm run build`
	- `firebase deploy --only functions`
5. Run app:
	- Pass Gemini settings through Dart defines:
	  - `--dart-define=GEMINI_API_KEY=your_key`
	  - `--dart-define=GEMINI_CHAT_FAST_MODEL=models/gemini-2.5-flash`
	  - `--dart-define=GEMINI_CHAT_DEEP_MODEL=models/gemini-2.5-pro`
	  - `--dart-define=GEMINI_VOICE_MODEL=models/gemini-3.1-flash-live-preview`
	- Example:
	  - `flutter run -d chrome --dart-define=GEMINI_API_KEY=your_key`
	- or:
	  - `flutter run -d android --dart-define=GEMINI_API_KEY=your_key`

## Core docs

- Folder map: `docs/FOLDER_STRUCTURE.md`
- Firestore schema: `docs/FIREBASE_SCHEMA.md`
- Implementation plan: `docs/IMPLEMENTATION_GUIDE.md`
- Security rules: `firebase/firestore.rules`

## Security principles used

- No secrets or privileged flags in client
- OTP sessions are backend-only (`otpSessions` denied to clients)
- Per-user data isolation in Firestore rules (`request.auth.uid == userId`)
- Field-level validation for accounts, transactions, splits, and savings

## Notes

- Banking integrations are intentionally simulated; no real banking APIs are used.
- `assets/mock/mock_data.json` provides sample seed data for quick demos.
