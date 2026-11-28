import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'domain.dart';

class CustomItem {
  final int id;
  final String service, text;
  final bool prepared;

  const CustomItem({
    required this.id,
    required this.service,
    required this.text,
    required this.prepared,
  });

  CustomItem copyWith({bool? prepared}) => CustomItem(
    id: id,
    service: service,
    text: text,
    prepared: prepared ?? this.prepared,
  );
}

class ServiceTracker {
  final String branch, appointmentDate, referenceNo, notes;

  const ServiceTracker({
    this.branch = '',
    this.appointmentDate = '',
    this.referenceNo = '',
    this.notes = '',
  });

  bool get isEmpty =>
      branch.trim().isEmpty &&
      appointmentDate.trim().isEmpty &&
      referenceNo.trim().isEmpty &&
      notes.trim().isEmpty;
}

class LocalStore {
  final Database database;
  LocalStore(this.database);

  static Future<void> _createV2Tables(DatabaseExecutor db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS step_progress (service TEXT NOT NULL, step_id TEXT NOT NULL, PRIMARY KEY(service, step_id))',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS custom_items (id INTEGER PRIMARY KEY AUTOINCREMENT, service TEXT NOT NULL, text TEXT NOT NULL, prepared INTEGER NOT NULL DEFAULT 0)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS tracker (service TEXT PRIMARY KEY, branch TEXT NOT NULL DEFAULT \'\', appointment_date TEXT NOT NULL DEFAULT \'\', reference_no TEXT NOT NULL DEFAULT \'\', notes TEXT NOT NULL DEFAULT \'\')',
    );
  }

  static Future<LocalStore> open({
    DatabaseFactory? factory,
    String? location,
  }) async {
    final f = factory ?? databaseFactory;
    final db = await f.openDatabase(
      location ?? p.join(await f.getDatabasesPath(), 'tudok.db'),
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE checklist (service TEXT NOT NULL, requirement TEXT NOT NULL, PRIMARY KEY(service, requirement))',
          );
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
          await _createV2Tables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createV2Tables(db);
          }
        },
      ),
    );
    return LocalStore(db);
  }
}

class ChecklistRepository {
  final LocalStore store;
  ChecklistRepository(this.store);

  Future<Map<String, Set<String>>> read() async {
    final result = <String, Set<String>>{};
    for (final row in await store.database.query('checklist')) {
      (result[row['service'] as String] ??= <String>{}).add(
        row['requirement'] as String,
      );
    }
    return result;
  }

  Future<void> set(String service, String requirement, bool prepared) async {
    if (prepared) {
      await store.database.insert('checklist', {
        'service': service,
        'requirement': requirement,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await store.database.delete(
        'checklist',
        where: 'service = ? AND requirement = ?',
        whereArgs: [service, requirement],
      );
    }
  }

  Future<void> reset(String service) async {
    await store.database.delete(
      'checklist',
      where: 'service = ?',
      whereArgs: [service],
    );
  }

  Future<Map<String, Set<String>>> readSteps() async {
    final result = <String, Set<String>>{};
    for (final row in await store.database.query('step_progress')) {
      (result[row['service'] as String] ??= <String>{}).add(
        row['step_id'] as String,
      );
    }
    return result;
  }

  Future<void> setStep(String service, String stepId, bool done) async {
    if (done) {
      await store.database.insert('step_progress', {
        'service': service,
        'step_id': stepId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await store.database.delete(
        'step_progress',
        where: 'service = ? AND step_id = ?',
        whereArgs: [service, stepId],
      );
    }
  }

  Future<void> resetSteps(String service) async {
    await store.database.delete(
      'step_progress',
      where: 'service = ?',
      whereArgs: [service],
    );
  }

  Future<Map<String, List<CustomItem>>> readCustomItems() async {
    final result = <String, List<CustomItem>>{};
    for (final row in await store.database.query(
      'custom_items',
      orderBy: 'id ASC',
    )) {
      final item = CustomItem(
        id: row['id'] as int,
        service: row['service'] as String,
        text: row['text'] as String,
        prepared: (row['prepared'] as int) != 0,
      );
      (result[item.service] ??= <CustomItem>[]).add(item);
    }
    return result;
  }

  Future<CustomItem> addCustomItem(String service, String text) async {
    final id = await store.database.insert('custom_items', {
      'service': service,
      'text': text,
      'prepared': 0,
    });
    return CustomItem(id: id, service: service, text: text, prepared: false);
  }

  Future<void> setCustomItem(int id, bool prepared) async {
    await store.database.update(
      'custom_items',
      {'prepared': prepared ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCustomItem(int id) async {
    await store.database.delete(
      'custom_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> uncheckCustomItems(String service) async {
    await store.database.update(
      'custom_items',
      {'prepared': 0},
      where: 'service = ?',
      whereArgs: [service],
    );
  }

  Future<Map<String, ServiceTracker>> readTrackers() async {
    final result = <String, ServiceTracker>{};
    for (final row in await store.database.query('tracker')) {
      result[row['service'] as String] = ServiceTracker(
        branch: row['branch'] as String,
        appointmentDate: row['appointment_date'] as String,
        referenceNo: row['reference_no'] as String,
        notes: row['notes'] as String,
      );
    }
    return result;
  }

  Future<void> saveTracker(String service, ServiceTracker data) async {
    if (data.isEmpty) {
      await clearTracker(service);
      return;
    }
    await store.database.insert('tracker', {
      'service': service,
      'branch': data.branch.trim(),
      'appointment_date': data.appointmentDate.trim(),
      'reference_no': data.referenceNo.trim(),
      'notes': data.notes.trim(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearTracker(String service) async {
    await store.database.delete(
      'tracker',
      where: 'service = ?',
      whereArgs: [service],
    );
  }
}

class SettingsRepository {
  final LocalStore store;
  SettingsRepository(this.store);
  Future<String?> language() async {
    final rows = await store.database.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['language'],
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setLanguage(String language) async {
    await store.database.insert('settings', {
      'key': 'language',
      'value': language,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

class AppController extends ChangeNotifier {
  final ChecklistRepository checklists;
  final SettingsRepository settings;
  Map<String, Set<String>> prepared = {};
  Map<String, Set<String>> completedSteps = {};
  Map<String, List<CustomItem>> customItems = {};
  Map<String, ServiceTracker> trackers = {};
  String language = 'en';
  bool firstLaunch = true;

  Future<void> _queue = Future<void>.value();
  int _pending = 0;
  bool get busy => _pending > 0;

  AppController(this.checklists, this.settings);

  Future<void> initialize() async {
    prepared = await checklists.read();
    completedSteps = await checklists.readSteps();
    customItems = await checklists.readCustomItems();
    trackers = await checklists.readTrackers();
    final stored = await settings.language();
    firstLaunch = stored == null;
    language = stored == 'fil' ? 'fil' : 'en';
  }

  bool checked(String service, String requirement) =>
      prepared[service]?.contains(requirement) ?? false;

  bool stepDone(String service, String stepId) =>
      completedSteps[service]?.contains(stepId) ?? false;

  List<CustomItem> customItemsFor(String service) =>
      List.unmodifiable(customItems[service] ?? const <CustomItem>[]);

  ServiceTracker trackerFor(String service) =>
      trackers[service] ?? const ServiceTracker();

  int doneStepCount(Service s) =>
      s.steps.where((st) => stepDone(s.id, st.id)).length;

  int preparedItemCount(Service s) =>
      s.requirements.where((r) => checked(s.id, r.id)).length +
      customItemsFor(s.id).where((i) => i.prepared).length;

  int totalItemCount(Service s) =>
      s.requirements.length + customItemsFor(s.id).length;

  bool hasAnyProgress(Service s) =>
      preparedItemCount(s) > 0 ||
      doneStepCount(s) > 0 ||
      !trackerFor(s.id).isEmpty;

  bool isReady(Service s) =>
      s.verified &&
      totalItemCount(s) > 0 &&
      preparedItemCount(s) == totalItemCount(s);

  Future<bool> changeLanguage(String value) => _save(() async {
    await settings.setLanguage(value);
    language = value;
    firstLaunch = false;
  });

  Future<bool> toggle(String service, String requirement, bool value) =>
      _save(() async {
        await checklists.set(service, requirement, value);
        final items = prepared[service] ??= <String>{};
        if (value) {
          items.add(requirement);
        } else {
          items.remove(requirement);
        }
      });

  Future<bool> toggleStep(String service, String stepId, bool done) =>
      _save(() async {
        await checklists.setStep(service, stepId, done);
        final steps = completedSteps[service] ??= <String>{};
        if (done) {
          steps.add(stepId);
        } else {
          steps.remove(stepId);
        }
      });

  Future<bool> addCustomItem(String service, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return Future.value(false);
    }
    return _save(() async {
      final created = await checklists.addCustomItem(service, trimmed);
      (customItems[service] ??= <CustomItem>[]).add(created);
    });
  }

  Future<bool> toggleCustomItem(String service, int id, bool preparedValue) =>
      _save(() async {
        await checklists.setCustomItem(id, preparedValue);
        final list = customItems[service];
        if (list == null) return;
        final idx = list.indexWhere((i) => i.id == id);
        if (idx != -1) {
          list[idx] = list[idx].copyWith(prepared: preparedValue);
        }
      });

  Future<bool> deleteCustomItem(String service, int id) => _save(() async {
    await checklists.deleteCustomItem(id);
    customItems[service]?.removeWhere((i) => i.id == id);
  });

  Future<bool> saveTracker(String service, ServiceTracker data) =>
      _save(() async {
        await checklists.saveTracker(service, data);
        if (data.isEmpty) {
          trackers.remove(service);
        } else {
          trackers[service] = ServiceTracker(
            branch: data.branch.trim(),
            appointmentDate: data.appointmentDate.trim(),
            referenceNo: data.referenceNo.trim(),
            notes: data.notes.trim(),
          );
        }
      });

  Future<bool> clearTracker(String service) => _save(() async {
    await checklists.clearTracker(service);
    trackers.remove(service);
  });

  Future<bool> reset(String service) => _save(() async {
    await checklists.reset(service);
    await checklists.resetSteps(service);
    await checklists.uncheckCustomItems(service);
    prepared.remove(service);
    completedSteps.remove(service);
    final list = customItems[service];
    if (list != null) {
      for (var i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(prepared: false);
      }
    }
  });

  Future<bool> _save(Future<void> Function() operation) {
    _pending++;
    notifyListeners();
    final run = _queue.then((_) async {
      try {
        await operation();
        return true;
      } catch (_) {
        return false;
      } finally {
        _pending--;
        notifyListeners();
      }
    });
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }
}
