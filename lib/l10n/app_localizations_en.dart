// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Student Financial OS';

  @override
  String get appName => 'Student Financial OS';

  @override
  String get profile => 'Profile';

  @override
  String get bank => 'Bank';

  @override
  String get upi => 'UPI';

  @override
  String get cash => 'Cash';

  @override
  String get wallet => 'Wallet';

  @override
  String get totalBalance => 'Total balance';

  @override
  String get income => 'Income';

  @override
  String get spent => 'Spent';

  @override
  String get safeToSpend => 'Safe to spend';

  @override
  String get weeklySpend => 'Weekly spend';

  @override
  String get burnRatePerDay => 'Burn rate/day';

  @override
  String get errorPrefix => 'Error';

  @override
  String get loginTagline => 'Track everything. Split faster. Save smarter.';

  @override
  String get collegeEmailLabel => 'College email';

  @override
  String get collegeEmailHint => 'you@college.edu';

  @override
  String get otpLabel => 'OTP';

  @override
  String get otpHint => 'Enter 6-digit OTP';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get authFailed => 'Authentication failed.';

  @override
  String get unifiedFinancePlatform => 'Unified Finance Platform';

  @override
  String get home => 'Home';

  @override
  String get insights => 'Insights';

  @override
  String get goals => 'Goals';

  @override
  String get activity => 'Activity';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get languageMarathi => 'Marathi';

  @override
  String get signOut => 'Sign out';

  @override
  String get dashboardUnifiedPlatform => 'Unified Platform';

  @override
  String get dashboardOneCleanView => 'One clean financial view across all your accounts.';

  @override
  String get dashboardConnectedToFeed => 'Connected Accounts → Unified Feed';

  @override
  String dashboardAccountsTransactions(int accountCount, int transactionCount) {
    return 'Accounts: $accountCount • Transactions: $transactionCount';
  }

  @override
  String get dashboardLiveUpdates => 'Live updates from Firestore streams';

  @override
  String get dashboardNoSourcesYet => 'No sources yet';

  @override
  String get smartGuidance => 'Smart Guidance';

  @override
  String get smartGuidanceSubtitle => 'Tap any icon to learn a quick finance tip';

  @override
  String get tipAtmSafety => 'ATM Safety';

  @override
  String get tipAtmSafetyBody => 'Always cover PIN entry and avoid ATMs with loose keypads or suspicious devices.';

  @override
  String get tipCreditScore => 'Credit Score';

  @override
  String get tipCreditScoreBody => 'Pay bills before due date and keep utilization low to improve your credit score.';

  @override
  String get tipBudgeting => 'Budgeting';

  @override
  String get tipBudgetingBody => 'Follow 50/30/20: needs, wants, and savings to keep spending balanced.';

  @override
  String get tipInvesting => 'Investing';

  @override
  String get tipInvestingBody => 'Invest small amounts regularly and stay consistent for long-term growth.';

  @override
  String get topSpendings => 'Top Spendings';

  @override
  String get topSpendingsSubtitle => 'Most active categories';

  @override
  String get connectedAccounts => 'Connected Accounts';

  @override
  String get connectedAccountsSubtitle => 'Bank + UPI + cash balances';

  @override
  String get noAccountsYet => 'No accounts yet';

  @override
  String get noAccountsYetBody => 'Create accounts to view unified balances.';

  @override
  String get monthlySpendingTrend => 'Monthly Spending Trend';

  @override
  String get monthlySpendingTrendSubtitle => 'Month-over-month analysis';

  @override
  String get noPreviousMonthBaseline => 'No previous month baseline yet';

  @override
  String spendingIncreasedBy(String percent) {
    return 'Spending increased by $percent%';
  }

  @override
  String spendingDecreasedBy(String percent) {
    return 'Spending decreased by $percent%';
  }

  @override
  String get notEnoughMonthlyData => 'Not enough monthly data';

  @override
  String get notEnoughMonthlyDataBody => 'Generate or add transactions to visualize spend trend.';

  @override
  String get categorySplit30d => 'Category Split (30d)';

  @override
  String get categorySplitSubtitle => 'Spending by category';

  @override
  String get noCategoryDataYet => 'No category data yet';

  @override
  String get noCategoryDataYetBody => 'Add transactions to unlock category insights.';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get latestTransactions => 'Latest transactions';

  @override
  String get noTransactionsFound => 'No transactions found';

  @override
  String get noTransactionsFoundBody => 'Add your first expense or income to start tracking.';

  @override
  String get unifiedInsights => 'Unified Insights';

  @override
  String get unifiedInsightsSubtitle => 'Simple money tips you can act on right now.';

  @override
  String get urgent => 'Urgent';

  @override
  String get headsUp => 'Heads-up';

  @override
  String get fyi => 'FYI';

  @override
  String get moneyFeed => 'Money Feed';

  @override
  String get moneyFeedSubtitle => 'Clear alerts + what to do next';

  @override
  String get refresh => 'Refresh';

  @override
  String get balanceRunway => 'Balance runway';

  @override
  String get balanceStable14Days => 'You look stable for the next 14 days.';

  @override
  String balanceTightAround(String date) {
    return 'At current pace, balance may get tight around $date.';
  }

  @override
  String get all => 'All';

  @override
  String get noInsightsInFilter => 'No insights in this filter';

  @override
  String get noInsightsInFilterBody => 'Tap Refresh or switch filter to see your money tips.';

  @override
  String get actionPauseSpending => 'Action: Pause non-essential spending today.';

  @override
  String get actionTightenBudget => 'Action: Tighten this week budget slightly.';

  @override
  String get actionKeepHabit => 'Action: Keep this habit going.';

  @override
  String get unifiedActivity => 'Unified Activity';

  @override
  String get unifiedActivitySubtitle => 'Track all account transactions in one consistent feed.';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get quickActionsSubtitle => 'Create focused transactions quickly';

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get quickQrEntry => 'Quick QR entry';

  @override
  String get combinedActivity => 'Combined Activity';

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String transactionsCount(int count) {
    return '$count transactions';
  }

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get noTransactionsYetBody => 'Add your first transaction and start generating insights.';

  @override
  String get manual => 'manual';

  @override
  String get auto => 'auto';

  @override
  String get overrideCategory => 'Override category';

  @override
  String get category => 'Category';

  @override
  String get updateCategory => 'Update category';

  @override
  String get title => 'Title';

  @override
  String get amount => 'Amount';

  @override
  String get sourceAccount => 'Source account';

  @override
  String get expense => 'Expense';

  @override
  String get tagsCommaSeparated => 'Tags (comma-separated)';

  @override
  String get saveTransaction => 'Save transaction';

  @override
  String get unifiedGoals => 'Unified Goals';

  @override
  String get unifiedGoalsSubtitle => 'Plan savings targets directly from your unified account platform.';

  @override
  String get savingsGoals => 'Savings goals';

  @override
  String get savingsGoalsSubtitle => 'Plan goals without killing daily life';

  @override
  String get newGoal => 'New goal';

  @override
  String get safeToSpendNow => 'Safe to spend now';

  @override
  String get safeToSpendNowSubtitle => 'After reserve + active goal allocation';

  @override
  String get noSavingsGoalsYet => 'No savings goals yet';

  @override
  String get noSavingsGoalsYetBody => 'Set up your first goal, like semester fee buffer or a new laptop.';

  @override
  String savedAmount(String amount) {
    return 'Saved $amount';
  }

  @override
  String targetAmount(String amount) {
    return 'Target $amount';
  }

  @override
  String addedToGoal(String amount) {
    return 'Added $amount to goal';
  }

  @override
  String get createGoal => 'Create goal';

  @override
  String get goalTitle => 'Goal title';

  @override
  String get targetAmountLabel => 'Target amount';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get unifiedAccounts => 'Unified Accounts';

  @override
  String get unifiedAccountsSubtitle => 'Manage bank, UPI and cash balances in one place.';

  @override
  String bankCount(int count) {
    return '$count bank';
  }

  @override
  String upiCount(int count) {
    return '$count upi';
  }

  @override
  String get accountHealth => 'Account Health';

  @override
  String get accountHealthSubtitle => 'Live balances and latest activity';

  @override
  String get liveModeDescription => 'Live mode: account balances and transactions update in real time via Firestore streams.';

  @override
  String get noAccountsFound => 'No accounts found';

  @override
  String get noAccountsFoundBody => 'Add an account from the activity flow to start tracking.';

  @override
  String transactionsShort(int count) {
    return '$count txns';
  }

  @override
  String get last => 'Last';

  @override
  String get latest => 'Latest';

  @override
  String get noRecentActivity => 'No recent activity.';
}
