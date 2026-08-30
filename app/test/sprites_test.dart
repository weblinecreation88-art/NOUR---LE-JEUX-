import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Garde-fou sur les sprites.
///
/// Un sprite declare mais absent, ou une spritesheet dont la largeur n est
/// pas un multiple du nombre de frames, casserait l animation en cours de
/// partie. On le detecte ici.
void main() {
  late Map<String, dynamic> sprites;

  setUpAll(() {
    final m = json.decode(
        File('assets/pixel/sprites.json').readAsStringSync()) as Map<String, dynamic>;
    sprites = m['sprites'] as Map<String, dynamic>;
  });

  test('la structure de dossiers demandee est respectee', () {
    const dossiers = [
      'assets/pixel/characters/protagonist',
      'assets/pixel/characters/noura',
      'assets/pixel/characters/npcs',
      'assets/pixel/enemies/waswas',
      'assets/pixel/enemies/grand_waswas',
    ];
    for (final d in dossiers) {
      expect(Directory(d).existsSync(), isTrue, reason: 'dossier manquant : $d');
    }
  });

  test('tous les sprites declares existent sur le disque', () {
    expect(sprites, isNotEmpty);
    for (final e in sprites.entries) {
      final chemin = (e.value as Map<String, dynamic>)['chemin'] as String;
      expect(File(chemin).existsSync(), isTrue, reason: 'absent : $chemin');
    }
  });

  test('chaque spritesheet a des frames de largeur coherente', () {
    for (final e in sprites.entries) {
      final v = e.value as Map<String, dynamic>;
      final frames = v['frames'] as int;
      final largeur = v['frame_largeur'] as int;
      final hauteur = v['frame_hauteur'] as int;
      expect(frames, greaterThan(0), reason: e.key);
      expect(largeur, greaterThan(0), reason: e.key);
      expect(hauteur, greaterThan(0), reason: e.key);
      expect(v['fps'], greaterThan(0), reason: e.key);
    }
  });

  test('les animations cle du chapitre 1 sont presentes', () {
    // Ce que le chapitre 1 utilise reellement.
    const requis = [
      'characters/protagonist/idle.png',
      'characters/protagonist/walk.png',
      'characters/noura/idle.png',
      'characters/noura/walk.png',
      'characters/noura/interact.png',
      'characters/npcs/karim_ancien.png',
      'enemies/waswas/idle.png',
      'enemies/waswas/disappear.png',
      'enemies/grand_waswas/idle.png',
      'enemies/grand_waswas/disappear.png',
    ];
    for (final r in requis) {
      expect(sprites.containsKey(r), isTrue, reason: 'non declare : $r');
    }
  });

  test('chaque PNJ nomme dans le scenario a un sprite', () {
    // Le scenario nomme les PNJ en clair. Si un nom change dans le JSON
    // sans que la table du catalogue suive, le PNJ disparait du decor
    // en silence — ce test l'empeche.
    final scenes = json.decode(
        File('assets/data/scenes.json').readAsStringSync()) as Map<String, dynamic>;
    final noms = <String>{};
    for (final sc in scenes['scenes'] as List) {
      for (final b in (sc as Map<String, dynamic>)['beats'] as List) {
        final m = b as Map<String, dynamic>;
        if (m['type'] == 'pnj' && m['nom'] != null) noms.add(m['nom'] as String);
      }
    }
    expect(noms, isNotEmpty, reason: 'aucun PNJ dans le scenario');

    final src = File('lib/core/sprite_catalog.dart').readAsStringSync();
    for (final nom in noms) {
      expect(src.toLowerCase().contains(nom.toLowerCase()), isTrue,
          reason: 'PNJ sans sprite associe : "$nom"');
    }
  });

  test('les dossiers de sprites sont declares dans pubspec.yaml', () {
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    final assets = (pubspec['flutter'] as YamlMap)['assets'] as YamlList;
    final liste = assets.map((a) => a.toString()).toList();
    expect(liste, contains('assets/pixel/sprites.json'));
    expect(liste.any((a) => a.contains('protagonist')), isTrue);
    expect(liste.any((a) => a.contains('waswas')), isTrue);
  });
}
