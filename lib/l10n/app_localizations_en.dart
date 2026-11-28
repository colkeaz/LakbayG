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
  String get intro => 'A little guidance for your next government document.';

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
  String get roadmap => 'Process roadmap';

  @override
  String get requirements => 'What to prepare';

  @override
  String get prepare => 'Prepare my checklist';

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
  String get back => 'Back';

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
  String get viewRoadmap => 'View roadmap';

  @override
  String get missingOnly => 'Show missing items only';

  @override
  String get reset => 'Reset checklist';

  @override
  String get resetConfirm => 'Clear all prepared items for this service?';

  @override
  String get cancel => 'Cancel';

  @override
  String get prepared => 'prepared';

  @override
  String get remaining => 'remaining';

  @override
  String get complete =>
      'All items prepared. This does not guarantee eligibility or approval.';

  @override
  String get empty =>
      'Your preparation starts here. Open a journey to build its checklist.';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose your language';

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
      'LakbayG helps you identify a service, review official guidance and save a readiness checklist. Your checklist and language stay on this device. No accounts or personal documents are collected.';

  @override
  String get reviewNotice =>
      'Content and Filipino wording still require independent team review. The Taal procedure is not release-ready.';

  @override
  String get retry => 'Retry';

  @override
  String get loadError =>
      'LakbayG could not load its local content or saved data. Retry without clearing app data.';

  @override
  String get step => 'Step';

  @override
  String get offline => 'Guidance available offline';

  @override
  String get linksNeedInternet =>
      'Official websites need an internet connection.';

  @override
  String get greeting => 'Welcome to LakbayG';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get myGuides => 'My guides';

  @override
  String get searchHint =>
      'Search service, agency, or use (e.g. job, OJT, birth)';

  @override
  String get notSure => 'Not sure which service? Answer a few questions.';

  @override
  String get noResults => 'No matching service found. Try another word.';

  @override
  String get steps => 'Step by step';

  @override
  String get whatToBring => 'What to bring';

  @override
  String get goTo => 'Go to';

  @override
  String get progress => 'Your progress';

  @override
  String get itemsReady => 'items ready';

  @override
  String get guidesStarted => 'guides started';

  @override
  String get openGuide => 'Open guide';

  @override
  String questionCount(Object count) {
    return 'Question $count';
  }

  @override
  String get documentQuestion => 'What document do you need?';

  @override
  String get resumeGuide => 'Continue preparing';

  @override
  String get inProgress => 'In progress';

  @override
  String get readyGroup => 'Prepared';

  @override
  String get serviceGuide => 'Service Guide';

  @override
  String get whatItIs => 'What it is';

  @override
  String get usedFor => 'Commonly used for';

  @override
  String get validityAndRelease => 'Validity & release';

  @override
  String get counterTips => 'Counter survival tips';

  @override
  String get questionsToAsk => 'Questions to ask the office';

  @override
  String get tipLabel => 'Tip';

  @override
  String get appointmentCardTitle => 'My Appointment Pocket Card';

  @override
  String get appointmentCardSubtitle =>
      'Save your reference number and schedule offline for counter check-in.';

  @override
  String get appointmentRefLabel => 'Reference number';

  @override
  String get appointmentRefHint => 'e.g. NPCS-2026-00123';

  @override
  String get appointmentScheduleLabel => 'Schedule & branch note (optional)';

  @override
  String get appointmentScheduleHint => 'e.g. Dec 5, 9:00 AM · Lipa Station';

  @override
  String get appointmentSave => 'Save details';

  @override
  String get appointmentEdit => 'Edit';

  @override
  String get appointmentClear => 'Clear';

  @override
  String get appointmentSaved => 'Saved offline on this device';

  @override
  String get appointmentRefRequired =>
      'Enter your reference number before saving.';

  @override
  String get appointmentRefInvalid =>
      'Use only letters, numbers, spaces, hyphens, underscores, or slashes.';

  @override
  String get appointmentScheduleInvalid =>
      'Remove unsupported symbols from your schedule note.';

  @override
  String get appointmentCopied => 'Reference number copied.';

  @override
  String get readinessGateTitle => 'Not all items are checked yet';

  @override
  String readinessGateBody(int count) {
    return 'You still have $count unchecked item(s) on your checklist. Review what to bring first, or continue to the official website?';
  }

  @override
  String get reviewChecklist => 'Review checklist';

  @override
  String get continueAnyway => 'Continue to website';
}
