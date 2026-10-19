import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String activeSymbol = '₹';
  static String activeCode = 'INR';

  static String format(double amount, {String? symbol, bool showDecimals = false}) {
    final s = symbol ?? activeSymbol;
    final formatter = NumberFormat.currency(
      symbol: s,
      decimalDigits: showDecimals ? 2 : (amount % 1 == 0 ? 0 : 2),
    );
    return formatter.format(amount);
  }

  static String formatCompact(double amount, {String? symbol}) {
    final s = symbol ?? activeSymbol;
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final sign = isNegative ? '-' : '';

    if (absAmount >= 10000000) {
      return '$sign$s${(absAmount / 10000000).toStringAsFixed(1)}Cr';
    } else if (absAmount >= 100000) {
      return '$sign$s${(absAmount / 100000).toStringAsFixed(1)}L';
    } else if (absAmount >= 1000) {
      return '$sign$s${(absAmount / 1000).toStringAsFixed(1)}k';
    }
    return '$sign$s${absAmount.toStringAsFixed(0)}';
  }
}

