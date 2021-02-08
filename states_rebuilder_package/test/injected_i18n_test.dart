import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:states_rebuilder/src/reactive_model.dart';

final i18n = RM.injectI18N({
  Locale('ar'): () => 'arabic',
  Locale('en', 'TN'): () => 'english_TN',
  Locale('en', 'US'): () => 'english_US',
  Locale('es', 'ES'): () => 'spanish',
});
final i18nStored = RM.injectI18N(
  {
    Locale('ar'): () => 'arabic',
    Locale('en', 'TN'): () => 'english_TN',
    Locale('en', 'US'): () => 'english_US',
    Locale('es', 'ES'): () => 'spanish',
  },
  persistKey: '_lan_',
);

void main() {
  testWidgets('system language is not in the supported local, get the first',
      (tester) async {
    TextDirection? textDirection;
    final i18n = RM.injectI18N({
      Locale('ar'): () => 'arabic',
      Locale('es'): () => 'spanish',
    });
    final widget = TopAppWidget(
      injectedI18N: i18n,
      builder: (context) {
        return MaterialApp(
          locale: i18n.locale,
          localeResolutionCallback: i18n.localeResolutionCallback,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (ctx) {
              textDirection = Directionality.of(ctx);
              return Text(i18n.of(ctx)!);
            },
          ),
        );
      },
    );

    await tester.pumpWidget(widget);
    expect(find.text('arabic'), findsOneWidget);
    expect(textDirection, TextDirection.rtl);
    i18n.locale = Locale('es');
    await tester.pump();
    expect(find.text('spanish'), findsOneWidget);
    expect(textDirection, TextDirection.ltr);
  });

  testWidgets(
      'system language is not in the supported local, get the same language code',
      (tester) async {
    TextDirection? textDirection;
    final i18n = RM.injectI18N({
      Locale('ar'): () => 'arabic',
      Locale('en', 'TN'): () => 'english_TN',
    });
    final widget = TopAppWidget(
      injectedI18N: i18n,
      builder: (context) {
        return MaterialApp(
          locale: i18n.locale,
          localeResolutionCallback: i18n.localeResolutionCallback,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (ctx) {
              textDirection = Directionality.of(ctx);
              return Text(i18n.of(ctx)!);
            },
          ),
        );
      },
    );

    await tester.pumpWidget(widget);
    expect(find.text('english_TN'), findsOneWidget);
    expect(textDirection, TextDirection.ltr);
    i18n.locale = Locale('ar', 'CN');
    await tester.pump();
    expect(find.text('arabic'), findsOneWidget);
    expect(textDirection, TextDirection.rtl);
  });

  testWidgets('system language is in the supported local, get it',
      (tester) async {
    final i18n = RM.injectI18N({
      Locale('ar'): () => 'arabic',
      Locale('en', 'TN'): () => 'english_TN',
      Locale('en', 'US'): () => 'english_US',
    });
    final widget = TopAppWidget(
      injectedI18N: i18n,
      builder: (context) {
        return MaterialApp(
          locale: i18n.locale,
          localeResolutionCallback: i18n.localeResolutionCallback,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (ctx) {
              print(i18n.of(ctx));
              return Text(i18n.of(ctx)!);
            },
          ),
        );
      },
    );

    await tester.pumpWidget(widget);
    expect(find.text('english_US'), findsOneWidget);
    i18n.locale = Locale('en', 'CN');
    await tester.pump();
    expect(find.text('english_US'), findsOneWidget);
    i18n.locale = Locale('en', 'TN');
    await tester.pumpAndSettle();
    expect(find.text('english_TN'), findsOneWidget);
  });

  testWidgets('change sytem language', (tester) async {
    //It uses the gobal i18n
    TextDirection? textDirection;
    Locale? localization;

    final widget = TopAppWidget(
      injectedI18N: i18n,
      builder: (context) {
        return MaterialApp(
          locale: i18n.locale,
          localeResolutionCallback: i18n.localeResolutionCallback,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (ctx) {
              textDirection = Directionality.of(ctx);
              localization = Localizations.localeOf(ctx);
              return const _App();
            },
          ),
        );
      },
    );

    await tester.pumpWidget(widget);
    expect(find.text('english_US'), findsOneWidget);
    expect(localization.toString(), 'en_US');

    await tester.binding.setLocales([Locale('ar')]);
    await tester.pumpAndSettle();
    expect(find.text('arabic'), findsOneWidget);
    expect(textDirection, TextDirection.rtl);
    expect(localization.toString(), 'ar');
    //
    await tester.binding.setLocales([Locale('es', 'ES')]);
    await tester.pumpAndSettle();
    expect(find.text('spanish'), findsOneWidget);
    expect(textDirection, TextDirection.ltr);
    expect(localization.toString(), 'es_ES');
    //
    await tester.binding.setLocales([Locale('fr')]);
    await tester.pumpAndSettle();
    expect(find.text('arabic'), findsOneWidget);
    expect(textDirection, TextDirection.rtl);
    expect(localization.toString(), 'ar');

    expect(i18n.supportedLocales.length, 4);
  });

  testWidgets('async translation', (tester) async {
    final i18n = RM.injectI18N(
      {
        Locale('ar'): () =>
            Future.delayed(Duration(seconds: 1), () => 'arabic'),
        Locale('en', 'TN'): () =>
            Future.delayed(Duration(seconds: 1), () => 'english_TN'),
        Locale('en', 'US'): () =>
            Future.delayed(Duration(seconds: 1), () => 'english_US'),
        Locale('es', 'ES'): () =>
            Future.delayed(Duration(seconds: 1), () => 'spanish'),
      },
    );
    TextDirection? textDirection;
    Locale? localization;

    final widget = TopAppWidget(
      injectedI18N: i18n,
      onWaiting: () => CircularProgressIndicator(),
      builder: (context) {
        return MaterialApp(
          locale: i18n.locale,
          localeResolutionCallback: i18n.localeResolutionCallback,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (ctx) {
              textDirection = Directionality.of(ctx);
              localization = Localizations.localeOf(ctx);
              print(i18n.of(context));
              return Text(i18n.of(context)!);
            },
          ),
        );
      },
    );

    await tester.pumpWidget(widget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(Duration(seconds: 1));
    expect(find.text('english_US'), findsOneWidget);
    expect(localization.toString(), 'en_US');

    await tester.binding.setLocales([Locale('ar')]);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(Duration(seconds: 1));
    expect(find.text('arabic'), findsOneWidget);
    expect(textDirection, TextDirection.rtl);
    expect(localization.toString(), 'ar');
    //
    i18n.locale = Locale('es');
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(Duration(seconds: 1));
    expect(find.text('spanish'), findsOneWidget);
    expect(localization.toString(), 'es_ES');
    //
    i18n.locale = SystemLocale();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(Duration(seconds: 1));
    expect(find.text('english_US'), findsOneWidget);
    expect(localization.toString(), 'en_US');
    //
    i18n.locale = SystemLocale();
    await tester.pump();
    expect(find.text('english_US'), findsOneWidget);
  });

  testWidgets('persist language. no locale is stored yet', (tester) async {
    TextDirection? textDirection;
    Locale? localization;
    late Map<String, String> store;
    final widget = TopAppWidget(
      waiteFor: () => [
        () async {
          store = (await RM.storageInitializerMock()).store!;
        }()
      ],
      onWaiting: () => CircularProgressIndicator(),
      injectedI18N: i18nStored,
      builder: (context) {
        return MaterialApp(
          locale: i18nStored.locale,
          localeResolutionCallback: i18nStored.localeResolutionCallback,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (ctx) {
              textDirection = Directionality.of(ctx);
              localization = Localizations.localeOf(ctx);
              return Text(i18nStored.of(context)!);
            },
          ),
        );
      },
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    expect(store['_lan_'], '#|#');
    //
    await tester.binding.setLocales([Locale('ar')]);
    await tester.pumpAndSettle();
    expect(store['_lan_'], '#|#');
    expect(find.text('arabic'), findsOneWidget);
    expect(textDirection, TextDirection.rtl);
    expect(localization.toString(), 'ar');
    //
    i18nStored.locale = Locale('es');
    await tester.pumpAndSettle();
    expect(store['_lan_'], 'es#|#ES');
    //
  });

  testWidgets('persist language. supported locale is stored', (tester) async {
    TextDirection? textDirection;
    Locale? localization;
    late Map<String, String> store;
    final widget = TopAppWidget(
      waiteFor: () => [
        () async {
          store = (await RM.storageInitializerMock()).store!;
          store.addAll({'_lan_': 'es#|#ES'});
        }()
      ],
      onWaiting: () => CircularProgressIndicator(),
      injectedI18N: i18nStored,
      builder: (context) {
        return MaterialApp(
          locale: i18nStored.locale,
          localeResolutionCallback: i18nStored.localeResolutionCallback,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (ctx) {
              textDirection = Directionality.of(ctx);
              localization = Localizations.localeOf(ctx);
              return Text(i18nStored.of(context)!);
            },
          ),
        );
      },
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    expect(store['_lan_'], 'es#|#ES');
    expect(textDirection, TextDirection.ltr);
    expect(localization.toString(), 'es_ES');
    //
    i18nStored.locale = Locale('ar');
    await tester.pumpAndSettle();
    expect(store['_lan_'], 'ar#|#null');
    expect(textDirection, TextDirection.rtl);
    expect(localization.toString(), 'ar');
    //
  });

  testWidgets('persist language. non suported locale is stored',
      (tester) async {
    TextDirection? textDirection;
    Locale? localization;
    late Map<String, String> store;
    final widget = TopAppWidget(
      waiteFor: () => [
        () async {
          store = (await RM.storageInitializerMock()).store!;
          store.addAll({'_lan_': 'fr#|#FF'});
        }()
      ],
      onWaiting: () => CircularProgressIndicator(),
      injectedI18N: i18nStored,
      builder: (context) {
        return MaterialApp(
          locale: i18nStored.locale,
          localeResolutionCallback: i18nStored.localeResolutionCallback,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (ctx) {
              textDirection = Directionality.of(ctx);
              localization = Localizations.localeOf(ctx);
              return Text(i18nStored.of(context)!);
            },
          ),
        );
      },
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    expect(store['_lan_'], 'fr#|#FF');
    expect(i18nStored.locale.toString(), 'ar');
    expect(textDirection, TextDirection.rtl);
    expect(localization.toString(), 'ar');

    //
    i18nStored.locale = SystemLocale();
    await tester.pumpAndSettle();
    expect(store['_lan_'], '#|#');
    expect(textDirection, TextDirection.ltr);
    expect(localization.toString(), 'en_US');
    //
  });

  testWidgets('persist language. system lang is stored', (tester) async {
    final i18nStored = RM.injectI18N(
      {
        Locale('ar'): () => 'arabic',
        Locale('en', 'TN'): () => 'english_TN',
        Locale('en', 'US'): () => 'english_US',
        Locale.fromSubtags(
            languageCode: 'es',
            scriptCode: 'script',
            countryCode: 'ES'): () => 'spanish',
      },
      persistKey: '_lan_',
    );

    TextDirection? textDirection;
    Locale? localization;
    late Map<String, String> store;
    final widget = TopAppWidget(
      waiteFor: () => [
        () async {
          store = (await RM.storageInitializerMock()).store!;
          store.addAll({'_lan_': '#|#'});
        }()
      ],
      onWaiting: () => CircularProgressIndicator(),
      injectedI18N: i18nStored,
      builder: (context) {
        return MaterialApp(
          locale: i18nStored.locale,
          localeResolutionCallback: i18nStored.localeResolutionCallback,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (ctx) {
              textDirection = Directionality.of(ctx);
              localization = Localizations.localeOf(ctx);
              return Text(i18nStored.of(context)!);
            },
          ),
        );
      },
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    expect(store['_lan_'], '#|#');
    expect(i18nStored.locale.toString(), 'en_US');
    expect(textDirection, TextDirection.ltr);
    expect(localization.toString(), 'en_US');

    //
    i18nStored.locale = Locale.fromSubtags(
      languageCode: 'es',
      scriptCode: 'script',
    );
    await tester.pumpAndSettle();
    expect(store['_lan_'], 'es#|#script#|#ES');
    expect(textDirection, TextDirection.ltr);
    expect(localization.toString(), 'es_script_ES');
    //
  });

  testWidgets('persist language. locale with script is stored', (tester) async {
    final i18nStored = RM.injectI18N(
      {
        Locale('ar'): () => 'arabic',
        Locale('en', 'TN'): () => 'english_TN',
        Locale('en', 'US'): () => 'english_US',
        Locale.fromSubtags(
            languageCode: 'es',
            scriptCode: 'script',
            countryCode: 'ES'): () => 'spanish',
      },
      persistKey: '_lan_',
    );

    TextDirection? textDirection;
    Locale? localization;
    late Map<String, String> store;
    final widget = TopAppWidget(
      waiteFor: () => [
        () async {
          store = (await RM.storageInitializerMock()).store!;
          store.addAll({'_lan_': 'es#|#script#|#ES'});
        }()
      ],
      onWaiting: () => CircularProgressIndicator(),
      injectedI18N: i18nStored,
      builder: (context) {
        return MaterialApp(
          locale: i18nStored.locale,
          localeResolutionCallback: i18nStored.localeResolutionCallback,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (ctx) {
              textDirection = Directionality.of(ctx);
              localization = Localizations.localeOf(ctx);
              return Text(i18nStored.of(context)!);
            },
          ),
        );
      },
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.pumpAndSettle();
    expect(store['_lan_'], 'es#|#script#|#ES');
    expect(textDirection, TextDirection.ltr);
    expect(localization.toString(), 'es_script_ES');
    //
  });
}

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) {
    final _i18n = i18n.of(context)!;
    return Text(_i18n);
  }
}