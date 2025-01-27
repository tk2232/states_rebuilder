import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../../states_rebuilder.dart';

import '../../builders/on_reactive.dart';
import '../../rm.dart';

abstract class InjectedI18N<I18N> implements Injected<I18N> {
  ///Get lists of supported locales
  List<Locale> get supportedLocales;

  @override
  I18N get state {
    OnReactiveState.addToTopStatelessObs?.call(this);
    return getInjectedState(this);
  }

  ///The current locale
  Locale? locale;

  ///Default locale resolution used by states_rebuilder.
  ///
  ///It first research for an exact match of the chosen locale in the list
  ///of supported locales, if no match exists, it search for the language
  ///code match, if it fails the first language is the supported language
  ///will be used.
  ///
  ///for more elaborate logic, use [MaterialApp.localeListResolutionCallback]
  ///and define your logic.
  Locale Function(Locale? locale, Iterable<Locale> supportedLocales)
      get localeResolutionCallback;

  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates =
      const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}

class InjectedI18NImp<I18N> extends InjectedImp<I18N> with InjectedI18N<I18N> {
  InjectedI18NImp({
    required this.i18Ns,
    String? persistKey,
    //
    SnapState<I18N>? Function(MiddleSnapState<I18N> middleSnap)?
        middleSnapState,
    void Function(I18N? s)? onInitialized,
    void Function(I18N s)? onDisposed,
    On<void>? onSetState,
    //
    DependsOn<I18N>? dependsOn,
    int undoStackLength = 0,
    //
    bool autoDisposeWhenNotUsed = true,
    // bool isLazy = true,
    String? debugPrintWhenNotifiedPreMessage,
  }) : super(
          creator: null,
          onInitialized: onInitialized,
          //
          middleSnapState: middleSnapState,
          // onSetState: onSetState,
          onDisposed: onDisposed,
          //
          dependsOn: dependsOn,
          autoDisposeWhenNotUsed: autoDisposeWhenNotUsed,
          // isLazy: isLazy,
          debugPrintWhenNotifiedPreMessage: debugPrintWhenNotifiedPreMessage,
        ) {
    _resetDefaultState = () {
      _locale = null;
      _resolvedLocale = null;
    };
    _resetDefaultState();
    final persist = persistKey == null
        ? null
        : PersistState<I18N>(
            key: persistKey,
            fromJson: (json) {
              final s = json.split('#|#');
              assert(s.length <= 3);
              if (s.first.isEmpty) {
                return _getLanguage(SystemLocale());
              }
              final l = Locale.fromSubtags(
                languageCode: s.first,
                scriptCode: s.length > 2 ? s[1] : null,
                countryCode: s.last.isNotEmpty ? s.last : null,
              );

              return _getLanguage(l);
            },
            toJson: (key) {
              String l = '';
              if (_locale is SystemLocale) {
                l = '#|#';
              } else {
                l = '${_resolvedLocale!.languageCode}#|#' +
                    (_locale?.scriptCode != null
                        ? '${_resolvedLocale!.scriptCode}#|#'
                        : '') +
                    '${_resolvedLocale!.countryCode}';
              }
              return l;
            },
          );
    if (undoStackLength > 0 || persist != null) {
      undoRedoPersistState = UndoRedoPersistState<I18N>(
        undoStackLength: undoStackLength,
        persistanceProvider: persist,
      );
    }

    reactiveModelState = ReactiveModelBase<I18N>(
      creator: () {
        return _getLanguage(SystemLocale());
      },
      initializer: initialize,
      autoDisposeWhenNotUsed: autoDisposeWhenNotUsed,
      debugPrintWhenNotifiedPreMessage: debugPrintWhenNotifiedPreMessage,
    );

    if (onSetState != null) {
      //For InjectedI18N and InjectedTheme schedule side effects
      //for the next frame.
      subscribeToRM(
        (_) {
          WidgetsBinding.instance?.addPostFrameCallback(
            (_) => onSetState.call(snapState),
          );
        },
      );
    }
  }

  final Map<Locale, FutureOr<I18N> Function()> i18Ns;

  Locale? _locale;

  //_resolvedLocale vs _local :
  //_locale may be equal SystemLocale which is not a recognized locale
  //_resolvedLocale is a valid locale from the supported locale list
  Locale? _resolvedLocale;

  late final VoidCallback _resetDefaultState;

  @override
  List<Locale> get supportedLocales {
    OnReactiveState.addToTopStatelessObs?.call(this);
    return i18Ns.keys.toList();
  }

  @override
  Locale? get locale {
    initialize();
    OnReactiveState.addToTopStatelessObs?.call(this);
    return _locale is SystemLocale ? _resolvedLocale : _locale;
  }

  @override
  set locale(Locale? l) {
    if (l == null || _locale == l) {
      return;
    }
    final lan = _getLanguage(l);
    setState((s) => lan);
  }

  ///If an exact match for the device locale isn’t found,
  ///then the first supported locale with a matching languageCode is used.
  ///If that fails, then the first element of the supportedLocales list is used.
  FutureOr<I18N> _getLanguage(Locale locale) {
    if (locale is SystemLocale) {
      var l = locale._locale != null ? locale._locale! : _getSystemLocale();
      _resolvedLocale = _localeResolution(l);
      _locale = SystemLocale();
    } else {
      _resolvedLocale = _localeResolution(locale);
      _locale = _resolvedLocale;
    }

    return i18Ns[_resolvedLocale]!.call();
  }

  Locale _localeResolution(Locale locale, [bool tryWithSystemLocale = true]) {
    if (i18Ns.keys.contains(locale)) {
      return locale;
    }
    //If locale is not supported,
    //check if it has the same language code as the system local
    if (tryWithSystemLocale) {
      final sys = _getSystemLocale();
      if (locale.languageCode == sys.languageCode) {
        return _localeResolution(sys, false);
      }
    }

    final l = i18Ns.keys
        .firstWhereOrNull((l) => locale.languageCode == l.languageCode);
    if (l != null) {
      return l;
    }
    return i18Ns.keys.first;
  }

  Locale _getSystemLocale() {
    return WidgetsBinding.instance!.platformDispatcher.locale;
  }

  @override
  Locale Function(Locale? locale, Iterable<Locale> supportedLocales)
      get localeResolutionCallback => (locale, __) {
            return _resolvedLocale!;
          };

  void didChangeLocales(List<Locale>? locales) {
    if (_locale is SystemLocale && locales != null) {
      _locale = locales.first;
      locale = SystemLocale._(locales.first);
    }
  }

  // @override
  // void initialize() {
  //   super.initialize();
  // }

  @override
  I18N of(
    BuildContext context, {
    bool defaultToGlobal = false,
  }) {
    try {
      return super.of(
        context,
        defaultToGlobal: defaultToGlobal,
      );
    } catch (e) {
      final widget = context.widget;
      if (widget is TopStatelessWidget) {
        throw ('No Parent InheritedWidget of type [TopReactiveStateless] is found.\n'
            'There are several ways to avoid this problem. The simplest is to '
            'use a Builder to get a context that is "under" the [TopReactiveStateless].\n'
            'A more efficient solution is to split your build function into several widgets. This '
            'introduces a new context from which you can obtain the [TopReactiveStateless].\n'
            '${context.describeElement('The context used was')}');
      }
      throw ('No Parent InheritedWidget of type [TopReactiveStateless ] is found.\n'
          'Make sure to use [TopReactiveStateless] widget on top of MaterialApp '
          'Widget.\n'
          '${context.describeElement('The context used was')}');
    }
  }

  @override
  Injected<I18N> call(
    BuildContext context, {
    bool defaultToGlobal = false,
  }) {
    throw Exception(
      'Use of(context) method instead',
    );
  }

  @override
  void dispose() {
    super.dispose();
    _resetDefaultState();
  }
}

///Used to represent the locale of the system.
class SystemLocale extends Locale {
  final Locale? _locale;

  const SystemLocale._(this._locale) : super('systemLocale');

  factory SystemLocale() {
    return const SystemLocale._(null);
  }
  @override
  bool operator ==(Object other) {
    return other is SystemLocale;
  }

  @override
  int get hashCode => 0;
}
