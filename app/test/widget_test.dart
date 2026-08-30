import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nour/core/models.dart';

/// Tests QA du contenu et du moteur.
///
/// Ils vérifient d'abord l'intégrité du contenu (aucune référence cassée),
/// puis les règles non négociables du CDC (§3, §8, §11) — celles-ci doivent
/// échouer bruyamment si quelqu'un les casse par inadvertance.

Map<String, dynamic> _lire(String nom) => json.decode(
      File('assets/data/$nom.json').readAsStringSync(),
    ) as Map<String, dynamic>;

void main() {
  late List<Scene> scenes;
  late Map<String, QuizQuestion> quiz;
  late Map<String, RealAction> actions;
  late Map<String, Notion> notions;

  setUpAll(() {
    scenes = (_lire('scenes')['scenes'] as List)
        .map((s) => Scene.fromJson(s as Map<String, dynamic>))
        .toList();
    quiz = {
      for (final q in _lire('quiz')['questions'] as List)
        (q as Map<String, dynamic>)['id'] as String: QuizQuestion.fromJson(q)
    };
    actions = {
      for (final a in _lire('real_actions')['actions'] as List)
        (a as Map<String, dynamic>)['id'] as String: RealAction.fromJson(a)
    };
    notions = {
      for (final n in _lire('knowledge')['notions'] as List)
        (n as Map<String, dynamic>)['id'] as String: Notion.fromJson(n)
    };
  });

  group('Intégrité du contenu', () {
    test('les 9 scènes du chapitre 1 sont présentes et ordonnées', () {
      expect(scenes.length, 9);
      final ordres = scenes.map((s) => s.ordre).toList()..sort();
      expect(ordres, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('chaque référence de beat pointe vers un contenu existant', () {
      final ids = scenes.map((s) => s.id).toSet();
      for (final s in scenes) {
        for (final b in s.beats) {
          switch (b.type) {
            case 'quiz':
              expect(quiz.containsKey(b.questionId), isTrue,
                  reason: '${s.id} → quiz ${b.questionId}');
            case 'real_action':
              expect(actions.containsKey(b.actionId), isTrue,
                  reason: '${s.id} → action ${b.actionId}');
            case 'transition':
              expect(ids.contains(b.vers), isTrue,
                  reason: '${s.id} → scène ${b.vers}');
          }
        }
      }
    });

    test('chaque quiz pointe vers une notion de la bibliothèque', () {
      for (final q in quiz.values) {
        expect(notions.containsKey(q.notion), isTrue, reason: q.id);
      }
    });

    test('l\'index de bonne réponse est valide pour chaque quiz', () {
      for (final q in quiz.values) {
        expect(q.reponse, greaterThanOrEqualTo(0), reason: q.id);
        expect(q.reponse, lessThan(q.choix.length), reason: q.id);
      }
    });

    test('la dernière scène se termine par un beat de fin', () {
      final derniere = scenes.firstWhere((s) => s.ordre == 9);
      expect(derniere.beats.last.type, 'fin');
    });

    test('toutes les scènes sauf la dernière mènent quelque part', () {
      for (final s in scenes.where((s) => s.ordre < 9)) {
        expect(s.beats.any((b) => b.type == 'transition'), isTrue,
            reason: '${s.id} n\'a pas de transition');
      }
    });
  });

  group('Règles non négociables — contenu islamique (CDC §3, §8)', () {
    test('toute question porte une source et une référence non vides', () {
      for (final q in quiz.values) {
        expect(q.source.trim(), isNotEmpty, reason: q.id);
        expect(q.reference.trim(), isNotEmpty, reason: q.id);
      }
    });

    test('toute notion porte une source et une référence non vides', () {
      for (final n in notions.values) {
        expect(n.source.trim(), isNotEmpty, reason: n.id);
        expect(n.reference.trim(), isNotEmpty, reason: n.id);
      }
    });

    test(
        'aucun contenu religieux n\'est marqué VALIDE sans validation humaine',
        () {
      // Seule exception admise : la phrase de philosophie du jeu, qui n'est
      // pas un texte religieux (CDC §10 Q10).
      final valides =
          quiz.values.where((q) => q.statut.estValide).map((q) => q.id).toSet();
      expect(valides, {'q10_ilm'},
          reason: 'Un contenu religieux a été marqué VALIDE sans validation. '
              'Seul q10_ilm (formulation pédagogique) peut l\'être.');

      final notionsValides =
          notions.values.where((n) => n.statut.estValide).map((n) => n.id);
      expect(notionsValides, isEmpty,
          reason: 'Aucune notion ne doit être VALIDE avant vérification.');
    });
  });

  group('Règles non négociables — protection du joueur (CDC §9, §11, §16)', () {
    test('aucune action réelle ne demande de preuve intrusive', () {
      const interdits = [
        'photo',
        'capture',
        'selfie',
        'enregistre',
        'audio',
        'micro',
        'localisation',
        'gps',
        'position',
        'preuve',
        'prouve',
        'vérifier que tu',
      ];
      for (final a in actions.values) {
        final texte =
            '${a.titre} ${a.variantes.join(' ')}'.toLowerCase();
        for (final mot in interdits) {
          expect(texte.contains(mot), isFalse,
              reason: 'Action ${a.id} contient le terme interdit "$mot"');
        }
      }
    });

    test('chaque action réelle propose au moins deux variantes de contexte',
        () {
      for (final a in actions.values) {
        expect(a.variantes.length, greaterThanOrEqualTo(2), reason: a.id);
      }
    });

    test('l\'XP est toujours positive et jamais retirée', () {
      for (final s in scenes) {
        for (final b in s.beats.where((b) => b.type == 'xp')) {
          expect(b.montant, greaterThan(0), reason: s.id);
        }
      }
    });
  });

  group('Boucle de gameplay (CDC §4)', () {
    test('chaque scène de progression contient une action réelle', () {
      // Le carrefour (scène 2) est un pur choix narratif ; toutes les autres
      // doivent ramener le joueur vers la vraie vie.
      for (final s in scenes.where((s) => s.ordre != 2)) {
        expect(s.beats.any((b) => b.type == 'real_action'), isTrue,
            reason: '${s.id} n\'a pas d\'action réelle');
      }
    });

    test('chaque action réelle est suivie d\'une récompense XP', () {
      for (final s in scenes) {
        for (var i = 0; i < s.beats.length; i++) {
          if (s.beats[i].type != 'real_action') continue;
          final suite = s.beats.sublist(i + 1);
          expect(suite.any((b) => b.type == 'xp'), isTrue,
              reason: '${s.id}: action sans XP derrière');
        }
      }
    });

    test('la Lumière ne recule jamais d\'une scène à l\'autre', () {
      final ordonnees = [...scenes]..sort((a, b) => a.ordre.compareTo(b.ordre));
      for (var i = 1; i < ordonnees.length; i++) {
        expect(ordonnees[i].lumiere,
            greaterThanOrEqualTo(ordonnees[i - 1].lumiere),
            reason: '${ordonnees[i].id} fait reculer la Lumière');
      }
    });

    test('Noura apparaît bien dans le parcours', () {
      expect(scenes.any((s) => s.beats.any((b) => b.type == 'noura')), isTrue);
    });
  });
}
