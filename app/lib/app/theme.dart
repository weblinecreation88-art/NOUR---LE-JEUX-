import 'package:flutter/material.dart';

/// Direction artistique NOUR (CDC §12) : ocre, sable, beige, terre cuite,
/// tons naturels lumineux. Jamais sombre ni horrifique.
class NourColors {
  const NourColors._();

  static const sable = Color(0xFFF5E9D0);
  static const sableClair = Color(0xFFFBF4E6);
  static const parchemin = Color(0xFFEFDDBC);
  static const ocre = Color(0xFFD9A441);
  static const ocreFonce = Color(0xFFB07C2A);
  static const terreCuite = Color(0xFFB5623C);
  static const bois = Color(0xFF8A5A33);
  static const boisFonce = Color(0xFF5C3A22);
  static const encre = Color(0xFF3B2A1C);
  static const encreDouce = Color(0xFF6B5744);

  /// La lanterne : la « Lumière » narrative. Jamais une mesure de foi (CDC §3).
  static const lumiere = Color(0xFFF2C14E);
  static const lumiereHalo = Color(0xFFFFE9A8);

  /// Le Waswas : masse abstraite. Sourd, jamais horrifique (CDC §12).
  static const waswas = Color(0xFF6E6480);
  static const waswasFonce = Color(0xFF4A4358);

  static const succes = Color(0xFF7A9A5B);
  static const verrou = Color(0xFFBFAE93);
}

class NourTheme {
  const NourTheme._();

  /// Police à chasse fixe : rendu « pixel/terminal » lisible sur petit écran,
  /// sans dépendre d'une police externe (aucun téléchargement réseau).
  static const pixelFont = 'monospace';

  static ThemeData build() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: NourColors.sable,
      colorScheme: base.colorScheme.copyWith(
        primary: NourColors.ocre,
        secondary: NourColors.terreCuite,
        surface: NourColors.sableClair,
        onSurface: NourColors.encre,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: pixelFont,
        bodyColor: NourColors.encre,
        displayColor: NourColors.encre,
      ),
    );
  }
}

/// Cadre de bois récurrent de l'UI (cf. planches de référence).
class NourPanel extends StatelessWidget {
  const NourPanel({
    super.key,
    required this.child,
    this.color = NourColors.sableClair,
    this.borderColor = NourColors.bois,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor, width: 3),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Bouton principal, style bois/ocre.
class NourButton extends StatelessWidget {
  const NourButton({
    super.key,
    required this.label,
    this.onPressed,
    this.filled = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bg = !enabled
        ? NourColors.verrou
        : (filled ? NourColors.ocre : NourColors.sableClair);
    final fg = !enabled
        ? NourColors.sableClair
        : (filled ? NourColors.boisFonce : NourColors.encre);

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: NourColors.bois, width: 3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: NourTheme.pixelFont,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: fg,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
