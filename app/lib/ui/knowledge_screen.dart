import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/models.dart';
import '../core/player_progress.dart';
import '../data/content_repository.dart';
import 'beat_widgets.dart';

/// Bibliothèque des connaissances (CDC §13).
///
/// Chaque fiche affiche obligatoirement source, référence et statut (CDC §8).
/// Une fiche « à valider » est affichée comme telle : le joueur ne doit jamais
/// croire qu'un contenu non vérifié est définitif.
class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({
    super.key,
    required this.content,
    required this.progress,
  });

  final ContentRepository content;
  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final notions = content.notions;
    final vues = progress.notionsVues;

    return Scaffold(
      backgroundColor: NourColors.sable,
      appBar: AppBar(
        backgroundColor: NourColors.parchemin,
        foregroundColor: NourColors.encre,
        title: const Text('Bibliothèque',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          NourPanel(
            color: const Color(0xFFF6EDDA),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 15, color: NourColors.ocreFonce),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les fiches marquées « à valider » n\'ont pas encore été '
                    'vérifiées par une personne compétente. Ne les considère '
                    'pas comme définitives — vérifie auprès de quelqu\'un de '
                    'confiance.',
                    style: TextStyle(fontSize: 11.5, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              '${vues.length} / ${notions.length} notions rencontrées',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: NourColors.encreDouce),
            ),
          ),
          for (final n in notions)
            _Fiche(notion: n, decouverte: vues.contains(n.id)),
        ],
      ),
    );
  }
}

class _Fiche extends StatelessWidget {
  const _Fiche({required this.notion, required this.decouverte});
  final Notion notion;
  final bool decouverte;

  @override
  Widget build(BuildContext context) {
    if (!decouverte) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: NourPanel(
          color: const Color(0xFFEDE4D2),
          borderColor: NourColors.verrou,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.lock_outline,
                  size: 15, color: NourColors.verrou),
              const SizedBox(width: 10),
              Text(
                'À découvrir dans l\'histoire',
                style: TextStyle(
                    fontSize: 12.5,
                    color: NourColors.verrou,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NourPanel(
        color: NourColors.sableClair,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notion.translitteration,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        notion.titreFr,
                        style: const TextStyle(
                            fontSize: 12, color: NourColors.encreDouce),
                      ),
                    ],
                  ),
                ),
                Text(
                  notion.termeAr,
                  style: const TextStyle(
                      fontSize: 20, color: NourColors.ocreFonce),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(notion.definition,
                style: const TextStyle(fontSize: 13, height: 1.5)),
            const SizedBox(height: 8),
            Text(
              notion.explication,
              style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: NourColors.encreDouce),
            ),
            const SizedBox(height: 10),
            Text(
              'Source : ${notion.source}',
              style: const TextStyle(
                  fontSize: 10.5, color: NourColors.encreDouce),
            ),
            const SizedBox(height: 8),
            StatutBadge(statut: notion.statut, reference: notion.reference),
          ],
        ),
      ),
    );
  }
}
