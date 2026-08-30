import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;

/// Une spritesheet et sa cadence, décrites par `assets/pixel/sprites.json`.
///
/// Aucune dimension n'est codée en dur : remplacer une planche et relancer
/// `tools/decoupe_sprites.py` régénère le manifeste, et le jeu suit.
class SpriteAnim {
  const SpriteAnim({
    required this.chemin,
    required this.frames,
    required this.largeur,
    required this.hauteur,
    required this.fps,
    required this.boucle,
    required this.image,
  });

  final String chemin;
  final int frames;
  final int largeur;
  final int hauteur;
  final int fps;
  final bool boucle;
  final ui.Image image;

  double get ratio => largeur / hauteur;

  /// Index de frame pour un temps donné (en secondes).
  int frameA(double t) {
    if (frames <= 1) return 0;
    final i = (t * fps).floor();
    return boucle ? i % frames : i.clamp(0, frames - 1);
  }

  /// Rectangle source de la frame dans la planche.
  ui.Rect rectSource(int i) => ui.Rect.fromLTWH(
        (i * largeur).toDouble(),
        0,
        largeur.toDouble(),
        hauteur.toDouble(),
      );
}

/// Charge et met en cache les sprites du jeu.
///
/// Le chargement est tolérant : si une planche manque, l'animation est
/// simplement absente et le rendu procédural prend le relais. Un asset
/// manquant ne doit jamais interrompre une partie.
class SpriteCatalog {
  SpriteCatalog._(this._anims);

  final Map<String, SpriteAnim> _anims;

  SpriteAnim? operator [](String cle) => _anims[cle];
  bool get estVide => _anims.isEmpty;
  int get nombre => _anims.length;

  static Future<ui.Image> _decoder(String chemin) async {
    final data = await rootBundle.load(chemin);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<SpriteCatalog> load() async {
    final anims = <String, SpriteAnim>{};
    try {
      final raw = await rootBundle.loadString('assets/pixel/sprites.json');
      final doc = json.decode(raw) as Map<String, dynamic>;
      final sprites = doc['sprites'] as Map<String, dynamic>;

      for (final e in sprites.entries) {
        final v = e.value as Map<String, dynamic>;
        final chemin = v['chemin'] as String;
        try {
          anims[e.key] = SpriteAnim(
            chemin: chemin,
            frames: v['frames'] as int,
            largeur: v['frame_largeur'] as int,
            hauteur: v['frame_hauteur'] as int,
            fps: v['fps'] as int,
            boucle: v['boucle'] as bool,
            image: await _decoder(chemin),
          );
        } catch (_) {
          // Planche absente ou illisible : on continue sans elle.
        }
      }
    } catch (_) {
      // Manifeste absent : le jeu tourne en rendu procédural.
    }
    return SpriteCatalog._(anims);
  }

  // Raccourcis utilisés par le jeu.
  SpriteAnim? get protagonisteIdle => _anims['characters/protagonist/idle.png'];
  SpriteAnim? get protagonisteWalk => _anims['characters/protagonist/walk.png'];
  SpriteAnim? get nouraIdle => _anims['characters/noura/idle.png'];
  SpriteAnim? get nouraInteract => _anims['characters/noura/interact.png'];
  SpriteAnim? get waswasIdle => _anims['enemies/waswas/idle.png'];
  SpriteAnim? get waswasDisparait => _anims['enemies/waswas/disappear.png'];
  SpriteAnim? get grandWaswasIdle => _anims['enemies/grand_waswas/idle.png'];
  SpriteAnim? get grandWaswasDisparait =>
      _anims['enemies/grand_waswas/disappear.png'];
  SpriteAnim? get karim => _anims['characters/npcs/karim_ancien.png'];
  SpriteAnim? npc(String nom) => _anims['characters/npcs/$nom.png'];

  /// Nom affiche dans le scenario -> fichier de sprite.
  ///
  /// Le scenario nomme les PNJ en clair ("Un homme au puits"). Cette table
  /// evite de coder ces libelles dans le moteur : le contenu reste editable
  /// dans les JSON sans toucher au code.
  static const _parNom = <String, String>{
    'un homme au puits': 'homme_puits',
    "une femme sous l'auvent": 'femme_auvent',
    'un jeune du village': 'jeune_village',
  };

  /// Sprite du PNJ qui parle, ou null si aucun ne correspond.
  SpriteAnim? pnjParNom(String? nom) {
    if (nom == null) return null;
    final cle = _parNom[nom.toLowerCase().trim()];
    return cle == null ? null : npc(cle);
  }
}
