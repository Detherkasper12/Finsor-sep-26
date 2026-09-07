/// Currency display format options (1Money-style).
/// formatId is stored in UserSettings.currencyFormatId.
class CurrencyFormatOption {
  final String id;
  final String name;
  final String example;

  const CurrencyFormatOption({required this.id, required this.name, required this.example});
}

const List<CurrencyFormatOption> currencyFormatOptions = [
  CurrencyFormatOption(id: 'default', name: 'Default', example: '-1,234,567.90 \$'),
  CurrencyFormatOption(id: 'space_comma', name: 'Space, comma decimal', example: '-1 234 567,90 \$'),
  CurrencyFormatOption(id: 'symbol_left_space', name: '\$ -1 234 567,90', example: '\$ -1 234 567,90'),
  CurrencyFormatOption(id: 'comma_dot', name: 'Comma thousands, dot decimal', example: '-1,234,567.90 \$'),
  CurrencyFormatOption(id: 'dot_comma', name: 'Dot thousands, comma decimal', example: '-1.234.567,90 \$'),
  CurrencyFormatOption(id: 'symbol_right_space', name: '-1 234 567.90 \$', example: '-1 234 567.90 \$'),
  CurrencyFormatOption(id: 'no_group', name: 'No thousands separator', example: '-1234567.90 \$'),
  CurrencyFormatOption(id: 'symbol_after_negative', name: 'Symbol after amount', example: '-1234567.90 \$'),
];

/// Format a number with the given formatId. Symbol is applied per option.
String formatAmountWithId(double amount, String symbol, String formatId, {int decimalDigits = 2}) {
  final neg = amount < 0;
  final abs = amount.abs();
  final dec = abs.toStringAsFixed(decimalDigits).split('.');
  final intPart = dec[0];
  final fracPart = decimalDigits > 0 ? dec[1] : '';
  final useCommaDecimal = formatId == 'space_comma' || formatId == 'dot_comma' || formatId == 'symbol_left_space';
  String formattedInt;
  switch (formatId) {
    case 'space_comma':
    case 'symbol_left_space':
      formattedInt = intPart.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
      break;
    case 'dot_comma':
      formattedInt = intPart.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
      break;
    case 'no_group':
    case 'symbol_after_negative':
      formattedInt = intPart;
      break;
    default:
      formattedInt = intPart.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
  final numStr = decimalDigits == 0 ? formattedInt : (useCommaDecimal ? '$formattedInt,$fracPart' : '$formattedInt.$fracPart');
  final prefix = neg ? '-' : '';
  if (formatId == 'symbol_left_space') return '$prefix$symbol $numStr';
  return '$prefix$numStr $symbol';
}
