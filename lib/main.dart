import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'domain.dart';
import 'storage.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Bootstrap());
}

/// A single-hue blue system: deep navy for anchors, one primary blue for
/// actions, and soft blue tints for grouping. No gradients, no competing
/// accent colors — flat values stay calm and readable for low-vision users.
abstract final class Palette {
  static const background = Color(0xffF2F6FC);
  static const surface = Colors.white;
  static const ink = Color(0xff142A47);
  static const muted = Color(0xff4E6686);
  static const primary = Color(0xff1B4E91);
  static const navy = Color(0xff143866);
  static const blueSoft = Color(0xffE6EFFA);
  static const blueWarn = Color(0xffCFE0F5);
  static const line = Color(0xffDDE7F4);
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
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Palette.background,
          colorScheme: ColorScheme.fromSeed(seedColor: Palette.primary),
        ),
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

class AppScope extends InheritedNotifier<AppController> {
  final Catalog catalog;
  const AppScope({
    super.key,
    required this.catalog,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);
  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;
}

extension ViewContext on BuildContext {
  AppController get state => AppScope.of(this).notifier!;
  Catalog get catalog => AppScope.of(this).catalog;
  AppLocalizations get l => AppLocalizations.of(this)!;
  String tr(LocalText value) => value.at(state.language);
  void open(Widget screen) =>
      Navigator.of(this).push(MaterialPageRoute<void>(builder: (_) => screen));
  void saveResult(bool success) {
    if (!success && mounted) {
      ScaffoldMessenger.of(this)
          .showSnackBar(SnackBar(content: Text(l.saveError)));
    }
  }
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
        title: 'TuDok',
        debugShowCheckedModeBanner: false,
        locale: Locale(controller.language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Palette.primary),
          scaffoldBackgroundColor: Palette.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: Palette.background,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Palette.ink,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Palette.surface,
            surfaceTintColor: Colors.transparent,
            margin: const EdgeInsets.symmetric(vertical: 7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Palette.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Palette.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Palette.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Palette.primary, width: 1.5),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Palette.surface,
            surfaceTintColor: Colors.transparent,
            indicatorColor: Palette.blueSoft,
            height: 72,
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Palette.ink,
              ),
            ),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontSize: 18, color: Palette.ink, height: 1.4),
            bodyMedium: TextStyle(fontSize: 16, color: Palette.ink, height: 1.4),
            bodySmall: TextStyle(
              fontSize: 14,
              color: Palette.muted,
              height: 1.35,
            ),
          ),
        ),
        home: controller.firstLaunch
            ? const LanguageScreen()
            : const HomeShell(),
      ),
    ),
  );
}

/// Flat rounded container used instead of cards where a soft tint helps
/// group related information without adding visual noise.
class SoftTile extends StatelessWidget {
  final Color color;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SoftTile({
    super.key,
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 72,
                  color: Palette.primary,
                ),
                const SizedBox(height: 20),
                const Text(
                  'TuDok',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l.chooseLanguage,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l.languageHelp,
                  style: const TextStyle(fontSize: 16, color: Palette.muted),
                ),
                const SizedBox(height: 28),
                for (final item in [('en', 'English'), ('fil', 'Filipino')])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: context.state.busy
                            ? null
                            : () async {
                                final ok = await context.state.changeLanguage(
                                  item.$1,
                                );
                                if (context.mounted) {
                                  context.saveResult(ok);
                                }
                              },
                        child: Text(
                          item.$2,
                          style: const TextStyle(fontSize: 17),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('TuDok'),
      actions: const [LanguageMenu()],
    ),
    body: IndexedStack(
      index: index,
      children: [
        HomeView(onTab: (value) => setState(() => index = value)),
        const ChecklistsView(),
        const SettingsView(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: context.l.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.checklist_outlined),
          label: context.l.checklists,
        ),
        NavigationDestination(
          icon: const Icon(Icons.info_outline),
          label: context.l.settings,
        ),
      ],
    ),
  );
}

class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key});
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: context.l.language,
    icon: const Icon(Icons.translate, color: Palette.primary),
    onSelected: (value) async {
      final ok = await context.state.changeLanguage(value);
      if (context.mounted) {
        context.saveResult(ok);
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'en', child: Text('English')),
      PopupMenuItem(value: 'fil', child: Text('Filipino')),
    ],
  );
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ],
  );
}

class Section extends StatelessWidget {
  final String title;
  const Section(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Palette.ink,
      ),
    ),
  );
}

class Notice extends StatelessWidget {
  final String text;
  final bool warning;
  const Notice(this.text, {super.key, this.warning = false});
  @override
  Widget build(BuildContext context) => SoftTile(
    color: warning ? Palette.blueWarn : Palette.blueSoft,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 22, color: Palette.ink),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Palette.ink, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

Future<void> pickLanguage(BuildContext context) async {
  final value = await showDialog<String>(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(c.l.chooseLanguage),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(c, 'en'),
          child: const Text('English'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(c, 'fil'),
          child: const Text('Filipino'),
        ),
      ],
    ),
  );
  if (!context.mounted || value == null || value == context.state.language) {
    return;
  }
  context.saveResult(await context.state.changeLanguage(value));
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 112),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28, color: Palette.primary),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class HomeView extends StatefulWidget {
  final ValueChanged<int> onTab;
  const HomeView({super.key, required this.onTab});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final state = context.state;
    final services = context.catalog.services.where((s) {
      if (query.trim().isEmpty) return true;
      final q = query.trim().toLowerCase();
      return context.tr(s.title).toLowerCase().contains(q) ||
          s.agency.toLowerCase().contains(q);
    }).toList();
    final total = context.catalog.services.fold<int>(
      0,
      (n, s) => n + s.requirements.length,
    );
    final done = context.catalog.services.fold<int>(
      0,
      (n, s) =>
          n + s.requirements.where((r) => state.checked(s.id, r.id)).length,
    );
    final started = context.catalog.services
        .where((s) => s.requirements.any((r) => state.checked(s.id, r.id)))
        .length;

    return PageBody(
      children: [
        Text(
          l.greeting,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Palette.ink,
          ),
        ),
        SoftTile(
          color: Palette.navy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    size: 22,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l.progress,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$done / $total ${l.itemsReady}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 10,
                  backgroundColor: Colors.white54,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$started ${l.guidesStarted}',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
        Section(l.quickActions),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _QuickAction(
                icon: Icons.search_rounded,
                label: l.findService,
                color: Palette.blueSoft,
                onTap: () => context.open(NavigatorScreen()),
              ),
              const SizedBox(width: 10),
              _QuickAction(
                icon: Icons.checklist_rounded,
                label: l.myGuides,
                color: Palette.blueSoft,
                onTap: () => widget.onTab(1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _QuickAction(
                icon: Icons.translate_rounded,
                label: l.language,
                color: Palette.blueSoft,
                onTap: () => pickLanguage(context),
              ),
              const SizedBox(width: 10),
              _QuickAction(
                icon: Icons.info_outline_rounded,
                label: l.settings,
                color: Palette.blueSoft,
                onTap: () => widget.onTab(2),
              ),
            ],
          ),
        ),
        Section(l.explore),
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: InputDecoration(
            hintText: l.searchHint,
            prefixIcon: const Icon(Icons.search_rounded, color: Palette.muted),
          ),
        ),
        const SizedBox(height: 8),
        if (services.isEmpty)
          SoftTile(color: Palette.surface, child: Text(l.noResults)),
        for (final s in services) ServiceCard(service: s),
        Notice(l.studentNotice),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final Service service;
  final bool checklist;
  const ServiceCard({super.key, required this.service, this.checklist = false});
  @override
  Widget build(BuildContext context) {
    final s = service;
    final count = s.requirements
        .where((r) => context.state.checked(s.id, r.id))
        .length;
    return Card(
      child: ListTile(
        key: ValueKey<String>('service-${s.id}'),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Palette.blueSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            s.id == 'taal-birth'
                ? Icons.description_outlined
                : s.id == 'pnp'
                ? Icons.local_police_outlined
                : Icons.badge_outlined,
            color: Palette.primary,
            size: 24,
          ),
        ),
        title: Text(
          context.tr(s.title),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Palette.ink,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            !s.verified
                ? context.l.pending
                : checklist
                ? '$count / ${s.requirements.length} ${context.l.prepared}'
                : s.agency,
            style: const TextStyle(fontSize: 14, color: Palette.muted),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Palette.muted),
        onTap: () => context.open(ChecklistScreen(service: s)),
      ),
    );
  }
}

class ChecklistsView extends StatelessWidget {
  const ChecklistsView({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Section(context.l.checklists),
      SoftTile(
        color: Palette.blueSoft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline, size: 22, color: Palette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l.empty,
                style: const TextStyle(fontSize: 15, color: Palette.ink),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      for (final s in context.catalog.services)
        ServiceCard(service: s, checklist: true),
    ],
  );
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Section(context.l.about),
      SoftTile(
        color: Palette.surface,
        child: Text(
          context.l.aboutBody,
          style: const TextStyle(fontSize: 16, color: Palette.ink, height: 1.5),
        ),
      ),
      Section(context.l.language),
      SoftTile(
        color: Palette.surface,
        child: SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'en', label: Text('English')),
            ButtonSegment(value: 'fil', label: Text('Filipino')),
          ],
          selected: {context.state.language},
          onSelectionChanged: context.state.busy
              ? null
              : (values) async {
                  final ok = await context.state.changeLanguage(values.first);
                  if (context.mounted) {
                    context.saveResult(ok);
                  }
                },
        ),
      ),
      Notice(context.l.studentNotice),
      Notice(context.l.reviewNotice, warning: true),
      SoftTile(
        color: Palette.blueSoft,
        child: Row(
          children: [
            const Icon(Icons.wifi_off, size: 20, color: Palette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l.linksNeedInternet,
                style: const TextStyle(fontSize: 15, color: Palette.ink),
              ),
            ),
          ],
        ),
      ),
      Section(context.l.sources),
      for (final s in context.catalog.sources) SourceCard(source: s),
    ],
  );
}

class SourceCard extends StatelessWidget {
  final Source source;
  const SourceCard({super.key, required this.source});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      title: Text(
        source.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${context.l.lastChecked}: ${source.checked}'),
      trailing: const Icon(Icons.open_in_new, color: Palette.muted),
      onTap: () => openOfficial(context, source.url),
    ),
  );
}

Future<void> openOfficial(BuildContext context, String url) async {
  bool opened = false;
  try {
    opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    opened = false;
  }
  if (opened || !context.mounted) {
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(c.l.linkError),
      content: SelectableText(url),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (c.mounted) {
              Navigator.pop(c);
            }
          },
          child: Text(c.l.copyLink),
        ),
        TextButton(onPressed: () => Navigator.pop(c), child: Text(c.l.close)),
      ],
    ),
  );
}

/// One screen for the whole journey: where to go, the steps, and what to
/// bring. Previously the steps lived on a separate roadmap screen that was
/// lost as soon as the user opened their checklist.
class ChecklistScreen extends StatefulWidget {
  final Service service;
  const ChecklistScreen({super.key, required this.service});
  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  bool missing = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final state = context.state;
    final l = context.l;
    final count = s.requirements.where((r) => state.checked(s.id, r.id)).length;
    final total = s.requirements.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.checklists),
        actions: const [LanguageMenu()],
      ),
      body: PageBody(
        children: [
          SoftTile(
            color: Palette.navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(s.title),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.agency,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      icon: s.verified ? Icons.verified_outlined : Icons.schedule,
                      label: s.verified ? l.sourceChecked : l.pending,
                    ),
                    _Chip(
                      icon: Icons.numbers,
                      label: '${s.steps.length} ${l.steps}',
                    ),
                    _Chip(
                      icon: Icons.checklist_outlined,
                      label: '$total ${l.whatToBring}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Section(l.location),
          SoftTile(
            color: Palette.blueSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, size: 22, color: Palette.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(s.location),
                    style: const TextStyle(fontSize: 16, color: Palette.ink),
                  ),
                ),
              ],
            ),
          ),
          if (s.verified && s.steps.isNotEmpty) ...[
            Section(l.steps),
            for (final (index, step) in s.steps.indexed)
              SoftTile(
                color: Palette.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Palette.blueSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Palette.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr(step.title),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Palette.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr(step.detail),
                      style: const TextStyle(fontSize: 16, color: Palette.ink),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: Palette.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l.goTo}: ${context.tr(step.place)}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Palette.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
          Section(l.scope),
          Text(
            context.tr(s.summary),
            style: const TextStyle(fontSize: 16, color: Palette.ink),
          ),
          Notice(context.tr(s.notice), warning: true),
          Section(l.whatToBring),
          SoftTile(
            color: Palette.blueSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count / $total ${l.prepared}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : count / total,
                    minHeight: 10,
                    backgroundColor: Palette.surface,
                    color: Palette.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${total - count} ${l.remaining}',
                  style: const TextStyle(fontSize: 14, color: Palette.muted),
                ),
              ],
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l.missingOnly,
              style: const TextStyle(fontSize: 16, color: Palette.ink),
            ),
            value: missing,
            onChanged: (v) => setState(() => missing = v),
          ),
          for (final r in s.requirements.where(
            (r) => !missing || !state.checked(s.id, r.id),
          ))
            Card(
              child: CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  context.tr(r.text),
                  style: const TextStyle(fontSize: 16, color: Palette.ink),
                ),
                value: state.checked(s.id, r.id),
                onChanged: state.busy
                    ? null
                    : (value) async {
                        final ok = await state.toggle(
                          s.id,
                          r.id,
                          value ?? false,
                        );
                        if (context.mounted) {
                          context.saveResult(ok);
                        }
                      },
              ),
            ),
          if (total > 0 && count == total) Notice(l.complete),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: state.busy
                  ? null
                  : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text(c.l.resetConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: Text(c.l.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: Text(c.l.reset),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final ok = await state.reset(s.id);
                        if (context.mounted) {
                          context.saveResult(ok);
                        }
                      }
                    },
              icon: const Icon(Icons.restart_alt),
              label: Text(l.reset),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => openOfficial(context, s.url),
              icon: const Icon(Icons.open_in_new),
              label: Text(l.openOfficial),
            ),
          ),
          Section(l.sources),
          for (final id in s.sources)
            SourceCard(
              source: context.catalog.sources.firstWhere((r) => r.id == id),
            ),
          Notice(l.studentNotice),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Palette.surface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Palette.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Palette.ink),
        ),
      ],
    ),
  );
}

/// Longest chain of questions still reachable from [id]. Referrals and
/// services are terminals and contribute zero.
int questionsRemaining(Catalog catalog, String id) {
  final current = catalog.questions.where((q) => q.id == id);
  if (current.isEmpty) {
    return 0;
  }
  return 1 +
      current.single.choices
          .map((c) => questionsRemaining(catalog, c.next))
          .reduce((a, b) => a > b ? a : b);
}

class NavigatorScreen extends StatefulWidget {
  const NavigatorScreen({super.key});
  @override
  State<NavigatorScreen> createState() => _NavigatorScreenState();
}

class _NavigatorScreenState extends State<NavigatorScreen> {
  NavigationEngine? engine;
  bool validation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    engine ??= NavigationEngine(context.catalog);
  }

  void back() {
    setState(() {
      engine!.back();
      validation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = engine!;
    final question = e.isQuestion ? context.catalog.question(e.current) : null;
    // The questionnaire is a decision tree, not a fixed list: different
    // answers end after 1 to 4 questions. Count only the questions still
    // reachable from here so the progress bar matches the actual path.
    final remaining = questionsRemaining(context.catalog, e.current);
    final branchLength = e.position + 1 + remaining;
    final service = e.current.startsWith('service:')
        ? context.catalog.service(e.current.substring(8))
        : null;
    final referral = question == null && service == null
        ? context.catalog.referrals.firstWhere((r) => r.id == e.current)
        : null;
    return PopScope(
      canPop: e.position == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          back();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l.findService),
          leading: BackButton(
            color: Palette.primary,
            onPressed: () {
              if (e.position > 0) {
                back();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          actions: const [LanguageMenu()],
        ),
        body: PageBody(
          children: [
            if (question != null) ...[
              Text(
                context.l.questionCount(e.position + 1),
                style: const TextStyle(fontSize: 14, color: Palette.muted),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (e.position + 1) / branchLength,
                  minHeight: 10,
                  backgroundColor: Palette.line,
                  color: Palette.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                context.tr(question.text),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(height: 20),
              for (final c in question.choices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: e.answers[e.current] == c.id
                        ? Palette.blueSoft
                        : Palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() {
                        e.select(c.id);
                        validation = false;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              e.answers[e.current] == c.id
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: Palette.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                context.tr(c.text),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Palette.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (validation) Notice(context.l.selectAnswer, warning: true),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => setState(() {
                    validation = !e.next();
                  }),
                  child: Text(context.l.next),
                ),
              ),
            ] else ...[
              const Icon(Icons.explore_outlined, size: 56, color: Palette.primary),
              const SizedBox(height: 20),
              Text(
                service != null ? context.l.result : context.l.referral,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                service != null
                    ? context.l.match
                    : context.tr(referral!.reason),
                style: const TextStyle(fontSize: 16, color: Palette.ink),
              ),
              if (service != null) ...[
                Section(context.tr(service.title)),
                Text(
                  context.tr(service.summary),
                  style: const TextStyle(fontSize: 16, color: Palette.ink),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.open(ChecklistScreen(service: service)),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(context.l.openGuide),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => openOfficial(context, referral!.url),
                    child: Text(context.l.openOfficial),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => setState(() {
                e.restart();
                validation = false;
              }),
              icon: const Icon(Icons.restart_alt),
              label: Text(context.l.restart),
            ),
          ],
        ),
      ),
    );
  }
}
