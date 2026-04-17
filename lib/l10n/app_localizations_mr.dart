// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'स्टुडंट फायनान्शियल ओएस';

  @override
  String get appName => 'स्टुडंट फायनान्शियल ओएस';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get bank => 'बँक';

  @override
  String get upi => 'यूपीआय';

  @override
  String get cash => 'रोख';

  @override
  String get wallet => 'वॉलेट';

  @override
  String get totalBalance => 'एकूण शिल्लक';

  @override
  String get income => 'उत्पन्न';

  @override
  String get spent => 'खर्च';

  @override
  String get safeToSpend => 'खर्चासाठी सुरक्षित';

  @override
  String get weeklySpend => 'साप्ताहिक खर्च';

  @override
  String get burnRatePerDay => 'बर्न रेट/दिवस';

  @override
  String get errorPrefix => 'त्रुटी';

  @override
  String get loginTagline => 'सगळे ट्रॅक करा. खर्च वाटा. शहाणपणाने बचत करा.';

  @override
  String get collegeEmailLabel => 'कॉलेज ईमेल';

  @override
  String get collegeEmailHint => 'you@college.edu';

  @override
  String get otpLabel => 'ओटीपी';

  @override
  String get otpHint => '6 अंकी ओटीपी टाका';

  @override
  String get verifyOtp => 'ओटीपी पडताळा';

  @override
  String get sendOtp => 'ओटीपी पाठवा';

  @override
  String get continueWithGoogle => 'Google सह पुढे जा';

  @override
  String get authFailed => 'प्रमाणीकरण अयशस्वी झाले.';

  @override
  String get unifiedFinancePlatform => 'युनिफाइड फायनान्स प्लॅटफॉर्म';

  @override
  String get home => 'होम';

  @override
  String get insights => 'इनसाइट्स';

  @override
  String get goals => 'ध्येये';

  @override
  String get activity => 'अॅक्टिव्हिटी';

  @override
  String get language => 'भाषा';

  @override
  String get languageEnglish => 'इंग्रजी';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get languageMarathi => 'मराठी';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get dashboardUnifiedPlatform => 'युनिफाइड प्लॅटफॉर्म';

  @override
  String get dashboardOneCleanView => 'तुमच्या सर्व खात्यांचा एक स्वच्छ आर्थिक आढावा.';

  @override
  String get dashboardConnectedToFeed => 'कनेक्टेड अकाउंट्स → युनिफाइड फीड';

  @override
  String dashboardAccountsTransactions(int accountCount, int transactionCount) {
    return 'अकाउंट्स: $accountCount • ट्रान्झॅक्शन्स: $transactionCount';
  }

  @override
  String get dashboardLiveUpdates => 'Firestore स्ट्रीम्समधून लाइव्ह अपडेट्स';

  @override
  String get dashboardNoSourcesYet => 'अजून स्रोत नाहीत';

  @override
  String get smartGuidance => 'स्मार्ट मार्गदर्शन';

  @override
  String get smartGuidanceSubtitle => 'झटपट आर्थिक टिपसाठी कोणत्याही आयकॉनवर टॅप करा';

  @override
  String get tipAtmSafety => 'एटीएम सुरक्षितता';

  @override
  String get tipAtmSafetyBody => 'पिन टाकताना कीपॅड झाका आणि संशयास्पद एटीएम टाळा.';

  @override
  String get tipCreditScore => 'क्रेडिट स्कोअर';

  @override
  String get tipCreditScoreBody => 'बिले वेळेवर भरा आणि वापर कमी ठेवा.';

  @override
  String get tipBudgeting => 'बजेटिंग';

  @override
  String get tipBudgetingBody => '50/30/20 नियम पाळा: गरजा, इच्छा आणि बचत.';

  @override
  String get tipInvesting => 'गुंतवणूक';

  @override
  String get tipInvestingBody => 'लहान रक्कम नियमितपणे गुंतवा आणि सातत्य ठेवा.';

  @override
  String get topSpendings => 'टॉप खर्च';

  @override
  String get topSpendingsSubtitle => 'सर्वाधिक सक्रिय श्रेणी';

  @override
  String get connectedAccounts => 'कनेक्टेड अकाउंट्स';

  @override
  String get connectedAccountsSubtitle => 'बँक + यूपीआय + रोख शिल्लक';

  @override
  String get noAccountsYet => 'अजून अकाउंट नाही';

  @override
  String get noAccountsYetBody => 'युनिफाइड शिल्लक पाहण्यासाठी अकाउंट तयार करा.';

  @override
  String get monthlySpendingTrend => 'मासिक खर्च ट्रेंड';

  @override
  String get monthlySpendingTrendSubtitle => 'महिना-निहाय विश्लेषण';

  @override
  String get noPreviousMonthBaseline => 'मागील महिन्याचा बेसलाइन उपलब्ध नाही';

  @override
  String spendingIncreasedBy(String percent) {
    return 'खर्च $percent% वाढला';
  }

  @override
  String spendingDecreasedBy(String percent) {
    return 'खर्च $percent% कमी झाला';
  }

  @override
  String get notEnoughMonthlyData => 'पुरेसा मासिक डेटा नाही';

  @override
  String get notEnoughMonthlyDataBody => 'ट्रेंड पाहण्यासाठी ट्रान्झॅक्शन्स जोडा.';

  @override
  String get categorySplit30d => 'श्रेणी विभाजन (30 दिवस)';

  @override
  String get categorySplitSubtitle => 'श्रेणीप्रमाणे खर्च';

  @override
  String get noCategoryDataYet => 'अजून श्रेणी डेटा नाही';

  @override
  String get noCategoryDataYetBody => 'श्रेणी इनसाइट्ससाठी ट्रान्झॅक्शन्स जोडा.';

  @override
  String get recentActivity => 'अलीकडील अॅक्टिव्हिटी';

  @override
  String get latestTransactions => 'नवीनतम ट्रान्झॅक्शन्स';

  @override
  String get noTransactionsFound => 'ट्रान्झॅक्शन सापडले नाही';

  @override
  String get noTransactionsFoundBody => 'ट्रॅकिंग सुरू करण्यासाठी पहिला ट्रान्झॅक्शन जोडा.';

  @override
  String get unifiedInsights => 'युनिफाइड इनसाइट्स';

  @override
  String get unifiedInsightsSubtitle => 'आता लगेच वापरता येतील असे सोपे पैशाचे टिप्स.';

  @override
  String get urgent => 'तातडीचे';

  @override
  String get headsUp => 'सूचना';

  @override
  String get fyi => 'माहितीसाठी';

  @override
  String get moneyFeed => 'मनी फीड';

  @override
  String get moneyFeedSubtitle => 'स्पष्ट अलर्ट + पुढे काय करावे';

  @override
  String get refresh => 'रिफ्रेश';

  @override
  String get balanceRunway => 'बॅलन्स रनवे';

  @override
  String get balanceStable14Days => 'पुढील 14 दिवसांसाठी स्थिती स्थिर दिसते.';

  @override
  String balanceTightAround(String date) {
    return 'सध्याच्या गतीनुसार $date च्या आसपास बॅलन्स कमी पडू शकतो.';
  }

  @override
  String get all => 'सर्व';

  @override
  String get noInsightsInFilter => 'या फिल्टरमध्ये इनसाइट्स नाहीत';

  @override
  String get noInsightsInFilterBody => 'रिफ्रेश करा किंवा फिल्टर बदला.';

  @override
  String get actionPauseSpending => 'क्रिया: आज अनावश्यक खर्च थांबवा.';

  @override
  String get actionTightenBudget => 'क्रिया: या आठवड्याचा बजेट थोडा कमी करा.';

  @override
  String get actionKeepHabit => 'क्रिया: ही चांगली सवय सुरू ठेवा.';

  @override
  String get unifiedActivity => 'युनिफाइड अॅक्टिव्हिटी';

  @override
  String get unifiedActivitySubtitle => 'सर्व अकाउंट ट्रान्झॅक्शन्स एकाच फीडमध्ये ट्रॅक करा.';

  @override
  String get quickActions => 'क्विक अॅक्शन्स';

  @override
  String get quickActionsSubtitle => 'जलद ट्रान्झॅक्शन्स तयार करा';

  @override
  String get addTransaction => 'ट्रान्झॅक्शन जोडा';

  @override
  String get quickQrEntry => 'क्विक QR एन्ट्री';

  @override
  String get combinedActivity => 'कंबाइंड अॅक्टिव्हिटी';

  @override
  String get noActivityYet => 'अजून अॅक्टिव्हिटी नाही';

  @override
  String transactionsCount(int count) {
    return '$count ट्रान्झॅक्शन्स';
  }

  @override
  String get noTransactionsYet => 'अजून ट्रान्झॅक्शन्स नाहीत';

  @override
  String get noTransactionsYetBody => 'पहिला ट्रान्झॅक्शन जोडा आणि इनसाइट्स सुरू करा.';

  @override
  String get manual => 'मॅन्युअल';

  @override
  String get auto => 'ऑटो';

  @override
  String get overrideCategory => 'श्रेणी बदला';

  @override
  String get category => 'श्रेणी';

  @override
  String get updateCategory => 'श्रेणी अपडेट करा';

  @override
  String get title => 'शीर्षक';

  @override
  String get amount => 'रक्कम';

  @override
  String get sourceAccount => 'स्रोत अकाउंट';

  @override
  String get expense => 'खर्च';

  @override
  String get tagsCommaSeparated => 'टॅग्स (कॉमा-सेपरेटेड)';

  @override
  String get saveTransaction => 'ट्रान्झॅक्शन सेव्ह करा';

  @override
  String get unifiedGoals => 'युनिफाइड गोल्स';

  @override
  String get unifiedGoalsSubtitle => 'युनिफाइड प्लॅटफॉर्मवरून बचत लक्ष्य तयार करा.';

  @override
  String get savingsGoals => 'बचत ध्येये';

  @override
  String get savingsGoalsSubtitle => 'दैनंदिन जीवन बिघडवू न देता ध्येय ठरवा';

  @override
  String get newGoal => 'नवे ध्येय';

  @override
  String get safeToSpendNow => 'आत्ता खर्चासाठी सुरक्षित';

  @override
  String get safeToSpendNowSubtitle => 'रिझर्व्ह + सक्रिय ध्येय वाटपानंतर';

  @override
  String get noSavingsGoalsYet => 'अजून बचत ध्येय नाही';

  @override
  String get noSavingsGoalsYetBody => 'पहिले ध्येय सेट करा, उदा. फी बफर किंवा लॅपटॉप.';

  @override
  String savedAmount(String amount) {
    return 'बचत $amount';
  }

  @override
  String targetAmount(String amount) {
    return 'लक्ष्य $amount';
  }

  @override
  String addedToGoal(String amount) {
    return 'ध्येयात $amount जोडले';
  }

  @override
  String get createGoal => 'ध्येय तयार करा';

  @override
  String get goalTitle => 'ध्येय शीर्षक';

  @override
  String get targetAmountLabel => 'लक्ष्य रक्कम';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get create => 'तयार करा';

  @override
  String get unifiedAccounts => 'युनिफाइड अकाउंट्स';

  @override
  String get unifiedAccountsSubtitle => 'बँक, यूपीआय आणि रोख शिल्लक एकाच ठिकाणी व्यवस्थापित करा.';

  @override
  String bankCount(int count) {
    return '$count बँक';
  }

  @override
  String upiCount(int count) {
    return '$count यूपीआय';
  }

  @override
  String get accountHealth => 'अकाउंट हेल्थ';

  @override
  String get accountHealthSubtitle => 'लाइव्ह शिल्लक आणि अलीकडील अॅक्टिव्हिटी';

  @override
  String get liveModeDescription => 'लाइव्ह मोड: अकाउंट शिल्लक आणि ट्रान्झॅक्शन्स Firestore स्ट्रीम्सद्वारे रिअल-टाइममध्ये अपडेट होतात.';

  @override
  String get noAccountsFound => 'अकाउंट सापडले नाही';

  @override
  String get noAccountsFoundBody => 'ट्रॅकिंग सुरू करण्यासाठी अॅक्टिव्हिटीमधून अकाउंट जोडा.';

  @override
  String transactionsShort(int count) {
    return '$count ट्रान्झॅक्शन';
  }

  @override
  String get last => 'मागील';

  @override
  String get latest => 'नवीनतम';

  @override
  String get noRecentActivity => 'अलीकडील अॅक्टिव्हिटी नाही.';
}
