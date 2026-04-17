import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/l10n/app_localizations.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';

class AccountAggregatorScreen extends ConsumerStatefulWidget {
  const AccountAggregatorScreen({super.key});

  @override
  ConsumerState<AccountAggregatorScreen> createState() => _AccountAggregatorScreenState();
}

class _AccountAggregatorScreenState extends ConsumerState<AccountAggregatorScreen> {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<Account> accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final List<FinanceTransaction> txs =
        ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];
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
                    l10n.unifiedAccounts,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.unifiedAccountsSubtitle,
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
                      _chip(context, icon: Icons.account_balance, label: l10n.bankCount(bankAccounts)),
                      _chip(context, icon: Icons.qr_code_2, label: l10n.upiCount(upiAccounts)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionHeader(
              title: l10n.accountHealth,
              subtitle: l10n.accountHealthSubtitle,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.liveModeDescription,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: accounts.isEmpty
                  ? EmptyState(
                    title: l10n.noAccountsFound,
                    message: l10n.noAccountsFoundBody,
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
                                            '${account.provider ?? l10n.wallet} • ${account.accountType.toUpperCase()} • ${l10n.transactionsShort(byAccount.length)}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                          if (latest != null) ...<Widget>[
                                            const SizedBox(height: 2),
                                            Text(
                                              '${l10n.last}: ${latest.title}',
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
                                Text(
                                  latest == null
                                      ? l10n.noRecentActivity
                                      : '${l10n.latest}: ${latest.category} • ${CurrencyFormatter.inr(latest.amount)}',
                                  style: Theme.of(context).textTheme.bodySmall,
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
