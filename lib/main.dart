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
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1b4e91)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xfff6f8fc),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xfff6f8fc)),
          cardTheme: const CardThemeData(
            elevation: 0,
            margin: EdgeInsets.symmetric(vertical: 6),
            color: Colors.white,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: Colors.white,
          ),
        ),
        home: controller.firstLaunch
            ? const LanguageScreen()
            : const HomeShell(),
      ),
    ),
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
                  color: Color(0xff1b4e91),
                ),
                const SizedBox(height: 20),
                Text(
                  'TuDok',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 24),
                Text(
                  context.l.chooseLanguage,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(context.l.languageHelp),
                const SizedBox(height: 24),
                for (final item in [('en', 'English'), ('fil', 'Filipino')])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FilledButton.tonal(
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
                      child: Text(item.$2),
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
      title: const Text(
        'TuDok',
        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.7),
      ),
      actions: [const LanguageMenu()],
    ),
    body: IndexedStack(
      index: index,
      children: const [HomeView(), ChecklistsView(), SettingsView()],
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
    icon: const Icon(Icons.translate),
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
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class Notice extends StatelessWidget {
  final String text;
  final bool warning;
  const Notice(this.text, {super.key, this.warning = false});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: warning ? const Color(0xfffff1d6) : const Color(0xffe8effb),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(warning ? Icons.info_outline : Icons.shield_outlined, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xff173f77),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.explore_outlined, color: Colors.white, size: 38),
            const SizedBox(height: 22),
            Text(
              context.l.tagline,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              context.l.intro,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff173f77),
            ).let(
              (style) => FilledButton.icon(
                style: style,
                onPressed: () => context.open(const NavigatorScreen()),
                icon: const Icon(Icons.arrow_forward),
                label: Text(context.l.findService),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Wrap(
          spacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.offline_pin_outlined, size: 18),
              label: Text(context.l.offline),
            ),
          ],
        ),
      ),
      Section(context.l.explore),
      for (final s in context.catalog.services) ServiceCard(service: s),
      Notice(context.l.studentNotice),
    ],
  );
}

extension Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
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
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          s.id == 'taal-birth'
              ? Icons.description_outlined
              : s.id == 'pnp'
              ? Icons.local_police_outlined
              : Icons.badge_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          context.tr(s.title),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            !s.verified
                ? context.l.pending
                : checklist
                ? '$count / ${s.requirements.length} ${context.l.prepared}'
                : s.agency,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.open(
          checklist && s.verified
              ? ChecklistScreen(service: s)
              : RoadmapScreen(service: s),
        ),
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
      if (context.state.prepared.values.every((items) => items.isEmpty)) ...[
        Text(context.l.empty),
        const SizedBox(height: 12),
      ],
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
      Text(context.l.aboutBody),
      Section(context.l.language),
      SegmentedButton<String>(
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
      Notice(context.l.studentNotice),
      Notice(context.l.reviewNotice, warning: true),
      Text(context.l.linksNeedInternet),
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
      title: Text(source.title),
      subtitle: Text('${context.l.lastChecked}: ${source.checked}'),
      trailing: const Icon(Icons.open_in_new),
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

class RoadmapScreen extends StatelessWidget {
  final Service service;
  const RoadmapScreen({super.key, required this.service});
  @override
  Widget build(BuildContext context) {
    final s = service;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l.roadmap),
        actions: const [LanguageMenu()],
      ),
      body: PageBody(
        children: [
          Text(
            context.tr(s.title),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(s.agency),
          Notice(
            s.verified ? context.l.sourceChecked : context.l.pending,
            warning: !s.verified,
          ),
          Section(context.l.scope),
          Text(context.tr(s.summary)),
          Notice(context.tr(s.notice), warning: true),
          Section(context.l.location),
          Text(context.tr(s.location)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => openOfficial(context, s.url),
            icon: const Icon(Icons.open_in_new),
            label: Text(context.l.openOfficial),
          ),
          if (s.verified) ...[
            Section(context.l.roadmap),
            for (final (index, step) in s.steps.indexed)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.l.step} ${index + 1} · ${context.tr(step.title)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(context.tr(step.detail)),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(step.place),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Section(context.l.requirements),
            for (final r in s.requirements)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(context.tr(r.text)),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.open(ChecklistScreen(service: s)),
              icon: const Icon(Icons.checklist),
              label: Text(context.l.prepare),
            ),
          ],
          Section(context.l.sources),
          for (final id in s.sources)
            SourceCard(
              source: context.catalog.sources.firstWhere((r) => r.id == id),
            ),
          Notice(context.l.studentNotice),
        ],
      ),
    );
  }
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
              LinearProgressIndicator(value: (e.position + 1) / 5),
              const SizedBox(height: 28),
              Text(
                context.tr(question.text),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              for (final c in question.choices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(18),
                      backgroundColor: e.answers[e.current] == c.id
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.white,
                    ),
                    onPressed: () => setState(() {
                      e.select(c.id);
                      validation = false;
                    }),
                    child: Row(
                      children: [
                        Icon(
                          e.answers[e.current] == c.id
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(context.tr(c.text))),
                      ],
                    ),
                  ),
                ),
              if (validation) Notice(context.l.selectAnswer, warning: true),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => setState(() {
                  validation = !e.next();
                }),
                child: Text(context.l.next),
              ),
            ] else ...[
              const Icon(Icons.explore_outlined, size: 56),
              const SizedBox(height: 20),
              Text(
                service != null ? context.l.result : context.l.referral,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                service != null
                    ? context.l.match
                    : context.tr(referral!.reason),
              ),
              if (service != null) ...[
                Section(context.tr(service.title)),
                Text(context.tr(service.summary)),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      context.open(RoadmapScreen(service: service)),
                  child: Text(context.l.viewRoadmap),
                ),
              ] else ...[
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => openOfficial(context, referral!.url),
                  child: Text(context.l.openOfficial),
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
    final s = widget.service, state = context.state;
    final count = s.requirements.where((r) => state.checked(s.id, r.id)).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l.checklists),
        actions: const [LanguageMenu()],
      ),
      body: PageBody(
        children: [
          Text(
            context.tr(s.title),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Text(
            '$count / ${s.requirements.length} ${context.l.prepared}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: s.requirements.isEmpty ? 0 : count / s.requirements.length,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 10),
          Text('${s.requirements.length - count} ${context.l.remaining}'),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l.missingOnly),
            value: missing,
            onChanged: (v) => setState(() => missing = v),
          ),
          for (final r in s.requirements.where(
            (r) => !missing || !state.checked(s.id, r.id),
          ))
            Card(
              child: CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(context.tr(r.text)),
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
          if (count == s.requirements.length) Notice(context.l.complete),
          const SizedBox(height: 20),
          OutlinedButton.icon(
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
            label: Text(context.l.reset),
          ),
          Notice(context.l.studentNotice),
        ],
      ),
    );
  }
}
