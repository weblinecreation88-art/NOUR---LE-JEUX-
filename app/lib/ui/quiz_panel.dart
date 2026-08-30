import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/models.dart';
import 'beat_widgets.dart';

/// Écran de quiz (CDC §13).
///
/// Le quiz est un apprentissage, jamais une attaque ni un sort (CDC §5).
/// Une mauvaise réponse ne retire aucun XP et n'entraîne aucun reproche :
/// on montre la bonne réponse et l'explication, puis on continue (CDC §11).
class QuizPanel extends StatefulWidget {
  const QuizPanel({
    super.key,
    required this.question,
    required this.onTermine,
  });

  final QuizQuestion question;
  final VoidCallback onTermine;

  @override
  State<QuizPanel> createState() => _QuizPanelState();
}

class _QuizPanelState extends State<QuizPanel> {
  int? _choisi;

  bool get _repondu => _choisi != null;
  bool get _correct => _choisi == widget.question.reponse;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return NourPanel(
      color: NourColors.sableClair,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined,
                  size: 16, color: NourColors.ocreFonce),
              const SizedBox(width: 6),
              const Text(
                'APPRENDRE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: NourColors.ocreFonce,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            q.question,
            style: const TextStyle(
                fontSize: 14.5, height: 1.45, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...List.generate(q.choix.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Choix(
                texte: q.choix[i],
                index: i,
                etat: !_repondu
                    ? _EtatChoix.neutre
                    : i == q.reponse
                        ? _EtatChoix.bon
                        : (i == _choisi
                            ? _EtatChoix.mauvais
                            : _EtatChoix.estompe),
                onTap: _repondu ? null : () => setState(() => _choisi = i),
              ),
            );
          }),
          if (_repondu) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: NourColors.parchemin,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: NourColors.bois, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Aucun reproche en cas d'erreur (CDC §11, §19).
                    _correct ? 'Exactement.' : 'Pas tout à fait — et ce n\'est pas grave.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _correct
                          ? NourColors.succes
                          : NourColors.ocreFonce,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(q.explication,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            StatutBadge(statut: q.statut, reference: q.reference),
            const SizedBox(height: 12),
            NourButton(label: 'Continuer', onPressed: widget.onTermine),
          ],
        ],
      ),
    );
  }
}

enum _EtatChoix { neutre, bon, mauvais, estompe }

class _Choix extends StatelessWidget {
  const _Choix({
    required this.texte,
    required this.index,
    required this.etat,
    this.onTap,
  });

  final String texte;
  final int index;
  final _EtatChoix etat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    late Color fond, bord, txt;
    switch (etat) {
      case _EtatChoix.neutre:
        fond = NourColors.sable;
        bord = NourColors.bois;
        txt = NourColors.encre;
      case _EtatChoix.bon:
        fond = const Color(0xFFE6F0DE);
        bord = NourColors.succes;
        txt = NourColors.encre;
      case _EtatChoix.mauvais:
        fond = const Color(0xFFF6E6DE);
        bord = NourColors.terreCuite;
        txt = NourColors.encre;
      case _EtatChoix.estompe:
        fond = NourColors.sable;
        bord = NourColors.verrou;
        txt = NourColors.encreDouce;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        decoration: BoxDecoration(
          color: fond,
          border: Border.all(color: bord, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              String.fromCharCode(65 + index),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: bord == NourColors.verrou ? NourColors.verrou : bord,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                texte,
                style: TextStyle(fontSize: 13, height: 1.4, color: txt),
              ),
            ),
            if (etat == _EtatChoix.bon)
              const Icon(Icons.check, size: 16, color: NourColors.succes),
          ],
        ),
      ),
    );
  }
}
