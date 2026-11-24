import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fil'),
  ];

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @checklists.
  ///
  /// In en, this message translates to:
  /// **'My Checklists'**
  String get checklists;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'About & Settings'**
  String get settings;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Know where to go. Arrive prepared.'**
  String get tagline;

  /// No description provided for @intro.
  ///
  /// In en, this message translates to:
  /// **'A little guidance for your next government document.'**
  String get intro;

  /// No description provided for @findService.
  ///
  /// In en, this message translates to:
  /// **'Find the right service'**
  String get findService;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore the journeys'**
  String get explore;

  /// No description provided for @studentNotice.
  ///
  /// In en, this message translates to:
  /// **'Independent student prototype. Guidance only; confirm current instructions with the agency.'**
  String get studentNotice;

  /// No description provided for @sourceChecked.
  ///
  /// In en, this message translates to:
  /// **'Source checked'**
  String get sourceChecked;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Official confirmation needed'**
  String get pending;

  /// No description provided for @roadmap.
  ///
  /// In en, this message translates to:
  /// **'Process roadmap'**
  String get roadmap;

  /// No description provided for @requirements.
  ///
  /// In en, this message translates to:
  /// **'What to prepare'**
  String get requirements;

  /// No description provided for @prepare.
  ///
  /// In en, this message translates to:
  /// **'Prepare my checklist'**
  String get prepare;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Official references'**
  String get sources;

  /// No description provided for @lastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last source check'**
  String get lastChecked;

  /// No description provided for @scope.
  ///
  /// In en, this message translates to:
  /// **'Who this guide is for'**
  String get scope;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Where to go'**
  String get location;

  /// No description provided for @openOfficial.
  ///
  /// In en, this message translates to:
  /// **'Open official website'**
  String get openOfficial;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get restart;

  /// No description provided for @selectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Choose an answer to continue.'**
  String get selectAnswer;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Your next step'**
  String get result;

  /// No description provided for @match.
  ///
  /// In en, this message translates to:
  /// **'Your answers match this service’s supported scenario.'**
  String get match;

  /// No description provided for @referral.
  ///
  /// In en, this message translates to:
  /// **'Let’s confirm with the right source'**
  String get referral;

  /// No description provided for @viewRoadmap.
  ///
  /// In en, this message translates to:
  /// **'View roadmap'**
  String get viewRoadmap;

  /// No description provided for @missingOnly.
  ///
  /// In en, this message translates to:
  /// **'Show missing items only'**
  String get missingOnly;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset checklist'**
  String get reset;

  /// No description provided for @resetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all prepared items for this service?'**
  String get resetConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @prepared.
  ///
  /// In en, this message translates to:
  /// **'prepared'**
  String get prepared;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'All items prepared. This does not guarantee eligibility or approval.'**
  String get complete;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Your preparation starts here. Open a journey to build its checklist.'**
  String get empty;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @languageHelp.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in Settings.'**
  String get languageHelp;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Your previous saved state is unchanged. Please try again.'**
  String get saveError;

  /// No description provided for @linkError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link. Copy it and try in your browser when connected.'**
  String get linkError;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About TuDok'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Tulong-Dokyumento helps you identify a service, review official guidance and save a readiness checklist. Your checklist and language stay on this device. No accounts or personal documents are collected.'**
  String get aboutBody;

  /// No description provided for @reviewNotice.
  ///
  /// In en, this message translates to:
  /// **'PNP and NBI guides cover standard first-time applications only. The Taal birth-record journey remains an official referral pending a current municipal charter.'**
  String get reviewNotice;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'TuDok could not load its local content or saved data. Retry without clearing app data.'**
  String get loadError;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Guidance available offline'**
  String get offline;

  /// No description provided for @linksNeedInternet.
  ///
  /// In en, this message translates to:
  /// **'Official websites need an internet connection.'**
  String get linksNeedInternet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
