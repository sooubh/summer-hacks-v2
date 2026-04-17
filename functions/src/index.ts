import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import crypto from "node:crypto";

admin.initializeApp();

const db = admin.firestore();
const REGION = "asia-south1";
const OTP_VALIDITY_MS = 5 * 60 * 1000;
const OTP_MAX_ATTEMPTS = 5;

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

function emailHash(email: string): string {
  return crypto.createHash("sha256").update(normalizeEmail(email)).digest("hex");
}

function otpHash(email: string, otp: string): string {
  return crypto
    .createHash("sha256")
    .update(`${normalizeEmail(email)}:${otp}`)
    .digest("hex");
}

function generateOtp(): string {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function monthWindowUtc(date: Date): { start: Date; end: Date } {
  const start = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1, 0, 0, 0));
  const end = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 1, 0, 0, 0));
  return { start, end };
}

export const requestEmailOtp = onCall({ region: REGION }, async (request) => {
  const rawEmail = request.data?.email;
  if (typeof rawEmail !== "string" || rawEmail.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Valid email is required.");
  }

  const email = normalizeEmail(rawEmail);
  const otp = generateOtp();
  const key = emailHash(email);
  const nowMillis = Date.now();

  await db.collection("otpSessions").doc(key).set({
    email,
    emailHash: key,
    otpHash: otpHash(email, otp),
    attempts: 0,
    createdAt: admin.firestore.Timestamp.fromMillis(nowMillis),
    updatedAt: admin.firestore.Timestamp.fromMillis(nowMillis),
    expiresAt: admin.firestore.Timestamp.fromMillis(nowMillis + OTP_VALIDITY_MS),
  });

  // In production, send OTP through an email provider. This avoids returning secrets to clients.
  logger.info("Email OTP generated", { emailHash: key });

  return {
    success: true,
    ttlSeconds: OTP_VALIDITY_MS / 1000,
    ...(process.env.FUNCTIONS_EMULATOR === "true" ? { debugOtp: otp } : {}),
  };
});

export const verifyEmailOtp = onCall({ region: REGION }, async (request) => {
  const rawEmail = request.data?.email;
  const rawOtp = request.data?.otp;

  if (typeof rawEmail !== "string" || rawEmail.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Valid email is required.");
  }
  if (typeof rawOtp !== "string" || !/^\d{6}$/.test(rawOtp.trim())) {
    throw new HttpsError("invalid-argument", "A valid 6-digit OTP is required.");
  }

  const email = normalizeEmail(rawEmail);
  const otp = rawOtp.trim();
  const key = emailHash(email);
  const sessionRef = db.collection("otpSessions").doc(key);
  const sessionSnapshot = await sessionRef.get();

  if (!sessionSnapshot.exists) {
    throw new HttpsError("not-found", "OTP session not found.");
  }

  const data = sessionSnapshot.data() as {
    otpHash: string;
    attempts: number;
    expiresAt: admin.firestore.Timestamp;
  };

  if (data.expiresAt.toMillis() < Date.now()) {
    await sessionRef.delete();
    throw new HttpsError("deadline-exceeded", "OTP expired. Request a new code.");
  }

  if ((data.attempts ?? 0) >= OTP_MAX_ATTEMPTS) {
    throw new HttpsError("resource-exhausted", "Too many attempts. Request a new OTP.");
  }

  if (data.otpHash !== otpHash(email, otp)) {
    await sessionRef.update({
      attempts: (data.attempts ?? 0) + 1,
      updatedAt: admin.firestore.Timestamp.now(),
    });
    throw new HttpsError("permission-denied", "Incorrect OTP.");
  }

  await sessionRef.delete();

  let userRecord: admin.auth.UserRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
  } catch {
    userRecord = await admin.auth().createUser({
      email,
      displayName: "Student",
      emailVerified: true,
    });
  }

  await db.collection("users").doc(userRecord.uid).set(
    {
      email,
      fullName: userRecord.displayName ?? "Student",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      defaultCurrency: "INR",
    },
    { merge: true },
  );

  const customToken = await admin.auth().createCustomToken(userRecord.uid);
  return { customToken };
});

export const dailySpendingReminder = onSchedule(
  {
    region: REGION,
    schedule: "0 20 * * *",
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const users = await db.collection("users").get();
    let remindersCreated = 0;

    for (const userDoc of users.docs) {
      const pref = await userDoc.ref
        .collection("notification_preferences")
        .doc("daily_spend")
        .get();

      if (!pref.exists || pref.data()?.enabled !== true) {
        continue;
      }

      await userDoc.ref.collection("notifications").add({
        type: "daily_reminder",
        title: "Log today\'s spending",
        message: "Quick check-in: add today\'s expenses before the day ends.",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      remindersCreated += 1;
    }

    logger.info("Daily reminders generated", { remindersCreated });
  },
);

export const monthlySummary = onSchedule(
  {
    region: REGION,
    schedule: "0 9 1 * *",
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const now = new Date();
    const previousMonth = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1));
    const window = monthWindowUtc(previousMonth);

    const users = await db.collection("users").get();

    for (const userDoc of users.docs) {
      const txSnapshot = await userDoc.ref
        .collection("transactions")
        .where("transactionAt", ">=", admin.firestore.Timestamp.fromDate(window.start))
        .where("transactionAt", "<", admin.firestore.Timestamp.fromDate(window.end))
        .get();

      let expense = 0;
      let income = 0;

      for (const txDoc of txSnapshot.docs) {
        const tx = txDoc.data();
        const amount = Number(tx.amount ?? 0);
        if (tx.type === "expense") {
          expense += amount;
        }
        if (tx.type === "income") {
          income += amount;
        }
      }

      await userDoc.ref.collection("insights").add({
        userId: userDoc.id,
        title: "Monthly summary ready",
        message: `Last month: income Rs ${income.toFixed(0)}, expense Rs ${expense.toFixed(0)}.`,
        severity: "info",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        meta: {
          income,
          expense,
          month: previousMonth.getUTCMonth() + 1,
          year: previousMonth.getUTCFullYear(),
        },
      });
    }

    logger.info("Monthly summary insights generated");
  },
);

export const budgetAlertOnExpense = onDocumentCreated(
  {
    region: REGION,
    document: "users/{userId}/transactions/{transactionId}",
  },
  async (event) => {
    const userId = event.params.userId;
    const tx = event.data?.data();

    if (!tx || tx.type !== "expense") {
      return;
    }

    const userRef = db.collection("users").doc(userId);
    const budgetPref = await userRef.collection("notification_preferences").doc("budget_alert").get();

    if (!budgetPref.exists || budgetPref.data()?.enabled !== true) {
      return;
    }

    const monthlyLimit = Number(budgetPref.data()?.monthlyLimit ?? 0);
    if (monthlyLimit <= 0) {
      return;
    }

    const window = monthWindowUtc(new Date());
    const txSnapshot = await userRef
      .collection("transactions")
      .where("transactionAt", ">=", admin.firestore.Timestamp.fromDate(window.start))
      .where("transactionAt", "<", admin.firestore.Timestamp.fromDate(window.end))
      .where("type", "==", "expense")
      .get();

    let spent = 0;
    for (const doc of txSnapshot.docs) {
      spent += Number(doc.data().amount ?? 0);
    }

    if (spent >= monthlyLimit) {
      await userRef.collection("notifications").add({
        type: "budget_alert",
        title: "Budget crossed",
        message: `You spent Rs ${spent.toFixed(0)} this month against Rs ${monthlyLimit.toFixed(0)} limit.`,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await userRef.collection("insights").add({
        userId,
        title: "Monthly budget exceeded",
        message: "You crossed your monthly budget threshold. Tighten discretionary expenses.",
        severity: "critical",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        meta: {
          monthlyLimit,
          spent,
        },
      });
    }
  },
);
