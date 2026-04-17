import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/router/app_router.dart';
import 'package:student_fin_os/core/theme/app_theme.dart';
import 'package:student_fin_os/l10n/app_localizations.dart';
import 'package:student_fin_os/providers/locale_providers.dart';

class StudentFinOsApp extends ConsumerWidget {
  const StudentFinOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale? selectedLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      locale: selectedLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
