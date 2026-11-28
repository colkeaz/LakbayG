import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tudok/domain.dart';
import 'package:tudok/main.dart';
import 'package:tudok/pip.dart';
import 'package:tudok/storage.dart';

import 'localizations_helper.dart';

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
    );
    await controller.initialize();
  });
  tearDown(() async {
    controller.dispose();
    await store.database.close();
  });

  test('Bundled bilingual content validates and Taal is withheld', () {
    final c = fixture();
    expect(c.services.length, 8);
    expect(c.offices.length, 21);
    for (final s in c.services) {
      expect(c.officesFor(s.id), isNotEmpty);
    }
    expect(c.service('taal-birth').verified, false);
    expect(c.service('taal-birth').requirements, isEmpty);
    expect(c.service('taal-birth').steps, isEmpty);
  });

  test('Distance calculation and Google Maps directions URI work', () {
    const batangasCity = LatLng(13.76439, 121.06288);
    const lipa = LatLng(13.94385, 121.15040);
    final km = distanceKm(batangasCity, lipa);
    expect(km, greaterThan(15));
    expect(km, lessThan(28));
    final uri = googleMapsDirectionsUri(13.76439, 121.06288);
    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['destination'], '13.76439,121.06288');
  });

  test('PNP and NBI stay distinct; uncertain purpose gets comparison', () {
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
    final ref = fixture().referrals.firstWhere(
      (r) => r.id == 'clearance-referral',
    );
    expect(ref.compare, isNotNull);
    expect(ref.suggestedServices, ['pnp', 'nbi']);
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

  test('Malformed references, cycles, translations, and IDs are rejected', () {
    for (final change in <void Function(Map<String, dynamic>)>[
      (j) => j['services'][0]['sources'] = ['missing'],
      (j) => j['questions'][0]['choices'][0]['next'] = 'start',
      (j) => j['services'][0]['title']['fil'] = '',
      (j) => j['services'][0]['requirements'][1]['id'] =
          j['services'][0]['requirements'][0]['id'],
      (j) => j['services'][0]['steps'][1]['id'] =
          j['services'][0]['steps'][0]['id'],
      (j) => j['referrals'][0]['suggestedServices'] = ['nonexistent'],
      (j) => j['offices'][0]['serviceId'] = 'missing-service',
      (j) => j['offices'][0]['lat'] = 999,
    ]) {
      final j = jsonDecode(
        File('assets/catalog.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      change(j);
      expect(() => Catalog(j), throwsA(anything));
    }
  });

  test(
    'Checklist, steps, custom items, and tracker isolate and reload',
    () async {
      expect(await controller.toggle('pnp', 'pnp-id-v1', true), true);
      expect(await controller.toggleStep('pnp', 'pnp-step-1', true), true);
      expect(await controller.addCustomItem('pnp', '   '), false);
      expect(await controller.addCustomItem('pnp', 'Extra folder'), true);
      expect(
        await controller.saveTracker(
          'pnp',
          const ServiceTracker(
            branch: 'Batangas City PNP',
            appointmentDate: '2026-12-01',
            referenceNo: 'REF-1234',
            notes: 'Morning slot',
          ),
        ),
        true,
      );
      await controller.toggle('nbi', 'nbi-ids-v1', true);

      final restored = AppController(
        ChecklistRepository(store),
        SettingsRepository(store),
      );
      await restored.initialize();
      expect(restored.checked('pnp', 'pnp-id-v1'), true);
      expect(restored.checked('nbi', 'pnp-id-v1'), false);
      expect(restored.stepDone('pnp', 'pnp-step-1'), true);
      expect(restored.stepDone('nbi', 'pnp-step-1'), false);
      expect(restored.customItemsFor('pnp').single.text, 'Extra folder');
      expect(restored.trackerFor('pnp').referenceNo, 'REF-1234');

      final customId = restored.customItemsFor('pnp').single.id;
      expect(await restored.toggleCustomItem('pnp', customId, true), true);
      expect(restored.customItemsFor('pnp').single.prepared, true);

      await restored.reset('pnp');
      expect(restored.checked('pnp', 'pnp-id-v1'), false);
      expect(restored.stepDone('pnp', 'pnp-step-1'), false);
      expect(restored.customItemsFor('pnp').single.prepared, false);
      expect(restored.trackerFor('pnp').referenceNo, 'REF-1234');
      expect(restored.checked('nbi', 'nbi-ids-v1'), true);

      await restored.deleteCustomItem('pnp', customId);
      expect(restored.customItemsFor('pnp'), isEmpty);
      await restored.clearTracker('pnp');
      expect(restored.trackerFor('pnp').isEmpty, true);
      restored.dispose();
    },
  );

  test('SQLite v2 data survives closing and reopening the database', () async {
    final folder = await Directory.systemTemp.createTemp('tudok-test-');
    final path = '${folder.path}/test.db';
    final disk = await LocalStore.open(
      factory: databaseFactoryFfi,
      location: path,
    );
    final repo = ChecklistRepository(disk);
    await repo.set('pnp', 'pnp-id-v1', true);
    await repo.setStep('pnp', 'pnp-step-1', true);
    final item = await repo.addCustomItem('pnp', 'Ballpen');
    await repo.setCustomItem(item.id, true);
    await repo.saveTracker(
      'pnp',
      const ServiceTracker(branch: 'Taal PNP', referenceNo: 'ABC-99'),
    );
    await SettingsRepository(disk).setLanguage('fil');
    await disk.database.close();

    final reopened = await LocalStore.open(
      factory: databaseFactoryFfi,
      location: path,
    );
    final reopenedRepo = ChecklistRepository(reopened);
    expect((await reopenedRepo.read())['pnp'], contains('pnp-id-v1'));
    expect((await reopenedRepo.readSteps())['pnp'], contains('pnp-step-1'));
    expect(
      (await reopenedRepo.readCustomItems())['pnp']!.single.prepared,
      true,
    );
    expect((await reopenedRepo.readTrackers())['pnp']!.branch, 'Taal PNP');
    expect(await SettingsRepository(reopened).language(), 'fil');
    await reopened.database.close();
    await folder.delete(recursive: true);
  });

  test('SQLite v1 database upgrades safely to v2 without data loss', () async {
    final folder = await Directory.systemTemp.createTemp('tudok-v1-');
    final path = '${folder.path}/legacy.db';
    final legacyDb = await databaseFactoryFfi.openDatabase(
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
        },
      ),
    );
    await legacyDb.insert('checklist', {
      'service': 'pnp',
      'requirement': 'pnp-id-v1',
    });
    await legacyDb.insert('settings', {'key': 'language', 'value': 'fil'});
    await legacyDb.close();

    final upgraded = await LocalStore.open(
      factory: databaseFactoryFfi,
      location: path,
    );
    final repo = ChecklistRepository(upgraded);
    expect((await repo.read())['pnp'], contains('pnp-id-v1'));
    expect(await SettingsRepository(upgraded).language(), 'fil');
    await repo.setStep('pnp', 'pnp-step-1', true);
    expect((await repo.readSteps())['pnp'], contains('pnp-step-1'));
    await upgraded.database.close();
    await folder.delete(recursive: true);
  });

  test(
    'Concurrent controller writes are serialized without dropping',
    () async {
      final results = await Future.wait([
        controller.toggle('pnp', 'pnp-id-v1', true),
        controller.toggle('pnp', 'pnp-payment-v1', true),
        controller.toggleStep('pnp', 'pnp-step-1', true),
      ]);
      expect(results, everyElement(isTrue));
      expect(controller.checked('pnp', 'pnp-id-v1'), true);
      expect(controller.checked('pnp', 'pnp-payment-v1'), true);
      expect(controller.stepDone('pnp', 'pnp-step-1'), true);
    },
  );

  test(
    'Failed writes leave prepared state unchanged and allow retry',
    () async {
      final failed = AppController(
        FailingChecklist(store),
        SettingsRepository(store),
      );
      await failed.initialize();
      expect(await failed.toggle('pnp', 'pnp-id-v1', true), false);
      expect(failed.checked('pnp', 'pnp-id-v1'), false);
      expect(failed.busy, false);
      expect(await failed.toggleStep('pnp', 'pnp-step-1', true), true);
      expect(failed.stepDone('pnp', 'pnp-step-1'), true);
      failed.dispose();
    },
  );

  testWidgets('Language onboarding shows bilingual prompt and persists', (
    tester,
  ) async {
    await tester.pumpWidget(
      TuDokApp(catalog: fixture(), controller: controller),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget);
    expect(
      find.text('Choose your language / Piliin ang iyong wika'),
      findsOneWidget,
    );
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
    'Questionnaire validation, progress bar, comparison, and language switch',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() => controller.changeLanguage('en'));
      await tester.pumpWidget(
        TuDokApp(catalog: fixture(), controller: controller),
      );
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
      await tester.tap(find.text('Hindi tinukoy / ikumpara ang dalawa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Magpatuloy'));
      await tester.pumpAndSettle();
      expect(find.text('Mabilis na paghahambing'), findsOneWidget);
      expect(find.text('Mga kaugnay na gabay'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Taal unverified guide hides What to bring tab', (tester) async {
    await tester.runAsync(() => controller.changeLanguage('en'));
    final taal = fixture().service('taal-birth');
    await tester.pumpWidget(
      AppScope(
        catalog: fixture(),
        controller: controller,
        child: MaterialApp(
          localizationsDelegates: const TuDokLocalizations().delegates,
          supportedLocales: const TuDokLocalizations().locales,
          home: ChecklistScreen(service: taal, packing: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('What to bring'), findsNothing);
    expect(find.text('Official confirmation needed'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Home search by keyword and category chip filtering work', (
    tester,
  ) async {
    await tester.runAsync(() => controller.changeLanguage('en'));
    await tester.pumpWidget(
      TuDokApp(catalog: fixture(), controller: controller),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'first job');
    await tester.pumpAndSettle();
    expect(find.text('SSS Number (First-Time Registration)'), findsOneWidget);
    expect(find.text('Philippine Passport (New Adult)'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Gov IDs'));
    await tester.pumpAndSettle();
    expect(find.text('Philippine Passport (New Adult)'), findsOneWidget);
    expect(find.text('National ID (PhilSys)'), findsOneWidget);
    expect(find.text('National Police Clearance'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Guide steps toggle, custom item add, missing filter, and confirmed reset',
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
              home: ChecklistScreen(service: service, packing: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 / 4 steps done'), findsWidgets);
      await tester.tap(find.text('1'));
      await tester.runAsync(() async {
        while (controller.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('1 / 4 steps done'), findsWidgets);

      await tester.tap(find.text('What to bring'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.runAsync(() async {
        while (controller.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('1 / 4 prepared'), findsOneWidget);

      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '2x2 Photo');
      await tester.tap(find.text('Add'));
      await tester.runAsync(() async {
        while (controller.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('2x2 Photo'), findsOneWidget);
      expect(find.text('1 / 5 prepared'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsNWidgets(4));

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
      expect(controller.completedSteps, isEmpty);
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
    expect(find.byType(Checkbox), findsNWidgets(4));
    await tester.tap(find.byType(BackButton));
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

  testWidgets('Perched Pip follows the packing state in both languages', (
    tester,
  ) async {
    final catalog = fixture();
    final service = catalog.service('pnp');
    final lastId = service.requirements.last.id;
    await tester.runAsync(() async {
      await controller.changeLanguage('en');
      for (final item in service.requirements) {
        await controller.toggle(service.id, item.id, true);
      }
    });
    await tester.pumpWidget(TuDokApp(catalog: catalog, controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.checklist_outlined).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(service.title.en));
    await tester.pumpAndSettle();
    final perched = find.byWidgetPredicate(
      (widget) => widget is Pip && widget.pose == PipPose.perch,
    );
    for (final language in ['en', 'fil']) {
      await tester.runAsync(() => controller.changeLanguage(language));
      await tester.pumpAndSettle();
      final message = tester.element(find.byType(ChecklistScreen)).l.complete;
      expect(find.text(message), findsOneWidget);
      expect(perched, findsOneWidget);
      final image = tester.widget<Image>(
        find.descendant(of: perched, matching: find.byType(Image)),
      );
      expect((image.image as AssetImage).assetName, 'assets/pip/perch.png');
      expect(image.excludeFromSemantics, isTrue);
      await tester.runAsync(() => controller.toggle(service.id, lastId, false));
      await tester.pumpAndSettle();
      expect(perched, findsNothing);
      expect(find.text(message), findsNothing);
      await tester.runAsync(() => controller.toggle(service.id, lastId, true));
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Office map filters, GPS fallback, and Use as my branch work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await controller.changeLanguage('en');
      await controller.saveTracker(
        'pnp',
        const ServiceTracker(referenceNo: 'KEEP-REF-77'),
      );
    });

    var denyNext = false;
    await tester.pumpWidget(
      AppScope(
        catalog: fixture(),
        controller: controller,
        child: MaterialApp(
          localizationsDelegates: const TuDokLocalizations().delegates,
          supportedLocales: const TuDokLocalizations().locales,
          home: Scaffold(
            body: OfficeMapView(
              showTiles: false,
              locateOverride: () async => denyNext
                  ? const LocationResult(LocationOutcome.permissionDenied)
                  : const LocationResult(
                      LocationOutcome.ok,
                      LatLng(13.76439, 121.06288),
                    ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    expect(find.text('Batangas City Police Station'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Taal'));
    await tester.pumpAndSettle();
    expect(find.text('Taal Municipal Police Station'), findsOneWidget);
    expect(find.text('Lipa City Police Station'), findsNothing);

    await tester.tap(find.text('Locate me'));
    await tester.pumpAndSettle();
    expect(find.textContaining('km away'), findsWidgets);

    denyNext = true;
    await tester.tap(find.text('Locate me'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Location permission denied. You can still browse and filter offices.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Taal Municipal Police Station'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use as my branch'));
    await tester.runAsync(() async {
      while (controller.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await tester.pumpAndSettle();

    expect(
      controller.trackerFor('pnp').branch,
      'Taal Municipal Police Station',
    );
    expect(controller.trackerFor('pnp').referenceNo, 'KEEP-REF-77');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Guide opens pre-filtered OfficeMapScreen', (tester) async {
    await tester.runAsync(() => controller.changeLanguage('en'));
    final pnp = fixture().service('pnp');
    await tester.pumpWidget(
      AppScope(
        catalog: fixture(),
        controller: controller,
        child: MaterialApp(
          localizationsDelegates: const TuDokLocalizations().delegates,
          supportedLocales: const TuDokLocalizations().locales,
          home: ChecklistScreen(service: pnp),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('View offices on map (4)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('View offices on map (4)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View offices on map (4)'));
    await tester.pumpAndSettle();
    expect(find.text('Government Offices'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('pin-pnp-taal')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Small phone with 200% text has no layout errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.runAsync(() => controller.changeLanguage('fil'));
    await tester.pumpWidget(
      TuDokApp(catalog: fixture(), controller: controller),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.map_outlined).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Listahan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.home_outlined).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hanapin ang tamang serbisyo'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('service-pnp')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('service-pnp')),
      warnIfMissed: false,
    );
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
    await tester.tap(find.byIcon(Icons.map_outlined).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    await capture('office-map');
    await tester.tap(find.byIcon(Icons.home_outlined).last);
    await tester.pumpAndSettle();
    final target = find.byKey(const ValueKey<String>('service-pnp')).first;
    await tester.tap(target);
    await tester.pumpAndSettle();
    await capture('pnp-roadmap');
    await tester.pumpWidget(const SizedBox());
  });
}
