import 'package:flutter/widgets.dart';
import 'package:tudok/l10n/app_localizations.dart';

class TuDokLocalizations {
  const TuDokLocalizations();
  Iterable<LocalizationsDelegate<dynamic>> get delegates =>
      AppLocalizations.localizationsDelegates;
  Iterable<Locale> get locales => AppLocalizations.supportedLocales;
}
