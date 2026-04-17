import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/router/app_router.dart';
import 'package:student_fin_os/core/theme/app_theme.dart';

class StudentFinOsApp extends ConsumerWidget {
  const StudentFinOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Student Financial OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
