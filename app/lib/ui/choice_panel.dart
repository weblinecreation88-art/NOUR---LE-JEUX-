import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/models.dart';

/// Écran de choix narratif — sert aussi de panneau de direction (CDC §13).
class ChoicePanel extends StatefulWidget {
  const ChoicePanel({
    super.key,
    required this.question,
    required this.options,
    required this.onTermine,
  });

  final String question;
  final List<ChoixOption> options;
  final VoidCallback onTermine;

  @override
  State<ChoicePanel> createState() => _ChoicePanelState();
}

class _ChoicePanelState extends State<ChoicePanel> {
  ChoixOption? _choisi;

  @override
  Widget build(BuildContext context) {
    return NourPanel(
      color: NourColors.sableClair,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question,
            style: const TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.bold, height: 1.4),
          ),
          const SizedBox(height: 12),
          ...widget.options.map((o) {
            final verrouille = o.verrouille;
            final actif = _choisi?.id == o.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: verrouille || _choisi != null
                    ? null
                    : () => setState(() => _choisi = o),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 12),
                  decoration: BoxDecoration(
                    color: verrouille
                        ? const Color(0xFFEDE4D2)
                        : (actif ? NourColors.parchemin : NourColors.sable),
                    border: Border.all(
                      color: verrouille
                          ? NourColors.verrou
                          : (actif ? NourColors.ocre : NourColors.bois),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        verrouille ? Icons.lock_outline : Icons.chevron_right,
                        size: 15,
                        color: verrouille
                            ? NourColors.verrou
                            : NourColors.ocreFonce,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          o.texte,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: verrouille
                                ? NourColors.verrou
                                : NourColors.encre,
                            fontWeight:
                                verrouille ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (verrouille && o.note != null)
                        Text(
                          o.note!,
                          style: const TextStyle(
                              fontSize: 10, color: NourColors.verrou),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_choisi?.reponse != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: NourColors.parchemin,
                border: Border.all(color: NourColors.bois, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _choisi!.reponse!,
                style: const TextStyle(
                    fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          if (_choisi != null) ...[
            const SizedBox(height: 12),
            NourButton(label: 'Continuer', onPressed: widget.onTermine),
          ],
        ],
      ),
    );
  }
}
