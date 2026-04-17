// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'स्टूडेंट फाइनेंशियल ओएस';

  @override
  String get appName => 'स्टूडेंट फाइनेंशियल ओएस';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get bank => 'बैंक';

  @override
  String get upi => 'यूपीआई';

  @override
  String get cash => 'कैश';

  @override
  String get wallet => 'वॉलेट';

  @override
  String get totalBalance => 'कुल बैलेंस';

  @override
  String get income => 'आय';

  @override
  String get spent => 'खर्च';

  @override
  String get safeToSpend => 'खर्च के लिए सुरक्षित';

  @override
  String get weeklySpend => 'साप्ताहिक खर्च';

  @override
  String get burnRatePerDay => 'बर्न रेट/दिन';

  @override
  String get errorPrefix => 'त्रुटि';

  @override
  String get loginTagline => 'सब कुछ ट्रैक करें। खर्च बांटें। समझदारी से बचत करें।';

  @override
  String get collegeEmailLabel => 'कॉलेज ईमेल';

  @override
  String get collegeEmailHint => 'you@college.edu';

  @override
  String get otpLabel => 'ओटीपी';

  @override
  String get otpHint => '6 अंकों का ओटीपी दर्ज करें';

  @override
  String get verifyOtp => 'ओटीपी सत्यापित करें';

  @override
  String get sendOtp => 'ओटीपी भेजें';

  @override
  String get continueWithGoogle => 'Google से जारी रखें';

  @override
  String get authFailed => 'प्रमाणीकरण विफल हुआ।';

  @override
  String get unifiedFinancePlatform => 'यूनिफाइड फाइनेंस प्लेटफ़ॉर्म';

  @override
  String get home => 'होम';

  @override
  String get insights => 'इनसाइट्स';

  @override
  String get goals => 'लक्ष्य';

  @override
  String get activity => 'गतिविधि';

  @override
  String get language => 'भाषा';

  @override
  String get languageEnglish => 'अंग्रेज़ी';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get languageMarathi => 'मराठी';

  @override
  String get signOut => 'लॉग आउट';

  @override
  String get dashboardUnifiedPlatform => 'यूनिफाइड प्लेटफ़ॉर्म';

  @override
  String get dashboardOneCleanView => 'आपके सभी खातों का एक साफ वित्तीय दृश्य।';

  @override
  String get dashboardConnectedToFeed => 'कनेक्टेड अकाउंट्स → यूनिफाइड फीड';

  @override
  String dashboardAccountsTransactions(int accountCount, int transactionCount) {
    return 'अकाउंट्स: $accountCount • ट्रांजैक्शन्स: $transactionCount';
  }

  @override
  String get dashboardLiveUpdates => 'Firestore स्ट्रीम्स से लाइव अपडेट्स';

  @override
  String get dashboardNoSourcesYet => 'अभी कोई सोर्स नहीं';

  @override
  String get smartGuidance => 'स्मार्ट गाइडेंस';

  @override
  String get smartGuidanceSubtitle => 'जल्दी फाइनेंस टिप के लिए किसी आइकन पर टैप करें';

  @override
  String get tipAtmSafety => 'एटीएम सुरक्षा';

  @override
  String get tipAtmSafetyBody => 'पिन डालते समय हमेशा कीपैड को ढकें और संदिग्ध एटीएम से बचें।';

  @override
  String get tipCreditScore => 'क्रेडिट स्कोर';

  @override
  String get tipCreditScoreBody => 'समय पर बिल भरें और उपयोग कम रखें ताकि क्रेडिट स्कोर बेहतर हो।';

  @override
  String get tipBudgeting => 'बजटिंग';

  @override
  String get tipBudgetingBody => '50/30/20 नियम अपनाएँ: ज़रूरतें, इच्छाएँ और बचत।';

  @override
  String get tipInvesting => 'निवेश';

  @override
  String get tipInvestingBody => 'छोटी रकम नियमित रूप से निवेश करें और निरंतरता रखें।';

  @override
  String get topSpendings => 'टॉप खर्च';

  @override
  String get topSpendingsSubtitle => 'सबसे सक्रिय श्रेणियाँ';

  @override
  String get connectedAccounts => 'कनेक्टेड अकाउंट्स';

  @override
  String get connectedAccountsSubtitle => 'बैंक + यूपीआई + कैश बैलेंस';

  @override
  String get noAccountsYet => 'अभी कोई अकाउंट नहीं';

  @override
  String get noAccountsYetBody => 'यूनिफाइड बैलेंस देखने के लिए अकाउंट बनाएँ।';

  @override
  String get monthlySpendingTrend => 'मासिक खर्च ट्रेंड';

  @override
  String get monthlySpendingTrendSubtitle => 'महीना-दर-महीना विश्लेषण';

  @override
  String get noPreviousMonthBaseline => 'पिछले महीने का बेसलाइन अभी नहीं है';

  @override
  String spendingIncreasedBy(String percent) {
    return 'खर्च $percent% बढ़ा';
  }

  @override
  String spendingDecreasedBy(String percent) {
    return 'खर्च $percent% घटा';
  }

  @override
  String get notEnoughMonthlyData => 'पर्याप्त मासिक डेटा नहीं';

  @override
  String get notEnoughMonthlyDataBody => 'ट्रेंड देखने के लिए ट्रांजैक्शन जोड़ें।';

  @override
  String get categorySplit30d => 'श्रेणी विभाजन (30 दिन)';

  @override
  String get categorySplitSubtitle => 'श्रेणी अनुसार खर्च';

  @override
  String get noCategoryDataYet => 'अभी कोई श्रेणी डेटा नहीं';

  @override
  String get noCategoryDataYetBody => 'श्रेणी इनसाइट्स के लिए ट्रांजैक्शन जोड़ें।';

  @override
  String get recentActivity => 'हाल की गतिविधि';

  @override
  String get latestTransactions => 'नवीनतम ट्रांजैक्शन्स';

  @override
  String get noTransactionsFound => 'कोई ट्रांजैक्शन नहीं मिला';

  @override
  String get noTransactionsFoundBody => 'ट्रैकिंग शुरू करने के लिए पहला ट्रांजैक्शन जोड़ें।';

  @override
  String get unifiedInsights => 'यूनिफाइड इनसाइट्स';

  @override
  String get unifiedInsightsSubtitle => 'सीधे उपयोग में आने वाले आसान पैसे के टिप्स।';

  @override
  String get urgent => 'तुरंत';

  @override
  String get headsUp => 'ध्यान दें';

  @override
  String get fyi => 'जानकारी';

  @override
  String get moneyFeed => 'मनी फीड';

  @override
  String get moneyFeedSubtitle => 'स्पष्ट अलर्ट + आगे क्या करें';

  @override
  String get refresh => 'रिफ्रेश';

  @override
  String get balanceRunway => 'बैलेंस रनवे';

  @override
  String get balanceStable14Days => 'अगले 14 दिनों के लिए स्थिति स्थिर लग रही है।';

  @override
  String balanceTightAround(String date) {
    return 'वर्तमान रफ्तार पर बैलेंस $date के आसपास कम पड़ सकता है।';
  }

  @override
  String get all => 'सभी';

  @override
  String get noInsightsInFilter => 'इस फ़िल्टर में कोई इनसाइट नहीं';

  @override
  String get noInsightsInFilterBody => 'रिफ्रेश करें या फ़िल्टर बदलें।';

  @override
  String get actionPauseSpending => 'कार्य: आज गैर-ज़रूरी खर्च रोकें।';

  @override
  String get actionTightenBudget => 'कार्य: इस हफ्ते का बजट थोड़ा कड़ा रखें।';

  @override
  String get actionKeepHabit => 'कार्य: यह आदत जारी रखें।';

  @override
  String get unifiedActivity => 'यूनिफाइड एक्टिविटी';

  @override
  String get unifiedActivitySubtitle => 'सभी अकाउंट ट्रांजैक्शन्स एक फीड में देखें।';

  @override
  String get quickActions => 'क्विक एक्शन्स';

  @override
  String get quickActionsSubtitle => 'तेज़ी से ट्रांजैक्शन बनाएँ';

  @override
  String get addTransaction => 'ट्रांजैक्शन जोड़ें';

  @override
  String get quickQrEntry => 'क्विक QR एंट्री';

  @override
  String get combinedActivity => 'कम्बाइंड एक्टिविटी';

  @override
  String get noActivityYet => 'अभी कोई गतिविधि नहीं';

  @override
  String transactionsCount(int count) {
    return '$count ट्रांजैक्शन्स';
  }

  @override
  String get noTransactionsYet => 'अभी कोई ट्रांजैक्शन नहीं';

  @override
  String get noTransactionsYetBody => 'पहला ट्रांजैक्शन जोड़ें और इनसाइट्स शुरू करें।';

  @override
  String get manual => 'मैनुअल';

  @override
  String get auto => 'ऑटो';

  @override
  String get overrideCategory => 'श्रेणी बदलें';

  @override
  String get category => 'श्रेणी';

  @override
  String get updateCategory => 'श्रेणी अपडेट करें';

  @override
  String get title => 'शीर्षक';

  @override
  String get amount => 'राशि';

  @override
  String get sourceAccount => 'सोर्स अकाउंट';

  @override
  String get expense => 'खर्च';

  @override
  String get tagsCommaSeparated => 'टैग (कॉमा से अलग)';

  @override
  String get saveTransaction => 'ट्रांजैक्शन सेव करें';

  @override
  String get unifiedGoals => 'यूनिफाइड गोल्स';

  @override
  String get unifiedGoalsSubtitle => 'अपने यूनिफाइड प्लेटफ़ॉर्म से बचत लक्ष्य प्लान करें।';

  @override
  String get savingsGoals => 'बचत लक्ष्य';

  @override
  String get savingsGoalsSubtitle => 'दैनिक जीवन बिगाड़े बिना लक्ष्य बनाएं';

  @override
  String get newGoal => 'नया लक्ष्य';

  @override
  String get safeToSpendNow => 'अभी खर्च के लिए सुरक्षित';

  @override
  String get safeToSpendNowSubtitle => 'रिज़र्व + सक्रिय लक्ष्यों के बाद';

  @override
  String get noSavingsGoalsYet => 'अभी कोई बचत लक्ष्य नहीं';

  @override
  String get noSavingsGoalsYetBody => 'पहला लक्ष्य सेट करें, जैसे फीस बफर या नया लैपटॉप।';

  @override
  String savedAmount(String amount) {
    return 'बचाया $amount';
  }

  @override
  String targetAmount(String amount) {
    return 'लक्ष्य $amount';
  }

  @override
  String addedToGoal(String amount) {
    return 'लक्ष्य में $amount जोड़ा गया';
  }

  @override
  String get createGoal => 'लक्ष्य बनाएँ';

  @override
  String get goalTitle => 'लक्ष्य शीर्षक';

  @override
  String get targetAmountLabel => 'लक्ष्य राशि';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get create => 'बनाएँ';

  @override
  String get unifiedAccounts => 'यूनिफाइड अकाउंट्स';

  @override
  String get unifiedAccountsSubtitle => 'बैंक, यूपीआई और कैश बैलेंस एक जगह मैनेज करें।';

  @override
  String bankCount(int count) {
    return '$count बैंक';
  }

  @override
  String upiCount(int count) {
    return '$count यूपीआई';
  }

  @override
  String get accountHealth => 'अकाउंट हेल्थ';

  @override
  String get accountHealthSubtitle => 'लाइव बैलेंस और हाल की गतिविधि';

  @override
  String get liveModeDescription => 'लाइव मोड: अकाउंट बैलेंस और ट्रांजैक्शन Firestore स्ट्रीम्स से तुरंत अपडेट होते हैं।';

  @override
  String get noAccountsFound => 'कोई अकाउंट नहीं मिला';

  @override
  String get noAccountsFoundBody => 'ट्रैकिंग शुरू करने के लिए एक्टिविटी से अकाउंट जोड़ें।';

  @override
  String transactionsShort(int count) {
    return '$count ट्रांजैक्शन';
  }

  @override
  String get last => 'पिछला';

  @override
  String get latest => 'नवीनतम';

  @override
  String get noRecentActivity => 'हाल की कोई गतिविधि नहीं।';
}
