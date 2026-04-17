import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Financial OS'**
  String get appTitle;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Student Financial OS'**
  String get appName;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// No description provided for @upi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get upi;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get totalBalance;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @safeToSpend.
  ///
  /// In en, this message translates to:
  /// **'Safe to spend'**
  String get safeToSpend;

  /// No description provided for @weeklySpend.
  ///
  /// In en, this message translates to:
  /// **'Weekly spend'**
  String get weeklySpend;

  /// No description provided for @burnRatePerDay.
  ///
  /// In en, this message translates to:
  /// **'Burn rate/day'**
  String get burnRatePerDay;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Track everything. Split faster. Save smarter.'**
  String get loginTagline;

  /// No description provided for @collegeEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'College email'**
  String get collegeEmailLabel;

  /// No description provided for @collegeEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@college.edu'**
  String get collegeEmailHint;

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otpLabel;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP'**
  String get otpHint;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed.'**
  String get authFailed;

  /// No description provided for @unifiedFinancePlatform.
  ///
  /// In en, this message translates to:
  /// **'Unified Finance Platform'**
  String get unifiedFinancePlatform;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// No description provided for @languageMarathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get languageMarathi;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @dashboardUnifiedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Unified Platform'**
  String get dashboardUnifiedPlatform;

  /// No description provided for @dashboardOneCleanView.
  ///
  /// In en, this message translates to:
  /// **'One clean financial view across all your accounts.'**
  String get dashboardOneCleanView;

  /// No description provided for @dashboardConnectedToFeed.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts → Unified Feed'**
  String get dashboardConnectedToFeed;

  /// No description provided for @dashboardAccountsTransactions.
  ///
  /// In en, this message translates to:
  /// **'Accounts: {accountCount} • Transactions: {transactionCount}'**
  String dashboardAccountsTransactions(int accountCount, int transactionCount);

  /// No description provided for @dashboardLiveUpdates.
  ///
  /// In en, this message translates to:
  /// **'Live updates from Firestore streams'**
  String get dashboardLiveUpdates;

  /// No description provided for @dashboardNoSourcesYet.
  ///
  /// In en, this message translates to:
  /// **'No sources yet'**
  String get dashboardNoSourcesYet;

  /// No description provided for @smartGuidance.
  ///
  /// In en, this message translates to:
  /// **'Smart Guidance'**
  String get smartGuidance;

  /// No description provided for @smartGuidanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap any icon to learn a quick finance tip'**
  String get smartGuidanceSubtitle;

  /// No description provided for @tipAtmSafety.
  ///
  /// In en, this message translates to:
  /// **'ATM Safety'**
  String get tipAtmSafety;

  /// No description provided for @tipAtmSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Always cover PIN entry and avoid ATMs with loose keypads or suspicious devices.'**
  String get tipAtmSafetyBody;

  /// No description provided for @tipCreditScore.
  ///
  /// In en, this message translates to:
  /// **'Credit Score'**
  String get tipCreditScore;

  /// No description provided for @tipCreditScoreBody.
  ///
  /// In en, this message translates to:
  /// **'Pay bills before due date and keep utilization low to improve your credit score.'**
  String get tipCreditScoreBody;

  /// No description provided for @tipBudgeting.
  ///
  /// In en, this message translates to:
  /// **'Budgeting'**
  String get tipBudgeting;

  /// No description provided for @tipBudgetingBody.
  ///
  /// In en, this message translates to:
  /// **'Follow 50/30/20: needs, wants, and savings to keep spending balanced.'**
  String get tipBudgetingBody;

  /// No description provided for @tipInvesting.
  ///
  /// In en, this message translates to:
  /// **'Investing'**
  String get tipInvesting;

  /// No description provided for @tipInvestingBody.
  ///
  /// In en, this message translates to:
  /// **'Invest small amounts regularly and stay consistent for long-term growth.'**
  String get tipInvestingBody;

  /// No description provided for @topSpendings.
  ///
  /// In en, this message translates to:
  /// **'Top Spendings'**
  String get topSpendings;

  /// No description provided for @topSpendingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Most active categories'**
  String get topSpendingsSubtitle;

  /// No description provided for @connectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get connectedAccounts;

  /// No description provided for @connectedAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bank + UPI + cash balances'**
  String get connectedAccountsSubtitle;

  /// No description provided for @noAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get noAccountsYet;

  /// No description provided for @noAccountsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Create accounts to view unified balances.'**
  String get noAccountsYetBody;

  /// No description provided for @monthlySpendingTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly Spending Trend'**
  String get monthlySpendingTrend;

  /// No description provided for @monthlySpendingTrendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Month-over-month analysis'**
  String get monthlySpendingTrendSubtitle;

  /// No description provided for @noPreviousMonthBaseline.
  ///
  /// In en, this message translates to:
  /// **'No previous month baseline yet'**
  String get noPreviousMonthBaseline;

  /// No description provided for @spendingIncreasedBy.
  ///
  /// In en, this message translates to:
  /// **'Spending increased by {percent}%'**
  String spendingIncreasedBy(String percent);

  /// No description provided for @spendingDecreasedBy.
  ///
  /// In en, this message translates to:
  /// **'Spending decreased by {percent}%'**
  String spendingDecreasedBy(String percent);

  /// No description provided for @notEnoughMonthlyData.
  ///
  /// In en, this message translates to:
  /// **'Not enough monthly data'**
  String get notEnoughMonthlyData;

  /// No description provided for @notEnoughMonthlyDataBody.
  ///
  /// In en, this message translates to:
  /// **'Generate or add transactions to visualize spend trend.'**
  String get notEnoughMonthlyDataBody;

  /// No description provided for @categorySplit30d.
  ///
  /// In en, this message translates to:
  /// **'Category Split (30d)'**
  String get categorySplit30d;

  /// No description provided for @categorySplitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get categorySplitSubtitle;

  /// No description provided for @noCategoryDataYet.
  ///
  /// In en, this message translates to:
  /// **'No category data yet'**
  String get noCategoryDataYet;

  /// No description provided for @noCategoryDataYetBody.
  ///
  /// In en, this message translates to:
  /// **'Add transactions to unlock category insights.'**
  String get noCategoryDataYetBody;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @latestTransactions.
  ///
  /// In en, this message translates to:
  /// **'Latest transactions'**
  String get latestTransactions;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// No description provided for @noTransactionsFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first expense or income to start tracking.'**
  String get noTransactionsFoundBody;

  /// No description provided for @unifiedInsights.
  ///
  /// In en, this message translates to:
  /// **'Unified Insights'**
  String get unifiedInsights;

  /// No description provided for @unifiedInsightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simple money tips you can act on right now.'**
  String get unifiedInsightsSubtitle;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @headsUp.
  ///
  /// In en, this message translates to:
  /// **'Heads-up'**
  String get headsUp;

  /// No description provided for @fyi.
  ///
  /// In en, this message translates to:
  /// **'FYI'**
  String get fyi;

  /// No description provided for @moneyFeed.
  ///
  /// In en, this message translates to:
  /// **'Money Feed'**
  String get moneyFeed;

  /// No description provided for @moneyFeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear alerts + what to do next'**
  String get moneyFeedSubtitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @balanceRunway.
  ///
  /// In en, this message translates to:
  /// **'Balance runway'**
  String get balanceRunway;

  /// No description provided for @balanceStable14Days.
  ///
  /// In en, this message translates to:
  /// **'You look stable for the next 14 days.'**
  String get balanceStable14Days;

  /// No description provided for @balanceTightAround.
  ///
  /// In en, this message translates to:
  /// **'At current pace, balance may get tight around {date}.'**
  String balanceTightAround(String date);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noInsightsInFilter.
  ///
  /// In en, this message translates to:
  /// **'No insights in this filter'**
  String get noInsightsInFilter;

  /// No description provided for @noInsightsInFilterBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Refresh or switch filter to see your money tips.'**
  String get noInsightsInFilterBody;

  /// No description provided for @actionPauseSpending.
  ///
  /// In en, this message translates to:
  /// **'Action: Pause non-essential spending today.'**
  String get actionPauseSpending;

  /// No description provided for @actionTightenBudget.
  ///
  /// In en, this message translates to:
  /// **'Action: Tighten this week budget slightly.'**
  String get actionTightenBudget;

  /// No description provided for @actionKeepHabit.
  ///
  /// In en, this message translates to:
  /// **'Action: Keep this habit going.'**
  String get actionKeepHabit;

  /// No description provided for @unifiedActivity.
  ///
  /// In en, this message translates to:
  /// **'Unified Activity'**
  String get unifiedActivity;

  /// No description provided for @unifiedActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track all account transactions in one consistent feed.'**
  String get unifiedActivitySubtitle;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @quickActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create focused transactions quickly'**
  String get quickActionsSubtitle;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addTransaction;

  /// No description provided for @quickQrEntry.
  ///
  /// In en, this message translates to:
  /// **'Quick QR entry'**
  String get quickQrEntry;

  /// No description provided for @combinedActivity.
  ///
  /// In en, this message translates to:
  /// **'Combined Activity'**
  String get combinedActivity;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivityYet;

  /// No description provided for @transactionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String transactionsCount(int count);

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @noTransactionsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first transaction and start generating insights.'**
  String get noTransactionsYetBody;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'manual'**
  String get manual;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'auto'**
  String get auto;

  /// No description provided for @overrideCategory.
  ///
  /// In en, this message translates to:
  /// **'Override category'**
  String get overrideCategory;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @updateCategory.
  ///
  /// In en, this message translates to:
  /// **'Update category'**
  String get updateCategory;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @sourceAccount.
  ///
  /// In en, this message translates to:
  /// **'Source account'**
  String get sourceAccount;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @tagsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma-separated)'**
  String get tagsCommaSeparated;

  /// No description provided for @saveTransaction.
  ///
  /// In en, this message translates to:
  /// **'Save transaction'**
  String get saveTransaction;

  /// No description provided for @unifiedGoals.
  ///
  /// In en, this message translates to:
  /// **'Unified Goals'**
  String get unifiedGoals;

  /// No description provided for @unifiedGoalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan savings targets directly from your unified account platform.'**
  String get unifiedGoalsSubtitle;

  /// No description provided for @savingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get savingsGoals;

  /// No description provided for @savingsGoalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan goals without killing daily life'**
  String get savingsGoalsSubtitle;

  /// No description provided for @newGoal.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get newGoal;

  /// No description provided for @safeToSpendNow.
  ///
  /// In en, this message translates to:
  /// **'Safe to spend now'**
  String get safeToSpendNow;

  /// No description provided for @safeToSpendNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After reserve + active goal allocation'**
  String get safeToSpendNowSubtitle;

  /// No description provided for @noSavingsGoalsYet.
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet'**
  String get noSavingsGoalsYet;

  /// No description provided for @noSavingsGoalsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Set up your first goal, like semester fee buffer or a new laptop.'**
  String get noSavingsGoalsYetBody;

  /// No description provided for @savedAmount.
  ///
  /// In en, this message translates to:
  /// **'Saved {amount}'**
  String savedAmount(String amount);

  /// No description provided for @targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target {amount}'**
  String targetAmount(String amount);

  /// No description provided for @addedToGoal.
  ///
  /// In en, this message translates to:
  /// **'Added {amount} to goal'**
  String addedToGoal(String amount);

  /// No description provided for @createGoal.
  ///
  /// In en, this message translates to:
  /// **'Create goal'**
  String get createGoal;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal title'**
  String get goalTitle;

  /// No description provided for @targetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get targetAmountLabel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @unifiedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Unified Accounts'**
  String get unifiedAccounts;

  /// No description provided for @unifiedAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage bank, UPI and cash balances in one place.'**
  String get unifiedAccountsSubtitle;

  /// No description provided for @bankCount.
  ///
  /// In en, this message translates to:
  /// **'{count} bank'**
  String bankCount(int count);

  /// No description provided for @upiCount.
  ///
  /// In en, this message translates to:
  /// **'{count} upi'**
  String upiCount(int count);

  /// No description provided for @accountHealth.
  ///
  /// In en, this message translates to:
  /// **'Account Health'**
  String get accountHealth;

  /// No description provided for @accountHealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live balances and latest activity'**
  String get accountHealthSubtitle;

  /// No description provided for @liveModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Live mode: account balances and transactions update in real time via Firestore streams.'**
  String get liveModeDescription;

  /// No description provided for @noAccountsFound.
  ///
  /// In en, this message translates to:
  /// **'No accounts found'**
  String get noAccountsFound;

  /// No description provided for @noAccountsFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Add an account from the activity flow to start tracking.'**
  String get noAccountsFoundBody;

  /// No description provided for @transactionsShort.
  ///
  /// In en, this message translates to:
  /// **'{count} txns'**
  String transactionsShort(int count);

  /// No description provided for @last.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get last;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity.'**
  String get noRecentActivity;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'mr': return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
