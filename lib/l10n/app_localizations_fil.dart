// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get home => 'Simula';

  @override
  String get checklists => 'Mga Checklist';

  @override
  String get settings => 'Tungkol at Mga Setting';

  @override
  String get tagline => 'Alamin ang pupuntahan. Dumating nang handa.';

  @override
  String get findService => 'Hanapin ang tamang serbisyo';

  @override
  String get explore => 'Tingnan ang mga gabay';

  @override
  String get studentNotice =>
      'Malayang prototype ng mag-aaral. Gabay lamang; kumpirmahin sa ahensya ang kasalukuyang tagubilin.';

  @override
  String get sourceChecked => 'Nasuri ang sanggunian';

  @override
  String get pending => 'Kailangan ng opisyal na kumpirmasyon';

  @override
  String get sources => 'Mga opisyal na sanggunian';

  @override
  String get lastChecked => 'Huling pagsusuri ng sanggunian';

  @override
  String get scope => 'Para kanino ang gabay';

  @override
  String get location => 'Saan pupunta';

  @override
  String get openOfficial => 'Buksan ang opisyal na website';

  @override
  String get next => 'Magpatuloy';

  @override
  String get restart => 'Magsimulang muli';

  @override
  String get selectAnswer => 'Pumili ng sagot upang magpatuloy.';

  @override
  String get result => 'Susunod mong hakbang';

  @override
  String get match => 'Tumutugma ang mga sagot mo sa saklaw ng serbisyong ito.';

  @override
  String get referral => 'Kumpirmahin sa tamang sanggunian';

  @override
  String get missingOnly => 'Ipakita lamang ang kulang';

  @override
  String get reset => 'I-reset ang checklist';

  @override
  String get resetConfirm =>
      'Alisin ang lahat ng markang handa at tapos na hakbang para sa serbisyong ito?';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get prepared => 'handa';

  @override
  String get remaining => 'kulang';

  @override
  String get complete =>
      'Handa na ang lahat ng item. Kumpirmahin pa rin ang huling patakaran sa ahensya bago pumunta.';

  @override
  String get empty =>
      'Dito nagsisimula ang paghahanda. Magbukas ng gabay upang masubaybayan ang mga hakbang, detalye, at dalahin.';

  @override
  String get language => 'Wika';

  @override
  String get chooseLanguage => 'Piliin ang iyong wika';

  @override
  String get bilingualPrompt => 'Choose your language / Piliin ang iyong wika';

  @override
  String get languageHelp => 'Mababago mo ito anumang oras sa Mga Setting.';

  @override
  String get saveError =>
      'Hindi na-save. Nananatili ang dating na-save na estado. Subukang muli.';

  @override
  String get linkError =>
      'Hindi mabuksan ang link. Kopyahin at subukan sa browser kapag may koneksyon.';

  @override
  String get copyLink => 'Kopyahin ang link';

  @override
  String get close => 'Isara';

  @override
  String get about => 'Tungkol sa LakbayG';

  @override
  String get aboutBody =>
      'Tinutulungan ka ng LakbayG na mahanap ang tamang serbisyo ng pamahalaan, sundan ang mga hakbang, i-save ang detalye ng appointment, at maghanda ng checklist nang offline. Nananatili sa device na ito ang lahat—walang account o personal na upload.';

  @override
  String get retry => 'Subukang muli';

  @override
  String get loadError =>
      'Hindi ma-load ng LakbayG ang lokal na nilalaman o datos. Subukang muli nang hindi binubura ang app data.';

  @override
  String get linksNeedInternet =>
      'Kailangan ng internet para sa opisyal na website.';

  @override
  String get searchHint =>
      'Maghanap ng serbisyo, ahensya, o salita (hal., trabaho)';

  @override
  String get noResults =>
      'Walang tumugmang serbisyo. Subukan ang ibang salita.';

  @override
  String get steps => 'Hakbang-hakbang';

  @override
  String get whatToBring => 'Mga dalahin';

  @override
  String get goTo => 'Pupuntahan';

  @override
  String get openGuide => 'Buksan ang gabay';

  @override
  String questionCount(Object count) {
    return 'Tanong $count';
  }

  @override
  String get documentQuestion => 'Anong dokumento ang kailangan mo?';

  @override
  String get pipWelcome =>
      'Hindi sigurado kung anong dokumento ang kailangan mo? Ako si Pip. Hanapin natin.';

  @override
  String get resumeGuide => 'Ipagpatuloy ang paghahanda';

  @override
  String get inProgress => 'Inihahanda';

  @override
  String get readyGroup => 'Handa na';

  @override
  String get catAll => 'Lahat';

  @override
  String get catClearance => 'Clearance';

  @override
  String get catCivil => 'Civil Registry';

  @override
  String get catId => 'Government ID';

  @override
  String get catBenefits => 'Pang-trabaho';

  @override
  String get estimatedFee => 'Bayarin';

  @override
  String get processingTime => 'Proseso';

  @override
  String get validity => 'Bisa';

  @override
  String stepsDone(Object done, Object total) {
    return '$done / $total hakbang tapos';
  }

  @override
  String get tapToMarkDone =>
      'Pindutin ang bilang ng hakbang upang markahang tapos';

  @override
  String get goToChecklist => 'Ihanda ang mga dalahin';

  @override
  String get acceptedIds => 'Mga tinatanggap na ID';

  @override
  String get goodToKnow => 'Mahalagang paalala at tip';

  @override
  String get myItems => 'Mga dinagdag mo';

  @override
  String get addItem => 'Magdagdag ng item';

  @override
  String get addItemHint => 'hal., Itim na bolpen, photocopy ng ID';

  @override
  String get emptyItemError => 'Maglagay ng pangalan ng item.';

  @override
  String get add => 'Idagdag';

  @override
  String get delete => 'Tanggalin';

  @override
  String get myApplication => 'Detalye ng aplikasyon ko';

  @override
  String get trackerEmptyHint =>
      'I-save nang offline sa teleponong ito ang sangay, iskedyul, o reference number.';

  @override
  String get editDetails => 'I-edit';

  @override
  String get addDetails => 'Magdagdag ng detalye';

  @override
  String get branchLabel => 'Sangay o istasyon';

  @override
  String get branchHint => 'hal., NBI Batangas City / Taal PNP';

  @override
  String get appointmentDate => 'Petsa ng appointment';

  @override
  String get pickDate => 'Pumili ng petsa';

  @override
  String get clearDate => 'Alisin ang petsa';

  @override
  String get referenceNumber => 'Reference / Transaction #';

  @override
  String get notesLabel => 'Sariling tala';

  @override
  String get save => 'I-save';

  @override
  String get clearDetails => 'Burahin';

  @override
  String get copied => 'Nakopya sa clipboard';

  @override
  String get saved => 'Na-save nang offline sa device';

  @override
  String get quickComparison => 'Mabilis na paghahambing';

  @override
  String get relatedGuides => 'Mga kaugnay na gabay';

  @override
  String get readyBadge => 'Handa na';

  @override
  String get guidesStarted => 'gabay na sinimulan';

  @override
  String get stepsLabel => 'hakbang';

  @override
  String get itemsLabel => 'item';

  @override
  String get offlineNote =>
      'Gumagana nang offline · Naka-save lamang sa device na ito · Malayang gabay ng mag-aaral; kumpirmahin lagi sa ahensya ang huling tagubilin.';

  @override
  String get mapTab => 'Mapa';

  @override
  String get navChecklists => 'Checklist';

  @override
  String get navSettings => 'Setting';

  @override
  String get officeMapTitle => 'Mga Tanggapan';

  @override
  String get mapView => 'Mapa';

  @override
  String get listView => 'Listahan';

  @override
  String get allServices => 'Lahat ng serbisyo';

  @override
  String get allAreas => 'Lahat ng lugar';

  @override
  String get officeHours => 'Karaniwang oras';

  @override
  String get getDirections => 'Kumuha ng direksyon';

  @override
  String get useAsBranch => 'Gawing sangay ko';

  @override
  String get branchSaved => 'Na-save bilang iyong sangay sa tracker.';

  @override
  String get viewOnMap => 'Tingnan sa mapa';

  @override
  String viewOfficesOnMap(Object count) {
    return 'Tingnan sa mapa ($count)';
  }

  @override
  String distanceKm(Object km) {
    return '$km km ang layo';
  }

  @override
  String get locateMe => 'Hanapin ako';

  @override
  String get fitPins => 'Ipakita lahat ng pin';

  @override
  String get locationOff =>
      'Naka-off ang GPS. Ipinapakita ang mapa ng Batangas.';

  @override
  String get locationDenied =>
      'Hindi pinayagan ang lokasyon. Maaari pa ring maghanap ng tanggapan.';

  @override
  String get locationUnavailable =>
      'Hindi makuha ang kasalukuyang lokasyon ngayon.';

  @override
  String get mapOfflineHint =>
      'Kailangan ng internet sa mapa · Gumagana offline ang listahan';

  @override
  String get noOffices => 'Walang tanggapang tugma sa napiling filter.';

  @override
  String get osmAttribution => '© OpenStreetMap';
}
