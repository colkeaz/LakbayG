import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tudok/domain.dart';
import 'package:tudok/main.dart';
import 'package:tudok/storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android SQLite persistence and bilingual application smoke', (
    tester,
  ) async {
    final catalog = await ServiceRepository().load();
    final store = await LocalStore.open();
    final checklists = ChecklistRepository(store);
    final original = await checklists.read();
    final settings = SettingsRepository(store);
    final originalLanguage = await settings.language();
    final controller = AppController(checklists, settings);
    try {
      await controller.initialize();
      await controller.changeLanguage('en');
      await tester.pumpWidget(
        TuDokApp(catalog: catalog, controller: controller),
      );
      await tester.pumpAndSettle();
      expect(find.text('Find the right service'), findsOneWidget);
      await controller.toggle('pnp', 'pnp-id-v1', false);
      for (final label in [
        'Find the right service',
        'A clearance',
        'Continue',
        'National Police Clearance (PNP)',
        'Continue',
        'Yes — standard first-time application',
        'Continue',
        'View roadmap',
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(find.text('Prepare my checklist'), 300);
      await tester.tap(find.text('Prepare my checklist'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      while (controller.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(controller.checked('pnp', 'pnp-id-v1'), isTrue);
      final restored = AppController(checklists, settings);
      await restored.initialize();
      expect(restored.checked('pnp', 'pnp-id-v1'), isTrue);
      restored.dispose();
      await controller.changeLanguage('fil');
      await tester.pumpAndSettle();
      expect(find.text('Mga Checklist'), findsOneWidget);
      expect(
        (tester.widget(find.byType(Checkbox).first) as Checkbox).value,
        isTrue,
      );
      while (find.byType(BackButton).evaluate().isNotEmpty) {
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Mga Checklist'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 handa'), findsOneWidget);
      await tester.tap(find.text('Lokal na kopya ng tala ng kapanganakan'));
      await tester.pumpAndSettle();
      expect(find.text('Kailangan ng opisyal na kumpirmasyon'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tungkol at Mga Setting'));
      await tester.pumpAndSettle();
      expect(find.text('Tungkol sa TuDok'), findsOneWidget);
      await tester.pumpWidget(const Placeholder());
    } finally {
      await checklists.set(
        'pnp',
        'pnp-id-v1',
        original['pnp']?.contains('pnp-id-v1') ?? false,
      );
      if (originalLanguage != null) {
        await settings.setLanguage(originalLanguage);
      } else {
        await store.database.delete(
          'settings',
          where: 'key = ?',
          whereArgs: ['language'],
        );
      }
      controller.dispose();
      await store.database.close();
    }
  });
}
