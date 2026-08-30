import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../core/models.dart';

/// Charge le contenu depuis `assets/data/`.
///
/// Le contenu est volontairement séparé du code (CDC §6) : modifier un quiz ou
/// un dialogue n'implique aucune modification de la logique du jeu.
///
/// Migration Firestore : remplacer `_load` par une lecture de collection.
/// Les modèles et le moteur de scène restent inchangés.
class ContentRepository {
  ContentRepository._(
    this._scenes,
    this._quiz,
    this._actions,
    this._notions,
    this.chapitreTitre,
    this.chapitreParcours,
  );

  final List<Scene> _scenes;
  final Map<String, QuizQuestion> _quiz;
  final Map<String, RealAction> _actions;
  final Map<String, Notion> _notions;

  final String chapitreTitre;
  final String chapitreParcours;

  List<Scene> get scenes => List.unmodifiable(_scenes);
  List<Notion> get notions => List.unmodifiable(_notions.values);

  Scene? sceneById(String id) {
    for (final s in _scenes) {
      if (s.id == id) return s;
    }
    return null;
  }

  Scene get premiereScene => _scenes.first;

  QuizQuestion? quiz(String id) => _quiz[id];
  RealAction? action(String id) => _actions[id];
  Notion? notion(String id) => _notions[id];

  static Future<Map<String, dynamic>> _load(String name) async {
    final raw = await rootBundle.loadString('assets/data/$name.json');
    return json.decode(raw) as Map<String, dynamic>;
  }

  static Future<ContentRepository> load() async {
    final scenesJson = await _load('scenes');
    final quizJson = await _load('quiz');
    final actionsJson = await _load('real_actions');
    final knowledgeJson = await _load('knowledge');

    final scenes = (scenesJson['scenes'] as List)
        .map((s) => Scene.fromJson(s as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.ordre.compareTo(b.ordre));

    final quiz = <String, QuizQuestion>{};
    for (final q in quizJson['questions'] as List) {
      final parsed = QuizQuestion.fromJson(q as Map<String, dynamic>);
      quiz[parsed.id] = parsed;
    }

    final actions = <String, RealAction>{};
    for (final a in actionsJson['actions'] as List) {
      final parsed = RealAction.fromJson(a as Map<String, dynamic>);
      actions[parsed.id] = parsed;
    }

    final notions = <String, Notion>{};
    for (final n in knowledgeJson['notions'] as List) {
      final parsed = Notion.fromJson(n as Map<String, dynamic>);
      notions[parsed.id] = parsed;
    }

    final chap = scenesJson['chapitre'] as Map<String, dynamic>? ?? const {};

    final repo = ContentRepository._(
      scenes,
      quiz,
      actions,
      notions,
      chap['titre'] as String? ?? 'Chapitre 1',
      chap['parcours'] as String? ?? '',
    );
    repo._verifierIntegrite();
    return repo;
  }

  /// Garde-fou de développement : toute référence cassée entre les JSON
  /// (un quiz ou une action absent) doit échouer au chargement, jamais
  /// bloquer le joueur en plein chapitre.
  void _verifierIntegrite() {
    final erreurs = <String>[];
    final ids = _scenes.map((s) => s.id).toSet();
    for (final s in _scenes) {
      for (final b in s.beats) {
        switch (b.type) {
          case 'quiz':
            if (!_quiz.containsKey(b.questionId)) {
              erreurs.add('${s.id}: quiz introuvable "${b.questionId}"');
            }
          case 'real_action':
            if (!_actions.containsKey(b.actionId)) {
              erreurs.add('${s.id}: action introuvable "${b.actionId}"');
            }
          case 'transition':
            if (!ids.contains(b.vers)) {
              erreurs.add('${s.id}: scène introuvable "${b.vers}"');
            }
        }
      }
    }
    if (erreurs.isNotEmpty) {
      throw StateError('Contenu NOUR incohérent :\n${erreurs.join('\n')}');
    }
  }
}
