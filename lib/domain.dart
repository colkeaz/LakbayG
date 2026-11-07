import 'dart:convert';

import 'package:flutter/services.dart';

typedef Json = Map<String, dynamic>;

class LocalText {
  final String en, fil;
  const LocalText(this.en, this.fil);
  factory LocalText.parse(dynamic value) {
    final j = value as Json;
    if ((j['en'] as String).trim().isEmpty ||
        (j['fil'] as String).trim().isEmpty) {
      throw const FormatException('Missing translation');
    }
    return LocalText(j['en'], j['fil']);
  }
  String at(String language) => language == 'fil' ? fil : en;
}

class Source {
  final String id, title, url, checked, section;
  Source(Json j)
    : id = j['id'],
      title = j['title'],
      url = j['url'],
      checked = j['checked'],
      section = j['section'];
}

class Requirement {
  final String id;
  final LocalText text;
  Requirement(Json j) : id = j['id'], text = LocalText.parse(j['text']);
}

class ProcessStep {
  final LocalText title, detail, place;
  ProcessStep(Json j)
    : title = LocalText.parse(j['title']),
      detail = LocalText.parse(j['detail']),
      place = LocalText.parse(j['place']);
}

class Service {
  final String id, agency, url;
  final bool verified;
  final LocalText title, summary, location, notice;
  final List<ProcessStep> steps;
  final List<Requirement> requirements;
  final List<String> sources;
  Service(Json j)
    : id = j['id'],
      agency = j['agency'],
      url = j['url'],
      verified = j['verified'],
      title = LocalText.parse(j['title']),
      summary = LocalText.parse(j['summary']),
      location = LocalText.parse(j['location']),
      notice = LocalText.parse(j['notice']),
      steps = (j['steps'] as List).map((e) => ProcessStep(e)).toList(),
      requirements = (j['requirements'] as List)
          .map((e) => Requirement(e))
          .toList(),
      sources = List<String>.from(j['sources']);
}

class Choice {
  final String id, next;
  final LocalText text;
  Choice(Json j)
    : id = j['id'],
      next = j['next'],
      text = LocalText.parse(j['text']);
}

class Question {
  final String id;
  final LocalText text;
  final List<Choice> choices;
  Question(Json j)
    : id = j['id'],
      text = LocalText.parse(j['text']),
      choices = (j['choices'] as List).map((e) => Choice(e)).toList();
}

class Referral {
  final String id, url;
  final LocalText reason;
  Referral(Json j)
    : id = j['id'],
      url = j['url'],
      reason = LocalText.parse(j['reason']);
}

class Catalog {
  final List<Service> services;
  final List<Source> sources;
  final List<Question> questions;
  final List<Referral> referrals;
  Catalog(Json j)
    : services = (j['services'] as List).map((e) => Service(e)).toList(),
      sources = (j['sources'] as List).map((e) => Source(e)).toList(),
      questions = (j['questions'] as List).map((e) => Question(e)).toList(),
      referrals = (j['referrals'] as List).map((e) => Referral(e)).toList() {
    validate();
  }
  Service service(String id) => services.firstWhere((s) => s.id == id);
  Question question(String id) => questions.firstWhere((q) => q.id == id);
  void validate() {
    void unique(Iterable<String> ids) {
      final values = ids.toList();
      if (values.toSet().length != values.length) {
        throw const FormatException('Duplicate identifier');
      }
    }

    unique(services.map((s) => s.id));
    unique(sources.map((s) => s.id));
    unique([
      ...questions.map((q) => q.id),
      ...referrals.map((r) => r.id),
      ...services.map((s) => 'service:${s.id}'),
    ]);
    bool validUrl(String url) {
      final u = Uri.tryParse(url);
      return u != null && u.scheme == 'https' && u.host.isNotEmpty;
    }

    for (final s in sources) {
      if (!validUrl(s.url) || DateTime.tryParse(s.checked) == null) {
        throw const FormatException('Invalid source');
      }
    }
    for (final s in services) {
      unique(s.requirements.map((r) => r.id));
      if (!validUrl(s.url) ||
          s.sources.isEmpty ||
          s.sources.any((id) => !sources.any((r) => r.id == id))) {
        throw const FormatException('Invalid service references');
      }
      if (s.verified && (s.steps.isEmpty || s.requirements.isEmpty)) {
        throw const FormatException('Empty verified journey');
      }
      if (!s.verified && (s.steps.isNotEmpty || s.requirements.isNotEmpty)) {
        throw const FormatException('Unverified procedure');
      }
    }
    for (final r in referrals) {
      if (!validUrl(r.url)) {
        throw const FormatException('Invalid referral');
      }
    }
    final visited = <String>{};
    void visit(String id, Set<String> path) {
      if (path.contains(id)) {
        throw const FormatException('Question cycle');
      }
      if (id.startsWith('service:')) {
        service(id.substring(8));
        visited.add(id);
        return;
      }
      if (referrals.any((r) => r.id == id)) {
        visited.add(id);
        return;
      }
      final q = question(id);
      visited.add(id);
      unique(q.choices.map((c) => c.id));
      if (q.choices.length < 2) {
        throw const FormatException('Insufficient choices');
      }
      for (final c in q.choices) {
        visit(c.next, {...path, id});
      }
    }

    visit('start', {});
    if (questions.any((q) => !visited.contains(q.id)) ||
        services.any((s) => !visited.contains('service:${s.id}')) ||
        referrals.any((r) => !visited.contains(r.id))) {
      throw const FormatException('Unreachable content');
    }
  }
}

class ServiceRepository {
  Future<Catalog> load() async => Catalog(
    jsonDecode(await rootBundle.loadString('assets/catalog.json')) as Json,
  );
}

/// A path, rather than a bag of answers, prevents stale dependent selections.
class NavigationEngine {
  final Catalog catalog;
  final List<String> path = ['start'];
  final Map<String, String> answers = {};
  int position = 0;
  NavigationEngine(this.catalog);
  String get current => path[position];
  bool get isQuestion => catalog.questions.any((q) => q.id == current);
  void select(String choiceId) {
    final q = catalog.question(current);
    q.choices.firstWhere((c) => c.id == choiceId);
    if (answers[current] != choiceId) {
      for (final id in path.skip(position + 1)) {
        answers.remove(id);
      }
      path.removeRange(position + 1, path.length);
    }
    answers[current] = choiceId;
  }

  bool next() {
    final selected = answers[current];
    if (selected == null) {
      return false;
    }
    final target = catalog
        .question(current)
        .choices
        .firstWhere((c) => c.id == selected)
        .next;
    if (path.length == position + 1) {
      path.add(target);
    }
    position++;
    return true;
  }

  bool back() {
    if (position == 0) {
      return false;
    }
    position--;
    return true;
  }

  void restart() {
    path
      ..clear()
      ..add('start');
    answers.clear();
    position = 0;
  }
}
