import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/sprite_catalog.dart';

/// Décors du jeu.
///
/// Deux sources possibles, transparentes pour le reste du code :
///  1. un **fond peint** (`assets/bg/…`) quand l'illustration existe ;
///  2. un fond **procédural** (CustomPainter) en placeholder sinon.
///
/// Dans les deux cas les acteurs (protagoniste, Noura, Waswas, compagnon) et
/// la lanterne sont composés par-dessus, animés. Ajouter une illustration =
/// ajouter une ligne dans `_fonds`, rien d'autre à changer.
class DecorView extends StatelessWidget {
  const DecorView({
    super.key,
    required this.decor,
    required this.lumiere,
    this.waswasVisible = false,
    this.nouraVisible = false,
    this.nouraParle = false,
    this.compagnonVisible = false,
    this.pnjNom,
    this.animation = 0,
    this.sprites,
    this.temps = 0,
  });

  final String decor;
  final int lumiere;
  final bool waswasVisible;
  final bool nouraVisible;

  /// Noura prononce la replique courante : on la montre alors de face,
  /// tournee vers le joueur. Elle parle 17 fois dans le chapitre — la voir
  /// de dos pendant un dialogue est etrange.
  final bool nouraParle;

  final bool compagnonVisible;

  /// Nom du PNJ qui prononce la replique courante, tel qu'ecrit dans le
  /// scenario. Null si personne ne parle.
  final String? pnjNom;

  /// Phase 0..1 pour les micro-animations (respiration, halo, flottement).
  final double animation;

  /// Sprites chargés. Null ou incomplet -> repli sur le rendu procédural :
  /// une planche manquante ne doit jamais interrompre une partie.
  final SpriteCatalog? sprites;

  /// Temps écoulé en secondes, pour cadencer les spritesheets.
  final double temps;

  /// Illustrations disponibles. Les décors absents de cette table sont rendus
  /// procéduralement en attendant leur illustration définitive.
  static const _fonds = <String, String>{
    'chambre': 'assets/bg/chambre.png',
    'carrefour': 'assets/bg/carrefour.png',
    'waswas': 'assets/bg/waswas.png',
    'vallee': 'assets/bg/vallee.png',
    'village': 'assets/bg/village.png',
    'riviere': 'assets/bg/riviere.png',
    'climax': 'assets/bg/climax.png',
  };

  static const _fondsAvecProtagoniste = <String>{};

  /// Fonds peints qui contiennent déjà Noura.
  static const _fondsAvecNoura = <String>{};

  /// Fonds peints qui contiennent déjà la masse du Waswas.
  static const _fondsAvecWaswas = <String>{};

  @override
  Widget build(BuildContext context) {
    final fond = _fonds[decor];

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (fond != null)
            Image.asset(
              fond,
              fit: BoxFit.cover,
              // Pixel art : jamais de lissage à l'agrandissement (CDC §12).
              filterQuality: FilterQuality.none,
              isAntiAlias: false,
            )
          else
            CustomPaint(
              painter: _FondPainter(decor: decor, lumiere: lumiere, t: animation),
              child: const SizedBox.expand(),
            ),

          // Voile de lumière : la scène s'éclaircit à mesure que la Lumière
          // narrative progresse, avec une très légère respiration pour que
          // l'image ne soit jamais complètement figée (CDC §5 du brief).
          // Métaphore de récit, pas une mesure de foi.
          if (fond != null && lumiere > 0)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      NourColors.lumiereHalo.withValues(
                        alpha: (0.020 + 0.012 * math.sin(animation * math.pi * 2)) *
                            (lumiere / 100),
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // Acteurs et lanterne, composés par-dessus le fond.
          CustomPaint(
            painter: _ActeursPainter(
              lumiere: lumiere,
              waswasVisible:
                  waswasVisible && !_fondsAvecWaswas.contains(decor),
              nouraVisible:
                  nouraVisible && !_fondsAvecNoura.contains(decor),
              nouraParle: nouraParle,
              compagnonVisible: compagnonVisible,
              pnjNom: pnjNom,
              protagonisteVisible: !_fondsAvecProtagoniste.contains(decor),
              sprites: sprites,
              temps: temps,
              decor: decor,
              // Les illustrations peintes ont deja leurs propres sources de
              // lumiere : y superposer la lanterne du painter ferait doublon.
              lanterneVisible: fond == null,
              t: animation,
            ),
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}

/// Base commune : grille de « pixels » logiques mise à l'échelle.
abstract class _GrillePainter extends CustomPainter {
  static const gw = 96.0;
  static const gh = 64.0;

  late double _u;
  late double _ox;
  late double _oy;

  void _cadrer(Size size) {
    _u = math.max(size.width / gw, size.height / gh);
    _ox = (size.width - gw * _u) / 2;
    _oy = (size.height - gh * _u) / 2;
  }

  void _px(Canvas c, double x, double y, double w, double h, Color col) {
    c.drawRect(
      Rect.fromLTWH(_ox + x * _u, _oy + y * _u, w * _u + 0.5, h * _u + 0.5),
      Paint()..color = col,
    );
  }
}

// ─────────────────────────────────────────────────────────── fonds procéduraux

class _FondPainter extends _GrillePainter {
  _FondPainter({required this.decor, required this.lumiere, required this.t});

  final String decor;
  final int lumiere;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    _cadrer(size);
    switch (decor) {
      case 'village':
        _village(canvas);
      case 'feu':
        _feu(canvas);
      case 'climax':
        _climax(canvas);
      default:
        _vallee(canvas);
    }
  }

  void _vallee(Canvas c) {
    _px(c, 0, 0, _GrillePainter.gw, 26, const Color(0xFFCFE4EC));
    _px(c, 0, 18, _GrillePainter.gw, 8, const Color(0xFFE8DCC0));
    _px(c, 0, 22, 40, 10, const Color(0xFFC9A870));
    _px(c, 30, 20, 44, 12, const Color(0xFFD4B57E));
    _px(c, 62, 23, 34, 9, const Color(0xFFC09A63));
    _px(c, 0, 30, _GrillePainter.gw, 34, const Color(0xFFDCC08A));
    _px(c, 34, 30, 22, 34, const Color(0xFFCBAA76));
    _px(c, 8, 34, 7, 5, const Color(0xFF7E8F55));
    _px(c, 76, 37, 8, 5, const Color(0xFF6E8049));
  }

  void _village(Canvas c) {
    _px(c, 0, 0, _GrillePainter.gw, 24, const Color(0xFFD7E8EC));
    _px(c, 0, 24, _GrillePainter.gw, 40, const Color(0xFFD8BC86));
    _px(c, 4, 12, 24, 20, const Color(0xFFE0CBA4));
    _px(c, 2, 8, 28, 5, NourColors.terreCuite);
    _px(c, 12, 22, 6, 10, NourColors.boisFonce);
    _px(c, 34, 14, 22, 18, const Color(0xFFD9C29B));
    _px(c, 32, 10, 26, 5, const Color(0xFFA85436));
    _px(c, 40, 18, 5, 5, const Color(0xFF9BB8CC));
    _px(c, 66, 13, 26, 19, const Color(0xFFE3CFA9));
    _px(c, 64, 9, 30, 5, NourColors.terreCuite);
    _px(c, 76, 21, 6, 11, NourColors.boisFonce);
    _px(c, 20, 44, 10, 7, const Color(0xFF9C8A6E));
    _px(c, 20, 42, 10, 2, NourColors.bois);
    for (var x = 0.0; x < _GrillePainter.gw; x += 7) {
      _px(c, x, 52, 5, 1, const Color(0x18000000));
    }
  }

  void _feu(Canvas c) {
    _px(c, 0, 0, _GrillePainter.gw, 30, const Color(0xFF3E4A63));
    _px(c, 0, 22, _GrillePainter.gw, 8, const Color(0xFF7A6A6E));
    _px(c, 0, 30, _GrillePainter.gw, 34, const Color(0xFF6B5638));
    for (var i = 0; i < 12; i++) {
      _px(c, (i * 13 % 90) + 3.0, (i * 7 % 16) + 2.0, 1, 1,
          const Color(0xCCFFF3D0));
    }
    final flick = (math.sin(t * math.pi * 2) + 1) / 2;
    _px(c, 42, 44, 14, 3, NourColors.boisFonce);
    _px(c, 44, 38, 10, 7, const Color(0xFFE07A3C));
    _px(c, 46, 34 - flick, 6, 6 + flick, const Color(0xFFF2A93B));
    _px(c, 48, 32 - flick, 3, 4, NourColors.lumiereHalo);
    _px(c, 32, 36, 34, 14, const Color(0x22F2C14E));
  }

  void _climax(Canvas c) {
    _px(c, 0, 0, _GrillePainter.gw, 28, const Color(0xFF9AA0AE));
    _px(c, 0, 20, _GrillePainter.gw, 10, const Color(0xFFB0A896));
    _px(c, 0, 28, _GrillePainter.gw, 36, const Color(0xFFB9A177));
    _px(c, 0, 34, 30, 30, const Color(0xFFA8906A));
    _px(c, 66, 32, 30, 32, const Color(0xFFAD9670));
    final w = 6 + lumiere / 8;
    _px(c, 44 - w / 2, 0, w, 22,
        Color.lerp(const Color(0x00FFFFFF), const Color(0x66FFE9A8), lumiere / 100)!);
  }

  @override
  bool shouldRepaint(_FondPainter old) =>
      old.decor != decor || old.lumiere != lumiere || old.t != t;
}

// ────────────────────────────────────────────────────────────────── acteurs

class _ActeursPainter extends _GrillePainter {
  _ActeursPainter({
    required this.lumiere,
    required this.waswasVisible,
    required this.nouraVisible,
    required this.compagnonVisible,
    required this.pnjNom,
    required this.protagonisteVisible,
    required this.lanterneVisible,
    required this.t,
    required this.sprites,
    required this.temps,
    required this.decor,
    required this.nouraParle,
  });

  final int lumiere;
  final bool waswasVisible;
  final bool nouraVisible;

  final bool compagnonVisible;
  final String? pnjNom;
  final bool protagonisteVisible;
  final bool lanterneVisible;
  final double t;
  final SpriteCatalog? sprites;
  final double temps;
  final String decor;
  final bool nouraParle;

  /// Mise en scene par decor : (ligne de sol, hauteur du personnage) en
  /// pixels logiques. Ajuste pour que le personnage s'integre a la
  /// perspective de chaque illustration.
  /// Ligne de sol et taille des acteurs, PAR DECOR.
  ///
  /// Chaque illustration a son propre horizon : une valeur unique donnait
  /// des personnages geants au village et minuscules sur la crete.
  ///
  /// Ordre : [ligne de sol, hauteur du personnage]. Grille logique 0..64.
  static const _cadrage = <String, List<double>>{
    // Chambre : le tapis central sert de zone de marche.
    'chambre': [50, 22],
    // Le pont est surélevé par rapport au sol par défaut.
    'carrefour': [39, 19],
    // Clairiere entre les deux arbres.
    'waswas': [50, 21],
    'village': [52, 18],
    'vallee': [50, 22],
    'riviere': [52, 21],
    'climax': [56, 20],
  };

  /// Position horizontale des acteurs, PAR DECOR.
  ///
  /// Indispensable : une position unique placait Noura dans la riviere et
  /// le compagnon hors du chemin. Chaque illustration a sa propre zone
  /// praticable — ces valeurs y posent les personnages.
  ///
  /// Ordre : [protagoniste, Noura, compagnon]. Grille logique 0..96.
  static const _placement = <String, List<double>>{
    // Chambre : sur le tapis, au centre. Noura n'y apparait jamais.
    'chambre': [44, 62, 26],
    // Clairiere : le protagoniste a gauche, le waswas lui fait face.
    'waswas': [34, 20, 50],
    // Chemin à gauche, avant le pont (pour ne pas être sur l'eau).
    'carrefour': [24, 38, 12],
    // Berge de gauche : l'eau occupe le centre-droit.
    'riviere': [30, 18, 42],
    // Chemin central, large.
    'vallee': [40, 55, 27],
    // Place du village, devant le puits.
    'village': [40, 56, 28],
    // Crête dégagée (climax), on les centre sur l'esplanade (le Waswas arrive à droite).
    'climax': [50, 38, 62],
  };

  double get _sol => _cadrage[decor]?[0] ?? 48;
  double get _tailleActeur => _cadrage[decor]?[1] ?? 26;

  double _x(int role, double defaut) {
    final p = _placement[decor];
    return p == null ? defaut : p[role];
  }

  /// Dessine une frame de spritesheet dans la grille logique.
  ///
  /// `x` et `basY` sont exprimés en pixels logiques ; le sprite est centré
  /// horizontalement et posé sur `basY` (les pieds), pour que le personnage
  /// ne « flotte » jamais et ne saute pas d'une frame à l'autre.
  void _sprite(Canvas c, SpriteAnim a, double x, double basY, double hauteur) {
    final i = a.frameA(temps);
    final larg = hauteur * a.ratio;
    final dst = Rect.fromLTWH(
      _ox + (x - larg / 2) * _u,
      _oy + (basY - hauteur) * _u,
      larg * _u,
      hauteur * _u,
    );
    c.drawImageRect(
      a.image,
      a.rectSource(i),
      dst,
      // Pixel art : jamais de lissage (CDC §12).
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _cadrer(size);
    if (decor == 'village') _villageNPCs(canvas);
    if (waswasVisible) _waswas(canvas);
    if (nouraVisible) _noura(canvas, _x(1, 58));
    if (compagnonVisible) _compagnon(canvas, _x(2, 70));
    _pnj(canvas);
    if (protagonisteVisible) _protagoniste(canvas, _x(0, 40));
    if (lanterneVisible) _lanterne(canvas);
  }

  void _villageNPCs(Canvas c) {
    final marchand = sprites?.npc('marchand');
    if (marchand != null) _sprite(c, marchand, 15, _sol, _tailleActeur * 1.05);

    final fille = sprites?.npc('fille_panier');
    if (fille != null) _sprite(c, fille, 80, _sol, _tailleActeur * 0.95);

    final enfant = sprites?.npc('enfant_pecheur');
    if (enfant != null) _sprite(c, enfant, 92, _sol, _tailleActeur * 0.85);
  }

  /// Protagoniste : silhouette simple, visage non détaillé (CDC §6, §12).
  void _protagoniste(Canvas c, double x) {
    final a = sprites?.protagonisteIdle;
    if (a != null) {
      _sprite(c, a, x + 5, _sol, _tailleActeur);
      return;
    }
    final breathe = math.sin(t * math.pi * 2) < 0 ? 0.0 : 1.0;
    const y = 36.0;
    _px(c, x + 2, y - 8 + breathe, 6, 6, const Color(0xFFD9A87E));
    _px(c, x + 2, y - 9 + breathe, 6, 2, const Color(0xFF4A3524));
    _px(c, x + 1, y - 2 + breathe, 8, 9, const Color(0xFF6B7F9E));
    _px(c, x, y + 1 + breathe, 2, 6, const Color(0xFF5C6F8C));
    _px(c, x + 8, y + 1 + breathe, 2, 6, const Color(0xFF5C6F8C));
    _px(c, x + 2, y + 7, 3, 5, const Color(0xFF4A3B2C));
    _px(c, x + 6, y + 7, 3, 5, const Color(0xFF4A3B2C));
  }

  /// Noura : reconnaissable par la silhouette, les couleurs et l'accessoire —
  /// jamais par un visage détaillé (CDC §12).
  void _noura(Canvas c, double x) {
    // De face quand elle parle, de dos sinon.
    final a = nouraParle
        ? (sprites?.nouraInteract ?? sprites?.nouraIdle)
        : (sprites?.nouraIdle ?? sprites?.nouraInteract);
    if (a != null) {
      _sprite(c, a, x + 5, _sol, _tailleActeur * 1.04);
      return;
    }
    final float = math.sin(t * math.pi * 2) * 0.5;
    final y = 34.0 + float;
    _px(c, x + 1, y - 9, 8, 8, const Color(0xFF3E7C6B));
    _px(c, x + 3, y - 7, 5, 5, const Color(0xFFD9A87E));
    _px(c, x, y - 1, 10, 13, const Color(0xFF2F6558));
    _px(c, x + 1, y + 4, 8, 2, NourColors.ocre);
    _px(c, x - 1, y + 12, 12, 1, const Color(0x22000000));
  }

  void _compagnon(Canvas c, double x) {
    final a = sprites?.karim;
    if (a != null) {
      _sprite(c, a, x + 5, _sol, _tailleActeur * 0.96);
      return;
    }
    const y = 37.0;
    _px(c, x + 2, y - 8, 6, 6, const Color(0xFFCFA079));
    _px(c, x + 2, y - 9, 6, 2, const Color(0xFFE8E2D8));
    _px(c, x + 1, y - 2, 8, 9, NourColors.terreCuite);
    _px(c, x + 2, y + 7, 3, 5, const Color(0xFF5C4A38));
    _px(c, x + 6, y + 7, 3, 5, const Color(0xFF5C4A38));
  }

  /// PNJ qui prononce la replique courante. Il se place a l'oppose du
  /// protagoniste pour que les deux restent lisibles.
  void _pnj(Canvas c) {
    final a = sprites?.pnjParNom(pnjNom);
    if (a == null) return;
    final xProta = _x(0, 40);
    // Cote oppose au protagoniste, en restant dans le cadre.
    final x = xProta < 48 ? (xProta + 26).clamp(0.0, 88.0)
                          : (xProta - 26).clamp(8.0, 96.0);
    _sprite(c, a, x, _sol, _tailleActeur * 0.98);
  }

  /// Waswas : masse abstraite et pixelisée, jamais une figure littérale
  /// d'un être invisible (CDC §12).
  void _waswas(Canvas c) {
    // Au climax, c'est le Grand Waswas : plus large, plus lourd (CDC scene 9).
    final grand = decor == 'climax';
    final a = grand ? sprites?.grandWaswasIdle : sprites?.waswasIdle;
    if (a != null) {
      // Le waswas se place a l oppose du protagoniste, sur la zone libre.
      _sprite(c, a, _x(0, 40) + (grand ? 30 : 28), _sol - 2,
          grand ? _tailleActeur * 1.7 : _tailleActeur * 1.15);
      return;
    }
    final pulse = math.sin(t * math.pi * 2);
    const cx = 68.0;
    final cy = 30.0 + pulse * 1.5;
    final rnd = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final r = rnd.nextDouble() * 9;
      final s = 2 + rnd.nextDouble() * 3;
      _px(
        c,
        cx + math.cos(a) * r,
        cy + math.sin(a) * r * 0.8,
        s,
        s,
        i.isEven
            ? NourColors.waswas.withValues(alpha: 0.55)
            : NourColors.waswasFonce.withValues(alpha: 0.45),
      );
    }
    _px(c, cx - 6, cy - 4, 12, 9,
        NourColors.waswasFonce.withValues(alpha: 0.35));
  }

  /// Lanterne : indicateur narratif de Lumière, en bas à gauche du décor.
  void _lanterne(Canvas c) {
    final glow = 0.35 + (lumiere / 100) * 0.65;
    final pulse = 1 + math.sin(t * math.pi * 2) * 0.08;
    _px(c, 6, 52, 5, 6, NourColors.boisFonce);
    _px(c, 7, 53, 3, 4,
        Color.lerp(const Color(0xFF7A6A4A), NourColors.lumiere, glow)!);
    _px(c, 7, 51, 3, 1, NourColors.bois);
    if (lumiere > 0) {
      _px(c, 3, 49 - pulse, 11, 12 * pulse,
          NourColors.lumiereHalo.withValues(alpha: 0.10 * glow));
    }
  }

  @override
  bool shouldRepaint(_ActeursPainter old) =>
      old.lumiere != lumiere ||
      old.waswasVisible != waswasVisible ||
      old.nouraVisible != nouraVisible ||
      old.compagnonVisible != compagnonVisible ||
      old.pnjNom != pnjNom ||
      old.protagonisteVisible != protagonisteVisible ||
      old.lanterneVisible != lanterneVisible ||
      old.sprites != sprites ||
      old.temps != temps ||
      old.decor != decor ||
      old.nouraParle != nouraParle ||
      old.t != t;
}
