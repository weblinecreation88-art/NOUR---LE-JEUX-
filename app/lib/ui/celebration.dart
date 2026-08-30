import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Pop-up de celebration affiche quand le joueur valide une action reelle.
///
/// Ton volontairement chaleureux, jamais moralisateur : on felicite un
/// EFFORT accompli dans la vraie vie, pas une performance religieuse.
/// L'XP reste une mecanique de jeu (CDC §3).
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.xp,
    required this.message,
    required this.onTermine,
  });

  final int xp;
  final String message;
  final VoidCallback onTermine;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entree;
  late final AnimationController _particules;

  @override
  void initState() {
    super.initState();
    _entree = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _particules = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Refermeture automatique : le joueur n'a pas a chercher un bouton.
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) widget.onTermine();
    });
  }

  @override
  void dispose() {
    _entree.dispose();
    _particules.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Voile leger : concentre le regard sans assombrir la scene.
            FadeTransition(
              opacity: _entree,
              child: Container(color: const Color(0x33000000)),
            ),

            // Etincelles montantes
            AnimatedBuilder(
              animation: _particules,
              builder: (_, __) => CustomPaint(
                painter: _EtincellesPainter(_particules.value),
                child: const SizedBox.expand(),
              ),
            ),

            // Carte de validation
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _entree,
                curve: Curves.easeOutBack,
              ),
              child: FadeTransition(
                opacity: _entree,
                child: _Carte(xp: widget.xp, message: widget.message),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({required this.xp, required this.message});

  final int xp;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7EC),
        border: Border.all(color: NourColors.succes, width: 3),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coche verte
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: NourColors.succes,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 34),
          ),
          const SizedBox(height: 14),
          const Text(
            'C\'EST FAIT',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: NourColors.succes,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: NourColors.encre,
            ),
          ),
          const SizedBox(height: 16),
          // Gain d'XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: NourColors.boisFonce,
              border: Border.all(color: NourColors.lumiere, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome,
                    size: 17, color: NourColors.lumiere),
                const SizedBox(width: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: xp.toDouble()),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    '+${v.round()} XP',
                    style: const TextStyle(
                      color: NourColors.lumiere,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Etincelles qui montent depuis la carte. Discretes : le CDC demande des
/// animations courtes, la fluidite prime sur la complexite.
class _EtincellesPainter extends CustomPainter {
  _EtincellesPainter(this.t);
  final double t;

  static final _rnd = math.Random(11);
  static final _graines = List.generate(
    18,
    (_) => (
      _rnd.nextDouble(),          // x relatif
      _rnd.nextDouble(),          // decalage temporel
      0.6 + _rnd.nextDouble(),    // vitesse
      2.0 + _rnd.nextDouble() * 3 // taille
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (final (rx, delai, vitesse, taille) in _graines) {
      var p = (t * vitesse - delai);
      if (p < 0 || p > 1) continue;
      final x = size.width * (0.18 + rx * 0.64);
      final y = size.height * (0.62 - p * 0.42);
      final opacite = (1 - p) * 0.9;
      canvas.drawRect(
        Rect.fromLTWH(x, y, taille, taille),
        Paint()
          ..color = (p < 0.5 ? NourColors.lumiere : NourColors.succes)
              .withValues(alpha: opacite),
      );
    }
  }

  @override
  bool shouldRepaint(_EtincellesPainter old) => old.t != t;
}
