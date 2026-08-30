import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nour/core/models.dart';

/// Simulation d'une partie complete, sans UI : on rejoue le chapitre 1
/// beat par beat comme le ferait un joueur, et on verifie qu'on atteint
/// bien la fin sans blocage.
void main() {
  test('un joueur peut traverser le chapitre 1 de bout en bout', () {
    Map<String, dynamic> lire(String n) =>
        json.decode(File('assets/data/$n.json').readAsStringSync())
            as Map<String, dynamic>;

    final scenes = <String, Scene>{
      for (final s in lire('scenes')['scenes'] as List)
        (s as Map<String, dynamic>)['id'] as String: Scene.fromJson(s)
    };

    var scene = scenes.values.firstWhere((s) => s.ordre == 1);
    var i = 0, xp = 0, gardeFou = 0;
    var quiz = 0, actionsFaites = 0;
    final visitees = <String>{scene.id};
    var fini = false;

    while (gardeFou++ < 500) {
      if (i >= scene.beats.length) break;
      final b = scene.beats[i];

      switch (b.type) {
        case 'xp':
          xp += b.montant;
        case 'quiz':
          quiz++;
        case 'real_action':
          actionsFaites++;
        case 'fin':
          fini = true;
        case 'transition':
          scene = scenes[b.vers]!;
          visitees.add(scene.id);
          i = 0;
          continue;
      }
      if (fini) break;
      i++;
    }

    expect(fini, isTrue, reason: 'le chapitre ne se termine pas');
    expect(visitees.length, 9, reason: 'toutes les scenes ne sont pas visitees');
    expect(quiz, 8, reason: 'nombre de quiz traverses');
    expect(actionsFaites, 8, reason: 'nombre d actions reelles');
    expect(xp, 910, reason: 'XP total du chapitre');
    expect(gardeFou, lessThan(500), reason: 'boucle infinie detectee');
  });
}
