import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

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
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE checklist (service TEXT NOT NULL, requirement TEXT NOT NULL, PRIMARY KEY(service, requirement))',
          );
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
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

class AppController extends ChangeNotifier {
  final ChecklistRepository checklists;
  final SettingsRepository settings;
  Map<String, Set<String>> prepared = {};
  String language = 'en';
  bool firstLaunch = true, busy = false;
  AppController(this.checklists, this.settings);
  Future<void> initialize() async {
    prepared = await checklists.read();
    final stored = await settings.language();
    firstLaunch = stored == null;
    language = stored == 'fil' ? 'fil' : 'en';
  }

  bool checked(String service, String requirement) =>
      prepared[service]?.contains(requirement) ?? false;
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
