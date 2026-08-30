import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/models.dart';
import '../core/player_progress.dart';
import '../core/scene_engine.dart';
import '../core/sprite_catalog.dart';
import '../data/content_repository.dart';
import 'action_panel.dart';
import 'beat_widgets.dart';
import 'celebration.dart';
import 'choice_panel.dart';
import 'decor_painter.dart';
import 'history_screen.dart';
import 'hud.dart';
import 'knowledge_screen.dart';
import 'map_screen.dart';
import 'quiz_panel.dart';

/// Écran principal : décor + HUD + fil narratif + panneau d'interaction.
/// Volontairement simple, compréhensible sans tutoriel (CDC §4 du brief).
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.content,
    required this.progress,
    this.sprites,
  });

  final ContentRepository content;
  final PlayerProgress progress;
  final SpriteCatalog? sprites;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final SceneEngine _engine;
  late final AnimationController _anim;
  final _scroll = ScrollController();

  /// Micro-animations d'état (CDC §5 du brief) — courtes, jamais bloquantes.
  bool _waswasVisible = false;
  bool _nouraVisible = false;
  bool _compagnonVisible = false;

  /// Numero de scene ou Noura / le compagnon ont ete rencontres (0 = jamais).
  /// Remis a zero quand on recommence le chapitre.
  int _ordreRencontreNoura = 0;
  int _ordreRencontreCompagnon = 0;

  /// Bandeau d'XP éphémère (gains hors action réelle).
  int? _xpFlash;

  /// Célébration plein écran après une action réelle validée.
  int? _celebrationXp;
  String _celebrationTexte = '';

  /// Horloge de scène, en secondes. Le controller d'animation boucle sur
  /// 0..1 ; on en derive un temps qui avance sans revenir en arriere, sinon
  /// les spritesheets repartiraient a la frame 0 a chaque cycle.
  final _depart = DateTime.now();
  double get _horloge =>
      DateTime.now().difference(_depart).inMilliseconds / 1000.0;

  @override
  void initState() {
    super.initState();
    _engine = SceneEngine(content: widget.content, progress: widget.progress)
      ..addListener(_onEngine);
    widget.progress.addListener(_onEngine);

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _syncActeurs();
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngine);
    widget.progress.removeListener(_onEngine);
    _anim.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onEngine() {
    if (mounted) setState(_syncActeurs);
    _autoScroll();
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Présence des acteurs déduite des beats déjà joués de la scène.
  /// Qui est visible dans le decor, deduit UNIQUEMENT de la scene courante.
  ///
  /// Important : on ne reporte jamais l'etat precedent. Sinon un personnage
  /// rencontre plus loin restait affiche apres un retour en arriere — Noura
  /// apparaissait dans la chambre quand on recommencait le chapitre.
  void _syncActeurs() {
    var waswas = false, noura = false, comp = false;

    // Le beat COURANT compte aussi : au premier beat d'une scene la liste
    // des beats joues est vide, et Noura n'apparaissait pas alors qu'elle
    // etait deja en train de parler.
    final aExaminer = [..._engine.joues];
    final courant = _engine.beatCourant;
    if (courant != null) aExaminer.add(courant);

    for (final b in aExaminer) {
      if (b.type == 'waswas') {
        waswas = b.etat != 'disparition';
      }
      if (b.type == 'noura') noura = true;
      if (b.type == 'compagnon') comp = true;
    }

    // Une fois rencontres dans le chapitre, Noura et le compagnon restent
    // presents dans les scenes SUIVANTES — mais jamais dans les precedentes.
    final ordre = _engine.scene.ordre;
    if (ordre > _ordreRencontreNoura && _ordreRencontreNoura > 0) noura = true;
    if (ordre > _ordreRencontreCompagnon && _ordreRencontreCompagnon > 0) {
      comp = true;
    }
    // Memoriser la premiere apparition, pour les scenes d'apres.
    if (noura && (_ordreRencontreNoura == 0 || ordre < _ordreRencontreNoura)) {
      _ordreRencontreNoura = ordre;
    }
    if (comp &&
        (_ordreRencontreCompagnon == 0 || ordre < _ordreRencontreCompagnon)) {
      _ordreRencontreCompagnon = ordre;
    }

    _waswasVisible = waswas;
    _nouraVisible = noura;
    _compagnonVisible = comp;
  }

  void _avancer() {
    _engine.avancer();
    final b = _engine.beatCourant;
    if (b != null && b.type == 'xp') {
      setState(() => _xpFlash = b.montant);
      _engine.avancer();
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _xpFlash = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = _engine.scene;
    final beat = _engine.beatCourant;

    return Scaffold(
      backgroundColor: NourColors.sable,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Hud(
                    progress: widget.progress,
                    quete: '${scene.ordre}. ${scene.titre}',
                    onCarte: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(
                          content: widget.content,
                          sceneCouranteId: scene.id,
                        ),
                      ),
                    ),
                    onHistorique: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryScreen(
                          titreScene: '${scene.ordre}. ${scene.titre}',
                          beats: _engine.joues,
                        ),
                      ),
                    ),
                    onBibliotheque: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KnowledgeScreen(
                          content: widget.content,
                          progress: widget.progress,
                        ),
                      ),
                    ),
                  ),
                ),

                // Décor.
                //
                // `Material` opaque : sans lui, le fil narratif qui defile
                // dessous transparait derriere le cadre (les bulles semblaient
                // passer sous l'illustration).
                Material(
                  color: NourColors.sable,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AspectRatio(
                      // Les illustrations sont en 768x429 (~16/9). Un cadre
                      // 3:2 les rognait fortement : on perdait la fenetre de
                      // la chambre et le panneau du carrefour.
                      aspectRatio: 768 / 429,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: NourColors.bois,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: AnimatedBuilder(
                                animation: _anim,
                                builder: (_, __) => DecorView(
                                  decor: scene.decor,
                                  lumiere: widget.progress.lumiere,
                                  waswasVisible: _waswasVisible,
                                  nouraVisible: _nouraVisible,
                                  // De face pendant qu'elle parle.
                                  nouraParle:
                                      _engine.beatCourant?.type == 'noura',
                                  compagnonVisible: _compagnonVisible,
                                  animation: _anim.value,
                                  sprites: widget.sprites,
                                  temps: _horloge,
                                ),
                              ),
                            ),
                          ),
                          if (_xpFlash != null)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: _XpFlash(montant: _xpFlash!),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Zone de dialogue : UNE SEULE replique a la fois.
                //
                // Empiler l'historique comme un fil de discussion obligeait le
                // joueur a relire pour trouver la nouvelle ligne. Un RPG affiche
                // une replique, on avance, elle est remplacee. L'historique reste
                // accessible via le bouton en haut a droite de la zone.
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: SingleChildScrollView(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (beat != null)
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  switchInCurve: Curves.easeOut,
                                  transitionBuilder: (enfant, anim) =>
                                      FadeTransition(
                                        opacity: anim,
                                        child: SlideTransition(
                                          position: Tween(
                                            begin: const Offset(0, 0.06),
                                            end: Offset.zero,
                                          ).animate(anim),
                                          child: enfant,
                                        ),
                                      ),
                                  // La cle force la transition a chaque beat.
                                  child: KeyedSubtree(
                                    key: ValueKey(
                                      '${_engine.scene.id}_${_engine.index}',
                                    ),
                                    child: _panneau(beat),
                                  ),
                                ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bouton d'avance (uniquement si le beat n'est pas bloquant)
                if (beat != null && !_engine.estBloque)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: NourButton(
                      label: _labelAvance(beat),
                      onPressed: _avancer,
                    ),
                  ),
              ],
            ),
          ),

          // Celebration : par-dessus tout, apres une action reelle validee.
          if (_celebrationXp != null)
            CelebrationOverlay(
              key: ValueKey(_celebrationXp),
              xp: _celebrationXp!,
              message: _celebrationTexte,
              onTermine: () {
                if (mounted) setState(() => _celebrationXp = null);
              },
            ),
        ],
      ),
    );
  }

  String _labelAvance(Beat b) => switch (b.type) {
    'narration' || 'monologue' || 'noura' || 'pnj' || 'waswas' => 'Suite',
    'etape' => 'Continuer',
    'compagnon' => 'Bien',
    _ => 'Suite',
  };

  Widget _panneau(Beat beat) {
    switch (beat.type) {
      case 'quiz':
        final q = widget.content.quiz(beat.questionId!)!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: QuizPanel(
            key: ValueKey(q.id),
            question: q,
            onTermine: () => _engine.validerQuiz(q),
          ),
        );

      case 'choix':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ChoicePanel(
            key: ValueKey('choix_${_engine.index}'),
            question: beat.questionChoix,
            options: beat.options,
            onTermine: _engine.validerChoix,
          ),
        );

      case 'real_action':
        final a = widget.content.action(beat.actionId!)!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ActionPanel(
            key: ValueKey(a.id),
            action: a,
            intro: beat.intro ?? '',
            onValide: () {
              _engine.validerAction(a);
              final suivant = _engine.beatCourant;
              if (suivant != null && suivant.type == 'xp') {
                // On celebre l'effort accompli dans la vraie vie, puis on
                // laisse l'XP s'ajouter visiblement a la barre du HUD.
                setState(() {
                  _celebrationXp = suivant.montant;
                  _celebrationTexte = suivant.texte;
                });
                _engine.avancer();
              }
            },
            onReporte: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: NourColors.boisFonce,
                  duration: Duration(seconds: 3),
                  content: Text(
                    'Pas de souci. Ça t\'attend, sans compte à rebours.',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              );
            },
          ),
        );

      case 'fin':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: _FinChapitre(
            titre: beat.titre ?? '',
            texte: beat.texte,
            sousTexte: beat.sousTexte ?? '',
            xp: widget.progress.xp,
            lumiere: widget.progress.lumiere,
            onRejouer: () async {
              await widget.progress.reinitialiser();
              // Oublier les rencontres : on repart de la chambre, seul.
              _ordreRencontreNoura = 0;
              _ordreRencontreCompagnon = 0;
              _engine.recommencer();
            },
          ),
        );

      default:
        return BeatBubble(beat: beat);
    }
  }
}

class _XpFlash extends StatelessWidget {
  const _XpFlash({required this.montant});
  final int montant;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: NourColors.boisFonce,
          border: Border.all(color: NourColors.lumiere, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 15, color: NourColors.lumiere),
            const SizedBox(width: 6),
            Text(
              '+$montant XP',
              style: const TextStyle(
                color: NourColors.lumiere,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinChapitre extends StatelessWidget {
  const _FinChapitre({
    required this.titre,
    required this.texte,
    required this.sousTexte,
    required this.xp,
    required this.lumiere,
    required this.onRejouer,
  });

  final String titre;
  final String texte;
  final String sousTexte;
  final int xp;
  final int lumiere;
  final VoidCallback onRejouer;

  @override
  Widget build(BuildContext context) {
    return NourPanel(
      color: NourColors.parchemin,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.light_mode, size: 34, color: NourColors.lumiere),
          const SizedBox(height: 12),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: NourColors.ocreFonce,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            texte,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: NourColors.encreDouce),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(label: 'XP', valeur: '$xp'),
              _Stat(label: 'Lumière', valeur: '$lumiere%'),
            ],
          ),
          // Cadre affiche seulement s'il y a quelque chose a dire :
          // un sous-texte vide laissait un encadre vide a l'ecran.
          if (sousTexte.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NourColors.sableClair,
                border: Border.all(color: NourColors.bois, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sousTexte,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          NourButton(
            label: 'Recommencer le chapitre',
            filled: false,
            onPressed: onRejouer,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.valeur});
  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valeur,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: NourColors.ocreFonce,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: NourColors.encreDouce),
        ),
      ],
    );
  }
}
