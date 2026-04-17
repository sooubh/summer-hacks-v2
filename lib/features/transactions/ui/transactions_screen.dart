import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/l10n/app_localizations.dart';
import 'package:student_fin_os/core/utils/brand_styles.dart';
import 'package:student_fin_os/features/dashboard/ui/transaction_details_sheet.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/transaction_providers.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final txList = ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];

    return Scaffold(
      body: SafeArea(
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
                      l10n.unifiedActivity,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.unifiedActivitySubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title: l10n.quickActions,
                subtitle: l10n.quickActionsSubtitle,
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: accounts.isEmpty
                        ? null
                        : () => _openAddTransactionSheet(context, ref, accounts),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addTransaction),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: accounts.isEmpty
                        ? null
                        : () {
                            _simulateQrEntry(context, ref, accounts.first.id);
                          },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(l10n.quickQrEntry),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title: l10n.combinedActivity,
                subtitle:
                    txList.isEmpty ? l10n.noActivityYet : l10n.transactionsCount(txList.length),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: txList.isEmpty
                    ? EmptyState(
                      title: l10n.noTransactionsYet,
                      message: l10n.noTransactionsYetBody,
                        icon: Icons.receipt_long,
                      )
                    : ListView.builder(
                        itemCount: txList.length,
                        itemBuilder: (BuildContext context, int index) {
                          final FinanceTransaction tx = txList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (ctx) => TransactionDetailsSheet(
                                      transactions: txList,
                                      initialIndex: index,
                                    )
                                  );
                                },
                                leading: CircleAvatar(
                                  backgroundColor: BrandStyles.getColor(tx.title).withValues(alpha: 0.15),
                                  child: Icon(BrandStyles.getIcon(tx.title, tx.category), color: BrandStyles.getColor(tx.title), size: 20),
                              ),
                              title: Text(tx.title),
                              subtitle: Text(
                                '${tx.category} • ${tx.source}${tx.isCategoryOverridden ? ' • ${l10n.manual}' : ' • ${l10n.auto}'}',
                              ),
                              onLongPress: () {
                                _openCategoryOverrideSheet(context, ref, tx);
                              },
                              trailing: Text(
                                '${tx.isExpense ? '-' : '+'}${CurrencyFormatter.inr(tx.amount)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _simulateQrEntry(
    BuildContext context,
    WidgetRef ref,
    String accountId,
  ) async {
    await ref.read(transactionControllerProvider.notifier).addManualTransaction(
          title: 'Cafe payment via QR',
          accountId: accountId,
          amount: 240,
          type: TransactionType.expense,
          category: 'food',
          tags: const <String>['qr', 'upi'],
          note: 'QR transaction',
          source: 'qr',
          channel: 'upi',
        );
  }

  Future<void> _openCategoryOverrideSheet(
    BuildContext context,
    WidgetRef ref,
    FinanceTransaction tx,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    String selected = tx.category;
    final List<String> categories =
        ref.read(transactionCategoriesProvider).where((String item) => item != 'auto').toList();

    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.overrideCategory,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selected,
                    items: categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setModalState(() {
                        selected = value ?? selected;
                      });
                    },
                    decoration: InputDecoration(labelText: l10n.category),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await ref.read(transactionControllerProvider.notifier).overrideCategory(
                              transactionId: tx.id,
                              category: selected,
                            );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(l10n.updateCategory),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openAddTransactionSheet(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _AddTransactionSheet(accounts: accounts, ref: ref);
      },
    );
  }
}

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet({required this.accounts, required this.ref});

  final List<Account> accounts;
  final WidgetRef ref;

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _tags = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String _category = 'auto';
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _accountId = widget.accounts.isEmpty ? null : widget.accounts.first.id;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<String> categories =
        widget.ref.watch(transactionCategoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.addTransaction,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(controller: _title, decoration: InputDecoration(labelText: l10n.title)),
          const SizedBox(height: 10),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.amount),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _accountId,
            items: widget.accounts.map((Account account) {
              return DropdownMenuItem<String>(
                value: account.id,
                child: Text(account.name),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _accountId = value;
              });
            },
            decoration: InputDecoration(labelText: l10n.sourceAccount),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _category = value ?? 'misc';
              });
            },
            decoration: InputDecoration(labelText: l10n.category),
          ),
          const SizedBox(height: 10),
          SegmentedButton<TransactionType>(
            segments: <ButtonSegment<TransactionType>>[
              ButtonSegment<TransactionType>(
                value: TransactionType.expense,
                label: Text(l10n.expense),
              ),
              ButtonSegment<TransactionType>(
                value: TransactionType.income,
                label: Text(l10n.income),
              ),
            ],
            selected: <TransactionType>{_type},
            onSelectionChanged: (Set<TransactionType> values) {
              setState(() {
                _type = values.first;
              });
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _tags,
            decoration: InputDecoration(labelText: l10n.tagsCommaSeparated),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final double amount = double.tryParse(_amount.text.trim()) ?? 0;
                if (_accountId == null || amount <= 0 || _title.text.trim().isEmpty) {
                  return;
                }

                await widget.ref.read(transactionControllerProvider.notifier).addManualTransaction(
                      title: _title.text.trim(),
                      accountId: _accountId!,
                      amount: amount,
                      type: _type,
                      category: _category,
                      tags: _tags.text
                          .split(',')
                          .map((String item) => item.trim())
                          .where((String item) => item.isNotEmpty)
                          .toList(),
                    );

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(l10n.saveTransaction),
            ),
          ),
        ],
      ),
    );
  }
}
