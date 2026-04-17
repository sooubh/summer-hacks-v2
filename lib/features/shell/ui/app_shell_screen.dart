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
  static const List<int> _mobileTabIndexes = <int>[0, 2, 4, 5];

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

  int _mobileSelectedIndex() {
    final int selected = _mobileTabIndexes.indexOf(_index);
    return selected < 0 ? 0 : selected;
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

  Widget _buildCustomBottomNavigationBar(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final int selectedIndex = _mobileSelectedIndex();

    void showAssistantChoices() {
      showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'FinMate AI',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: const Text('AI Chat'),
                    subtitle: const Text('Text-based guidance & planning'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push(AppRoutes.chatAssistant);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.graphic_eq),
                    title: const Text('AI Voice'),
                    subtitle: const Text('Hands-free continuous conversation'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _openVoiceAssistant();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    Widget buildNavItem(IconData icon, String label, int index) {
      final bool isSelected = selectedIndex == index;
      return Expanded(
        child: InkWell(
          onTap: () {
            _onDestinationSelected(_mobileTabIndexes[index]);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 32,
                width: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.secondaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        color: colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            buildNavItem(Icons.space_dashboard, 'Home', 0),
            buildNavItem(Icons.swap_horiz, 'Txns', 1),
            Card(
              elevation: 4,
              color: colorScheme.primary,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: IconButton(
                  tooltip: 'FinMate AI',
                  icon: Icon(Icons.auto_awesome,
                      color: colorScheme.onPrimary),
                  onPressed: showAssistantChoices,
                ),
              ),
            ),
            buildNavItem(Icons.savings, 'Savings', 2),
            buildNavItem(Icons.lightbulb, 'Insights', 3),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool desktopLayout = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: 'Profile',
              icon: const Icon(Icons.account_circle, size: 28),
              onPressed: () {
                context.go('/app/profile');
              },
            );
          }
        ),
        title: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: Icon(Icons.search, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        actions: <Widget>[
          if (desktopLayout)
            IconButton(
              tooltip: 'Chat assistant',
              onPressed: () {
                context.push(AppRoutes.chatAssistant);
              },
              icon: const Icon(Icons.chat_bubble_outline),
            ),
          if (desktopLayout)
            IconButton(
              tooltip: 'Voice assistant',
              onPressed: _openVoiceAssistant,
              icon: const Icon(Icons.mic_none),
            ),
          IconButton(
            tooltip: 'Alerts',
            onPressed: () {},
            icon: const Badge(child: Icon(Icons.notifications_none)),
          ),
          IconButton(
            tooltip: 'Logout',
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
          : _buildCustomBottomNavigationBar(context),
    );
  }
}
