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
  /// **'Clear all checked items and step progress for this service?'**
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
  /// **'All items prepared. Confirm final rules with the agency before visiting.'**
  String get complete;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Your preparation starts here. Open a guide to track steps, details, and what to bring.'**
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

  /// No description provided for @bilingualPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose your language / Piliin ang iyong wika'**
  String get bilingualPrompt;

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
  /// **'About LakbayG'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'LakbayG helps you identify the right government service, follow verified steps, save appointment details, and prepare a readiness checklist offline. Everything stays on this device—no accounts or personal uploads.'**
  String get aboutBody;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'LakbayG could not load its local content or saved data. Retry without clearing app data.'**
  String get loadError;

  /// No description provided for @linksNeedInternet.
  ///
  /// In en, this message translates to:
  /// **'Official websites need an internet connection.'**
  String get linksNeedInternet;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search service, agency, or keyword (e.g., first job)'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No matching service found. Try another keyword.'**
  String get noResults;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Step by step'**
  String get steps;

  /// No description provided for @whatToBring.
  ///
  /// In en, this message translates to:
  /// **'What to bring'**
  String get whatToBring;

  /// No description provided for @goTo.
  ///
  /// In en, this message translates to:
  /// **'Go to'**
  String get goTo;

  /// No description provided for @openGuide.
  ///
  /// In en, this message translates to:
  /// **'Open guide'**
  String get openGuide;

  /// Progress label in the service questionnaire.
  ///
  /// In en, this message translates to:
  /// **'Question {count}'**
  String questionCount(Object count);

  /// No description provided for @documentQuestion.
  ///
  /// In en, this message translates to:
  /// **'What document do you need?'**
  String get documentQuestion;

  /// No description provided for @pipWelcome.
  ///
  /// In en, this message translates to:
  /// **'Unsure which document you need? I’m Pip. Let’s find it together.'**
  String get pipWelcome;

  /// No description provided for @resumeGuide.
  ///
  /// In en, this message translates to:
  /// **'Continue preparing'**
  String get resumeGuide;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @readyGroup.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get readyGroup;

  /// No description provided for @catAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catAll;

  /// No description provided for @catClearance.
  ///
  /// In en, this message translates to:
  /// **'Clearances'**
  String get catClearance;

  /// No description provided for @catCivil.
  ///
  /// In en, this message translates to:
  /// **'Civil Registry'**
  String get catCivil;

  /// No description provided for @catId.
  ///
  /// In en, this message translates to:
  /// **'Gov IDs'**
  String get catId;

  /// No description provided for @catBenefits.
  ///
  /// In en, this message translates to:
  /// **'First Job'**
  String get catBenefits;

  /// No description provided for @estimatedFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get estimatedFee;

  /// No description provided for @processingTime.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processingTime;

  /// No description provided for @validity.
  ///
  /// In en, this message translates to:
  /// **'Validity'**
  String get validity;

  /// No description provided for @stepsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} steps done'**
  String stepsDone(Object done, Object total);

  /// No description provided for @tapToMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Tap a step number to mark it done'**
  String get tapToMarkDone;

  /// No description provided for @goToChecklist.
  ///
  /// In en, this message translates to:
  /// **'Prepare what to bring'**
  String get goToChecklist;

  /// No description provided for @acceptedIds.
  ///
  /// In en, this message translates to:
  /// **'Accepted valid IDs'**
  String get acceptedIds;

  /// No description provided for @goodToKnow.
  ///
  /// In en, this message translates to:
  /// **'Good to know & tips'**
  String get goodToKnow;

  /// No description provided for @myItems.
  ///
  /// In en, this message translates to:
  /// **'Your added items'**
  String get myItems;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @addItemHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Black pen, ID photocopy'**
  String get addItemHint;

  /// No description provided for @emptyItemError.
  ///
  /// In en, this message translates to:
  /// **'Enter an item name.'**
  String get emptyItemError;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @myApplication.
  ///
  /// In en, this message translates to:
  /// **'My application details'**
  String get myApplication;

  /// No description provided for @trackerEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Save your branch, schedule, or reference number offline on this phone.'**
  String get trackerEmptyHint;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editDetails;

  /// No description provided for @addDetails.
  ///
  /// In en, this message translates to:
  /// **'Add appointment details'**
  String get addDetails;

  /// No description provided for @branchLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch or station'**
  String get branchLabel;

  /// No description provided for @branchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., NBI Batangas City / Taal PNP'**
  String get branchHint;

  /// No description provided for @appointmentDate.
  ///
  /// In en, this message translates to:
  /// **'Appointment date'**
  String get appointmentDate;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get pickDate;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDate;

  /// No description provided for @referenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Reference / Transaction #'**
  String get referenceNumber;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Personal notes'**
  String get notesLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @clearDetails.
  ///
  /// In en, this message translates to:
  /// **'Clear details'**
  String get clearDetails;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved offline on this device'**
  String get saved;

  /// No description provided for @quickComparison.
  ///
  /// In en, this message translates to:
  /// **'Quick comparison'**
  String get quickComparison;

  /// No description provided for @relatedGuides.
  ///
  /// In en, this message translates to:
  /// **'Recommended guides to explore'**
  String get relatedGuides;

  /// No description provided for @readyBadge.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get readyBadge;

  /// No description provided for @guidesStarted.
  ///
  /// In en, this message translates to:
  /// **'guides started'**
  String get guidesStarted;

  /// No description provided for @stepsLabel.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get stepsLabel;

  /// No description provided for @itemsLabel.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get itemsLabel;

  /// No description provided for @offlineNote.
  ///
  /// In en, this message translates to:
  /// **'Works offline · Saved only on this device · Independent student guide; confirm final instructions with the agency.'**
  String get offlineNote;

  /// No description provided for @mapTab.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTab;

  /// No description provided for @navChecklists.
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get navChecklists;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @officeMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Government Offices'**
  String get officeMapTitle;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @allServices.
  ///
  /// In en, this message translates to:
  /// **'All services'**
  String get allServices;

  /// No description provided for @allAreas.
  ///
  /// In en, this message translates to:
  /// **'All areas'**
  String get allAreas;

  /// No description provided for @officeHours.
  ///
  /// In en, this message translates to:
  /// **'Typical hours'**
  String get officeHours;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get getDirections;

  /// No description provided for @useAsBranch.
  ///
  /// In en, this message translates to:
  /// **'Use as my branch'**
  String get useAsBranch;

  /// No description provided for @branchSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved as your branch in checklist tracker.'**
  String get branchSaved;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get viewOnMap;

  /// No description provided for @viewOfficesOnMap.
  ///
  /// In en, this message translates to:
  /// **'View offices on map ({count})'**
  String viewOfficesOnMap(Object count);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String distanceKm(Object km);

  /// No description provided for @locateMe.
  ///
  /// In en, this message translates to:
  /// **'Locate me'**
  String get locateMe;

  /// No description provided for @fitPins.
  ///
  /// In en, this message translates to:
  /// **'Fit all pins'**
  String get fitPins;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off. Showing Batangas map.'**
  String get locationOff;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. You can still browse and filter offices.'**
  String get locationDenied;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not get current location right now.'**
  String get locationUnavailable;

  /// No description provided for @mapOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Map tiles need internet · Office directory & pins work offline'**
  String get mapOfflineHint;

  /// No description provided for @noOffices.
  ///
  /// In en, this message translates to:
  /// **'No offices match your current filters.'**
  String get noOffices;

  /// No description provided for @osmAttribution.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap'**
  String get osmAttribution;
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
