import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  static String inr(num amount) {
    return _inrFormatter.format(amount);
  }
}
