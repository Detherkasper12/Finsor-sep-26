import 'package:intl/intl.dart';
import '../models/user_settings.dart';
import '../models/wallet.dart';
import '../constants/supported_currencies.dart';
import '../constants/currency_format_options.dart';

/// Currency formatting utility class
class CurrencyFormatter {
  static bool isCrypto(String currencyCode) {
    return SupportedCurrencies.crypto.any((c) => c.code == currencyCode.toUpperCase());
  }

  /// Format wallet balance in its own currency. Crypto: raw value + symbol (max 8 decimals). Fiat: NumberFormat.
  static String formatWalletBalance(Wallet wallet) {
    final code = wallet.currency;
    final info = SupportedCurrencies.byCode(code);
    if (info == null) {
      return '${wallet.currentBalance.toStringAsFixed(2)} $code';
    }
    if (SupportedCurrencies.crypto.any((c) => c.code == info.code)) {
      final decimals = info.decimalPlaces.clamp(0, 8);
      final formatted = wallet.currentBalance.toStringAsFixed(decimals);
      return '$formatted ${info.symbol}';
    }
    final currency = SupportedCurrencies.toCurrency(info);
    return formatBalance(wallet.currentBalance, currency);
  }
  static String formatAmount(
    double amount,
    Currency currency, {
    bool showSymbol = true,
    bool showCurrency = false,
    String? locale,
    String? formatId,
  }) {
    if (formatId != null && formatId != 'default') {
      return formatAmountWithId(amount, showSymbol ? currency.symbol : '', formatId, decimalDigits: currency.decimalPlaces);
    }
    final localeStr = locale ?? 'en';
    final formatter = NumberFormat.currency(
      locale: localeStr,
      symbol: showSymbol ? currency.symbol : '',
      decimalDigits: currency.decimalPlaces,
    );
    final formattedAmount = formatter.format(amount);
    if (showCurrency && !showSymbol) return '$formattedAmount ${currency.code}';
    return formattedAmount;
  }
  
  /// Format amount with proper sign for transactions
  static String formatTransactionAmount(
    double amount,
    String transactionType,
    Currency currency,
  ) {
    final prefix = _getTransactionPrefix(transactionType);
    final formattedAmount = formatAmount(amount.abs(), currency);
    return '$prefix$formattedAmount';
  }
  
  /// Get prefix for transaction type
  static String _getTransactionPrefix(String transactionType) {
    switch (transactionType.toLowerCase()) {
      case 'income':
        return '+';
      case 'expense':
        return '-';
      case 'transfer':
        return '';
      default:
        return '';
    }
  }
  
  /// Format balance with proper currency display. Pass formatId from settings for custom format.
  static String formatBalance(double balance, Currency currency, {String? formatId}) {
    return formatAmount(balance, currency, formatId: formatId);
  }
  
  /// Parse amount string to double
  static double parseAmount(String amountString) {
    // Remove currency symbols and formatting
    final cleanString = amountString
        .replaceAll(RegExp(r'[^\d.-]'), '')
        .trim();
    
    return double.tryParse(cleanString) ?? 0.0;
  }
}
