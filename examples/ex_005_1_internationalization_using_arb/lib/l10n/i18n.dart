import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_ar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_es.dart';

final i18nRM = RM.injectI18N({
  'en'.locale(): () => AppLocalizationsEn(),
  'ar'.locale(): () => AppLocalizationsAr(),
  'es'.locale(): () => AppLocalizationsEs(),
});
