import re

with open('lib/features/dashboard/ui/dashboard_screen.dart', 'r', encoding='utf-8') as f:
    data = f.read()

# Add imports
data = data.replace('import \'package:student_fin_os/providers/firebase_providers.dart\';', 'import \'package:student_fin_os/providers/firebase_providers.dart\';\nimport \'package:student_fin_os/core/utils/brand_styles.dart\';\nimport \'package:student_fin_os/core/utils/dummy_data.dart\';')

dummy_replace = r"final List<Map<String, dynamic>> dummies = \[.*?\];"
data = re.sub(dummy_replace, 'final List<Map<String, dynamic>> dummies = generateDummyTransactions();', data, flags=re.DOTALL)

data = data.replace('_getBrandColor(tx.title)', 'BrandStyles.getColor(tx.title)')
data = data.replace('_getBrandIcon(tx.title, tx.category)', 'BrandStyles.getIcon(tx.title, tx.category)')

data = re.sub(r'  Color _getBrandColor.*?return Colors\.blueGrey;\n  }\n', '', data, flags=re.DOTALL)
data = re.sub(r'  IconData _getBrandIcon.*?return Icons\.receipt;\n  }\n', '', data, flags=re.DOTALL)

with open('lib/features/dashboard/ui/dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(data)
