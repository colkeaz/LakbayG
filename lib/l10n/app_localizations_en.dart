// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get home => 'Home';

  @override
  String get checklists => 'My Checklists';

  @override
  String get settings => 'About & Settings';

  @override
  String get tagline => 'Know where to go. Arrive prepared.';

  @override
  String get findService => 'Find the right service';

  @override
  String get explore => 'Explore the journeys';

  @override
  String get studentNotice =>
      'Independent student prototype. Guidance only; confirm current instructions with the agency.';

  @override
  String get sourceChecked => 'Source checked';

  @override
  String get pending => 'Official confirmation needed';

  @override
  String get sources => 'Official references';

  @override
  String get lastChecked => 'Last source check';

  @override
  String get scope => 'Who this guide is for';

  @override
  String get location => 'Where to go';

  @override
  String get openOfficial => 'Open official website';

  @override
  String get next => 'Continue';

  @override
  String get restart => 'Start again';

  @override
  String get selectAnswer => 'Choose an answer to continue.';

  @override
  String get result => 'Your next step';

  @override
  String get match => 'Your answers match this service’s supported scenario.';

  @override
  String get referral => 'Let’s confirm with the right source';

  @override
  String get missingOnly => 'Show missing items only';

  @override
  String get reset => 'Reset checklist';

  @override
  String get resetConfirm =>
      'Clear all checked items and step progress for this service?';

  @override
  String get cancel => 'Cancel';

  @override
  String get prepared => 'prepared';

  @override
  String get remaining => 'remaining';

  @override
  String get complete =>
      'All items prepared. Confirm final rules with the agency before visiting.';

  @override
  String get empty =>
      'Your preparation starts here. Open a guide to track steps, details, and what to bring.';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get bilingualPrompt => 'Choose your language / Piliin ang iyong wika';

  @override
  String get languageHelp => 'You can change this anytime in Settings.';

  @override
  String get saveError =>
      'Could not save. Your previous saved state is unchanged. Please try again.';

  @override
  String get linkError =>
      'Could not open the link. Copy it and try in your browser when connected.';

  @override
  String get copyLink => 'Copy link';

  @override
  String get close => 'Close';

  @override
  String get about => 'About LakbayG';

  @override
  String get aboutBody =>
      'LakbayG helps you identify the right government service, follow verified steps, save appointment details, and prepare a readiness checklist offline. Everything stays on this device—no accounts or personal uploads.';

  @override
  String get retry => 'Retry';

  @override
  String get loadError =>
      'LakbayG could not load its local content or saved data. Retry without clearing app data.';

  @override
  String get linksNeedInternet =>
      'Official websites need an internet connection.';

  @override
  String get searchHint =>
      'Search service, agency, or keyword (e.g., first job)';

  @override
  String get noResults => 'No matching service found. Try another keyword.';

  @override
  String get steps => 'Step by step';

  @override
  String get whatToBring => 'What to bring';

  @override
  String get goTo => 'Go to';

  @override
  String get openGuide => 'Open guide';

  @override
  String questionCount(Object count) {
    return 'Question $count';
  }

  @override
  String get documentQuestion => 'What document do you need?';

  @override
  String get pipWelcome =>
      'Unsure which document you need? I’m Pip. Let’s find it together.';

  @override
  String get resumeGuide => 'Continue preparing';

  @override
  String get inProgress => 'In progress';

  @override
  String get readyGroup => 'Prepared';

  @override
  String get catAll => 'All';

  @override
  String get catClearance => 'Clearances';

  @override
  String get catCivil => 'Civil Registry';

  @override
  String get catId => 'Gov IDs';

  @override
  String get catBenefits => 'First Job';

  @override
  String get estimatedFee => 'Fee';

  @override
  String get processingTime => 'Processing';

  @override
  String get validity => 'Validity';

  @override
  String stepsDone(Object done, Object total) {
    return '$done / $total steps done';
  }

  @override
  String get tapToMarkDone => 'Tap a step number to mark it done';

  @override
  String get goToChecklist => 'Prepare what to bring';

  @override
  String get acceptedIds => 'Accepted valid IDs';

  @override
  String get goodToKnow => 'Good to know & tips';

  @override
  String get myItems => 'Your added items';

  @override
  String get addItem => 'Add item';

  @override
  String get addItemHint => 'e.g., Black pen, ID photocopy';

  @override
  String get emptyItemError => 'Enter an item name.';

  @override
  String get add => 'Add';

  @override
  String get delete => 'Delete';

  @override
  String get myApplication => 'My application details';

  @override
  String get trackerEmptyHint =>
      'Save your branch, schedule, or reference number offline on this phone.';

  @override
  String get editDetails => 'Edit details';

  @override
  String get addDetails => 'Add appointment details';

  @override
  String get branchLabel => 'Branch or station';

  @override
  String get branchHint => 'e.g., NBI Batangas City / Taal PNP';

  @override
  String get appointmentDate => 'Appointment date';

  @override
  String get pickDate => 'Choose date';

  @override
  String get clearDate => 'Clear date';

  @override
  String get referenceNumber => 'Reference / Transaction #';

  @override
  String get notesLabel => 'Personal notes';

  @override
  String get save => 'Save';

  @override
  String get clearDetails => 'Clear details';

  @override
  String get copied => 'Copied to clipboard';

  @override
  String get saved => 'Saved offline on this device';

  @override
  String get quickComparison => 'Quick comparison';

  @override
  String get relatedGuides => 'Recommended guides to explore';

  @override
  String get readyBadge => 'Ready';

  @override
  String get guidesStarted => 'guides started';

  @override
  String get stepsLabel => 'steps';

  @override
  String get itemsLabel => 'items';

  @override
  String get offlineNote =>
      'Works offline · Saved only on this device · Independent student guide; confirm final instructions with the agency.';

  @override
  String get mapTab => 'Map';

  @override
  String get navChecklists => 'Checklists';

  @override
  String get navSettings => 'Settings';

  @override
  String get officeMapTitle => 'Government Offices';

  @override
  String get mapView => 'Map';

  @override
  String get listView => 'List';

  @override
  String get allServices => 'All services';

  @override
  String get allAreas => 'All areas';

  @override
  String get officeHours => 'Typical hours';

  @override
  String get getDirections => 'Get directions';

  @override
  String get useAsBranch => 'Use as my branch';

  @override
  String get branchSaved => 'Saved as your branch in checklist tracker.';

  @override
  String get viewOnMap => 'View on map';

  @override
  String viewOfficesOnMap(Object count) {
    return 'View offices on map ($count)';
  }

  @override
  String distanceKm(Object km) {
    return '$km km away';
  }

  @override
  String get locateMe => 'Locate me';

  @override
  String get fitPins => 'Fit all pins';

  @override
  String get locationOff =>
      'Location services are turned off. Showing Batangas map.';

  @override
  String get locationDenied =>
      'Location permission denied. You can still browse and filter offices.';

  @override
  String get locationUnavailable => 'Could not get current location right now.';

  @override
  String get mapOfflineHint =>
      'Map tiles need internet · Office directory & pins work offline';

  @override
  String get noOffices => 'No offices match your current filters.';

  @override
  String get osmAttribution => '© OpenStreetMap';
}
