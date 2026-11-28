import 'package:flutter/material.dart';

import '../domain.dart';
import '../pip.dart';
import '../theme.dart';
import 'guide_screen.dart';

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
    final remaining = questionsRemaining(context.catalog, e.current);
    final branchLength = e.position + remaining;
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
                  value: branchLength == 0
                      ? 1
                      : (e.position + 1) / branchLength,
                  minHeight: 10,
                  backgroundColor: Palette.line,
                  color: Palette.primary,
                ),
              ),
              const SizedBox(height: 24),
              PipCue(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(question.text),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: Palette.ink,
                      ),
                    ),
                    if (question.hint != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        context.tr(question.hint!),
                        style: const TextStyle(fontSize: 15, color: Palette.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              for (final c in question.choices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: e.answers[e.current] == c.id
                        ? Palette.blueSoft
                        : Palette.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: e.answers[e.current] == c.id
                            ? Palette.primary
                            : Palette.line,
                        width: e.answers[e.current] == c.id ? 1.5 : 1,
                      ),
                    ),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr(c.text),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Palette.ink,
                                    ),
                                  ),
                                  if (c.detail != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      context.tr(c.detail!),
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Palette.muted,
                                      ),
                                    ),
                                  ],
                                ],
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
              Icon(
                service != null
                    ? Icons.check_circle_outline
                    : Icons.explore_outlined,
                size: 54,
                color: Palette.primary,
              ),
              const SizedBox(height: 16),
              Text(
                service != null ? context.l.result : context.l.referral,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                SoftTile(
                  color: Palette.blueSoft,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.l.estimatedFee}: ${context.tr(service.fee)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Palette.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.l.validity}: ${context.tr(service.validity)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Palette.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                if (referral!.compare != null) ...[
                  const SizedBox(height: 14),
                  SoftTile(
                    color: Palette.blueSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l.quickComparison,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Palette.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr(referral.compare!),
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: Palette.ink,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (referral.suggestedServices.isNotEmpty) ...[
                  Section(context.l.relatedGuides),
                  for (final id in referral.suggestedServices)
                    ServiceCard(service: context.catalog.service(id)),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => openOfficial(context, referral.url),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(context.l.openOfficial),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 14),
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
