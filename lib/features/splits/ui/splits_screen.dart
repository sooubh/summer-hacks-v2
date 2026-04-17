import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/models/split_group.dart';
import 'package:student_fin_os/providers/split_providers.dart';

class SplitsScreen extends ConsumerWidget {
  const SplitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<SplitGroup> groups = ref.watch(splitGroupsProvider).value ?? const <SplitGroup>[];
    final List<dynamic> expenses = ref.watch(splitExpensesProvider).value ?? const <dynamic>[];
    final Map<String, double> net = ref.watch(splitNetBalancesProvider);
    final String? selectedId = ref.watch(selectedSplitGroupIdProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: SectionHeader(
                    title: 'Split groups',
                    subtitle: 'Roommates, trips, and shared bills',
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showCreateGroupDialog(context, ref),
                  icon: const Icon(Icons.group_add),
                  label: const Text('New group'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (groups.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: selectedId ?? groups.first.id,
                items: groups.map((SplitGroup group) {
                  return DropdownMenuItem<String>(
                    value: group.id,
                    child: Text(group.name),
                  );
                }).toList(),
                onChanged: (String? value) {
                  ref.read(selectedSplitGroupIdProvider.notifier).state = value;
                },
                decoration: const InputDecoration(labelText: 'Active group'),
              ),
            const SizedBox(height: 12),
            if (groups.isEmpty)
              const Expanded(
                child: EmptyState(
                  title: 'No split groups yet',
                  message:
                      'Create a group for your hostel or class project friends to track who owes whom.',
                  icon: Icons.groups,
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: <Widget>[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Net balances',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            if (net.isEmpty)
                              const Text('No split activity yet.')
                            else
                              ...net.entries.map((MapEntry<String, double> item) {
                                final bool positive = item.value >= 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(item.key),
                                      Text(
                                        '${positive ? '+' : '-'}${CurrencyFormatter.inr(item.value.abs())}',
                                        style: TextStyle(
                                          color: positive
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: selectedId == null
                          ? null
                          : () => _showAddExpenseDialog(
                                context,
                                ref,
                                selectedGroup: groups.firstWhere((SplitGroup g) => g.id == selectedId),
                              ),
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Add split expense'),
                    ),
                    const SizedBox(height: 8),
                    ...expenses.map((dynamic expense) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(expense.title.toString()),
                          subtitle: Text('Paid by ${expense.paidBy}'),
                          trailing: Text(CurrencyFormatter.inr(expense.totalAmount as num)),
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context, WidgetRef ref) async {
    final TextEditingController name = TextEditingController();
    final TextEditingController members = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create split group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Group name')),
              const SizedBox(height: 10),
              TextField(
                controller: members,
                decoration: const InputDecoration(
                  labelText: 'Member IDs (comma-separated)',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final List<String> list = members.text
                    .split(',')
                    .map((String item) => item.trim())
                    .where((String item) => item.isNotEmpty)
                    .toList();
                if (name.text.trim().isEmpty || list.isEmpty) {
                  return;
                }
                await ref.read(splitControllerProvider.notifier).createGroup(
                      name: name.text.trim(),
                      memberIds: list,
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddExpenseDialog(
    BuildContext context,
    WidgetRef ref, {
    required SplitGroup selectedGroup,
  }) async {
    final TextEditingController title = TextEditingController();
    final TextEditingController amount = TextEditingController();
    String paidBy = selectedGroup.memberIds.first;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add split expense'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: paidBy,
                    items: selectedGroup.memberIds.map((String member) {
                      return DropdownMenuItem<String>(
                        value: member,
                        child: Text(member),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        paidBy = value ?? selectedGroup.memberIds.first;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Paid by'),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final double total = double.tryParse(amount.text.trim()) ?? 0;
                    if (title.text.trim().isEmpty || total <= 0) {
                      return;
                    }
                    final double perHead = total / selectedGroup.memberIds.length;
                    final Map<String, double> owedBy = <String, double>{
                      for (final String member in selectedGroup.memberIds) member: perHead,
                    };
                    await ref.read(splitControllerProvider.notifier).addExpense(
                          groupId: selectedGroup.id,
                          title: title.text.trim(),
                          totalAmount: total,
                          paidBy: paidBy,
                          owedBy: owedBy,
                        );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
