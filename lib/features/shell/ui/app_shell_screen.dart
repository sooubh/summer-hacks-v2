import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/features/accounts/ui/account_aggregator_screen.dart';
import 'package:student_fin_os/features/cashflow/ui/cash_flow_screen.dart';
import 'package:student_fin_os/features/dashboard/ui/dashboard_screen.dart';
import 'package:student_fin_os/features/insights/ui/insights_screen.dart';
import 'package:student_fin_os/features/savings/ui/savings_screen.dart';
import 'package:student_fin_os/features/splits/ui/splits_screen.dart';
import 'package:student_fin_os/features/transactions/ui/transactions_screen.dart';
import 'package:student_fin_os/providers/auth_providers.dart';

class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  int _index = 0;

  late final List<Widget> _pages = const <Widget>[
    DashboardScreen(),
    AccountAggregatorScreen(),
    TransactionsScreen(),
    SplitsScreen(),
    SavingsScreen(),
    InsightsScreen(),
    CashFlowScreen(),
  ];

  late final List<NavigationDestination> _destinations =
      const <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.space_dashboard), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.account_balance), label: 'Accounts'),
    NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Txns'),
    NavigationDestination(icon: Icon(Icons.groups), label: 'Splits'),
    NavigationDestination(icon: Icon(Icons.savings), label: 'Savings'),
    NavigationDestination(icon: Icon(Icons.lightbulb), label: 'Insights'),
    NavigationDestination(icon: Icon(Icons.timeline), label: 'CashFlow'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool desktopLayout = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Financial OS'),
        actions: <Widget>[
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: desktopLayout
          ? Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: _index,
                  destinations: _destinations.map((NavigationDestination item) {
                    return NavigationRailDestination(
                      icon: item.icon,
                      label: Text(item.label),
                    );
                  }).toList(),
                  onDestinationSelected: (int value) {
                    setState(() {
                      _index = value;
                    });
                  },
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: _pages[_index],
                  ),
                ),
              ],
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _pages[_index],
            ),
      bottomNavigationBar: desktopLayout
          ? null
          : NavigationBar(
              selectedIndex: _index,
              destinations: _destinations,
              onDestinationSelected: (int value) {
                setState(() {
                  _index = value;
                });
              },
            ),
    );
  }
}
