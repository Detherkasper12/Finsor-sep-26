import 'package:flutter/material.dart';

/// Simple localization system for Finsor
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }
  
  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      // Navigation
      'home': 'Home',
      'add': 'Add',
      'analytics': 'Analytics',
      'ai': 'AI',
      'settings': 'Settings',
      
      // Home Screen
      'good_morning': 'Good morning',
      'good_afternoon': 'Good afternoon', 
      'good_evening': 'Good evening',
      'total_balance': 'Total Balance',
      'add_income': 'Add Income',
      'add_expense': 'Add Expense',
      'recent_transactions': 'Recent Transactions',
      'quick_stats': 'Quick Stats',
      
      // Transactions
      'income': 'Income',
      'expense': 'Expense',
      'transfer': 'Transfer',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'this_week': 'This Week',
      'this_month': 'This Month',
      'all_time': 'All Time',
      
      // Settings
      'theme': 'Theme',
      'currency': 'Currency',
      'language': 'Language',
      'notifications': 'Notifications',
      'export_data': 'Export Data',
      'import_data': 'Import Data',
      'security': 'Security',
      'about': 'About',
      
      // AI Assistant
      'ai_assistant': 'AI Assistant',
      'financial_insights': 'Financial Insights',
      'ask_question': 'Ask a question about your finances...',
      
      // Common
      'save': 'Save',
      'cancel': 'Cancel',
      'edit': 'Edit',
      'delete': 'Delete',
      'amount': 'Amount',
      'category': 'Category',
      'wallet': 'Wallet',
      'description': 'Description',
      'date': 'Date',
    },
    'ru': {
      // Navigation
      'home': 'Главная',
      'add': 'Добавить',
      'analytics': 'Аналитика',
      'ai': 'ИИ',
      'settings': 'Настройки',
      
      // Home Screen
      'good_morning': 'Доброе утро',
      'good_afternoon': 'Добрый день',
      'good_evening': 'Добрый вечер',
      'total_balance': 'Общий баланс',
      'add_income': 'Добавить доход',
      'add_expense': 'Добавить расход',
      'recent_transactions': 'Последние операции',
      'quick_stats': 'Быстрая статистика',
      
      // Transactions
      'income': 'Доход',
      'expense': 'Расход',
      'transfer': 'Перевод',
      'today': 'Сегодня',
      'yesterday': 'Вчера',
      'this_week': 'На этой неделе',
      'this_month': 'В этом месяце',
      'all_time': 'За все время',
      
      // Settings
      'theme': 'Тема',
      'currency': 'Валюта',
      'language': 'Язык',
      'notifications': 'Уведомления',
      'export_data': 'Экспорт данных',
      'import_data': 'Импорт данных',
      'security': 'Безопасность',
      'about': 'О приложении',
      
      // AI Assistant
      'ai_assistant': 'ИИ Помощник',
      'financial_insights': 'Финансовые инсайты',
      'ask_question': 'Задайте вопрос о ваших финансах...',
      
      // Common
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'edit': 'Редактировать',
      'delete': 'Удалить',
      'amount': 'Сумма',
      'category': 'Категория',
      'wallet': 'Кошелек',
      'description': 'Описание',
      'date': 'Дата',
    },
    'es': {
      // Navigation
      'home': 'Inicio',
      'add': 'Agregar',
      'analytics': 'Análisis',
      'ai': 'IA',
      'settings': 'Configuración',
      
      // Home Screen
      'good_morning': 'Buenos días',
      'good_afternoon': 'Buenas tardes',
      'good_evening': 'Buenas noches',
      'total_balance': 'Saldo Total',
      'add_income': 'Agregar Ingreso',
      'add_expense': 'Agregar Gasto',
      'recent_transactions': 'Transacciones Recientes',
      'quick_stats': 'Estadísticas Rápidas',
      
      // Transactions
      'income': 'Ingreso',
      'expense': 'Gasto',
      'transfer': 'Transferencia',
      'today': 'Hoy',
      'yesterday': 'Ayer',
      'this_week': 'Esta Semana',
      'this_month': 'Este Mes',
      'all_time': 'Todo el Tiempo',
      
      // Settings
      'theme': 'Tema',
      'currency': 'Moneda',
      'language': 'Idioma',
      'notifications': 'Notificaciones',
      'export_data': 'Exportar Datos',
      'import_data': 'Importar Datos',
      'security': 'Seguridad',
      'about': 'Acerca de',
      
      // AI Assistant
      'ai_assistant': 'Asistente IA',
      'financial_insights': 'Perspectivas Financieras',
      'ask_question': 'Haz una pregunta sobre tus finanzas...',
      
      // Common
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'edit': 'Editar',
      'delete': 'Eliminar',
      'amount': 'Cantidad',
      'category': 'Categoría',
      'wallet': 'Cartera',
      'description': 'Descripción',
      'date': 'Fecha',
    },
    'fr': {
      // Navigation
      'home': 'Accueil',
      'add': 'Ajouter',
      'analytics': 'Analyses',
      'ai': 'IA',
      'settings': 'Paramètres',
      
      // Home Screen
      'good_morning': 'Bonjour',
      'good_afternoon': 'Bon après-midi',
      'good_evening': 'Bonsoir',
      'total_balance': 'Solde Total',
      'add_income': 'Ajouter Revenu',
      'add_expense': 'Ajouter Dépense',
      'recent_transactions': 'Transactions Récentes',
      'quick_stats': 'Statistiques Rapides',
      
      // Transactions
      'income': 'Revenu',
      'expense': 'Dépense',
      'transfer': 'Transfert',
      'today': 'Aujourd\'hui',
      'yesterday': 'Hier',
      'this_week': 'Cette Semaine',
      'this_month': 'Ce Mois',
      'all_time': 'Tout le Temps',
      
      // Settings
      'theme': 'Thème',
      'currency': 'Devise',
      'language': 'Langue',
      'notifications': 'Notifications',
      'export_data': 'Exporter Données',
      'import_data': 'Importer Données',
      'security': 'Sécurité',
      'about': 'À propos',
      
      // AI Assistant
      'ai_assistant': 'Assistant IA',
      'financial_insights': 'Aperçus Financiers',
      'ask_question': 'Posez une question sur vos finances...',
      
      // Common
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'edit': 'Modifier',
      'delete': 'Supprimer',
      'amount': 'Montant',
      'category': 'Catégorie',
      'wallet': 'Portefeuille',
      'description': 'Description',
      'date': 'Date',
    },
    'de': {
      // Navigation
      'home': 'Startseite',
      'add': 'Hinzufügen',
      'analytics': 'Analysen',
      'ai': 'KI',
      'settings': 'Einstellungen',
      
      // Home Screen
      'good_morning': 'Guten Morgen',
      'good_afternoon': 'Guten Nachmittag',
      'good_evening': 'Guten Abend',
      'total_balance': 'Gesamtsaldo',
      'add_income': 'Einkommen Hinzufügen',
      'add_expense': 'Ausgabe Hinzufügen',
      'recent_transactions': 'Letzte Transaktionen',
      'quick_stats': 'Schnelle Statistiken',
      
      // Transactions
      'income': 'Einkommen',
      'expense': 'Ausgabe',
      'transfer': 'Übertragung',
      'today': 'Heute',
      'yesterday': 'Gestern',
      'this_week': 'Diese Woche',
      'this_month': 'Dieser Monat',
      'all_time': 'Alle Zeit',
      
      // Settings
      'theme': 'Thema',
      'currency': 'Währung',
      'language': 'Sprache',
      'notifications': 'Benachrichtigungen',
      'export_data': 'Daten Exportieren',
      'import_data': 'Daten Importieren',
      'security': 'Sicherheit',
      'about': 'Über',
      
      // AI Assistant
      'ai_assistant': 'KI-Assistent',
      'financial_insights': 'Finanzielle Einblicke',
      'ask_question': 'Stellen Sie eine Frage zu Ihren Finanzen...',
      
      // Common
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'edit': 'Bearbeiten',
      'delete': 'Löschen',
      'amount': 'Betrag',
      'category': 'Kategorie',
      'wallet': 'Geldbörse',
      'description': 'Beschreibung',
      'date': 'Datum',
    },
    'he': {
      'home': 'בית',
      'add': 'הוסף',
      'analytics': 'אנליטיקה',
      'ai': 'בינה מלאכותית',
      'settings': 'הגדרות',
      'good_morning': 'בוקר טוב',
      'good_afternoon': 'צהריים טובים',
      'good_evening': 'ערב טוב',
      'total_balance': 'יתרה כוללת',
      'add_income': 'הוסף הכנסה',
      'add_expense': 'הוסף הוצאה',
      'recent_transactions': 'תנועות אחרונות',
      'quick_stats': 'סטטיסטיקה',
      'income': 'הכנסה',
      'expense': 'הוצאה',
      'transfer': 'העברה',
      'today': 'היום',
      'yesterday': 'אתמול',
      'this_week': 'השבוע',
      'this_month': 'החודש',
      'all_time': 'כל הזמן',
      'theme': 'ערכת נושא',
      'currency': 'מטבע',
      'language': 'שפה',
      'notifications': 'התראות',
      'export_data': 'ייצוא נתונים',
      'import_data': 'ייבוא נתונים',
      'security': 'אבטחה',
      'about': 'אודות',
      'ai_assistant': 'עוזר AI',
      'financial_insights': 'תובנות פיננסיות',
      'ask_question': 'שאל שאלה על הכספים שלך...',
      'save': 'שמור',
      'cancel': 'ביטול',
      'edit': 'ערוך',
      'delete': 'מחק',
      'amount': 'סכום',
      'category': 'קטגוריה',
      'wallet': 'ארנק',
      'description': 'תיאור',
      'date': 'תאריך',
    },
  };

  /// Curated list (10–20 locales). Use for supportedLocales and language picker.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ru'),
    Locale('he'),
    Locale('uk'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('it'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('tr'),
    Locale('ar'),
    Locale('pl'),
    Locale('ro'),
    Locale('nl'),
    Locale('vi'),
    Locale('th'),
    Locale('zh'),
  ];

  static const List<Map<String, String>> supportedLanguagesWithNames = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ru', 'name': 'Русский'},
    {'code': 'he', 'name': 'עברית'},
    {'code': 'uk', 'name': 'Українська'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'de', 'name': 'Deutsch'},
    {'code': 'it', 'name': 'Italiano'},
    {'code': 'pt', 'name': 'Português'},
    {'code': 'pt_BR', 'name': 'Português (Brasil)'},
    {'code': 'tr', 'name': 'Türkçe'},
    {'code': 'ar', 'name': 'العربية'},
    {'code': 'pl', 'name': 'Polski'},
    {'code': 'ro', 'name': 'Română'},
    {'code': 'nl', 'name': 'Nederlands'},
    {'code': 'vi', 'name': 'Tiếng Việt'},
    {'code': 'th', 'name': 'ไทย'},
    {'code': 'zh', 'name': '中文'},
  ];

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }
  
  // Convenience getters for common strings
  String get home => get('home');
  String get add => get('add');
  String get analytics => get('analytics');
  String get ai => get('ai');
  String get settings => get('settings');
  String get totalBalance => get('total_balance');
  String get addIncome => get('add_income');
  String get addExpense => get('add_expense');
  String get recentTransactions => get('recent_transactions');
  String get income => get('income');
  String get expense => get('expense');
  String get transfer => get('transfer');
  String get today => get('today');
  String get yesterday => get('yesterday');
  String get thisWeek => get('this_week');
  String get thisMonth => get('this_month');
  String get theme => get('theme');
  String get currency => get('currency');
  String get language => get('language');
  String get save => get('save');
  String get cancel => get('cancel');
  String get amount => get('amount');
  String get category => get('category');
  String get wallet => get('wallet');
  String get description => get('description');
  String get date => get('date');
  
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return get('good_morning');
    } else if (hour < 17) {
      return get('good_afternoon');
    } else {
      return get('good_evening');
    }
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static bool isRtl(String languageCode) =>
      languageCode == 'he' || languageCode == 'ar';

  static Locale localeFromCode(String code) {
    if (code == 'pt_BR') return const Locale('pt', 'BR');
    return Locale(code);
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  static const _supportedLanguageCodes = {
    'en', 'ru', 'he', 'uk', 'es', 'fr', 'de', 'it', 'pt', 'tr', 'ar', 'pl', 'ro', 'nl', 'vi', 'th', 'zh',
  };

  @override
  bool isSupported(Locale locale) {
    if (_supportedLanguageCodes.contains(locale.languageCode)) return true;
    if (locale.languageCode == 'pt' && (locale.countryCode == 'BR' || locale.countryCode == null)) return true;
    return false;
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
