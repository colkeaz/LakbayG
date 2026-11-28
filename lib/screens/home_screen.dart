import 'package:flutter/material.dart';

import '../domain.dart';
import '../pip.dart';
import '../theme.dart';
import 'map_screen.dart';
import 'navigator_screen.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Pip(PipPose.map, width: 132)),
                const SizedBox(height: 16),
                const Text(
                  'LakbayG',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Palette.muted),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l.chooseLanguage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l.bilingualPrompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Palette.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l.languageHelp,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Palette.muted),
                ),
                const SizedBox(height: 24),
                for (final item in [('en', 'English'), ('fil', 'Filipino')])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 54,
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
  bool _visitedMap = false;

  void _selectTab(int value) {
    setState(() {
      if (value == 1) {
        _visitedMap = true;
      }
      index = value;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'LakbayG',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: const [LanguageMenu()],
    ),
    body: IndexedStack(
      index: index,
      children: [
        HomeView(onTab: _selectTab),
        _visitedMap ? const OfficeMapView() : const SizedBox.shrink(),
        ChecklistsView(explore: () => _selectTab(0)),
        const SettingsView(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: _selectTab,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: context.l.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.map_outlined),
          selectedIcon: const Icon(Icons.map),
          label: context.l.mapTab,
        ),
        NavigationDestination(
          icon: const Icon(Icons.checklist_outlined),
          selectedIcon: const Icon(Icons.checklist_rounded),
          label: context.l.navChecklists,
        ),
        NavigationDestination(
          icon: const Icon(Icons.info_outline),
          selectedIcon: const Icon(Icons.info),
          label: context.l.navSettings,
        ),
      ],
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
  final TextEditingController _searchController = TextEditingController();
  String query = '';
  String selectedCategory = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(BuildContext context, Service s) {
    if (selectedCategory != 'all' && s.category != selectedCategory) {
      return false;
    }
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    return s.title.en.toLowerCase().contains(q) ||
        s.title.fil.toLowerCase().contains(q) ||
        s.agency.toLowerCase().contains(q) ||
        s.summary.en.toLowerCase().contains(q) ||
        s.summary.fil.toLowerCase().contains(q) ||
        s.keywords.any((k) => k.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final state = context.state;
    final services = context.catalog.services
        .where((s) => _matches(context, s))
        .toList();
    final active = context.catalog.services
        .where((s) => state.hasAnyProgress(s) && !state.isReady(s))
        .toList();

    return PageBody(
      children: [
        SoftTile(
          color: Palette.blueSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.documentQuestion,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            color: Palette.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.pipWelcome,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (MediaQuery.textScalerOf(context).scale(16) < 28)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Pip(PipPose.map, width: 92),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: FilledButton.icon(
                  onPressed: () => context.open(const NavigatorScreen()),
                  icon: const Icon(Icons.alt_route),
                  label: Text(l.findService),
                ),
              ),
            ],
          ),
        ),
        if (active.isNotEmpty) ...[
          Section(l.resumeGuide),
          if (active.length == 1)
            ServiceCard(service: active.single, checklist: true)
          else
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Palette.blueSoft,
                  child: Icon(Icons.checklist_rounded, color: Palette.primary),
                ),
                title: Text(
                  l.checklists,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${active.length} ${l.guidesStarted}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.onTab(2),
              ),
            ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => query = value),
          decoration: InputDecoration(
            hintText: l.searchHint,
            prefixIcon: const Icon(Icons.search_rounded, color: Palette.muted),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: l.close,
                    onPressed: () => setState(() {
                      _searchController.clear();
                      query = '';
                    }),
                    icon: const Icon(Icons.close, color: Palette.muted),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final cat in ['all', ...Service.categories])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(categoryLabel(context, cat)),
                    selected: selectedCategory == cat,
                    selectedColor: Palette.blueSoft,
                    onSelected: (_) => setState(() => selectedCategory = cat),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (services.isEmpty)
          SoftTile(
            color: Palette.surface,
            child: Text(
              l.noResults,
              style: const TextStyle(fontSize: 15, color: Palette.muted),
            ),
          )
        else
          for (final s in services) ServiceCard(service: s),
        const SizedBox(height: 8),
        Notice(l.studentNotice),
      ],
    );
  }
}

class ChecklistsView extends StatelessWidget {
  final VoidCallback explore;
  const ChecklistsView({super.key, required this.explore});

  @override
  Widget build(BuildContext context) {
    final state = context.state;
    final l = context.l;
    final started = context.catalog.services
        .where(state.hasAnyProgress)
        .toList();
    final inProgress = started.where((s) => !state.isReady(s)).toList();
    final ready = started.where(state.isReady).toList();

    return PageBody(
      children: [
        Section(l.checklists),
        if (started.isEmpty) ...[
          const SizedBox(height: 18),
          const Center(child: Pip(PipPose.point, width: 120)),
          const SizedBox(height: 16),
          Text(
            l.empty,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Palette.muted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: FilledButton(onPressed: explore, child: Text(l.explore)),
          ),
        ],
        if (inProgress.isNotEmpty) ...[
          Section(l.inProgress),
          for (final s in inProgress) ServiceCard(service: s, checklist: true),
        ],
        if (ready.isNotEmpty) ...[
          Section(l.readyGroup),
          for (final s in ready) ServiceCard(service: s, checklist: true),
        ],
      ],
    );
  }
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
      const SizedBox(height: 6),
      Notice(context.l.offlineNote),
      Section(context.l.sources),
      for (final s in context.catalog.sources) SourceCard(source: s),
    ],
  );
}
