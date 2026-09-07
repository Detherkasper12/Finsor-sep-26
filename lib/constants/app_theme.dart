import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Professional app theme configuration with complete design system
class AppTheme {
  // === PROFESSIONAL COLOR SYSTEM ===
  
  // Primary Brand Colors
  static const Color primaryColor = Color(0xFF6366F1); // Modern Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  
  // Financial Semantic Colors
  static const Color incomeColor = Color(0xFF10B981); // Emerald Green
  static const Color expenseColor = Color(0xFFEF4444); // Coral Red
  static const Color transferColor = Color(0xFF3B82F6); // Blue
  static const Color savingsColor = Color(0xFF8B5CF6); // Purple
  
  // System Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);
  
  // Neutral Colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);
  
  // Professional Dark Mode Colors
  static const Color darkBackground = Color(0xFF0E0E11);   // Very dark background
  static const Color darkSurface = Color(0xFF121212);      // Main dark surface
  static const Color darkCard = Color(0xFF1A1A1D);         // Card backgrounds
  static const Color darkElevated = Color(0xFF1E1E1E);     // Elevated surfaces
  static const Color darkBorder = Color(0xFF2C2C2C);       // Subtle dividers
  static const Color darkButton = Color(0xFF292929);       // Button backgrounds
  
  // Dark Mode Text Colors
  static const Color darkTextPrimary = Color(0xFFF5F5F5);  // High contrast text
  static const Color darkTextSecondary = Color(0xFFB0B0B0); // Secondary text
  static const Color darkTextTertiary = Color(0xFF808080);  // Tertiary text
  
  // Dark Mode Accent
  static const Color darkAccent = Color(0xFF8F9EFF);       // Primary accent
  static const Color darkAccentVariant = Color(0xFF7C4DFF); // Accent variant
  
  // Dark Mode Financial Colors
  static const Color darkIncomeColor = Color(0xFF81C784);   // Softer green
  static const Color darkExpenseColor = Color(0xFFFF6E6E); // Warmer red
  static const Color darkTransferColor = Color(0xFF64B5F6); // Softer blue
  static const Color darkSavingsColor = Color(0xFFBA68C8); // Softer purple
  
  // === TYPOGRAPHY SYSTEM ===
  static const String fontFamily = 'Inter';
  
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.4,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  // Financial Amount Styles
  static const TextStyle amountLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle amountMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.3,
  );
  
  static const TextStyle amountSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // === SPACING SYSTEM ===
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;
  
  // === BORDER RADIUS ===
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  
  // === ELEVATION ===
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation4 = 4.0;
  static const double elevation8 = 8.0;

  /// Professional Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: infoColor,
        surface: Colors.white,
        surfaceContainerHighest: neutral100,
        onSurface: neutral900,
        onSurfaceVariant: neutral600,
        outline: neutral300,
        error: errorColor,
        onError: Colors.white,
        tertiary: savingsColor,
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: neutral50,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: neutral900,
        elevation: 0,
        centerTitle: false,
        titleSpacing: spacing20,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: h3.copyWith(color: neutral900),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: neutral500,
        type: BottomNavigationBarType.fixed,
        elevation: elevation8,
        showUnselectedLabels: true,
        selectedLabelStyle: labelLarge.copyWith(color: primaryColor),
        unselectedLabelStyle: caption.copyWith(color: neutral500),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: elevation2,
        shadowColor: neutral900.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: elevation2,
          shadowColor: primaryColor.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: labelLarge.copyWith(color: Colors.white),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: labelLarge.copyWith(color: primaryColor),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutral100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16),
        labelStyle: bodyMedium.copyWith(color: neutral600),
        hintStyle: bodyMedium.copyWith(color: neutral400),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: elevation4,
        shape: CircleBorder(),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing20, vertical: spacing4),
        titleTextStyle: bodyLarge.copyWith(color: neutral900),
        subtitleTextStyle: bodyMedium.copyWith(color: neutral600),
        leadingAndTrailingTextStyle: bodyMedium.copyWith(color: neutral600),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: neutral200,
        thickness: 1,
        space: spacing16,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: neutral600,
        size: 24,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: h1.copyWith(color: neutral900),
        displayMedium: h2.copyWith(color: neutral900),
        displaySmall: h3.copyWith(color: neutral900),
        headlineLarge: h2.copyWith(color: neutral900),
        headlineMedium: h3.copyWith(color: neutral900),
        titleLarge: h3.copyWith(color: neutral900),
        titleMedium: bodyLarge.copyWith(color: neutral900, fontWeight: FontWeight.w600),
        titleSmall: bodyMedium.copyWith(color: neutral900, fontWeight: FontWeight.w600),
        bodyLarge: bodyLarge.copyWith(color: neutral900),
        bodyMedium: bodyMedium.copyWith(color: neutral700),
        bodySmall: caption.copyWith(color: neutral600),
        labelLarge: labelLarge.copyWith(color: neutral900),
        labelMedium: bodyMedium.copyWith(color: neutral700, fontWeight: FontWeight.w500),
        labelSmall: caption.copyWith(color: neutral600),
      ),
    );
  }

  /// Professional Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: darkAccent,
        primaryContainer: darkAccentVariant,
        secondary: darkTransferColor,
        surface: darkCard,
        surfaceContainerHighest: darkElevated,
        surfaceContainer: darkButton,
        onSurface: darkTextPrimary,
        onSurfaceVariant: darkTextSecondary,
        outline: darkBorder,
        outlineVariant: Color(0xFF404040),
        error: darkExpenseColor,
        onError: darkTextPrimary,
        tertiary: darkSavingsColor,
        onTertiary: darkTextPrimary,
        inverseSurface: darkTextPrimary,
        onInverseSurface: darkSurface,
        shadow: Colors.black87,
        scrim: Colors.black54,
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: darkBackground,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: spacing20,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: h3.copyWith(color: Colors.white),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: darkAccent,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: elevation8,
        showUnselectedLabels: true,
        selectedLabelStyle: labelLarge.copyWith(color: darkAccent),
        unselectedLabelStyle: caption.copyWith(color: darkTextSecondary),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: elevation4,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: darkBackground,
          elevation: elevation2,
          shadowColor: darkAccent.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: labelLarge.copyWith(color: darkBackground, fontWeight: FontWeight.w600),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkAccent,
          padding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: labelLarge.copyWith(color: darkAccent),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkAccent,
          side: const BorderSide(color: darkAccent, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: labelLarge.copyWith(color: darkAccent, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: darkAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: darkExpenseColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16),
        labelStyle: bodyMedium.copyWith(color: darkTextSecondary),
        hintStyle: bodyMedium.copyWith(color: darkTextTertiary),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkAccent,
        foregroundColor: darkBackground,
        elevation: elevation4,
        shape: CircleBorder(),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: spacing20, vertical: spacing4),
        titleTextStyle: bodyLarge.copyWith(color: darkTextPrimary),
        subtitleTextStyle: bodyMedium.copyWith(color: darkTextSecondary),
        leadingAndTrailingTextStyle: bodyMedium.copyWith(color: darkTextSecondary),
        tileColor: Colors.transparent,
        selectedTileColor: darkAccent.withOpacity(0.1),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: spacing16,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: darkTextSecondary,
        size: 24,
      ),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: darkAccent,
        size: 24,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: h1.copyWith(color: darkTextPrimary),
        displayMedium: h2.copyWith(color: darkTextPrimary),
        displaySmall: h3.copyWith(color: darkTextPrimary),
        headlineLarge: h2.copyWith(color: darkTextPrimary),
        headlineMedium: h3.copyWith(color: darkTextPrimary),
        titleLarge: h3.copyWith(color: darkTextPrimary),
        titleMedium: bodyLarge.copyWith(color: darkTextPrimary, fontWeight: FontWeight.w600),
        titleSmall: bodyMedium.copyWith(color: darkTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: bodyLarge.copyWith(color: darkTextPrimary),
        bodyMedium: bodyMedium.copyWith(color: darkTextSecondary),
        bodySmall: caption.copyWith(color: darkTextSecondary),
        labelLarge: labelLarge.copyWith(color: darkTextPrimary),
        labelMedium: bodyMedium.copyWith(color: darkTextSecondary, fontWeight: FontWeight.w500),
        labelSmall: caption.copyWith(color: darkTextTertiary),
      ),
    );
  }

  // === UTILITY METHODS ===
  
  /// Get semantic color for transaction type
  static Color getTransactionColor(String transactionType, {bool isDark = false}) {
    switch (transactionType.toLowerCase()) {
      case 'income':
        return isDark ? darkIncomeColor : incomeColor;
      case 'expense':
        return isDark ? darkExpenseColor : expenseColor;
      case 'transfer':
        return isDark ? darkTransferColor : transferColor;
      default:
        return isDark ? darkTextSecondary : neutral600;
    }
  }
  
  /// Get gradient for balance cards
  static LinearGradient getPrimaryGradient({bool isDark = false}) {
    if (isDark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [darkAccent, darkAccentVariant],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, primaryLight],
    );
  }
  
  /// Get box shadow for cards
  static List<BoxShadow> getCardShadow({bool isDark = false}) {
    return [
      BoxShadow(
        color: isDark 
            ? Colors.black.withOpacity(0.3)
            : neutral900.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
