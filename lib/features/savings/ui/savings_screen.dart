import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/l10n/app_localizations.dart';
import 'package:student_fin_os/models/savings_goal.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/savings_providers.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<SavingsGoal> goals = ref.watch(savingsGoalsProvider).value ?? const <SavingsGoal>[];
    final double safeToSpend = ref.watch(safeToSpendProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: <Color>[
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.18),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.unifiedGoals,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.unifiedGoalsSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: SectionHeader(
                    title: l10n.savingsGoals,
                    subtitle: l10n.savingsGoalsSubtitle,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openCreateGoalDialog(context, ref),
                  icon: const Icon(Icons.savings),
                  label: Text(l10n.newGoal),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance),
                title: Text(l10n.safeToSpendNow),
                subtitle: Text(l10n.safeToSpendNowSubtitle),
                trailing: Text(
                  CurrencyFormatter.inr(safeToSpend),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: goals.isEmpty
                  ? EmptyState(
                    title: l10n.noSavingsGoalsYet,
                    message: l10n.noSavingsGoalsYetBody,
                      icon: Icons.flag,
                    )
                  : ListView.builder(
                      itemCount: goals.length,
                      itemBuilder: (BuildContext context, int index) {
                        final SavingsGoal goal = goals[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      goal.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    Text(DateFormat('dd MMM').format(goal.deadline)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(value: goal.progress),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(l10n.savedAmount(CurrencyFormatter.inr(goal.savedAmount))),
                                    Text(l10n.targetAmount(CurrencyFormatter.inr(goal.targetAmount))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: <Widget>[
                                    OutlinedButton(
                                      onPressed: () => _contribute(context, ref, goal.id, 200),
                                      child: const Text('+200'),
                                    ),
                                    OutlinedButton(
                                      onPressed: () => _contribute(context, ref, goal.id, 500),
                                      child: const Text('+500'),
                                    ),
                                    OutlinedButton(
                                      onPressed: () => _contribute(context, ref, goal.id, 1000),
                                      child: const Text('+1000'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contribute(
    BuildContext context,
    WidgetRef ref,
    String goalId,
    double amount,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    await ref.read(savingsControllerProvider.notifier).addContribution(
          goalId: goalId,
          amount: amount,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addedToGoal(CurrencyFormatter.inr(amount)))),
      );
    }
  }

  Future<void> _openCreateGoalDialog(BuildContext context, WidgetRef ref) async {
    final TextEditingController title = TextEditingController();
    final TextEditingController target = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.createGoal),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: title, decoration: InputDecoration(labelText: l10n.goalTitle)),
              const SizedBox(height: 10),
              TextField(
                controller: target,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.targetAmountLabel),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final double amount = double.tryParse(target.text.trim()) ?? 0;
                if (title.text.trim().isEmpty || amount <= 0) {
                  return;
                }
                await ref.read(savingsControllerProvider.notifier).createGoal(
                      title: title.text.trim(),
                      targetAmount: amount,
                      deadline: DateTime.now().toUtc().add(const Duration(days: 120)),
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(l10n.create),
            ),
          ],
        );
      },
    );
  }
}
