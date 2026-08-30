import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/models.dart';

/// Écran d'action réelle + validation (CDC §13).
///
/// Règles non négociables encodées ici (CDC §9, §11, §16) :
///  - validation strictement déclarative ;
///  - aucune preuve demandée : ni photo, ni audio, ni localisation ;
///  - « Plus tard » est toujours proposé, sans reproche ni pénalité ;
///  - le jeu ne prétend jamais savoir si l'action a réellement été faite.
class ActionPanel extends StatefulWidget {
  const ActionPanel({
    super.key,
    required this.action,
    required this.intro,
    required this.onValide,
    required this.onReporte,
  });

  final RealAction action;
  final String intro;
  final VoidCallback onValide;
  final VoidCallback onReporte;

  @override
  State<ActionPanel> createState() => _ActionPanelState();
}

class _ActionPanelState extends State<ActionPanel> {
  int _variante = 0;
  bool _enCours = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    return NourPanel(
      color: const Color(0xFFFBF2DE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_walk,
                  size: 16, color: NourColors.terreCuite),
              const SizedBox(width: 6),
              const Text(
                'DANS LA VRAIE VIE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: NourColors.terreCuite,
                ),
              ),
              const Spacer(),
              Text(
                a.duree,
                style: const TextStyle(
                    fontSize: 10, color: NourColors.encreDouce),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            a.titre,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, height: 1.35),
          ),
          const SizedBox(height: 6),
          Text(
            widget.intro,
            style: const TextStyle(
                fontSize: 13, height: 1.5, color: NourColors.encreDouce),
          ),
          const SizedBox(height: 12),

          if (!_enCours) ...[
            const Text(
              'Choisis ce qui colle à ta situation :',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: NourColors.encreDouce),
            ),
            const SizedBox(height: 8),
            ...List.generate(a.variantes.length, (i) {
              final actif = i == _variante;
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: InkWell(
                  onTap: () => setState(() => _variante = i),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 10),
                    decoration: BoxDecoration(
                      color: actif ? NourColors.parchemin : NourColors.sable,
                      border: Border.all(
                        color: actif ? NourColors.ocre : NourColors.verrou,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          actif
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 15,
                          color: actif
                              ? NourColors.ocreFonce
                              : NourColors.verrou,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(a.variantes[i],
                              style: const TextStyle(
                                  fontSize: 13, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
            NourButton(
              label: 'J\'y vais',
              icon: Icons.logout,
              onPressed: () => setState(() => _enCours = true),
            ),
            const SizedBox(height: 8),
            _BoutonDiscret(
              label: 'Plus tard',
              onTap: widget.onReporte,
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: NourColors.parchemin,
                border: Border.all(color: NourColors.ocre, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ton action',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: NourColors.ocreFonce)),
                  const SizedBox(height: 5),
                  Text(a.variantes[_variante],
                      style: const TextStyle(fontSize: 13.5, height: 1.45)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reviens quand c\'est fait. Rien ne presse.',
              style: TextStyle(
                  fontSize: 13, height: 1.5, color: NourColors.encreDouce),
            ),
            const SizedBox(height: 12),
            NourButton(
              label: 'C\'est fait',
              icon: Icons.check,
              onPressed: widget.onValide,
            ),
            const SizedBox(height: 8),
            _BoutonDiscret(
              label: 'Pas encore — j\'y reviens plus tard',
              onTap: widget.onReporte,
            ),
            const SizedBox(height: 12),
            const _NoticeConfiance(),
          ],
        ],
      ),
    );
  }
}

/// Affiché au moment de la validation : le joueur doit savoir que rien
/// n'est vérifié ni collecté (CDC §16, §19).
class _NoticeConfiance extends StatelessWidget {
  const _NoticeConfiance();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EADA),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: NourColors.verrou, width: 1.5),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 13, color: NourColors.encreDouce),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'On te croit sur parole. NOUR ne demande jamais de photo, '
              'd\'enregistrement ni de localisation, et ne peut pas savoir '
              'ce que tu as fait.',
              style: TextStyle(
                  fontSize: 10.5, height: 1.45, color: NourColors.encreDouce),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoutonDiscret extends StatelessWidget {
  const _BoutonDiscret({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: NourColors.encreDouce,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
