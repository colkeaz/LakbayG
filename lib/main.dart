import 'package:flutter/material.dart';

import 'domain.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'storage.dart';
import 'theme.dart';

export 'location_service.dart';
export 'screens/guide_screen.dart';
export 'screens/home_screen.dart';
export 'screens/map_screen.dart';
export 'screens/navigator_screen.dart';
export 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<(Catalog, AppController)> loading;
  @override
  void initState() {
    super.initState();
    loading = load();
  }

  Future<(Catalog, AppController)> load() async {
    final catalog = await ServiceRepository().load();
    final store = await LocalStore.open();
    final controller = AppController(
      ChecklistRepository(store),
      SettingsRepository(store),
    );
    await controller.initialize();
    return (catalog, controller);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return TuDokApp(
          catalog: snapshot.data!.$1,
          controller: snapshot.data!.$2,
        );
      }
      return MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: snapshot.hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppLocalizations.of(context)!.loadError),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => setState(() => loading = load()),
                            child: Text(AppLocalizations.of(context)!.retry),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class TuDokApp extends StatelessWidget {
  final Catalog catalog;
  final AppController controller;
  const TuDokApp({super.key, required this.catalog, required this.controller});
  @override
  Widget build(BuildContext context) => AppScope(
    catalog: catalog,
    controller: controller,
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        title: 'LakbayG',
        debugShowCheckedModeBanner: false,
        locale: Locale(controller.language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(),
        home: controller.firstLaunch
            ? const LanguageScreen()
            : const HomeShell(),
      ),
    ),
  );
}
