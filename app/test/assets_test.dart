import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Garde-fou : un decor qui reference une illustration absente casserait
/// l affichage en cours de partie. On le detecte ici, pas chez le joueur.
void main() {
  test('toutes les illustrations referencees existent sur le disque', () {
    final src = File('lib/ui/decor_painter.dart').readAsStringSync();
    final chemins = RegExp(r"'(assets/bg/[^']+)'")
        .allMatches(src)
        .map((m) => m.group(1)!)
        .toSet();

    expect(chemins, isNotEmpty, reason: 'aucun fond declare');
    for (final c in chemins) {
      expect(File(c).existsSync(), isTrue, reason: 'fichier manquant : $c');
    }
  });

  test('le logo de l ecran-titre existe', () {
    final src = File('lib/main.dart').readAsStringSync();
    for (final m in RegExp(r"'(assets/bg/[^']+)'").allMatches(src)) {
      expect(File(m.group(1)!).existsSync(), isTrue,
          reason: 'fichier manquant : ${m.group(1)}');
    }
  });

  test('le dossier assets/bg est bien declare dans pubspec.yaml', () {
    final pubspec =
        loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    final assets = (pubspec['flutter'] as YamlMap)['assets'] as YamlList;
    expect(assets.contains('assets/bg/'), isTrue);
  });

  test('chaque decor de scenes.json est rendu (peint ou procedural)', () {
    final scenes = json.decode(
        File('assets/data/scenes.json').readAsStringSync()) as Map<String, dynamic>;
    final decors = (scenes['scenes'] as List)
        .map((s) => (s as Map<String, dynamic>)['decor'] as String)
        .toSet();

    final src = File('lib/ui/decor_painter.dart').readAsStringSync();
    for (final d in decors) {
      // soit une illustration declaree, soit un case du painter procedural,
      // soit le default du switch.
      final peint = src.contains("'$d': 'assets/bg/");
      final procedural = src.contains("case '$d':") || d == 'vallee';
      expect(peint || procedural, isTrue, reason: 'decor non rendu : $d');
    }
  });
}
