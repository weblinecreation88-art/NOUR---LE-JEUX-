import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../data/content_repository.dart';

/// Carte du chapitre (CDC §13). Lecture seule : elle situe le joueur,
/// elle ne permet pas de sauter des scènes.
class MapScreen extends StatelessWidget {
  const MapScreen({
    super.key,
    required this.content,
    required this.sceneCouranteId,
  });

  final ContentRepository content;
  final String sceneCouranteId;

  @override
  Widget build(BuildContext context) {
    final scenes = content.scenes;
    final courant =
        scenes.indexWhere((s) => s.id == sceneCouranteId).clamp(0, 999);

    return Scaffold(
      backgroundColor: NourColors.sable,
      appBar: AppBar(
        backgroundColor: NourColors.parchemin,
        foregroundColor: NourColors.encre,
        title: Text(
          content.chapitreTitre,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          NourPanel(
            color: NourColors.parchemin,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CHAPITRE 1',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        color: NourColors.ocreFonce)),
                const SizedBox(height: 4),
                Text(content.chapitreTitre,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Parcours : ${content.chapitreParcours}',
                    style: const TextStyle(
                        fontSize: 12, color: NourColors.encreDouce)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < scenes.length; i++)
            _Etape(
              numero: scenes[i].ordre,
              titre: scenes[i].titre,
              etat: i < courant
                  ? _Etat.faite
                  : (i == courant ? _Etat.courante : _Etat.aVenir),
              dernier: i == scenes.length - 1,
            ),
        ],
      ),
    );
  }
}

enum _Etat { faite, courante, aVenir }

class _Etape extends StatelessWidget {
  const _Etape({
    required this.numero,
    required this.titre,
    required this.etat,
    required this.dernier,
  });

  final int numero;
  final String titre;
  final _Etat etat;
  final bool dernier;

  @override
  Widget build(BuildContext context) {
    final (couleur, icone) = switch (etat) {
      _Etat.faite => (NourColors.succes, Icons.check),
      _Etat.courante => (NourColors.ocre, Icons.place),
      _Etat.aVenir => (NourColors.verrou, Icons.lock_outline),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: etat == _Etat.aVenir
                      ? const Color(0xFFEDE4D2)
                      : NourColors.sableClair,
                  border: Border.all(color: couleur, width: 2.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icone, size: 14, color: couleur),
              ),
              if (!dernier)
                Expanded(
                  child: Container(width: 2.5, color: couleur.withValues(alpha: 0.4)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$numero. $titre',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: etat == _Etat.courante
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: etat == _Etat.aVenir
                          ? NourColors.verrou
                          : NourColors.encre,
                    ),
                  ),
                  if (etat == _Etat.courante)
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Text('Tu es ici',
                          style: TextStyle(
                              fontSize: 11,
                              color: NourColors.ocreFonce,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
