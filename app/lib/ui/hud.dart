import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/player_progress.dart';

/// HUD : niveau, XP, Lumière, quête courante (CDC §13).
/// Volontairement dépouillé — le CDC demande de ne pas surcharger l'écran.
class Hud extends StatelessWidget {
  const Hud({
    super.key,
    required this.progress,
    required this.quete,
    this.onCarte,
    this.onBibliotheque,
    this.onHistorique,
  });

  final PlayerProgress progress;
  final String quete;
  final VoidCallback? onCarte;
  final VoidCallback? onBibliotheque;

  /// Relire les repliques de la scene : l'ecran n'en affiche qu'une a la fois.
  final VoidCallback? onHistorique;

  @override
  Widget build(BuildContext context) {
    return NourPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: NourColors.parchemin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(niveau: progress.niveau),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('XP',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: NourColors.encreDouce)),
                        const Spacer(),
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                              begin: progress.xp.toDouble(),
                              end: progress.xp.toDouble()),
                          duration: const Duration(milliseconds: 900),
                          builder: (context, v, _) => Text(
                            '${v.round()} / ${progress.xpProchainPalier}',
                            style: const TextStyle(
                                fontSize: 10, color: NourColors.encreDouce),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    _Barre(
                      valeur: progress.progressionNiveau,
                      couleur: NourColors.ocre,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Lanterne(pourcentage: progress.lumiere),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.flag_outlined,
                  size: 13, color: NourColors.encreDouce),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  quete,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: NourColors.encreDouce),
                ),
              ),
              if (onCarte != null)
                _MiniBouton(icon: Icons.map_outlined, onTap: onCarte!),
              if (onHistorique != null) ...[
                const SizedBox(width: 6),
                _MiniBouton(
                    icon: Icons.history, onTap: onHistorique!),
              ],
              if (onBibliotheque != null) ...[
                const SizedBox(width: 6),
                _MiniBouton(
                    icon: Icons.menu_book_outlined, onTap: onBibliotheque!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.niveau});
  final int niveau;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: NourColors.boisFonce,
        border: Border.all(color: NourColors.ocre, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$niveau',
        style: const TextStyle(
          color: NourColors.lumiere,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}

/// Barre d'XP. La valeur se remplit progressivement au lieu de sauter :
/// le joueur doit VOIR sa progression arriver apres une action reelle.
class _Barre extends StatelessWidget {
  const _Barre({required this.valeur, required this.couleur});
  final double valeur;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 9,
      decoration: BoxDecoration(
        color: const Color(0xFFD9C7A4),
        border: Border.all(color: NourColors.bois, width: 1.5),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: valeur.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                color: couleur,
                boxShadow: [
                  BoxShadow(
                    color: NourColors.lumiere.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicateur narratif de Lumière. Ce n'est pas une mesure de foi (CDC §3) :
/// l'infobulle le dit explicitement au joueur.
class _Lanterne extends StatelessWidget {
  const _Lanterne({required this.pourcentage});
  final int pourcentage;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'Lumière : un repère de progression dans l\'histoire.\nCe n\'est pas une mesure de ta foi.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.light_mode,
            size: 20,
            color: Color.lerp(
                const Color(0xFF9C8A6E), NourColors.lumiere, pourcentage / 100),
          ),
          const SizedBox(height: 2),
          Text('$pourcentage%',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: NourColors.ocreFonce)),
        ],
      ),
    );
  }
}

class _MiniBouton extends StatelessWidget {
  const _MiniBouton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: NourColors.sableClair,
          border: Border.all(color: NourColors.bois, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 15, color: NourColors.boisFonce),
      ),
    );
  }
}
