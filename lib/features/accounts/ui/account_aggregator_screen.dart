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

class AccountAggregatorScreen extends ConsumerWidget {
  const AccountAggregatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Account> accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final List<FinanceTransaction> txs =
        ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(
              title: 'Digital banking simulation',
              subtitle: 'Virtual bank + UPI + cash account aggregator',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: () {
                    ref.read(simulationControllerProvider.notifier).seedVirtualAccounts();
                  },
                  icon: const Icon(Icons.account_balance),
                  label: const Text('Seed accounts'),
                ),
                OutlinedButton.icon(
                  onPressed: accounts.isEmpty
                      ? null
                      : () {
                          ref
                              .read(simulationControllerProvider.notifier)
                              .generateMockTransactions(count: 10);
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
                                          ),
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
                                    FilledButton.tonalIcon(
                                      onPressed: () {
                                        ref
                                            .read(simulationControllerProvider.notifier)
                                            .simulateCredit(accountId: account.id, amount: 1800);
                                      },
                                      icon: const Icon(Icons.add_card),
                                      label: const Text('Credit'),
                                    ),
                                    FilledButton.tonalIcon(
                                      onPressed: () {
                                        ref
                                            .read(simulationControllerProvider.notifier)
                                            .simulateDebit(accountId: account.id, amount: 420);
                                      },
                                      icon: const Icon(Icons.remove_circle_outline),
                                      label: const Text('Debit'),
                                    ),
                                    FilledButton.tonalIcon(
                                      onPressed: account.type == AccountType.upi
                                          ? () {
                                              ref
                                                  .read(simulationControllerProvider.notifier)
                                                  .simulateUpiPayment(
                                                    accountId: account.id,
                                                    amount: 240,
                                                  );
                                            }
                                          : null,
                                      icon: const Icon(Icons.qr_code_2),
                                      label: const Text('UPI pay'),
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
}
