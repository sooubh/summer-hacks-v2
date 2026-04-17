import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:student_fin_os/core/router/app_router.dart';
import 'package:student_fin_os/features/accounts/ui/account_aggregator_screen.dart';
import 'package:student_fin_os/features/assistant/ui/voice_assistant_sheet.dart';
import 'package:student_fin_os/features/cashflow/ui/cash_flow_screen.dart';
import 'package:student_fin_os/features/dashboard/ui/dashboard_screen.dart';
import 'package:student_fin_os/features/insights/ui/insights_screen.dart';
import 'package:student_fin_os/features/savings/ui/savings_screen.dart';
import 'package:student_fin_os/features/splits/ui/splits_screen.dart';
import 'package:student_fin_os/features/transactions/ui/transactions_screen.dart';
import 'package:student_fin_os/providers/auth_providers.dart';

class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({required this.initialIndex, super.key});

  final int initialIndex;

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  late int _index;

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
        NavigationDestination(
          icon: Icon(Icons.account_balance),
          label: 'Accounts',
        ),
        NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Txns'),
        NavigationDestination(icon: Icon(Icons.groups), label: 'Splits'),
        NavigationDestination(icon: Icon(Icons.savings), label: 'Savings'),
        NavigationDestination(icon: Icon(Icons.lightbulb), label: 'Insights'),
        NavigationDestination(icon: Icon(Icons.timeline), label: 'CashFlow'),
      ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void _onDestinationSelected(int value) {
    if (value < 0 || value >= AppRoutes.appTabs.length) {
      return;
    }
    setState(() {
      _index = value;
    });
    context.go(AppRoutes.appTabs[value]);
  }

  Future<void> _openVoiceAssistant() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const FractionallySizedBox(
          heightFactor: 0.92,
          child: VoiceAssistantSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool desktopLayout = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Financial OS'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Chat assistant',
            onPressed: () {
              context.push(AppRoutes.chatAssistant);
            },
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            tooltip: 'Voice assistant',
            onPressed: _openVoiceAssistant,
            icon: const Icon(Icons.mic_none),
          ),
          IconButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
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
                    _onDestinationSelected(value);
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
                _onDestinationSelected(value);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openVoiceAssistant,
        icon: const Icon(Icons.mic),
        label: Text(desktopLayout ? 'Voice Assistant' : 'Voice'),
      ),
    );
  }
}
