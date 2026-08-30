import 'package:flutter/foundation.dart';
import '../data/content_repository.dart';
import 'models.dart';
import 'player_progress.dart';

/// Moteur de scène (CDC — étape 6 du PLAN).
///
/// Une scène est une liste de beats typés. Le moteur avance beat par beat ;
/// certains beats sont « bloquants » (quiz, choix, action réelle) et attendent
/// une décision du joueur avant que `avancer()` ait un effet.
///
/// Le moteur ne connaît aucun texte : tout vient des JSON. Ajouter du contenu
/// n'implique aucune modification ici.
class SceneEngine extends ChangeNotifier {
  SceneEngine({required this.content, required this.progress}) {
    _restaurer();
  }

  final ContentRepository content;
  final PlayerProgress progress;

  late Scene _scene;
  int _index = 0;

  /// Beats déjà joués dans la scène courante — l'écran les affiche empilés,
  /// comme un fil de discussion.
  final List<Beat> _joues = [];

  bool _chapitreTermine = false;

  Scene get scene => _scene;
  int get index => _index;
  List<Beat> get joues => List.unmodifiable(_joues);
  bool get chapitreTermine => _chapitreTermine;

  Beat? get beatCourant =>
      _index < _scene.beats.length ? _scene.beats[_index] : null;

  /// Beats qui exigent une action du joueur avant de pouvoir avancer.
  static const _bloquants = {'quiz', 'choix', 'real_action', 'fin'};

  bool get estBloque {
    final b = beatCourant;
    return b != null && _bloquants.contains(b.type);
  }

  void _restaurer() {
    final id = progress.sceneId;
    final scene = id == null ? null : content.sceneById(id);
    _scene = scene ?? content.premiereScene;
    _index = scene == null ? 0 : progress.beatIndex.clamp(0, _scene.beats.length);
    _joues
      ..clear()
      ..addAll(_scene.beats.take(_index));
    progress.reglerLumiere(_scene.lumiere);
  }

  /// Avance d'un beat. Sans effet si le beat courant attend une décision.
  void avancer() {
    if (estBloque) return;
    _consommerEtAvancer();
  }

  void _consommerEtAvancer() {
    final b = beatCourant;
    if (b == null) return;

    // Effets de bord du beat qu'on quitte.
    switch (b.type) {
      case 'xp':
        progress.gagnerXp(b.montant);
      case 'compagnon':
        if (b.nom != null) progress.ajouterCompagnon(b.nom!);
      case 'transition':
        _allerA(b.vers!);
        return;
    }

    _joues.add(b);
    _index++;
    progress.marquerPosition(_scene.id, _index);

    // Un beat de transition en fin de scène s'enchaîne sans clic.
    final suivant = beatCourant;
    if (suivant != null && suivant.type == 'transition') {
      _allerA(suivant.vers!);
      return;
    }
    notifyListeners();
  }

  void _allerA(String sceneId) {
    final s = content.sceneById(sceneId);
    if (s == null) return;
    _scene = s;
    _index = 0;
    _joues.clear();
    progress.reglerLumiere(s.lumiere);
    progress.marquerPosition(s.id, 0);
    notifyListeners();
  }

  /// Le joueur a répondu au quiz. Une mauvaise réponse ne retire jamais d'XP
  /// et ne bloque jamais : le beat se referme dans les deux cas, après
  /// l'explication (CDC §11, §19).
  void validerQuiz(QuizQuestion q) {
    progress.marquerNotion(q.notion);
    _forcerAvance();
  }

  /// Le joueur a fait son choix narratif.
  void validerChoix() => _forcerAvance();

  /// Le joueur déclare avoir accompli l'action réelle.
  /// Déclaratif uniquement — aucune preuve n'est demandée (CDC §11, §16).
  void validerAction(RealAction a) {
    progress.marquerAction(a.id);
    _forcerAvance();
  }

  /// Le joueur reporte l'action. Aucune pénalité, aucun reproche : il reste
  /// simplement sur ce beat, et pourra revenir quand il veut.
  void reporterAction() {
    notifyListeners();
  }

  void terminerChapitre() {
    _chapitreTermine = true;
    notifyListeners();
  }

  void _forcerAvance() {
    final b = beatCourant;
    if (b == null) return;
    _joues.add(b);
    _index++;
    progress.marquerPosition(_scene.id, _index);
    final suivant = beatCourant;
    if (suivant != null && suivant.type == 'transition') {
      _allerA(suivant.vers!);
      return;
    }
    notifyListeners();
  }

  void recommencer() {
    _chapitreTermine = false;
    _scene = content.premiereScene;
    _index = 0;
    _joues.clear();
    progress.marquerPosition(_scene.id, 0);
    notifyListeners();
  }
}
