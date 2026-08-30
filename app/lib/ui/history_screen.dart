import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/models.dart';
import 'beat_widgets.dart';

/// Historique de la scene courante.
///
/// Le jeu n'affiche qu'une replique a la fois : cet ecran permet de relire
/// ce qui a deja ete dit, sans encombrer l'ecran principal.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.titreScene,
    required this.beats,
  });

  final String titreScene;
  final List<Beat> beats;

  @override
  Widget build(BuildContext context) {
    // Seules les repliques ont un interet a la relecture.
    const parlants = {'narration', 'monologue', 'noura', 'pnj', 'waswas',
                      'etape', 'compagnon', 'xp'};
    final lisibles = beats
        .where((b) => parlants.contains(b.type) && b.texte.trim().isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: NourColors.sable,
      appBar: AppBar(
        backgroundColor: NourColors.parchemin,
        foregroundColor: NourColors.encre,
        title: Text(
          titreScene,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      body: lisibles.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Rien à relire pour l\'instant.',
                  style: TextStyle(
                      fontSize: 13, color: NourColors.encreDouce),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                for (final b in lisibles) BeatBubble(beat: b),
              ],
            ),
    );
  }
}
