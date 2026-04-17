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
const GEMINI_API_KEY_ENV = "GEMINI_API_KEY";
const GEMINI_CHAT_FAST_MODEL_ENV = "GEMINI_CHAT_FAST_MODEL";
const GEMINI_CHAT_DEEP_MODEL_ENV = "GEMINI_CHAT_DEEP_MODEL";
const GEMINI_VOICE_MODEL_ENV = "GEMINI_VOICE_MODEL";
const MAX_HISTORY_MESSAGES = 14;

type AssistantRole = "user" | "assistant";

interface AssistantMessage {
  role: AssistantRole;
  content: string;
}

interface GeminiModelConfig {
  fast: string;
  deep: string;
  voice: string;
}

interface AssistantContextSnapshot {
  totalBalance: number;
  weeklySpend: number;
  monthlySpend: number;
  safeToSpend: number;
  budgetMonthlyLimit: number;
  activeSavingsGoals: Array<{
    title: string;
    targetAmount: number;
    savedAmount: number;
    deadline: string;
  }>;
  recentTransactions: Array<{
    title: string;
    amount: number;
    type: string;
    category: string;
    transactionAt: string;
  }>;
  splitOverview: {
    activeGroups: number;
    pendingExpenses: number;
    pendingAmount: number;
  };
}

function requireEnv(name: string): string {
  const raw = process.env[name];
  if (typeof raw !== "string" || raw.trim().length === 0) {
    throw new HttpsError(
      "failed-precondition",
      `Missing required environment variable: ${name}`,
    );
  }
  return raw.trim();
}

function readGeminiModelConfig(): GeminiModelConfig {
  return {
    fast: requireEnv(GEMINI_CHAT_FAST_MODEL_ENV),
    deep: requireEnv(GEMINI_CHAT_DEEP_MODEL_ENV),
    voice: requireEnv(GEMINI_VOICE_MODEL_ENV),
  };
}

function asNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function parseIsoDate(value: unknown): string {
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate().toISOString();
  }
  if (value instanceof Date) {
    return value.toISOString();
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed.toISOString();
    }
  }
  return new Date(0).toISOString();
}

function parseAssistantMessageHistory(raw: unknown): AssistantMessage[] {
  if (!Array.isArray(raw)) {
    return [];
  }

  const parsed: AssistantMessage[] = [];

  for (const item of raw.slice(-MAX_HISTORY_MESSAGES)) {
    if (!item || typeof item !== "object") {
      continue;
    }

    const row = item as Record<string, unknown>;
    const rawContent = row.content;
    const rawRole = row.role;

    if (typeof rawContent !== "string") {
      continue;
    }

    const content = rawContent.trim();
    if (!content) {
      continue;
    }

    parsed.push({
      role: rawRole === "assistant" ? "assistant" : "user",
      content: content.slice(0, 2000),
    });
  }

  return parsed;
}

function parseAssistantContext(raw: unknown): Record<string, unknown> {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    return {};
  }
  return raw as Record<string, unknown>;
}

function parseRequestedMode(raw: unknown): "fast" | "deep" {
  return raw === "deep" ? "deep" : "fast";
}

function splitSpeechChunks(reply: string): string[] {
  const chunks = reply
    .split(/(?<=[.!?])\s+/)
    .map((part) => part.trim())
    .filter((part) => part.length > 0);

  if (chunks.length > 0) {
    return chunks;
  }

  if (reply.trim().length === 0) {
    return [];
  }

  return [reply.trim()];
}

function trimText(text: unknown, fieldName: string): string {
  if (typeof text !== "string") {
    throw new HttpsError("invalid-argument", `${fieldName} must be a string.`);
  }
  const value = text.trim();
  if (!value) {
    throw new HttpsError("invalid-argument", `${fieldName} is required.`);
  }
  return value.slice(0, 2000);
}

async function loadAssistantContext(userId: string): Promise<AssistantContextSnapshot> {
  const userRef = db.collection("users").doc(userId);

  const [
    accountsSnapshot,
    transactionsSnapshot,
    goalsSnapshot,
    splitGroupsSnapshot,
    splitExpensesSnapshot,
    budgetPrefSnapshot,
  ] = await Promise.all([
    userRef.collection("accounts").get(),
    userRef
      .collection("transactions")
      .orderBy("transactionAt", "desc")
      .limit(40)
      .get(),
    userRef.collection("savings_goals").limit(20).get(),
    userRef.collection("split_groups").limit(20).get(),
    userRef.collection("split_expenses").limit(40).get(),
    userRef.collection("notification_preferences").doc("budget_alert").get(),
  ]);

  let totalBalance = 0;
  for (const accountDoc of accountsSnapshot.docs) {
    totalBalance += asNumber(accountDoc.data().balance);
  }

  const now = Date.now();
  let weeklySpend = 0;
  let monthlySpend = 0;

  const recentTransactions: AssistantContextSnapshot["recentTransactions"] = [];
  for (const txDoc of transactionsSnapshot.docs) {
    const tx = txDoc.data();
    const amount = asNumber(tx.amount);
    const type = typeof tx.type === "string" ? tx.type : "expense";
    const category = typeof tx.category === "string" ? tx.category : "misc";
    const title = typeof tx.title === "string" ? tx.title : "Transaction";
    const transactionAt = parseIsoDate(tx.transactionAt);

    const txMillis = new Date(transactionAt).getTime();
    const ageDays = Math.floor((now - txMillis) / (1000 * 60 * 60 * 24));

    if (type === "expense") {
      if (ageDays <= 7) {
        weeklySpend += amount;
      }
      if (ageDays <= 30) {
        monthlySpend += amount;
      }
    }

    if (recentTransactions.length < 14) {
      recentTransactions.push({
        title,
        amount,
        type,
        category,
        transactionAt,
      });
    }
  }

  const activeSavingsGoals: AssistantContextSnapshot["activeSavingsGoals"] = [];
  let monthlyGoalContribution = 0;
  for (const goalDoc of goalsSnapshot.docs) {
    const goal = goalDoc.data();
    const status = typeof goal.status === "string" ? goal.status : "active";
    if (status !== "active") {
      continue;
    }

    const targetAmount = asNumber(goal.targetAmount);
    const savedAmount = asNumber(goal.savedAmount);
    const deadlineIso = parseIsoDate(goal.deadline);
    const deadline = new Date(deadlineIso);
    const daysLeft = Math.max(1, Math.ceil((deadline.getTime() - now) / (1000 * 60 * 60 * 24)));
    const monthsLeft = Math.max(1, Math.ceil(daysLeft / 30));
    const pending = Math.max(0, targetAmount - savedAmount);
    monthlyGoalContribution += pending / monthsLeft;

    if (activeSavingsGoals.length < 8) {
      activeSavingsGoals.push({
        title: typeof goal.title === "string" ? goal.title : "Goal",
        targetAmount,
        savedAmount,
        deadline: deadlineIso,
      });
    }
  }

  let pendingExpenses = 0;
  let pendingAmount = 0;
  for (const expenseDoc of splitExpensesSnapshot.docs) {
    const expense = expenseDoc.data();
    const status = typeof expense.status === "string" ? expense.status : "pending";
    if (status === "settled") {
      continue;
    }
    pendingExpenses += 1;
    pendingAmount += asNumber(expense.totalAmount);
  }

  const budgetMonthlyLimit = asNumber(budgetPrefSnapshot.data()?.monthlyLimit);

  const reserve = weeklySpend * 1.4;
  const safeToSpend = Math.max(0, totalBalance - reserve - monthlyGoalContribution);

  return {
    totalBalance,
    weeklySpend,
    monthlySpend,
    safeToSpend,
    budgetMonthlyLimit,
    activeSavingsGoals,
    recentTransactions,
    splitOverview: {
      activeGroups: splitGroupsSnapshot.size,
      pendingExpenses,
      pendingAmount,
    },
  };
}

function buildAssistantSystemPrompt(
  serverContext: AssistantContextSnapshot,
  clientContext: Record<string, unknown>,
): string {
  const serverContextJson = JSON.stringify(serverContext).slice(0, 12000);
  const clientContextJson = JSON.stringify(clientContext).slice(0, 12000);

  return [
    "You are FinMate, an in-app personal finance assistant for Indian college students.",
    "Primary tasks: spending summaries, budget Q&A, savings goals, transaction explanations, and split expense help.",
    "Only use the signed-in user's provided context. Never mention or infer other users' data.",
    "Be precise with INR values and explicitly state assumptions when data is missing.",
    "Respond conversationally, actionable, and concise unless the user asks for depth.",
    "Never claim to execute real bank transactions. This app uses simulated banking flows.",
    "If user asks unrelated topics, briefly redirect to finance assistance.",
    "SERVER_CONTEXT_JSON:",
    serverContextJson,
    "CLIENT_CONTEXT_JSON:",
    clientContextJson,
  ].join("\n");
}

function buildSuggestedPrompts(input: string): string[] {
  const lower = input.toLowerCase();
  if (lower.includes("budget")) {
    return [
      "Show me categories where I can cut spending this month.",
      "What daily spend cap should I follow for the rest of the month?",
      "How far am I from my monthly budget limit?",
    ];
  }
  if (lower.includes("split")) {
    return [
      "Who should settle first in my active split groups?",
      "Explain my pending split balances in simple terms.",
      "Draft a polite split settlement reminder message.",
    ];
  }
  if (lower.includes("save") || lower.includes("goal")) {
    return [
      "Which goal should I prioritize this month?",
      "How much should I set aside weekly for my goals?",
      "Show a realistic savings plan based on my recent spending.",
    ];
  }
  return [
    "Summarize my spending in one minute.",
    "What should I do this week to stay financially healthy?",
    "Explain my latest transactions and any red flags.",
  ];
}

function extractGeminiText(payload: unknown): string {
  if (!payload || typeof payload !== "object") {
    return "";
  }

  const root = payload as Record<string, unknown>;
  const candidates = root.candidates;
  if (!Array.isArray(candidates) || candidates.length === 0) {
    return "";
  }

  const first = candidates[0];
  if (!first || typeof first !== "object") {
    return "";
  }

  const content = (first as Record<string, unknown>).content;
  if (!content || typeof content !== "object") {
    return "";
  }

  const parts = (content as Record<string, unknown>).parts;
  if (!Array.isArray(parts)) {
    return "";
  }

  return parts
    .map((part) => {
      if (!part || typeof part !== "object") {
        return "";
      }
      const text = (part as Record<string, unknown>).text;
      return typeof text === "string" ? text : "";
    })
    .join("")
    .trim();
}

async function sleep(ms: number): Promise<void> {
  await new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function withRetry<T>(
  operationName: string,
  run: () => Promise<T>,
  attempts = 3,
): Promise<T> {
  let lastError: unknown;

  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      return await run();
    } catch (error) {
      lastError = error;
      logger.warn(`${operationName} failed`, { attempt, error: String(error) });
      if (attempt < attempts) {
        await sleep(250 * attempt);
      }
    }
  }

  throw lastError;
}

async function callGeminiText(params: {
  apiKey: string;
  model: string;
  systemPrompt: string;
  messages: AssistantMessage[];
  temperature: number;
  maxOutputTokens: number;
  thinkingLevel?: "minimal" | "low" | "medium" | "high";
}): Promise<string> {
  const generationConfig: Record<string, unknown> = {
    temperature: params.temperature,
    maxOutputTokens: params.maxOutputTokens,
  };

  if (params.thinkingLevel) {
    generationConfig.thinkingConfig = {
      thinkingLevel: params.thinkingLevel,
    };
  }

  const payload = {
    systemInstruction: {
      parts: [{ text: params.systemPrompt }],
    },
    contents: params.messages.map((message) => ({
      role: message.role === "assistant" ? "model" : "user",
      parts: [{ text: message.content }],
    })),
    generationConfig,
  };

  const endpoint =
    `https://generativelanguage.googleapis.com/v1beta/${params.model}:generateContent` +
    `?key=${params.apiKey}`;

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Gemini API failed (${response.status}): ${body.slice(0, 600)}`);
  }

  const json = (await response.json()) as unknown;
  const text = extractGeminiText(json);
  if (!text) {
    throw new Error("Gemini response did not contain any text output.");
  }

  return text;
}

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

export const assistantChatReply = onCall({ region: REGION }, async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const message = trimText(request.data?.message, "message");
  const history = parseAssistantMessageHistory(request.data?.history);
  const responseMode = parseRequestedMode(request.data?.responseMode);
  const clientContext = parseAssistantContext(request.data?.clientContext);

  const modelConfig = readGeminiModelConfig();
  const apiKey = requireEnv(GEMINI_API_KEY_ENV);

  let serverContext: AssistantContextSnapshot;
  try {
    serverContext = await loadAssistantContext(userId);
  } catch (error) {
    logger.error("Failed to load assistant context", { userId, error: String(error) });
    serverContext = {
      totalBalance: 0,
      weeklySpend: 0,
      monthlySpend: 0,
      safeToSpend: 0,
      budgetMonthlyLimit: 0,
      activeSavingsGoals: [],
      recentTransactions: [],
      splitOverview: {
        activeGroups: 0,
        pendingExpenses: 0,
        pendingAmount: 0,
      },
    };
  }

  const systemPrompt = buildAssistantSystemPrompt(serverContext, clientContext);
  const messages: AssistantMessage[] = [...history, { role: "user", content: message }];

  const primaryModel = responseMode === "deep" ? modelConfig.deep : modelConfig.fast;
  let modelUsed = primaryModel;
  let fallbackUsed = false;

  try {
    const reply = await withRetry(
      "assistantChatReply",
      async () =>
        callGeminiText({
          apiKey,
          model: primaryModel,
          systemPrompt,
          messages,
          temperature: responseMode === "deep" ? 0.35 : 0.45,
          maxOutputTokens: responseMode === "deep" ? 900 : 600,
          thinkingLevel: responseMode === "deep" ? "medium" : "minimal",
        }),
      3,
    );

    return {
      reply,
      modelUsed,
      fallbackUsed,
      suggestions: buildSuggestedPrompts(message),
      generatedAt: new Date().toISOString(),
    };
  } catch (error) {
    logger.error("Primary chat model failed", {
      userId,
      model: primaryModel,
      error: String(error),
    });

    if (responseMode !== "deep") {
      throw new HttpsError("internal", "Chat assistant is temporarily unavailable.");
    }
  }

  fallbackUsed = true;
  modelUsed = modelConfig.fast;

  try {
    const fallbackReply = await withRetry(
      "assistantChatReplyFallback",
      async () =>
        callGeminiText({
          apiKey,
          model: modelConfig.fast,
          systemPrompt,
          messages,
          temperature: 0.45,
          maxOutputTokens: 650,
          thinkingLevel: "minimal",
        }),
      2,
    );

    return {
      reply: fallbackReply,
      modelUsed,
      fallbackUsed,
      suggestions: buildSuggestedPrompts(message),
      generatedAt: new Date().toISOString(),
    };
  } catch (error) {
    logger.error("Fallback chat model failed", {
      userId,
      model: modelConfig.fast,
      error: String(error),
    });
    throw new HttpsError("internal", "Chat assistant is temporarily unavailable.");
  }
});

export const assistantVoiceReply = onCall({ region: REGION }, async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const transcript = trimText(request.data?.transcript, "transcript");
  const history = parseAssistantMessageHistory(request.data?.history);
  const clientContext = parseAssistantContext(request.data?.clientContext);

  const modelConfig = readGeminiModelConfig();
  const apiKey = requireEnv(GEMINI_API_KEY_ENV);

  let serverContext: AssistantContextSnapshot;
  try {
    serverContext = await loadAssistantContext(userId);
  } catch (error) {
    logger.error("Failed to load voice assistant context", {
      userId,
      error: String(error),
    });
    serverContext = {
      totalBalance: 0,
      weeklySpend: 0,
      monthlySpend: 0,
      safeToSpend: 0,
      budgetMonthlyLimit: 0,
      activeSavingsGoals: [],
      recentTransactions: [],
      splitOverview: {
        activeGroups: 0,
        pendingExpenses: 0,
        pendingAmount: 0,
      },
    };
  }

  const systemPrompt = buildAssistantSystemPrompt(serverContext, clientContext);
  const messages: AssistantMessage[] = [...history, { role: "user", content: transcript }];

  let modelUsed = modelConfig.voice;
  let fallbackUsed = false;
  let reply: string;

  try {
    reply = await withRetry(
      "assistantVoiceReply",
      async () =>
        callGeminiText({
          apiKey,
          model: modelConfig.voice,
          systemPrompt,
          messages,
          temperature: 0.3,
          maxOutputTokens: 420,
          thinkingLevel: "minimal",
        }),
      2,
    );
  } catch (error) {
    logger.error("Voice model failed, falling back", {
      userId,
      model: modelConfig.voice,
      error: String(error),
    });
    fallbackUsed = true;
    modelUsed = modelConfig.fast;
    reply = await withRetry(
      "assistantVoiceReplyFallback",
      async () =>
        callGeminiText({
          apiKey,
          model: modelConfig.fast,
          systemPrompt,
          messages,
          temperature: 0.35,
          maxOutputTokens: 420,
          thinkingLevel: "minimal",
        }),
      2,
    );
  }

  return {
    reply,
    speechChunks: splitSpeechChunks(reply),
    modelUsed,
    fallbackUsed,
    generatedAt: new Date().toISOString(),
  };
});
