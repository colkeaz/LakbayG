import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'dart:ui' show ImageByteFormat;

import 'localizations_helper.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tudok/domain.dart';
import 'package:tudok/storage.dart';
import 'package:tudok/main.dart';

Catalog fixture() =>
    Catalog(jsonDecode(File('assets/catalog.json').readAsStringSync()));
void choose(NavigationEngine e, String id) {
  e.select(id);
  expect(e.next(), true);
}

class FailingChecklist extends ChecklistRepository {
  FailingChecklist(super.store);
  @override
  Future<void> set(String service, String requirement, bool prepared) async {
    throw StateError('disk unavailable');
  }
}

class FailingAppointmentRepository extends AppointmentRepository {
  FailingAppointmentRepository(super.store);
  @override
  Future<void> save(String service, AppointmentNote note) async {
    throw StateError('disk unavailable');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  setUpAll(() async {
    final configFile = File('.dart_tool/package_config.json').absolute;
    final packages =
        jsonDecode(configFile.readAsStringSync())['packages'] as List;
    final flutter = packages.firstWhere((p) => p['name'] == 'flutter');
    final sdk = Directory.fromUri(
      configFile.uri.resolve(flutter['rootUri'] as String),
    ).parent.parent;
    final fonts = Directory('${sdk.path}/bin/cache/artifacts/material_fonts');
    for (final pair in [
      ('Roboto', 'roboto-regular.ttf'),
      ('MaterialIcons', 'materialicons-regular.otf'),
    ]) {
      final loader = FontLoader(pair.$1)
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('${fonts.path}/${pair.$2}').readAsBytesSync(),
            ),
          ),
        );
      await loader.load();
    }
  });
  late LocalStore store;
  late AppController controller;
  setUp(() async {
    store = await LocalStore.open(
      factory: databaseFactoryFfi,
      location: inMemoryDatabasePath,
    );
    controller = AppController(
      ChecklistRepository(store),
      SettingsRepository(store),
      AppointmentRepository(store),
    );
    await controller.initialize();
  });
  tearDown(() async {
    controller.dispose();
    await store.database.close();
  });
  test('Bundled bilingual content validates and Taal is withheld', () {
    final c = fixture();
    expect(c.services.length, 3);
    expect(c.service('taal-birth').verified, false);
    expect(c.service('taal-birth').requirements, isEmpty);
    expect(c.service('taal-birth').steps, isEmpty);
  });
  test('Catalog includes beginner explainers, hints, notes, tips and neutral referral', () {
    final c = fixture();
    for (final s in c.services) {
      expect(s.whatItIs.en, isNotEmpty);
      expect(s.whatItIs.fil, isNotEmpty);
      expect(s.usedFor, isNotEmpty);
      expect(s.validityNote.en, isNotEmpty);
      expect(s.validityNote.fil, isNotEmpty);
      expect(s.tips.length, greaterThanOrEqualTo(3));
    }
    for (final id in ['pnp', 'nbi']) {
      final s = c.service(id);
      expect(s.requirements.every((r) => r.note != null), true);
      expect(s.steps.any((st) => st.tip != null), true);
    }
    final birthChoices = c.question('birth-type').choices;
    expect(birthChoices.firstWhere((ch) => ch.id == 'local').hint, isNotNull);
    expect(birthChoices.firstWhere((ch) => ch.id == 'psa').hint, isNotNull);
    final clearanceChoices = c.question('clearance-type').choices;
    expect(clearanceChoices.firstWhere((ch) => ch.id == 'pnp').hint, isNotNull);
    expect(clearanceChoices.firstWhere((ch) => ch.id == 'nbi').hint, isNotNull);

    final clearanceRef = c.referrals.firstWhere(
      (r) => r.id == 'clearance-referral',
    );
    expect(clearanceRef.url, 'https://arta.gov.ph/');
    expect(clearanceRef.reason.en, contains('PNP'));
    expect(clearanceRef.reason.en, contains('NBI'));
  });
  test('PNP and NBI stay distinct; uncertain purpose gets referral', () {
    for (final id in ['pnp', 'nbi']) {
      final e = NavigationEngine(fixture());
      choose(e, 'clearance');
      choose(e, id);
      choose(e, 'yes');
      expect(e.current, 'service:$id');
    }
    final e = NavigationEngine(fixture());
    choose(e, 'clearance');
    choose(e, 'unsure');
    expect(e.current, 'clearance-referral');
  });
  test('Every possible path terminates and each terminal is exercised', () {
    final c = fixture();
    final endings = <String>{};
    void walk(String id, List<String> answers) {
      if (!c.questions.any((q) => q.id == id)) {
        final e = NavigationEngine(c);
        for (final a in answers) {
          choose(e, a);
        }
        expect(e.current, id);
        endings.add(id);
        return;
      }
      for (final choice in c.question(id).choices) {
        walk(choice.next, [...answers, choice.id]);
      }
    }

    walk('start', []);
    expect(endings.length, c.referrals.length + c.services.length);
  });
  test('Missing answer is rejected and editing removes dependent state', () {
    final e = NavigationEngine(fixture());
    expect(e.next(), false);
    choose(e, 'birth');
    choose(e, 'local');
    choose(e, 'yes');
    choose(e, 'yes');
    expect(e.current, 'service:taal-birth');
    while (e.position > 0) {
      e.back();
    }
    e.select('clearance');
    expect(e.answers.keys, ['start']);
    expect(e.path, ['start']);
    e.next();
    expect(e.current, 'clearance-type');
    e.restart();
    expect(e.answers, isEmpty);
    expect(e.position, 0);
  });
  test('Malformed references, cycles and translations are rejected', () {
    for (final change in <void Function(Map<String, dynamic>)>[
      (j) => j['services'][0]['sources'] = ['missing'],
      (j) => j['questions'][0]['choices'][0]['next'] = 'start',
      (j) => j['services'][0]['title']['fil'] = '',
      (j) => j['services'][1]['requirements'][1]['id'] =
          j['services'][1]['requirements'][0]['id'],
      (j) => j['questions'][1]['choices'][0]['hint']['fil'] = '',
      (j) => j['services'][1]['requirements'][0]['note']['en'] = '   ',
      (j) => j['services'][1]['steps'][0]['tip']['fil'] = '',
    ]) {
      final j = jsonDecode(
        File('assets/catalog.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      change(j);
      expect(() => Catalog(j), throwsA(anything));
    }
  });
  test('Checklist isolation, uncheck, reset and controller reload', () async {
    expect(await controller.toggle('pnp', 'pnp-id-v1', true), true);
    await controller.toggle('nbi', 'nbi-ids-v1', true);
    final restored = AppController(
      ChecklistRepository(store),
      SettingsRepository(store),
      AppointmentRepository(store),
    );
    await restored.initialize();
    expect(restored.checked('pnp', 'pnp-id-v1'), true);
    expect(restored.checked('nbi', 'pnp-id-v1'), false);
    await restored.toggle('pnp', 'pnp-id-v1', false);
    expect(restored.checked('pnp', 'pnp-id-v1'), false);
    await restored.reset('pnp');
    expect(restored.checked('nbi', 'nbi-ids-v1'), true);
    restored.dispose();
  });
  test(
    'Appointment notes validate, persist per service, and clear cleanly',
    () async {
      expect(await controller.saveAppointment('pnp', '   ', '9:00 AM'), false);
      expect(
        await controller.saveAppointment('pnp', 'BAD<REF>!', '9:00 AM'),
        false,
      );
      expect(
        await controller.saveAppointment('pnp', 'NPCS-2026-001', '<script>'),
        false,
      );
      expect(controller.appointment('pnp'), isNull);

      expect(
        await controller.saveAppointment(
          'pnp',
          ' NPCS-2026-001 ',
          ' Dec 5, 9:00 AM · Lipa ',
        ),
        true,
      );
      expect(controller.appointment('pnp')?.referenceNo, 'NPCS-2026-001');
      expect(
        controller.appointment('pnp')?.scheduleNote,
        'Dec 5, 9:00 AM · Lipa',
      );
      expect(controller.appointment('nbi'), isNull);

      final restored = AppController(
        ChecklistRepository(store),
        SettingsRepository(store),
        AppointmentRepository(store),
      );
      await restored.initialize();
      expect(restored.appointment('pnp')?.referenceNo, 'NPCS-2026-001');
      expect(
        restored.appointment('pnp')?.scheduleNote,
        'Dec 5, 9:00 AM · Lipa',
      );
      expect(await restored.clearAppointment('pnp'), true);
      expect(restored.appointment('pnp'), isNull);
      restored.dispose();
    },
  );
  test('SQLite data and appointments survive closing and reopening', () async {
    final folder = await Directory.systemTemp.createTemp('tudok-test-');
    final path = '${folder.path}/test.db';
    final disk = await LocalStore.open(
      factory: databaseFactoryFfi,
      location: path,
    );
    await ChecklistRepository(disk).set('pnp', 'pnp-id-v1', true);
    await SettingsRepository(disk).setLanguage('fil');
    await AppointmentRepository(disk).save(
      'pnp',
      const AppointmentNote(
        referenceNo: 'NPCS-2026-777',
        scheduleNote: 'Dec 8, 10:00 AM · Batangas',
      ),
    );
    await disk.database.close();
    final reopened = await LocalStore.open(
      factory: databaseFactoryFfi,
      location: path,
    );
    expect(
      (await ChecklistRepository(reopened).read())['pnp'],
      contains('pnp-id-v1'),
    );
    expect(await SettingsRepository(reopened).language(), 'fil');
    final saved = (await AppointmentRepository(reopened).read())['pnp'];
    expect(saved?.referenceNo, 'NPCS-2026-777');
    expect(saved?.scheduleNote, 'Dec 8, 10:00 AM · Batangas');
    await reopened.database.close();
    await folder.delete(recursive: true);
  });
  test('SQLite v1 database migrates cleanly to v2 without losing data', () async {
    final folder = await Directory.systemTemp.createTemp('tudok-migrate-');
    final path = '${folder.path}/legacy.db';
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE checklist (service TEXT NOT NULL, requirement TEXT NOT NULL, PRIMARY KEY(service, requirement))',
          );
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
          await db.insert('checklist', {
            'service': 'nbi',
            'requirement': 'nbi-ids-v1',
          });
          await db.insert('settings', {'key': 'language', 'value': 'fil'});
        },
      ),
    );
    await v1.close();

    final upgraded = await LocalStore.open(
      factory: databaseFactoryFfi,
      location: path,
    );
    expect(
      (await ChecklistRepository(upgraded).read())['nbi'],
      contains('nbi-ids-v1'),
    );
    expect(await SettingsRepository(upgraded).language(), 'fil');
    await AppointmentRepository(upgraded).save(
      'nbi',
      const AppointmentNote(
        referenceNo: 'NBI-2026-888',
        scheduleNote: 'Dec 10, PM slot',
      ),
    );
    expect(
      (await AppointmentRepository(upgraded).read())['nbi']?.referenceNo,
      'NBI-2026-888',
    );
    await upgraded.database.close();
    await folder.delete(recursive: true);
  });
  test(
    'Failed writes leave prepared and appointment state unchanged',
    () async {
      final failed = AppController(
        FailingChecklist(store),
        SettingsRepository(store),
        FailingAppointmentRepository(store),
      );
      await failed.initialize();
      expect(await failed.toggle('pnp', 'pnp-id-v1', true), false);
      expect(failed.checked('pnp', 'pnp-id-v1'), false);
      expect(
        await failed.saveAppointment('pnp', 'NPCS-2026-999', '9:00 AM'),
        false,
      );
      expect(failed.appointment('pnp'), isNull);
      expect(failed.busy, false);
      failed.dispose();
    },
  );
  testWidgets('Language onboarding persists Filipino choice', (tester) async {
    await tester.pumpWidget(
      TuDokApp(catalog: fixture(), controller: controller),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Filipino'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('Hanapin ang tamang serbisyo'), findsOneWidget);
    expect(
      await tester.runAsync(() => SettingsRepository(store).language()),
      'fil',
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Home search filters by use-case keywords and shows 1-line subtitles',
    (tester) async {
      await tester.runAsync(() => controller.changeLanguage('en'));
      await tester.pumpWidget(
        TuDokApp(catalog: fixture(), controller: controller),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Local private employment'), findsOneWidget);
      final search = find.byKey(const ValueKey<String>('home-search-field'));
      await tester.enterText(search, 'ojt');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('service-pnp')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('service-nbi')), findsNothing);
      await tester.enterText(search, 'job');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('service-pnp')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('service-nbi')), findsOneWidget);
      await tester.enterText(search, 'birth');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('service-taal-birth')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('service-pnp')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Questionnaire validation, choice hints, and language switch preserve selection',
    (tester) async {
      await tester.runAsync(() => controller.changeLanguage('en'));
      await tester.pumpWidget(
        TuDokApp(catalog: fixture(), controller: controller),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Find the right service'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Find the right service'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Choose an answer to continue.'), findsOneWidget);
      await tester.tap(find.text('A clearance'));
      await tester.pump();
      await tester.runAsync(() => controller.changeLanguage('fil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Magpatuloy'));
      await tester.pumpAndSettle();
      expect(
        find.text('Anong clearance ang tinukoy ng humihinging institusyon?'),
        findsOneWidget,
      );
      expect(
        find.textContaining('nangangailangan ng 1 balidong ID'),
        findsOneWidget,
      );
      expect(
        find.textContaining('nangangailangan ng 2 orihinal na balidong ID'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Guide AppBar uses concise title and pre-portal gate prompts when unchecked',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() => controller.changeLanguage('en'));
      final service = fixture().service('pnp');
      await tester.pumpWidget(
        AppScope(
          catalog: fixture(),
          controller: controller,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => MaterialApp(
              localizationsDelegates: const TuDokLocalizations().delegates,
              supportedLocales: const TuDokLocalizations().locales,
              home: ChecklistScreen(service: service),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Service Guide'), findsOneWidget);
      expect(find.text('National Police Clearance'), findsOneWidget);
      expect(find.text('What it is'), findsOneWidget);
      expect(find.text('Validity & release'), findsOneWidget);
      expect(find.text('Counter survival tips'), findsOneWidget);
      await tester.ensureVisible(find.text('Open official website'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open official website'));
      await tester.pumpAndSettle();
      expect(find.text('Not all items are checked yet'), findsOneWidget);
      await tester.tap(find.text('Review checklist'));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsNWidgets(3));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Checklist save, missing filter, appointment pocket card validation and reset',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() => controller.changeLanguage('en'));
      final service = fixture().service('pnp');
      await tester.pumpWidget(
        AppScope(
          catalog: fixture(),
          controller: controller,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => MaterialApp(
              localizationsDelegates: const TuDokLocalizations().delegates,
              supportedLocales: const TuDokLocalizations().locales,
              home: ChecklistScreen(service: service, packing: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('PhilID / ePhilID'), findsOneWidget);
      await tester.tap(find.byType(Checkbox).first);
      await tester.runAsync(() async {
        while (controller.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 prepared'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsNWidgets(2));

      // Appointment pocket card validation: empty and invalid characters rejected
      final saveBtn = find.byKey(
        const ValueKey<String>('appointment-save-button'),
      );
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(
        find.text('Enter your reference number before saving.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('appointment-ref-field')),
        'BAD<REF>!',
      );
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Use only letters, numbers, spaces, hyphens, underscores, or slashes.',
        ),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('appointment-ref-field')),
        'NPCS-2026-4455',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('appointment-schedule-field')),
        'Dec 6, 9:00 AM · Lipa',
      );
      await tester.runAsync(() async {
        await tester.tap(saveBtn);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('NPCS-2026-4455'), findsOneWidget);
      expect(find.text('Dec 6, 9:00 AM · Lipa'), findsOneWidget);
      expect(controller.appointment('pnp')?.referenceNo, 'NPCS-2026-4455');

      // Edit and clear saved appointment
      await tester.tap(
        find.byKey(const ValueKey<String>('appointment-edit-button')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('appointment-ref-field')),
        'NPCS-2026-9900',
      );
      await tester.runAsync(() async {
        await tester.tap(saveBtn);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('NPCS-2026-9900'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(
          find.byKey(const ValueKey<String>('appointment-clear-button')),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(controller.appointment('pnp'), isNull);

      await tester.ensureVisible(find.text('Reset checklist'));
      await tester.tap(find.text('Reset checklist'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Reset checklist').last);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        while (controller.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();
      expect(controller.prepared, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Resume opens packing and saved guides move between groups', (
    tester,
  ) async {
    final catalog = fixture();
    await tester.runAsync(() async {
      await controller.changeLanguage('en');
      await controller.toggle(
        'pnp',
        catalog.service('pnp').requirements.first.id,
        true,
      );
    });
    await tester.pumpWidget(TuDokApp(catalog: catalog, controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Continue preparing'), findsOneWidget);
    await tester.tap(find.text('National Police Clearance').first);
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNWidgets(3));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final r in catalog.service('pnp').requirements) {
        await controller.toggle('pnp', r.id, true);
      }
      await controller.toggle(
        'nbi',
        catalog.service('nbi').requirements.first.id,
        true,
      );
    });
    await tester.tap(find.byIcon(Icons.checklist_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Prepared'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    await tester.runAsync(() async {
      await controller.reset('pnp');
      await controller.reset('nbi');
    });
    await tester.pumpAndSettle();
    expect(find.text('Explore the journeys'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Small phone with 200% text has no layout errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => controller.changeLanguage('fil'));
    await tester.pumpWidget(
      TuDokApp(catalog: fixture(), controller: controller),
    );
    await tester.pumpAndSettle();
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Capture actual rendered home and roadmap screenshots', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => controller.changeLanguage('en'));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: TuDokApp(catalog: fixture(), controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await tester.runAsync(() => boundary.toImage());
      final bytes = await tester.runAsync(
        () => image!.toByteData(format: ImageByteFormat.png),
      );
      await tester.runAsync(() async {
        final file = File('docs/screenshots/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      });
      image!.dispose();
    }

    await capture('home-en');
    await tester.runAsync(() => controller.changeLanguage('fil'));
    await tester.pumpAndSettle();
    await capture('home-fil');
    await tester.runAsync(() => controller.changeLanguage('en'));
    await tester.pumpAndSettle();
    final target = find.byKey(const ValueKey<String>('service-pnp')).first;
    await tester.tap(target);
    await tester.pumpAndSettle();
    await capture('pnp-roadmap');
    await tester.pumpWidget(const SizedBox());
  });
}
