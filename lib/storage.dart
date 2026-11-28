import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppointmentNote {
  static final RegExp validReferencePattern = RegExp(r'^[A-Za-z0-9\-/_ ]+$');
  static final RegExp validSchedulePattern = RegExp(
    r"^[A-Za-z0-9\s,.:;/\-()@#&'·+]+$",
  );

  final String referenceNo;
  final String scheduleNote;
  const AppointmentNote({
    required this.referenceNo,
    required this.scheduleNote,
  });

  static bool isValidReference(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed.length <= 60 &&
        validReferencePattern.hasMatch(trimmed);
  }

  static bool isValidSchedule(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ||
        (trimmed.length <= 140 && validSchedulePattern.hasMatch(trimmed));
  }
}

class LocalStore {
  final Database database;
  LocalStore(this.database);
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
          await db.execute(
            'CREATE TABLE appointments (service TEXT PRIMARY KEY, reference_no TEXT NOT NULL, schedule_note TEXT NOT NULL)',
          );
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'CREATE TABLE IF NOT EXISTS appointments (service TEXT PRIMARY KEY, reference_no TEXT NOT NULL, schedule_note TEXT NOT NULL)',
            );
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

class AppointmentRepository {
  final LocalStore store;
  AppointmentRepository(this.store);
  Future<Map<String, AppointmentNote>> read() async {
    final result = <String, AppointmentNote>{};
    for (final row in await store.database.query('appointments')) {
      result[row['service'] as String] = AppointmentNote(
        referenceNo: row['reference_no'] as String,
        scheduleNote: row['schedule_note'] as String,
      );
    }
    return result;
  }

  Future<void> save(String service, AppointmentNote note) async {
    await store.database.insert('appointments', {
      'service': service,
      'reference_no': note.referenceNo,
      'schedule_note': note.scheduleNote,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clear(String service) async {
    await store.database.delete(
      'appointments',
      where: 'service = ?',
      whereArgs: [service],
    );
  }
}

class AppController extends ChangeNotifier {
  final ChecklistRepository checklists;
  final SettingsRepository settings;
  final AppointmentRepository appointments;
  Map<String, Set<String>> prepared = {};
  Map<String, AppointmentNote> savedAppointments = {};
  String language = 'en';
  bool firstLaunch = true, busy = false;
  AppController(
    this.checklists,
    this.settings, [
    AppointmentRepository? appointments,
  ]) : appointments = appointments ?? AppointmentRepository(checklists.store);

  Future<void> initialize() async {
    prepared = await checklists.read();
    savedAppointments = await appointments.read();
    final stored = await settings.language();
    firstLaunch = stored == null;
    language = stored == 'fil' ? 'fil' : 'en';
  }

  bool checked(String service, String requirement) =>
      prepared[service]?.contains(requirement) ?? false;

  AppointmentNote? appointment(String service) => savedAppointments[service];

  Future<bool> changeLanguage(String value) async => _save(() async {
    await settings.setLanguage(value);
    language = value;
    firstLaunch = false;
  });

  Future<bool> toggle(String service, String requirement, bool value) async =>
      _save(() async {
        await checklists.set(service, requirement, value);
        final items = prepared[service] ??= <String>{};
        if (value) {
          items.add(requirement);
        } else {
          items.remove(requirement);
        }
      });

  Future<bool> reset(String service) async => _save(() async {
    await checklists.reset(service);
    prepared.remove(service);
  });

  Future<bool> saveAppointment(
    String service,
    String referenceNo,
    String scheduleNote,
  ) async {
    final cleanedRef = referenceNo.trim();
    final cleanedSchedule = scheduleNote.trim();
    if (!AppointmentNote.isValidReference(cleanedRef) ||
        !AppointmentNote.isValidSchedule(cleanedSchedule)) {
      return false;
    }
    final note = AppointmentNote(
      referenceNo: cleanedRef,
      scheduleNote: cleanedSchedule,
    );
    return _save(() async {
      await appointments.save(service, note);
      savedAppointments[service] = note;
    });
  }

  Future<bool> clearAppointment(String service) async => _save(() async {
    await appointments.clear(service);
    savedAppointments.remove(service);
  });

  Future<bool> _save(Future<void> Function() operation) async {
    if (busy) {
      return false;
    }
    busy = true;
    notifyListeners();
    try {
      await operation();
      return true;
    } catch (_) {
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
