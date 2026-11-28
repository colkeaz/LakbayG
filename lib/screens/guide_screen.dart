import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain.dart';
import '../pip.dart';
import '../storage.dart';
import '../theme.dart';
import 'map_screen.dart';

class ChecklistScreen extends StatefulWidget {
  final Service service;
  final bool packing;
  const ChecklistScreen({
    super.key,
    required this.service,
    this.packing = false,
  });
  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final ScrollController _scrollController = ScrollController();
  late bool packing =
      widget.service.verified && widget.service.requirements.isNotEmpty
      ? widget.packing
      : false;
  bool missing = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openPackingTab() {
    setState(() => packing = true);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showAddItemDialog(Service s) async {
    final added = await showDialog<String>(
      context: context,
      builder: (_) => const _AddItemDialog(),
    );
    if (added == null || !mounted) {
      return;
    }
    final ok = await context.state.addCustomItem(s.id, added);
    if (mounted) {
      context.saveResult(ok);
    }
  }

  Future<void> _showTrackerSheet(Service s, ServiceTracker existing) async {
    final result = await showModalBottomSheet<ServiceTracker>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Palette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TrackerSheet(existing: existing),
    );
    if (result == null || !mounted) {
      return;
    }
    final ok = await context.state.saveTracker(s.id, result);
    if (!mounted) {
      return;
    }
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l.saved)));
    } else {
      context.saveResult(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final state = context.state;
    final l = context.l;
    final canPack = s.verified && s.requirements.isNotEmpty;
    final showPacking = canPack && packing;
    final customList = state.customItemsFor(s.id);
    final preparedCount = state.preparedItemCount(s);
    final totalCount = state.totalItemCount(s);
    final doneSteps = state.doneStepCount(s);
    final tracker = state.trackerFor(s.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(s.title)),
        actions: const [LanguageMenu()],
      ),
      body: PageBody(
        controller: _scrollController,
        children: [
          Text(s.agency, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusPill(
                label: s.verified ? l.sourceChecked : l.pending,
                background: s.verified ? Palette.blueSoft : Palette.blueWarn,
                foreground: s.verified ? Palette.primary : Palette.amberInk,
                icon: s.verified ? Icons.fact_check_outlined : Icons.schedule,
              ),
              if (s.verified && s.steps.isNotEmpty)
                StatusPill(
                  label: l.stepsDone(doneSteps, s.steps.length),
                  background: const Color(0xffEEF2EB),
                  foreground: Palette.ink,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (!s.verified) Notice(context.tr(s.notice), warning: true),
          if (canPack) ...[
            const SizedBox(height: 6),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l.steps)),
                ButtonSegment(value: true, label: Text(l.whatToBring)),
              ],
              selected: {showPacking},
              onSelectionChanged: (v) => setState(() => packing = v.single),
            ),
          ],
          if (!showPacking) ...[
            Section(l.scope),
            Text(
              context.tr(s.summary),
              style: const TextStyle(fontSize: 16, color: Palette.ink),
            ),
            const SizedBox(height: 12),
            _QuickFactsCard(service: s),
            if (s.verified) Notice(context.tr(s.notice), warning: true),
            Section(l.location),
            SoftTile(
              color: Palette.blueSoft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 22,
                    color: Palette.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr(s.location),
                      style: const TextStyle(
                        fontSize: 15.5,
                        color: Palette.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (context.catalog.officesFor(s.id).isNotEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.open(OfficeMapScreen(initialServiceId: s.id)),
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    l.viewOfficesOnMap(context.catalog.officesFor(s.id).length),
                  ),
                ),
              ),
            ],
            if (s.verified && s.steps.isNotEmpty) ...[
              Section(
                l.steps,
                trailing: Text(
                  l.stepsDone(doneSteps, s.steps.length),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Palette.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PipCue(
                  child: Text(
                    l.tapToMarkDone,
                    style: const TextStyle(fontSize: 15, color: Palette.muted),
                  ),
                ),
              ),
              for (final (index, step) in s.steps.indexed)
                _StepCard(
                  index: index,
                  step: step,
                  done: state.stepDone(s.id, step.id),
                  onToggle: state.busy
                      ? null
                      : () async {
                          final ok = await state.toggleStep(
                            s.id,
                            step.id,
                            !state.stepDone(s.id, step.id),
                          );
                          if (context.mounted) {
                            context.saveResult(ok);
                          }
                        },
                ),
            ],
            if (s.acceptedIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ExpandableInfoCard(
                icon: Icons.badge_outlined,
                title: l.acceptedIds,
                items: [for (final id in s.acceptedIds) context.tr(id)],
              ),
            ],
            if (s.tips.isNotEmpty) ...[
              const SizedBox(height: 4),
              _ExpandableInfoCard(
                icon: Icons.lightbulb_outline,
                title: l.goodToKnow,
                items: [for (final tip in s.tips) context.tr(tip)],
              ),
            ],
            if (canPack) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _openPackingTab,
                  icon: const Icon(Icons.checklist_rounded),
                  label: Text(l.goToChecklist),
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 12),
            SoftTile(
              color: Palette.blueSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$preparedCount / $totalCount ${l.prepared}',
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
                      value: totalCount == 0 ? 0 : preparedCount / totalCount,
                      minHeight: 10,
                      backgroundColor: Palette.surface,
                      color: Palette.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${totalCount - preparedCount} ${l.remaining}',
                    style: const TextStyle(fontSize: 14, color: Palette.muted),
                  ),
                ],
              ),
            ),
            _TrackerCard(
              tracker: tracker,
              onEdit: () => _showTrackerSheet(s, tracker),
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
            Section(
              l.myItems,
              trailing: TextButton.icon(
                onPressed: state.busy ? null : () => _showAddItemDialog(s),
                icon: const Icon(Icons.add),
                label: Text(l.addItem),
              ),
            ),
            for (final item in customList.where(
              (item) => !missing || !item.prepared,
            ))
              Card(
                child: CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    item.text,
                    style: const TextStyle(fontSize: 16, color: Palette.ink),
                  ),
                  secondary: IconButton(
                    tooltip: l.delete,
                    onPressed: state.busy
                        ? null
                        : () async {
                            final ok = await state.deleteCustomItem(
                              s.id,
                              item.id,
                            );
                            if (context.mounted) {
                              context.saveResult(ok);
                            }
                          },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Palette.muted,
                    ),
                  ),
                  value: item.prepared,
                  onChanged: state.busy
                      ? null
                      : (value) async {
                          final ok = await state.toggleCustomItem(
                            s.id,
                            item.id,
                            value ?? false,
                          );
                          if (context.mounted) {
                            context.saveResult(ok);
                          }
                        },
                ),
              ),
            if (totalCount > 0 && preparedCount == totalCount) ...[
              const SizedBox(height: 8),
              const Center(child: Pip(PipPose.perch)),
              Notice(l.complete),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
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
          ],
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: canPack && !showPacking
                ? OutlinedButton.icon(
                    onPressed: () => openOfficial(context, s.url),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l.openOfficial),
                  )
                : FilledButton.icon(
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

class _QuickFactsCard extends StatelessWidget {
  final Service service;
  const _QuickFactsCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final rows = [
      (Icons.payments_outlined, l.estimatedFee, context.tr(service.fee)),
      (
        Icons.schedule_outlined,
        l.processingTime,
        context.tr(service.processingTime),
      ),
      (Icons.verified_outlined, l.validity, context.tr(service.validity)),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (idx, row) in rows.indexed) ...[
              if (idx > 0) const Divider(height: 16, color: Palette.line),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(row.$1, size: 18, color: Palette.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.$2,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Palette.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.$3,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: Palette.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final ProcessStep step;
  final bool done;
  final VoidCallback? onToggle;
  const _StepCard({
    required this.index,
    required this.step,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: done ? const Color(0xffF2F7F2) : Palette.surface,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onToggle,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: done ? Palette.primary : Palette.blueSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Palette.primary,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr(step.title),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(step.detail),
            style: const TextStyle(fontSize: 15.5, color: Palette.ink),
          ),
          const SizedBox(height: 10),
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
                  '${context.l.goTo}: ${context.tr(step.place)}',
                  style: const TextStyle(fontSize: 14.5, color: Palette.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ExpandableInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  const _ExpandableInfoCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Palette.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Palette.ink,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Palette.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: Palette.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _TrackerCard extends StatelessWidget {
  final ServiceTracker tracker;
  final VoidCallback onEdit;
  const _TrackerCard({required this.tracker, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_outlined, color: Palette.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.myApplication,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Palette.ink,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  child: Text(tracker.isEmpty ? l.addDetails : l.editDetails),
                ),
              ],
            ),
            if (tracker.isEmpty)
              Text(
                l.trackerEmptyHint,
                style: const TextStyle(fontSize: 14, color: Palette.muted),
              )
            else ...[
              const SizedBox(height: 6),
              if (tracker.branch.isNotEmpty)
                _TrackerRow(label: l.branchLabel, value: tracker.branch),
              if (tracker.appointmentDate.isNotEmpty)
                _TrackerRow(
                  label: l.appointmentDate,
                  value: tracker.appointmentDate,
                ),
              if (tracker.referenceNo.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _TrackerRow(
                        label: l.referenceNumber,
                        value: tracker.referenceNo,
                      ),
                    ),
                    IconButton(
                      tooltip: l.copyLink,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: tracker.referenceNo),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(l.copied)));
                        }
                      },
                      icon: const Icon(
                        Icons.copy_outlined,
                        size: 18,
                        color: Palette.primary,
                      ),
                    ),
                  ],
                ),
              if (tracker.notes.isNotEmpty)
                _TrackerRow(label: l.notesLabel, value: tracker.notes),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrackerRow extends StatelessWidget {
  final String label, value;
  const _TrackerRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14.5, color: Palette.ink),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Palette.muted,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}

class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog();
  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = context.l.emptyItemError);
    } else {
      Navigator.pop(context, value);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l.addItem),
    content: TextField(
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: context.l.addItemHint,
        errorText: _errorText,
      ),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l.cancel),
      ),
      FilledButton(onPressed: _submit, child: Text(context.l.add)),
    ],
  );
}

class _TrackerSheet extends StatefulWidget {
  final ServiceTracker existing;
  const _TrackerSheet({required this.existing});
  @override
  State<_TrackerSheet> createState() => _TrackerSheetState();
}

class _TrackerSheetState extends State<_TrackerSheet> {
  late final TextEditingController _branchCtrl = TextEditingController(
    text: widget.existing.branch,
  );
  late final TextEditingController _refCtrl = TextEditingController(
    text: widget.existing.referenceNo,
  );
  late final TextEditingController _notesCtrl = TextEditingController(
    text: widget.existing.notes,
  );
  late String _dateText = widget.existing.appointmentDate;

  @override
  void dispose() {
    _branchCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.myApplication,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _branchCtrl,
              decoration: InputDecoration(
                labelText: l.branchLabel,
                hintText: l.branchHint,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final parsed = DateTime.tryParse(_dateText);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: parsed ?? now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 3),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _dateText =
                              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_dateText.isEmpty ? l.pickDate : _dateText),
                  ),
                ),
                if (_dateText.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l.clearDate,
                    onPressed: () => setState(() => _dateText = ''),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _refCtrl,
              decoration: InputDecoration(labelText: l.referenceNumber),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(labelText: l.notesLabel),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (!widget.existing.isEmpty) ...[
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, const ServiceTracker()),
                    child: Text(l.clearDetails),
                  ),
                  const Spacer(),
                ],
                Expanded(
                  flex: widget.existing.isEmpty ? 1 : 0,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      ServiceTracker(
                        branch: _branchCtrl.text,
                        appointmentDate: _dateText,
                        referenceNo: _refCtrl.text,
                        notes: _notesCtrl.text,
                      ),
                    ),
                    child: Text(l.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
