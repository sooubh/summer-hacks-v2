import re

with open('lib/features/transactions/ui/transactions_screen.dart', 'r', encoding='utf-8') as f:
    data = f.read()

# Add imports
data = data.replace('import \'package:student_fin_os/l10n/app_localizations.dart\';', 'import \'package:student_fin_os/l10n/app_localizations.dart\';\nimport \'package:student_fin_os/core/utils/brand_styles.dart\';\nimport \'package:student_fin_os/features/dashboard/ui/transaction_details_sheet.dart\';')

# Update ListTile leading
old_leading = '''                                leading: CircleAvatar(
                                  backgroundColor: tx.isExpense
                                      ? Colors.redAccent.withValues(alpha: 0.2)
                                      : Colors.greenAccent.withValues(alpha: 0.2),
                                  child: Icon(
                                    tx.isExpense ? Icons.call_made : Icons.call_received,
                                  ),
                                ),'''

new_leading = '''                                onTap: () {
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
                                ),'''

data = data.replace(old_leading, new_leading)

with open('lib/features/transactions/ui/transactions_screen.dart', 'w', encoding='utf-8') as f:
    f.write(data)
