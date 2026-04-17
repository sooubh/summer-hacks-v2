import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/simulation_providers.dart';

class AccountAggregatorScreen extends ConsumerStatefulWidget {
  const AccountAggregatorScreen({super.key});

  @override
  ConsumerState<AccountAggregatorScreen> createState() => _AccountAggregatorScreenState();
}

class _AccountAggregatorScreenState extends ConsumerState<AccountAggregatorScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<void>>(
      simulationControllerProvider,
      (AsyncValue<void>? previous, AsyncValue<void> next) {
        next.whenOrNull(
          error: (Object error, StackTrace stackTrace) {
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Action failed: $error')),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Account> accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final List<FinanceTransaction> txs =
        ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];
    final bool isBusy = ref.watch(simulationControllerProvider).isLoading;
    final double totalBalance =
        accounts.fold<double>(0, (double sum, Account item) => sum + item.balance);
    final int upiAccounts = accounts.where((Account a) => a.type == AccountType.upi).length;
    final int bankAccounts = accounts.where((Account a) => a.type == AccountType.bank).length;

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
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Unified Accounts',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage bank, UPI and cash balances in one place.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _chip(
                        context,
                        icon: Icons.account_balance_wallet,
                        label: CurrencyFormatter.inr(totalBalance),
                      ),
                      _chip(context, icon: Icons.account_balance, label: '$bankAccounts bank'),
                      _chip(context, icon: Icons.qr_code_2, label: '$upiAccounts upi'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionHeader(
              title: 'Platform Controls',
              subtitle: isBusy ? 'Running action...' : 'Seed accounts and generate consistent mock activity',
            ),
            const SizedBox(height: 6),
            Text(
              'Live mode: account balances and transactions update in real time via Firestore streams.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: isBusy
                      ? null
                      : () async {
                          await ref
                              .read(simulationControllerProvider.notifier)
                              .seedVirtualAccounts();
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Virtual accounts synced.')),
                          );
                        },
                  icon: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.account_balance),
                  label: const Text('Seed accounts'),
                ),
                OutlinedButton.icon(
                  onPressed: isBusy
                      ? null
                      : accounts.isEmpty
                          ? null
                      : () async {
                          await ref
                              .read(simulationControllerProvider.notifier)
                              .generateMockTransactions(count: 10);
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('10 mock transactions generated.')),
                          );
                        },
                  icon: const Icon(Icons.bolt),
                  label: const Text('Generate mock txns'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: accounts.isEmpty
                  ? const EmptyState(
                      title: 'No virtual accounts found',
                      message:
                          'Tap "Seed accounts" to create simulated SBI/HDFC bank, UPI wallet, and cash accounts.',
                      icon: Icons.account_balance_wallet,
                    )
                  : ListView.builder(
                      itemCount: accounts.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Account account = accounts[index];
                        final List<FinanceTransaction> byAccount = txs
                            .where((FinanceTransaction tx) => tx.accountId == account.id)
                            .toList();
                        final FinanceTransaction? latest =
                            byAccount.isEmpty ? null : byAccount.first;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    CircleAvatar(
                                      child: Icon(_iconForAccountType(account.type)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            account.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                          Text(
                                            '${account.provider ?? 'wallet'} • ${account.accountType.toUpperCase()} • ${byAccount.length} txns',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                          if (latest != null) ...<Widget>[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Last: ${latest.title}',
                                              style: Theme.of(context).textTheme.bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.inr(account.balance),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    ActionChip(
                                      avatar: const Icon(Icons.add_card, size: 18),
                                      label: const Text('Credit'),
                                      onPressed: isBusy
                                          ? null
                                          : () {
                                              ref
                                                  .read(simulationControllerProvider.notifier)
                                                  .simulateCredit(
                                                        accountId: account.id,
                                                        amount: 1800,
                                                      );
                                            },
                                    ),
                                    ActionChip(
                                      avatar:
                                          const Icon(Icons.remove_circle_outline, size: 18),
                                      label: const Text('Debit'),
                                      onPressed: isBusy
                                          ? null
                                          : () {
                                              ref
                                                  .read(simulationControllerProvider.notifier)
                                                  .simulateDebit(
                                                        accountId: account.id,
                                                        amount: 420,
                                                      );
                                            },
                                    ),
                                    ActionChip(
                                      avatar: const Icon(Icons.qr_code_2, size: 18),
                                      label: const Text('UPI pay'),
                                      onPressed: isBusy
                                          ? null
                                          : account.type == AccountType.upi
                                          ? () {
                                              ref
                                                  .read(simulationControllerProvider.notifier)
                                                  .simulateUpiPayment(
                                                    accountId: account.id,
                                                    amount: 240,
                                                  );
                                            }
                                          : null,
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

  IconData _iconForAccountType(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.upi:
        return Icons.smartphone;
      case AccountType.cash:
        return Icons.payments;
    }
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
