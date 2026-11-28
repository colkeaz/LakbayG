import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'domain.dart';
import 'l10n/app_localizations.dart';
import 'screens/guide_screen.dart';
import 'storage.dart';

abstract final class Palette {
  static const background = Color(0xffFAF7EF);
  static const surface = Colors.white;
  static const ink = Color(0xff17344A);
  static const muted = Color(0xff506358);
  static const primary = Color(0xff176658);
  static const blueSoft = Color(0xffE4EEE4);
  static const blueWarn = Color(0xffF6E7BC);
  static const amberInk = Color(0xff6B4E00);
  static const line = Color(0xffD8DFD3);
}

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Palette.primary),
  scaffoldBackgroundColor: Palette.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: Palette.background,
    surfaceTintColor: Colors.transparent,
    foregroundColor: Palette.ink,
  ),
  cardTheme: const CardThemeData(
    elevation: 0,
    color: Palette.surface,
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.symmetric(vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      side: BorderSide(color: Palette.line),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Palette.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    bodySmall: TextStyle(fontSize: 14, color: Palette.muted, height: 1.35),
  ),
);

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

IconData serviceIcon(String iconKey) => switch (iconKey) {
  'police' => Icons.local_police_outlined,
  'badge' => Icons.badge_outlined,
  'passport' => Icons.menu_book_outlined,
  'card' => Icons.credit_card_outlined,
  'health' => Icons.health_and_safety_outlined,
  'savings' => Icons.account_balance_wallet_outlined,
  _ => Icons.description_outlined,
};

String categoryLabel(BuildContext context, String category) {
  final l = context.l;
  return switch (category) {
    'clearance' => l.catClearance,
    'civil' => l.catCivil,
    'id' => l.catId,
    'benefits' => l.catBenefits,
    _ => l.catAll,
  };
}

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
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
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
  final ScrollController? controller;
  const PageBody({super.key, required this.children, this.controller});
  @override
  Widget build(BuildContext context) => ListView(
    controller: controller,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
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
  final Widget? trailing;
  const Section(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Palette.ink,
            ),
          ),
        ),
        ?trailing,
      ],
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
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          warning ? Icons.warning_amber_rounded : Icons.info_outline,
          size: 20,
          color: warning ? Palette.amberInk : Palette.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: warning ? Palette.amberInk : Palette.ink,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ],
    ),
  );
}

class ServiceCard extends StatelessWidget {
  final Service service;
  final bool checklist;
  const ServiceCard({super.key, required this.service, this.checklist = false});

  @override
  Widget build(BuildContext context) {
    final s = service;
    final state = context.state;
    final l = context.l;
    final doneSteps = state.doneStepCount(s);
    final totalSteps = s.steps.length;
    final prepared = state.preparedItemCount(s);
    final totalItems = state.totalItemCount(s);
    final hasProgress = state.hasAnyProgress(s);
    final ready = state.isReady(s);
    final tracker = state.trackerFor(s.id);

    return Card(
      child: InkWell(
        key: ValueKey<String>('service-${s.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () =>
            context.open(ChecklistScreen(service: s, packing: checklist)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: s.verified ? Palette.blueSoft : Palette.blueWarn,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  serviceIcon(s.icon),
                  color: s.verified ? Palette.primary : Palette.amberInk,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(s.title),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Palette.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.agency,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Palette.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (!s.verified)
                          StatusPill(
                            label: l.pending,
                            background: Palette.blueWarn,
                            foreground: Palette.amberInk,
                            icon: Icons.schedule,
                          )
                        else if (ready)
                          StatusPill(
                            label: l.readyBadge,
                            background: Palette.blueSoft,
                            foreground: Palette.primary,
                            icon: Icons.check_circle_outline,
                          )
                        else if (hasProgress)
                          StatusPill(
                            label:
                                '$doneSteps/$totalSteps ${l.stepsLabel} · $prepared/$totalItems ${l.itemsLabel}',
                            background: Palette.blueSoft,
                            foreground: Palette.primary,
                          )
                        else
                          StatusPill(
                            label: categoryLabel(context, s.category),
                            background: const Color(0xffEEF2EB),
                            foreground: Palette.muted,
                          ),
                        if (tracker.appointmentDate.isNotEmpty)
                          StatusPill(
                            label: tracker.appointmentDate,
                            background: const Color(0xffEEF2EB),
                            foreground: Palette.ink,
                            icon: Icons.event_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(Icons.chevron_right, color: Palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SourceCard extends StatelessWidget {
  final Source source;
  const SourceCard({super.key, required this.source});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        source.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${source.section}\n${context.l.lastChecked}: ${source.checked}',
          style: const TextStyle(fontSize: 13.5, color: Palette.muted),
        ),
      ),
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
