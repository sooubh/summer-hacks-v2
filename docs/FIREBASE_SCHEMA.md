# Firebase Schema (Firestore)

## Top-level

- `users/{uid}`
  - `fullName`: string
  - `email`: string
  - `photoUrl`: string?
  - `collegeName`: string?
  - `defaultCurrency`: string (default: INR)
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

## User subcollections

- `users/{uid}/accounts/{accountId}`
  - `userId`: string
  - `name`: string
  - `type`: enum(`bank`, `upi`, `cash`)
  - `accountType`: enum(`bank`, `upi`, `cash`) (normalized alias for aggregation)
  - `provider`: string?
  - `balance`: number
  - `transactionIds`: string[] (linked simulated/manual transaction ids)
  - `isActive`: bool
  - `icon`: string
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

- `users/{uid}/transactions/{transactionId}`
  - `userId`: string
  - `accountId`: string
  - `title`: string
  - `amount`: number
  - `type`: enum(`income`, `expense`, `transfer`, `splitSettlement`)
  - `category`: string
  - `transactionAt`: timestamp
  - `createdAt`: timestamp
  - `updatedAt`: timestamp
  - `tags`: string[]
  - `note`: string?
  - `source`: string (`manual`, `qr`, `simulation`)
  - `channel`: string (`cash`, `card`, `bank_transfer`, `upi`)
  - `isCategoryOverridden`: bool

- `users/{uid}/split_groups/{groupId}`
  - `ownerId`: string
  - `name`: string
  - `memberIds`: string[]
  - `description`: string?
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

- `users/{uid}/split_expenses/{splitExpenseId}`
  - `groupId`: string
  - `createdBy`: string
  - `title`: string
  - `totalAmount`: number
  - `currency`: string
  - `paidBy`: string
  - `owedBy`: map<string, number>
  - `status`: enum(`pending`, `partial`, `settled`)
  - `expenseAt`: timestamp
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

- `users/{uid}/savings_goals/{goalId}`
  - `userId`: string
  - `title`: string
  - `targetAmount`: number
  - `savedAmount`: number
  - `deadline`: timestamp
  - `status`: enum(`active`, `paused`, `achieved`)
  - `priority`: number
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

- `users/{uid}/insights/{insightId}`
  - `userId`: string
  - `title`: string
  - `message`: string
  - `severity`: enum(`info`, `warning`, `critical`)
  - `isRead`: bool
  - `meta`: map
  - `createdAt`: timestamp

- `users/{uid}/notification_preferences/{prefId}`
  - `enabled`: bool
  - `localTime`: string? (`HH:mm`)
  - `monthlyLimit`: number?
  - `updatedAt`: timestamp

- `users/{uid}/notifications/{notificationId}`
  - `type`: string
  - `title`: string
  - `message`: string
  - `isRead`: bool
  - `createdAt`: timestamp

## Server-only collections

- `otpSessions/{emailHash}`
  - `email`: string
  - `emailHash`: string
  - `otpHash`: string
  - `attempts`: number
  - `createdAt`: timestamp
  - `updatedAt`: timestamp
  - `expiresAt`: timestamp

Clients have no direct read/write access to `otpSessions`; only Cloud Functions access this collection.
