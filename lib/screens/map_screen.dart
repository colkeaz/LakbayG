import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../domain.dart';
import '../location_service.dart';
import '../storage.dart';
import '../theme.dart';
import 'guide_screen.dart';

class OfficeMapScreen extends StatelessWidget {
  final String initialServiceId;
  final bool? showTiles;
  final Future<LocationResult> Function()? locateOverride;

  const OfficeMapScreen({
    super.key,
    required this.initialServiceId,
    this.showTiles,
    this.locateOverride,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l.officeMapTitle),
      actions: const [LanguageMenu()],
    ),
    body: OfficeMapView(
      initialServiceId: initialServiceId,
      showTiles: showTiles,
      locateOverride: locateOverride,
    ),
  );
}

class OfficeMapView extends StatefulWidget {
  final String? initialServiceId;
  final bool? showTiles;
  final Future<LocationResult> Function()? locateOverride;

  const OfficeMapView({
    super.key,
    this.initialServiceId,
    this.showTiles,
    this.locateOverride,
  });

  @override
  State<OfficeMapView> createState() => _OfficeMapViewState();
}

class _OfficeMapViewState extends State<OfficeMapView> {
  final MapController _mapController = MapController();
  late String selectedServiceId = widget.initialServiceId ?? 'all';
  String selectedCity = 'all';
  bool listMode = false;
  String? selectedOfficeId;
  LatLng? userLocation;
  bool locating = false;
  bool _mapReady = false;

  bool get _renderTiles =>
      widget.showTiles ??
      !WidgetsBinding.instance.runtimeType.toString().contains('Test');

  List<Office> _filteredOffices(Catalog catalog) {
    final list = catalog.offices.where((o) {
      if (selectedServiceId != 'all' && o.serviceId != selectedServiceId) {
        return false;
      }
      if (selectedCity != 'all' && o.city != selectedCity) {
        return false;
      }
      return true;
    }).toList();
    if (userLocation != null) {
      list.sort(
        (a, b) => distanceKm(
          userLocation!,
          LatLng(a.lat, a.lng),
        ).compareTo(distanceKm(userLocation!, LatLng(b.lat, b.lng))),
      );
    }
    return list;
  }

  void _fitVisibleOffices(List<Office> offices) {
    if (!_mapReady || offices.isEmpty) {
      return;
    }
    try {
      if (offices.length == 1) {
        _mapController.move(
          LatLng(offices.single.lat, offices.single.lng),
          14.5,
        );
        return;
      }
      final bounds = LatLngBounds.fromPoints([
        for (final o in offices) LatLng(o.lat, o.lng),
      ]);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    } catch (_) {
      // Ignore camera calls if controller is not yet attached to a laid-out map.
    }
  }

  void _focusOffice(Office office) {
    setState(() {
      selectedOfficeId = office.id;
      listMode = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapReady) {
        try {
          _mapController.move(LatLng(office.lat, office.lng), 15);
        } catch (_) {}
      }
    });
  }

  Future<void> _locateMe(List<Office> currentOffices) async {
    if (locating) {
      return;
    }
    setState(() => locating = true);
    final result = await (widget.locateOverride ?? detectCurrentLocation)();
    if (!mounted) {
      return;
    }
    setState(() {
      locating = false;
      if (result.outcome == LocationOutcome.ok && result.point != null) {
        userLocation = result.point;
      }
    });
    final l = context.l;
    switch (result.outcome) {
      case LocationOutcome.ok:
        if (result.point != null && _mapReady && !listMode) {
          try {
            _mapController.move(result.point!, 12.5);
          } catch (_) {}
        }
      case LocationOutcome.serviceDisabled:
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.locationOff)));
      case LocationOutcome.permissionDenied:
      case LocationOutcome.permissionDeniedForever:
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.locationDenied)));
      case LocationOutcome.unavailable:
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.locationUnavailable)));
    }
  }

  Future<void> _showOfficeSheet(Office office) async {
    final service = context.catalog.service(office.serviceId);
    final km = userLocation == null
        ? null
        : distanceKm(userLocation!, LatLng(office.lat, office.lng));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Palette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final l = sheetCtx.l;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: service.verified
                            ? Palette.blueSoft
                            : Palette.blueWarn,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        serviceIcon(service.icon),
                        color: service.verified
                            ? Palette.primary
                            : Palette.amberInk,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            office.name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Palette.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${sheetCtx.tr(service.title)} · ${service.agency}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    StatusPill(
                      label: office.city,
                      background: Palette.blueSoft,
                      foreground: Palette.primary,
                      icon: Icons.location_city_outlined,
                    ),
                    if (km != null)
                      StatusPill(
                        label: l.distanceKm(km.toStringAsFixed(1)),
                        background: const Color(0xffEEF2EB),
                        foreground: Palette.ink,
                        icon: Icons.near_me_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _SheetInfoRow(icon: Icons.place_outlined, text: office.address),
                const SizedBox(height: 8),
                _SheetInfoRow(
                  icon: Icons.schedule_outlined,
                  text: '${l.officeHours}: ${sheetCtx.tr(office.hours)}',
                ),
                const SizedBox(height: 10),
                Notice(sheetCtx.tr(office.note), warning: !service.verified),
                const SizedBox(height: 14),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () => openOfficial(
                      sheetCtx,
                      googleMapsDirectionsUri(
                        office.lat,
                        office.lng,
                      ).toString(),
                    ),
                    icon: const Icon(Icons.directions_outlined),
                    label: Text(l.getDirections),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final state = context.state;
                      final existing = state.trackerFor(office.serviceId);
                      final ok = await state.saveTracker(
                        office.serviceId,
                        ServiceTracker(
                          branch: office.name,
                          appointmentDate: existing.appointmentDate,
                          referenceNo: existing.referenceNo,
                          notes: existing.notes,
                        ),
                      );
                      if (sheetCtx.mounted) {
                        Navigator.pop(sheetCtx);
                      }
                      if (mounted) {
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l.branchSaved)),
                          );
                        } else {
                          context.saveResult(false);
                        }
                      }
                    },
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: Text(l.useAsBranch),
                  ),
                ),
                if (widget.initialServiceId == null) ...[
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      context.open(ChecklistScreen(service: service));
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(l.openGuide),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.catalog;
    final l = context.l;
    final offices = _filteredOffices(catalog);
    final cities = catalog.officeCities;
    final showOfflineHint = MediaQuery.sizeOf(context).height > 500;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: false, label: Text(l.mapView)),
                        ButtonSegment(value: true, label: Text(l.listView)),
                      ],
                      selected: {listMode},
                      onSelectionChanged: (v) =>
                          setState(() => listMode = v.single),
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusPill(
                    label: '${offices.length}',
                    background: Palette.blueSoft,
                    foreground: Palette.primary,
                    icon: Icons.pin_drop_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(l.allServices),
                        selected: selectedServiceId == 'all',
                        selectedColor: Palette.blueSoft,
                        onSelected: (_) {
                          setState(() => selectedServiceId = 'all');
                          _fitVisibleOffices(_filteredOffices(catalog));
                        },
                      ),
                    ),
                    for (final s in catalog.services)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(context.tr(s.title)),
                          selected: selectedServiceId == s.id,
                          selectedColor: Palette.blueSoft,
                          onSelected: (_) {
                            setState(() => selectedServiceId = s.id);
                            _fitVisibleOffices(_filteredOffices(catalog));
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(l.allAreas),
                        selected: selectedCity == 'all',
                        selectedColor: Palette.blueSoft,
                        onSelected: (_) {
                          setState(() => selectedCity = 'all');
                          _fitVisibleOffices(_filteredOffices(catalog));
                        },
                      ),
                    ),
                    for (final city in cities)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(city),
                          selected: selectedCity == city,
                          selectedColor: Palette.blueSoft,
                          onSelected: (_) {
                            setState(() => selectedCity = city);
                            _fitVisibleOffices(_filteredOffices(catalog));
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: listMode
              ? _buildListView(context, offices)
              : _buildMapView(context, offices, showOfflineHint),
        ),
      ],
    );
  }

  Widget _buildMapView(
    BuildContext context,
    List<Office> offices,
    bool showOfflineHint,
  ) {
    final l = context.l;
    final initialCenter = offices.isNotEmpty
        ? LatLng(offices.first.lat, offices.first.lng)
        : defaultBatangasCenter;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 10.2,
            onMapReady: () {
              _mapReady = true;
              if (widget.initialServiceId != null) {
                _fitVisibleOffices(offices);
              }
            },
          ),
          children: [
            if (_renderTiles)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ph.edu.tudok.tudok',
                errorTileCallback: (_, _, _) {},
              ),
            MarkerLayer(
              markers: [
                if (userLocation != null)
                  Marker(
                    point: userLocation!,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                for (final o in offices) _buildMarker(context, o),
              ],
            ),
          ],
        ),
        if (showOfflineHint)
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Palette.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Palette.line),
                  ),
                  child: Text(
                    l.mapOfflineHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5, color: Palette.ink),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 12,
          left: 12,
          child: Material(
            color: Palette.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => openOfficial(
                context,
                'https://www.openstreetmap.org/copyright',
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  l.osmAttribution,
                  style: const TextStyle(fontSize: 11, color: Palette.muted),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 14,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'fit-pins-${widget.initialServiceId ?? 'tab'}',
                tooltip: l.fitPins,
                backgroundColor: Palette.surface,
                foregroundColor: Palette.ink,
                onPressed: () => _fitVisibleOffices(offices),
                child: const Icon(Icons.center_focus_strong),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'locate-me-${widget.initialServiceId ?? 'tab'}',
                tooltip: l.locateMe,
                backgroundColor: Palette.primary,
                foregroundColor: Colors.white,
                onPressed: locating ? null : () => _locateMe(offices),
                child: locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Marker _buildMarker(BuildContext context, Office office) {
    final service = context.catalog.service(office.serviceId);
    final selected = selectedOfficeId == office.id;
    final pinColor = service.verified ? Palette.primary : Palette.amberInk;

    return Marker(
      point: LatLng(office.lat, office.lng),
      width: selected ? 44 : 38,
      height: selected ? 44 : 38,
      child: GestureDetector(
        key: ValueKey<String>('pin-${office.id}'),
        onTap: () {
          setState(() => selectedOfficeId = office.id);
          _showOfficeSheet(office);
        },
        child: Container(
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: selected ? 3 : 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            serviceIcon(service.icon),
            size: selected ? 20 : 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<Office> offices) {
    final l = context.l;
    if (offices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l.noOffices,
            style: const TextStyle(fontSize: 15, color: Palette.muted),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: locating ? null : () => _locateMe(offices),
                    icon: const Icon(Icons.my_location, size: 18),
                    label: Text(l.locateMe),
                  ),
                ),
                for (final o in offices)
                  _OfficeListCard(
                    office: o,
                    service: context.catalog.service(o.serviceId),
                    distanceKmValue: userLocation == null
                        ? null
                        : distanceKm(userLocation!, LatLng(o.lat, o.lng)),
                    onTap: () => _showOfficeSheet(o),
                    onShowOnMap: () => _focusOffice(o),
                    onDirections: () => openOfficial(
                      context,
                      googleMapsDirectionsUri(o.lat, o.lng).toString(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OfficeListCard extends StatelessWidget {
  final Office office;
  final Service service;
  final double? distanceKmValue;
  final VoidCallback onTap;
  final VoidCallback onShowOnMap;
  final VoidCallback onDirections;

  const _OfficeListCard({
    required this.office,
    required this.service,
    required this.distanceKmValue,
    required this.onTap,
    required this.onShowOnMap,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Card(
      child: InkWell(
        key: ValueKey<String>('office-${office.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: service.verified
                          ? Palette.blueSoft
                          : Palette.blueWarn,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      serviceIcon(service.icon),
                      color: service.verified
                          ? Palette.primary
                          : Palette.amberInk,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          office.name,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Palette.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr(service.title),
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusPill(
                    label: office.city,
                    background: Palette.blueSoft,
                    foreground: Palette.primary,
                  ),
                  if (distanceKmValue != null)
                    StatusPill(
                      label: l.distanceKm(distanceKmValue!.toStringAsFixed(1)),
                      background: const Color(0xffEEF2EB),
                      foreground: Palette.ink,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                office.address,
                style: const TextStyle(fontSize: 14, color: Palette.ink),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: onShowOnMap,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: Text(l.viewOnMap),
                  ),
                  TextButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions_outlined, size: 18),
                    label: Text(l.getDirections),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SheetInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 19, color: Palette.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 14.5, color: Palette.ink),
        ),
      ),
    ],
  );
}
