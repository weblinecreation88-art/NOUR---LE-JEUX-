import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/models.dart';

/// Bulle de dialogue / narration.
class BeatBubble extends StatelessWidget {
  const BeatBubble({super.key, required this.beat});
  final Beat beat;

  @override
  Widget build(BuildContext context) {
    switch (beat.type) {
      case 'narration':
        return _Narration(texte: beat.texte);
      case 'monologue':
        return _Bulle(
          nom: 'Toi',
          texte: beat.texte,
          couleurNom: NourColors.bois,
          fond: NourColors.sableClair,
        );
      case 'noura':
        return _Bulle(
          nom: 'NOURA',
          texte: beat.texte,
          couleurNom: const Color(0xFF2F6558),
          fond: const Color(0xFFEDF3EC),
        );
      case 'pnj':
        return _Bulle(
          nom: beat.nom ?? 'Quelqu\'un',
          texte: beat.texte,
          couleurNom: NourColors.terreCuite,
          fond: NourColors.sableClair,
        );
      case 'waswas':
        if (beat.texte.isEmpty) return const SizedBox.shrink();
        return _Bulle(
          nom: 'WASWAS',
          texte: beat.texte,
          couleurNom: NourColors.waswasFonce,
          fond: const Color(0xFFEDEAF0),
          italique: true,
        );
      case 'etape':
        return _Etape(titre: beat.titre ?? '', texte: beat.texte);
      case 'compagnon':
        return _Systeme(
          icone: Icons.people_alt_outlined,
          texte: '${beat.nom} — ${beat.texte}',
        );
      case 'xp':
        return _Systeme(icone: Icons.auto_awesome, texte: beat.texte);
      default:
        return _Narration(texte: beat.texte);
    }
  }
}

class _Narration extends StatelessWidget {
  const _Narration({required this.texte});
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        texte,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          fontStyle: FontStyle.italic,
          color: NourColors.encreDouce,
        ),
      ),
    );
  }
}

class _Bulle extends StatelessWidget {
  const _Bulle({
    required this.nom,
    required this.texte,
    required this.couleurNom,
    required this.fond,
    this.italique = false,
  });

  final String nom;
  final String texte;
  final Color couleurNom;
  final Color fond;
  final bool italique;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: NourPanel(
        color: fond,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nom,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: couleurNom,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              texte,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: NourColors.encre,
                fontStyle: italique ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Etape extends StatelessWidget {
  const _Etape({required this.titre, required this.texte});
  final String titre;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: NourPanel(
        color: NourColors.parchemin,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: NourColors.ocreFonce)),
            const SizedBox(height: 4),
            Text(texte,
                style: const TextStyle(fontSize: 13, height: 1.45)),
          ],
        ),
      ),
    );
  }
}

class _Systeme extends StatelessWidget {
  const _Systeme({required this.icone, required this.texte});
  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    if (texte.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 15, color: NourColors.ocreFonce),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              texte,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: NourColors.ocreFonce,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marqueur de statut d'un contenu religieux (CDC §3, §8).
/// Rien n'est présenté comme définitivement validé tant que le statut
/// n'est pas VALIDE.
class StatutBadge extends StatelessWidget {
  const StatutBadge({super.key, required this.statut, required this.reference});
  final StatutValidation statut;
  final String reference;

  @override
  Widget build(BuildContext context) {
    final aValider = !statut.estValide;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: aValider ? const Color(0xFFF6EDDA) : const Color(0xFFEDF3E8),
        border: Border.all(
          color: aValider ? NourColors.ocreFonce : NourColors.succes,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            aValider ? Icons.info_outline : Icons.verified_outlined,
            size: 13,
            color: aValider ? NourColors.ocreFonce : NourColors.succes,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aValider ? 'Référence à valider' : 'Référence validée',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color:
                        aValider ? NourColors.ocreFonce : NourColors.succes,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reference,
                  style: const TextStyle(
                      fontSize: 10, color: NourColors.encreDouce, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
