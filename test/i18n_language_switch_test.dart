import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:finsor/utils/app_localizations.dart';

void main() {
  Widget buildApp(Locale locale, {bool useRtlBuilder = false}) {
    final textDirection = useRtlBuilder && AppLocalizations.isRtl(locale.languageCode)
        ? TextDirection.rtl
        : TextDirection.ltr;
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: useRtlBuilder
          ? (context, child) => Directionality(
                textDirection: textDirection,
                child: child!,
              )
          : null,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(body: Center(child: Text(l10n.settings)));
        },
      ),
    );
  }

  testWidgets('locale ru shows Settings as Настройки', (tester) async {
    await tester.pumpWidget(buildApp(const Locale('ru')));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);
  });

  testWidgets('locale en shows Settings as Settings', (tester) async {
    await tester.pumpWidget(buildApp(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('switching locale updates label', (tester) async {
    await tester.pumpWidget(buildApp(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.pumpWidget(buildApp(const Locale('ru')));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);

    await tester.pumpWidget(buildApp(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('locale he uses RTL Directionality', (tester) async {
    await tester.pumpWidget(buildApp(const Locale('he'), useRtlBuilder: true));
    await tester.pumpAndSettle();
    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets('locale ru has MaterialApp locale ru', (tester) async {
    await tester.pumpWidget(buildApp(const Locale('ru')));
    await tester.pumpAndSettle();
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.locale?.languageCode, 'ru');
  });
}
