import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:student_fin_os/l10n/app_localizations.dart';
import 'package:student_fin_os/providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpRequested = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<void> authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (AsyncValue<void>? previous,
        AsyncValue<void> next) {
      next.whenOrNull(
        error: (Object error, StackTrace stackTrace) {
          final String message;
          if (error is FirebaseAuthException) {
            message = error.message ?? l10n.authFailed;
          } else {
            message = error.toString();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
      );
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF070B14), Color(0xFF111E35), Color(0xFF0D1324)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.appName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.loginTagline,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.collegeEmailLabel,
                        hintText: l10n.collegeEmailHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_otpRequested)
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: l10n.otpLabel,
                          hintText: l10n.otpHint,
                        ),
                      ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: authState.isLoading
                          ? null
                          : () async {
                              final String email = _emailController.text.trim();
                              if (email.isEmpty) {
                                return;
                              }
                              if (!_otpRequested) {
                                await ref
                                    .read(authControllerProvider.notifier)
                                    .requestOtp(email);
                                if (mounted) {
                                  setState(() {
                                    _otpRequested = true;
                                  });
                                }
                              } else {
                                await ref
                                    .read(authControllerProvider.notifier)
                                    .verifyOtp(
                                      email: email,
                                      otp: _otpController.text.trim(),
                                    );
                              }
                            },
                      child: Text(_otpRequested ? l10n.verifyOtp : l10n.sendOtp),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithGoogle();
                            },
                      icon: const Icon(Icons.login),
                        label: Text(l10n.continueWithGoogle),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
