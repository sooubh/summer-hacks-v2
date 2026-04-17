import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/transaction_providers.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txList = ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionHeader(
                title: 'Transactions',
                subtitle: 'Manual + simulated QR entries',
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: accounts.isEmpty
                        ? null
                        : () => _openAddTransactionSheet(context, ref, accounts),
                    icon: const Icon(Icons.add),
                    label: const Text('Add transaction'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: accounts.isEmpty
                        ? null
                        : () {
                            _simulateQrEntry(context, ref, accounts.first.id);
                          },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Simulate QR scan'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: txList.isEmpty
                    ? const EmptyState(
                        title: 'No transactions yet',
                        message: 'Add your first transaction and start generating insights.',
                        icon: Icons.receipt_long,
                      )
                    : ListView.builder(
                        itemCount: txList.length,
                        itemBuilder: (BuildContext context, int index) {
                          final FinanceTransaction tx = txList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: tx.isExpense
                                    ? Colors.redAccent.withValues(alpha: 0.2)
                                    : Colors.greenAccent.withValues(alpha: 0.2),
                                child: Icon(
                                  tx.isExpense ? Icons.call_made : Icons.call_received,
                                ),
                              ),
                              title: Text(tx.title),
                              subtitle: Text(
                                '${tx.category} • ${tx.source}${tx.isCategoryOverridden ? ' • manual' : ' • auto'}',
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
          note: 'Simulated QR transaction',
          source: 'simulation',
          channel: 'upi',
        );
  }

  Future<void> _openCategoryOverrideSheet(
    BuildContext context,
    WidgetRef ref,
    FinanceTransaction tx,
  ) async {
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
                    'Override category',
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
                    decoration: const InputDecoration(labelText: 'Category'),
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
                      child: const Text('Update category'),
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
            'Add transaction',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
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
            decoration: const InputDecoration(labelText: 'Source account'),
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
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 10),
          SegmentedButton<TransactionType>(
            segments: const <ButtonSegment<TransactionType>>[
              ButtonSegment<TransactionType>(
                value: TransactionType.expense,
                label: Text('Expense'),
              ),
              ButtonSegment<TransactionType>(
                value: TransactionType.income,
                label: Text('Income'),
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
            decoration: const InputDecoration(labelText: 'Tags (comma-separated)'),
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
              child: const Text('Save transaction'),
            ),
          ),
        ],
      ),
    );
  }
}
