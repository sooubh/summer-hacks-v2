# Student Financial OS

Production-ready personal finance application for Indian college students, built with Flutter and Firebase.

## What this project solves

- Tracks money across bank, UPI, and cash accounts.
- Handles irregular income patterns (stipend, freelancing, pocket money).
- Supports split expenses for groups.
- Provides savings goals and practical recommendations.
- Includes AI chat and live voice assistant experiences.

## Main capabilities

- Authentication:
	- Google sign-in
	- Email OTP via Firebase Cloud Functions
- Money operations:
	- Multi-account balances
	- Transaction logging and categorization
	- Payment-method analysis (Google Pay, PhonePe, Paytm, card, bank, cash)
- Planning and insights:
	- Savings goals
	- Rule-based and trend-based dashboard insights
	- Budget alerts and reminders
- Assistant layer:
	- AI chat assistant with task execution
	- Live voice assistant with low-latency websocket flow

## Tech stack

- App: Flutter
- State: Riverpod
- Data: Cloud Firestore
- Auth: Firebase Authentication
- Server logic: Cloud Functions for Firebase (Node.js 20, TypeScript)
- Storage: Firebase Storage

## Quick start

1. Install prerequisites:
	 - Flutter SDK (stable)
	 - Node.js 20+
	 - Firebase CLI
	 - FlutterFire CLI
2. Install app dependencies:
	 - flutter pub get
3. Create environment file:
	 - Copy .env.example to .env
	 - Fill AI_API_KEY and model values
4. Configure Firebase project bindings:
	 - flutterfire configure
5. Deploy Firebase rules and indexes:
	 - firebase deploy --only firestore:rules,firestore:indexes,storage
6. Build and deploy cloud functions:
	 - cd functions
	 - npm install
	 - npm run build
	 - firebase deploy --only functions
7. Run the app:
	 - flutter run -d android
	 - or flutter run -d chrome

## Production documentation

All detailed docs are under [docs/README.md](docs/README.md).

High-value entry points:

- [Architecture](docs/ARCHITECTURE.md)
- [Local Development](docs/LOCAL_DEVELOPMENT.md)
- [Deployment](docs/DEPLOYMENT.md)
- [Security](docs/SECURITY.md)
- [Testing and QA](docs/TESTING_AND_QA.md)
- [Operations Runbook](docs/OPERATIONS_RUNBOOK.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Data Seeding](docs/DATA_SEEDING.md)
- [Firestore Schema](docs/FIREBASE_SCHEMA.md)
- [Folder Structure](docs/FOLDER_STRUCTURE.md)

## Current project assumptions

- This is a simulated finance experience and does not integrate with real bank APIs.
- Demo and starter data is sourced from assets/mock/mock_data.json.
- OTP delivery is currently logging-oriented; production email delivery provider integration is expected.
