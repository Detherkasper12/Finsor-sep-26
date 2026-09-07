import '../models/user_settings.dart';

/// Supported fiat currencies (ISO 4217) and crypto. Central source for pickers.
class SupportedCurrencies {
  static const List<CurrencyInfo> fiat = [
    CurrencyInfo('AFN', 'Afghan Afghani', '؋', 2),
    CurrencyInfo('ALL', 'Albanian Lek', 'L', 2),
    CurrencyInfo('DZD', 'Algerian Dinar', 'د.ج', 2),
    CurrencyInfo('AOA', 'Angolan Kwanza', 'Kz', 2),
    CurrencyInfo('ARS', 'Argentine Peso', '\$', 2),
    CurrencyInfo('AMD', 'Armenian Dram', '֏', 2),
    CurrencyInfo('AWG', 'Aruban Florin', 'ƒ', 2),
    CurrencyInfo('AUD', 'Australian Dollar', 'A\$', 2),
    CurrencyInfo('AZN', 'Azerbaijani Manat', '₼', 2),
    CurrencyInfo('BSD', 'Bahamian Dollar', '\$', 2),
    CurrencyInfo('BHD', 'Bahraini Dinar', '.د.ب', 3),
    CurrencyInfo('BDT', 'Bangladeshi Taka', '৳', 2),
    CurrencyInfo('BBD', 'Barbados Dollar', '\$', 2),
    CurrencyInfo('BYN', 'Belarusian Ruble', 'Br', 2),
    CurrencyInfo('BZD', 'Belize Dollar', 'BZ\$', 2),
    CurrencyInfo('BMD', 'Bermudian Dollar', '\$', 2),
    CurrencyInfo('BOB', 'Bolivian Boliviano', 'Bs', 2),
    CurrencyInfo('BAM', 'Bosnia-Herzegovina Convertible Mark', 'KM', 2),
    CurrencyInfo('BWP', 'Botswanan Pula', 'P', 2),
    CurrencyInfo('BRL', 'Brazilian Real', 'R\$', 2),
    CurrencyInfo('BND', 'Brunei Dollar', '\$', 2),
    CurrencyInfo('BGN', 'Bulgarian Lev', 'лв', 2),
    CurrencyInfo('BIF', 'Burundian Franc', 'FBu', 0),
    CurrencyInfo('CVE', 'Cape Verdean Escudo', '\$', 2),
    CurrencyInfo('KHR', 'Cambodian Riel', '៛', 2),
    CurrencyInfo('XAF', 'Central African CFA Franc', 'FCFA', 0),
    CurrencyInfo('CAD', 'Canadian Dollar', 'C\$', 2),
    CurrencyInfo('KYD', 'Cayman Islands Dollar', '\$', 2),
    CurrencyInfo('CLP', 'Chilean Peso', '\$', 0),
    CurrencyInfo('CNY', 'Chinese Yuan', '¥', 2),
    CurrencyInfo('COP', 'Colombian Peso', '\$', 2),
    CurrencyInfo('KMF', 'Comorian Franc', 'CF', 0),
    CurrencyInfo('CDF', 'Congolese Franc', 'FC', 2),
    CurrencyInfo('XOF', 'West African CFA Franc', 'CFA', 0),
    CurrencyInfo('CRC', 'Costa Rican Colón', '₡', 2),
    CurrencyInfo('CUP', 'Cuban Peso', '\$', 2),
    CurrencyInfo('CZK', 'Czech Koruna', 'Kč', 2),
    CurrencyInfo('DKK', 'Danish Krone', 'kr', 2),
    CurrencyInfo('DJF', 'Djiboutian Franc', 'Fdj', 0),
    CurrencyInfo('DOP', 'Dominican Peso', 'RD\$', 2),
    CurrencyInfo('EGP', 'Egyptian Pound', 'E£', 2),
    CurrencyInfo('ERN', 'Eritrean Nakfa', 'Nfk', 2),
    CurrencyInfo('ETB', 'Ethiopian Birr', 'Br', 2),
    CurrencyInfo('EUR', 'Euro', '€', 2),
    CurrencyInfo('FJD', 'Fijian Dollar', '\$', 2),
    CurrencyInfo('XPF', 'CFP Franc', '₣', 0),
    CurrencyInfo('GMD', 'Gambian Dalasi', 'D', 2),
    CurrencyInfo('GEL', 'Georgian Lari', '₾', 2),
    CurrencyInfo('GHS', 'Ghanaian Cedi', '₵', 2),
    CurrencyInfo('GIP', 'Gibraltar Pound', '£', 2),
    CurrencyInfo('GTQ', 'Guatemalan Quetzal', 'Q', 2),
    CurrencyInfo('GNF', 'Guinean Franc', 'FG', 0),
    CurrencyInfo('GYD', 'Guyana Dollar', '\$', 2),
    CurrencyInfo('HTG', 'Haitian Gourde', 'G', 2),
    CurrencyInfo('HNL', 'Honduran Lempira', 'L', 2),
    CurrencyInfo('HKD', 'Hong Kong Dollar', 'HK\$', 2),
    CurrencyInfo('HUF', 'Hungarian Forint', 'Ft', 2),
    CurrencyInfo('ISK', 'Icelandic Króna', 'kr', 0),
    CurrencyInfo('INR', 'Indian Rupee', '₹', 2),
    CurrencyInfo('IDR', 'Indonesian Rupiah', 'Rp', 2),
    CurrencyInfo('IRR', 'Iranian Rial', '﷼', 2),
    CurrencyInfo('IQD', 'Iraqi Dinar', 'ع.د', 3),
    CurrencyInfo('ILS', 'Israeli New Shekel', '₪', 2),
    CurrencyInfo('JMD', 'Jamaican Dollar', 'J\$', 2),
    CurrencyInfo('JPY', 'Japanese Yen', '¥', 0),
    CurrencyInfo('JOD', 'Jordanian Dinar', 'د.ا', 3),
    CurrencyInfo('KZT', 'Kazakhstani Tenge', '₸', 2),
    CurrencyInfo('KES', 'Kenyan Shilling', 'KSh', 2),
    CurrencyInfo('KWD', 'Kuwaiti Dinar', 'د.ك', 3),
    CurrencyInfo('KGS', 'Kyrgystani Som', 'с', 2),
    CurrencyInfo('LAK', 'Laotian Kip', '₭', 2),
    CurrencyInfo('LBP', 'Lebanese Pound', 'ل.ل', 2),
    CurrencyInfo('LSL', 'Lesotho Loti', 'L', 2),
    CurrencyInfo('LRD', 'Liberian Dollar', '\$', 2),
    CurrencyInfo('LYD', 'Libyan Dinar', 'ل.د', 3),
    CurrencyInfo('MOP', 'Macanese Pataca', 'MOP\$', 2),
    CurrencyInfo('MKD', 'Macedonian Denar', 'ден', 2),
    CurrencyInfo('MGA', 'Malagasy Ariary', 'Ar', 2),
    CurrencyInfo('MWK', 'Malawian Kwacha', 'MK', 2),
    CurrencyInfo('MYR', 'Malaysian Ringgit', 'RM', 2),
    CurrencyInfo('MVR', 'Maldivian Rufiyaa', 'Rf', 2),
    CurrencyInfo('MRU', 'Mauritanian Ouguiya', 'UM', 2),
    CurrencyInfo('MUR', 'Mauritian Rupee', '₨', 2),
    CurrencyInfo('MXN', 'Mexican Peso', '\$', 2),
    CurrencyInfo('MDL', 'Moldovan Leu', 'L', 2),
    CurrencyInfo('MNT', 'Mongolian Tugrik', '₮', 2),
    CurrencyInfo('MAD', 'Moroccan Dirham', 'د.م.', 2),
    CurrencyInfo('MZN', 'Mozambican Metical', 'MT', 2),
    CurrencyInfo('MMK', 'Myanma Kyat', 'K', 2),
    CurrencyInfo('NAD', 'Namibian Dollar', '\$', 2),
    CurrencyInfo('NPR', 'Nepalese Rupee', '₨', 2),
    CurrencyInfo('NZD', 'New Zealand Dollar', 'NZ\$', 2),
    CurrencyInfo('NIO', 'Nicaraguan Córdoba', 'C\$', 2),
    CurrencyInfo('NGN', 'Nigerian Naira', '₦', 2),
    CurrencyInfo('NOK', 'Norwegian Krone', 'kr', 2),
    CurrencyInfo('OMR', 'Omani Rial', 'ر.ع.', 3),
    CurrencyInfo('PKR', 'Pakistani Rupee', '₨', 2),
    CurrencyInfo('PAB', 'Panamanian Balboa', 'B/.', 2),
    CurrencyInfo('PGK', 'Papua New Guinean Kina', 'K', 2),
    CurrencyInfo('PYG', 'Paraguayan Guarani', '₲', 0),
    CurrencyInfo('PEN', 'Peruvian Sol', 'S/', 2),
    CurrencyInfo('PHP', 'Philippine Peso', '₱', 2),
    CurrencyInfo('PLN', 'Polish Zloty', 'zł', 2),
    CurrencyInfo('QAR', 'Qatari Rial', 'ر.ق', 2),
    CurrencyInfo('RON', 'Romanian Leu', 'lei', 2),
    CurrencyInfo('RUB', 'Russian Ruble', '₽', 2),
    CurrencyInfo('RWF', 'Rwandan Franc', 'FRw', 0),
    CurrencyInfo('SHP', 'Saint Helena Pound', '£', 2),
    CurrencyInfo('WST', 'Samoan Tala', 'T', 2),
    CurrencyInfo('SAR', 'Saudi Riyal', '﷼', 2),
    CurrencyInfo('RSD', 'Serbian Dinar', 'дин.', 2),
    CurrencyInfo('SCR', 'Seychellois Rupee', '₨', 2),
    CurrencyInfo('SLE', 'Sierra Leonean Leone', 'Le', 2),
    CurrencyInfo('SGD', 'Singapore Dollar', 'S\$', 2),
    CurrencyInfo('SBD', 'Solomon Islands Dollar', '\$', 2),
    CurrencyInfo('SOS', 'Somali Shilling', 'S', 2),
    CurrencyInfo('ZAR', 'South African Rand', 'R', 2),
    CurrencyInfo('SSP', 'South Sudanese Pound', '£', 2),
    CurrencyInfo('LKR', 'Sri Lankan Rupee', 'Rs', 2),
    CurrencyInfo('SDG', 'Sudanese Pound', 'ج.س.', 2),
    CurrencyInfo('SRD', 'Surinamese Dollar', '\$', 2),
    CurrencyInfo('SEK', 'Swedish Krona', 'kr', 2),
    CurrencyInfo('CHF', 'Swiss Franc', 'CHF', 2),
    CurrencyInfo('SYP', 'Syrian Pound', '£', 2),
    CurrencyInfo('TWD', 'New Taiwan Dollar', 'NT\$', 2),
    CurrencyInfo('TJS', 'Tajikistani Somoni', 'SM', 2),
    CurrencyInfo('TZS', 'Tanzanian Shilling', 'TSh', 2),
    CurrencyInfo('THB', 'Thai Baht', '฿', 2),
    CurrencyInfo('TOP', 'Tongan Paʻanga', 'T\$', 2),
    CurrencyInfo('TTD', 'Trinidad and Tobago Dollar', 'TT\$', 2),
    CurrencyInfo('TND', 'Tunisian Dinar', 'د.ت', 3),
    CurrencyInfo('TRY', 'Turkish Lira', '₺', 2),
    CurrencyInfo('TMT', 'Turkmenistani Manat', 'm', 2),
    CurrencyInfo('UGX', 'Ugandan Shilling', 'USh', 0),
    CurrencyInfo('UAH', 'Ukrainian Hryvnia', '₴', 2),
    CurrencyInfo('AED', 'UAE Dirham', 'د.إ', 2),
    CurrencyInfo('GBP', 'British Pound', '£', 2),
    CurrencyInfo('USD', 'US Dollar', '\$', 2),
    CurrencyInfo('UYU', 'Uruguayan Peso', '\$U', 2),
    CurrencyInfo('UZS', 'Uzbekistan Som', 'лв', 2),
    CurrencyInfo('VUV', 'Vanuatu Vatu', 'VT', 0),
    CurrencyInfo('VES', 'Venezuelan Bolívar', 'Bs.S', 2),
    CurrencyInfo('VND', 'Vietnamese Dong', '₫', 0),
    CurrencyInfo('XCD', 'East Caribbean Dollar', '\$', 2),
    CurrencyInfo('YER', 'Yemeni Rial', '﷼', 2),
    CurrencyInfo('ZMW', 'Zambian Kwacha', 'ZK', 2),
  ];

  static const List<CurrencyInfo> crypto = [
    CurrencyInfo('BTC', 'Bitcoin', '₿', 8),
    CurrencyInfo('ETH', 'Ethereum', 'Ξ', 8),
    CurrencyInfo('USDT', 'Tether', '₮', 2),
    CurrencyInfo('USDC', 'USD Coin', '\$', 2),
    CurrencyInfo('SOL', 'Solana', '◎', 8),
    CurrencyInfo('BNB', 'BNB', 'BNB', 8),
    CurrencyInfo('XRP', 'XRP', 'XRP', 6),
    CurrencyInfo('ADA', 'Cardano', '₳', 8),
    CurrencyInfo('DOGE', 'Dogecoin', 'Ð', 8),
    CurrencyInfo('TON', 'Toncoin', 'TON', 8),
  ];

  static List<CurrencyInfo> all([bool includeCrypto = true]) {
    if (includeCrypto) return [...fiat, ...crypto];
    return List.from(fiat);
  }

  static List<CurrencyInfo> forWalletType(bool isCrypto) {
    if (isCrypto) return crypto;
    return fiat;
  }

  static CurrencyInfo? byCode(String code) {
    final upper = code.toUpperCase();
    try {
      return all().firstWhere((c) => c.code == upper);
    } catch (_) {
      return null;
    }
  }

  static Currency toCurrency(CurrencyInfo info, {double exchangeRate = 1.0}) {
    return Currency(
      code: info.code,
      name: info.name,
      symbol: info.symbol,
      decimalPlaces: info.decimalPlaces,
      exchangeRate: exchangeRate,
    );
  }

  static Currency defaultFiat() => toCurrency(fiat.first);
  static Currency defaultCrypto() => toCurrency(crypto.first);
}

class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final int decimalPlaces;

  const CurrencyInfo(this.code, this.name, this.symbol, this.decimalPlaces);
}
