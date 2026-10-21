import 'package:intl/intl.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final String flagEmoji;
  /// Exchange rate relative to 1 USD
  final double rateToUsd;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flagEmoji,
    required this.rateToUsd,
  });
}

class CurrencyService {
  CurrencyService._();

  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee', flagEmoji: '🇮🇳', rateToUsd: 84.0),
    CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar', flagEmoji: '🇺🇸', rateToUsd: 1.0),
    CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flagEmoji: '🇪🇺', rateToUsd: 0.92),
    CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound', flagEmoji: '🇬🇧', rateToUsd: 0.78),
    CurrencyInfo(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham', flagEmoji: '🇦🇪', rateToUsd: 3.6725),
    CurrencyInfo(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal', flagEmoji: '🇸🇦', rateToUsd: 3.75),
    CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen', flagEmoji: '🇯🇵', rateToUsd: 153.0),
    CurrencyInfo(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar', flagEmoji: '🇨🇦', rateToUsd: 1.38),
    CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', flagEmoji: '🇦🇺', rateToUsd: 1.52),
    CurrencyInfo(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc', flagEmoji: '🇨🇭', rateToUsd: 0.88),
    CurrencyInfo(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', flagEmoji: '🇸🇬', rateToUsd: 1.32),
    CurrencyInfo(code: 'QAR', symbol: 'QR', name: 'Qatari Riyal', flagEmoji: '🇶🇦', rateToUsd: 3.64),
    CurrencyInfo(code: 'KWD', symbol: 'KD', name: 'Kuwaiti Dinar', flagEmoji: '🇰🇼', rateToUsd: 0.31),
    CurrencyInfo(code: 'OMR', symbol: 'OMR', name: 'Omani Rial', flagEmoji: '🇴🇲', rateToUsd: 0.385),
    CurrencyInfo(code: 'BHD', symbol: 'BD', name: 'Bahraini Dinar', flagEmoji: '🇧🇭', rateToUsd: 0.376),
    CurrencyInfo(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit', flagEmoji: '🇲🇾', rateToUsd: 4.40),
    CurrencyInfo(code: 'THB', symbol: '฿', name: 'Thai Baht', flagEmoji: '🇹🇭', rateToUsd: 34.0),
  ];

  static CurrencyInfo? findByCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final upper = code.toUpperCase();
    for (final c in supportedCurrencies) {
      if (c.code == upper) return c;
    }
    return null;
  }

  static CurrencyInfo getByCodeOrDefault(String? code, {String defaultCode = 'INR'}) {
    return findByCode(code) ?? findByCode(defaultCode) ?? supportedCurrencies.first;
  }

  /// Calculates default approximate exchange rate: 1 unit of `fromCode` = X units of `toCode`.
  static double getApproxExchangeRate(String fromCode, String toCode) {
    if (fromCode.toUpperCase() == toCode.toUpperCase()) return 1.0;

    final from = findByCode(fromCode);
    final to = findByCode(toCode);

    if (from == null || to == null) return 1.0;
    if (from.rateToUsd <= 0) return 1.0;

    // 1 fromCode = (1 / from.rateToUsd) USD
    // (1 / from.rateToUsd) * to.rateToUsd in toCode
    return to.rateToUsd / from.rateToUsd;
  }

  /// Convert amount from `fromCode` to `toCode` using default rate or custom exchange rate.
  static double convert(
    double amount, {
    required String fromCode,
    required String toCode,
    double? customRate,
  }) {
    if (fromCode.toUpperCase() == toCode.toUpperCase()) return amount;
    final rate = customRate ?? getApproxExchangeRate(fromCode, toCode);
    return amount * rate;
  }

  /// Format an amount with currency symbol and code.
  static String formatAmount(double amount, String currencyCode, {bool showDecimals = true}) {
    final info = findByCode(currencyCode);
    final symbol = info?.symbol ?? currencyCode;
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: showDecimals ? (amount % 1 == 0 ? 0 : 2) : 0,
    );
    return formatter.format(amount);
  }
}
