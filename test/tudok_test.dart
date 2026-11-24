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
    expect(c.services.length, 3);
    expect(c.service('taal-birth').verified, false);
    expect(c.service('taal-birth').requirements, isEmpty);
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
  test('SQLite data survives closing and reopening the database', () async {
    final folder = await Directory.systemTemp.createTemp('tudok-test-');
    final path = '${folder.path}/test.db';
    final disk = await LocalStore.open(
      factory: databaseFactoryFfi,
      location: path,
    );
    await ChecklistRepository(disk).set('pnp', 'pnp-id-v1', true);
    await SettingsRepository(disk).setLanguage('fil');
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
    await reopened.database.close();
    await folder.delete(recursive: true);
  });
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
      failed.dispose();
    },
  );
  testWidgets('Language onboarding persists Filipino choice', (tester) async {
    await tester.pumpWidget(
      LakbayGApp(catalog: fixture(), controller: controller),
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
    'Questionnaire validation and language switch preserve selection',
    (tester) async {
      await tester.runAsync(() => controller.changeLanguage('en'));
      await tester.pumpWidget(
        LakbayGApp(catalog: fixture(), controller: controller),
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
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Checklist save, missing filter, completion and confirmed reset',
    (tester) async {
      await tester.runAsync(() => controller.changeLanguage('en'));
      final service = fixture().service('pnp');
      await tester.pumpWidget(
        AppScope(
          catalog: fixture(),
          controller: controller,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => MaterialApp(
              localizationsDelegates: const LakbayGLocalizations().delegates,
              supportedLocales: const LakbayGLocalizations().locales,
              home: ChecklistScreen(service: service),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byType(Checkbox).first);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 prepared'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsNWidgets(2));
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
  testWidgets('Small phone with 200% text has no layout errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => controller.changeLanguage('fil'));
    await tester.pumpWidget(
      LakbayGApp(catalog: fixture(), controller: controller),
    );
    await tester.pumpAndSettle();
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Bottom navigation tabs, empty state visibility, and unverified service routing',
    (tester) async {
      await tester.runAsync(() => controller.changeLanguage('en'));
      await tester.pumpWidget(
        LakbayGApp(catalog: fixture(), controller: controller),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Checklists'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Your preparation starts here. Open a journey to build its checklist.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Local birth-record copy'));
      await tester.pumpAndSettle();
      expect(find.text('Official confirmation needed'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('National Police Clearance'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byType(Checkbox).first);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Your preparation starts here. Open a journey to build its checklist.',
        ),
        findsNothing,
      );
      expect(find.text('1 / 3 prepared'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Cancel reset keeps items, and failed save shows error SnackBar',
    (tester) async {
      await tester.runAsync(() => controller.changeLanguage('en'));
      await tester.runAsync(() => controller.toggle('pnp', 'pnp-id-v1', true));
      final service = fixture().service('pnp');
      await tester.pumpWidget(
        AppScope(
          catalog: fixture(),
          controller: controller,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => MaterialApp(
              localizationsDelegates: const LakbayGLocalizations().delegates,
              supportedLocales: const LakbayGLocalizations().locales,
              home: ChecklistScreen(service: service),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 prepared'), findsOneWidget);
      await tester.ensureVisible(find.text('Reset checklist'));
      await tester.tap(find.text('Reset checklist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 prepared'), findsOneWidget);

      final failing = AppController(
        FailingChecklist(store),
        SettingsRepository(store),
      );
      await tester.runAsync(() => failing.initialize());
      await tester.pumpWidget(
        AppScope(
          catalog: fixture(),
          controller: failing,
          child: ListenableBuilder(
            listenable: failing,
            builder: (context, _) => MaterialApp(
              localizationsDelegates: const LakbayGLocalizations().delegates,
              supportedLocales: const LakbayGLocalizations().locales,
              home: ChecklistScreen(service: service),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byType(Checkbox).at(1));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Could not save. Your previous saved state is unchanged. Please try again.',
        ),
        findsOneWidget,
      );
      expect(failing.checked('pnp', 'pnp-payment-v1'), false);
      await tester.pumpWidget(const SizedBox());
      failing.dispose();
    },
  );
  testWidgets(
    'Settings segmented language switch, sources list, and offline link fallback dialog',
    (tester) async {
      await tester.runAsync(() => controller.changeLanguage('en'));
      await tester.pumpWidget(
        LakbayGApp(catalog: fixture(), controller: controller),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('About & Settings'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Filipino'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('Tungkol sa LakbayG'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('English'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('About LakbayG'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('PNP application tutorial'),
        200,
        scrollable: find.descendant(
          of: find.byType(SettingsView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('PNP application tutorial'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Could not open the link. Copy it and try in your browser when connected.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('https://pnpclearance.ph/how_to_apply_v2.pdf'),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Navigator back button steps through question history before popping',
    (tester) async {
      await tester.runAsync(() => controller.changeLanguage('en'));
      await tester.pumpWidget(
        LakbayGApp(catalog: fixture(), controller: controller),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Find the right service'));
      await tester.pumpAndSettle();
      expect(find.text('What do you need help with?'), findsOneWidget);
      await tester.tap(find.text('A clearance'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Which clearance does the requesting institution specify?'),
        findsOneWidget,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('What do you need help with?'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Find the right service'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Capture actual rendered home and roadmap screenshots', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => controller.changeLanguage('en'));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: LakbayGApp(catalog: fixture(), controller: controller),
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
    await tester.scrollUntilVisible(
      find.text('National Police Clearance'),
      200,
    );
    await tester.tap(find.text('National Police Clearance'));
    await tester.pumpAndSettle();
    await capture('pnp-roadmap');
    await tester.pumpWidget(const SizedBox());
  });
}
