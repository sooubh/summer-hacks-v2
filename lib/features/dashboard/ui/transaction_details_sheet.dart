import 'package:flutter/material.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class TransactionDetailsSheet extends StatefulWidget {
  const TransactionDetailsSheet({
    super.key,
    required this.transactions,
    required this.initialIndex,
  });

  final List<FinanceTransaction> transactions;
  final int initialIndex;

  @override
  State<TransactionDetailsSheet> createState() => _TransactionDetailsSheetState();
}

class _TransactionDetailsSheetState extends State<TransactionDetailsSheet> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getBrandColor(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('swiggy')) return const Color(0xFFFC8019);
    if (lowerTitle.contains('zomato')) return const Color(0xFFE23744);
    if (lowerTitle.contains('uber')) return Colors.black;
    if (lowerTitle.contains('amazon')) return const Color(0xFFFF9900);
    if (lowerTitle.contains('netflix')) return const Color(0xFFE50914);
    if (lowerTitle.contains('spotify')) return const Color(0xFF1DB954);
    if (lowerTitle.contains('myntra')) return const Color(0xFFFF3F6C);
    return Colors.blueGrey;
  }

  IconData _getBrandIcon(String title, String category) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('swiggy') || lowerTitle.contains('zomato')) return Icons.restaurant;
    if (lowerTitle.contains('uber')) return Icons.directions_car;
    if (lowerTitle.contains('amazon') || lowerTitle.contains('myntra')) return Icons.shopping_bag;
    if (lowerTitle.contains('netflix') || lowerTitle.contains('spotify')) return Icons.play_arrow;
    
    if (category.toLowerCase().contains('food')) return Icons.fastfood;
    if (category.toLowerCase().contains('travel')) return Icons.commute;
    if (category.toLowerCase().contains('shop')) return Icons.store;
    return Icons.receipt;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.transactions.length,
              itemBuilder: (context, index) {
                final tx = widget.transactions[index];
                final brandColor = _getBrandColor(tx.title);
                final brandIcon = _getBrandIcon(tx.title, tx.category);

                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: brandColor.withValues(alpha: 0.2),
                        child: Icon(brandIcon, size: 40, color: brandColor),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        tx.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${tx.isExpense ? '-' : '+'}${CurrencyFormatter.inr(tx.amount)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: tx.isExpense ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _detailRow(context, Icons.category, 'Category', tx.category.toUpperCase()),
                      const SizedBox(height: 16),
                      _detailRow(context, Icons.account_balance_wallet, 'Source', tx.source.toUpperCase()),
                      const SizedBox(height: 16),
                      _detailRow(context, Icons.calendar_today, 'Date', DateFormat('MMM dd, yyyy - hh:mm a').format(tx.transactionAt)),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe_left, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text('Swipe to view more', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(width: 8),
                Icon(Icons.swipe_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
