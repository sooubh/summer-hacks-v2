# Firestore Schema Reference

This document describes the expected Firestore data model used by the app and cloud functions.

## Naming and type conventions

- Timestamps are stored as Firestore timestamp values.
- Money values are stored as number and expected to be positive where applicable.
- User-owned entities include userId and are scoped under users/{uid}.
- Channel values for transaction rails are normalized to:
  - upi
  - cash
  - card
  - bank_transfer

## Root collection

- users/{uid}
  - fullName: string
  - email: string
  - photoUrl: string?
  - collegeName: string?
  - defaultCurrency: string (default INR)
  - dummyBankSeedVersion: number?
  - dummyBankSeededAt: timestamp?
  - createdAt: timestamp
  - updatedAt: timestamp

## User subcollections

## users/{uid}/accounts/{accountId}

- userId: string
- name: string
- type: enum(bank, upi, cash)
- provider: string
- balance: number
- transactionIds: string[]
- isActive: bool
- icon: string
- createdAt: timestamp
- updatedAt: timestamp

## users/{uid}/transactions/{transactionId}

- userId: string
- accountId: string
- title: string
- amount: number (must be > 0)
- type: enum(income, expense, transfer, splitSettlement)
- category: string
- transactionAt: timestamp
- createdAt: timestamp
- updatedAt: timestamp
- tags: string[]
- note: string?
- source: string
- channel: enum(cash, card, bank_transfer, upi)
- isCategoryOverridden: bool

Example source values may include manual, qr, Google Pay, PhonePe, Paytm, Amazon Pay, bank transfer, or card labels.

## users/{uid}/split_groups/{groupId}

- ownerId: string
- name: string
- memberIds: string[]
- description: string?
- createdAt: timestamp
- updatedAt: timestamp

## users/{uid}/split_expenses/{expenseId}

- groupId: string
- createdBy: string
- title: string
- totalAmount: number
- currency: string
- paidBy: string
- owedBy: map<string, number>
- status: enum(pending, partial, settled)
- expenseAt: timestamp
- createdAt: timestamp
- updatedAt: timestamp

## users/{uid}/savings_goals/{goalId}

- userId: string
- title: string
- targetAmount: number
- savedAmount: number
- deadline: timestamp
- status: enum(active, paused, achieved)
- priority: number
- createdAt: timestamp
- updatedAt: timestamp

## users/{uid}/insights/{insightId}

- userId: string
- title: string
- message: string
- severity: enum(info, warning, critical)
- isRead: bool
- meta: map<string, dynamic>
- createdAt: timestamp

This collection is server-enriched for summary and budget events.

## users/{uid}/notification_preferences/{prefId}

- enabled: bool
- localTime: string? (HH:mm)
- monthlyLimit: number?
- updatedAt: timestamp

Known pref documents:

- daily_spend
- budget_alert

## users/{uid}/notifications/{notificationId}

- type: string
- title: string
- message: string
- isRead: bool
- createdAt: timestamp

## Server-only collection

## otpSessions/{emailHash}

- email: string
- emailHash: string
- otpHash: string
- attempts: number
- createdAt: timestamp
- updatedAt: timestamp
- expiresAt: timestamp

Client SDK access is denied by rules. Only Cloud Functions can read/write this collection.
