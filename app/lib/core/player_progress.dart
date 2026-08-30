import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Progression du joueur (CDC §15 `player_progress`).
///
/// L'XP est une mécanique de jeu, rien d'autre : elle ne mesure jamais la foi,
/// la piété ou la valeur d'une personne (CDC §3, §16). Aucune donnée sensible
/// n'est stockée — pas de preuve d'acte religieux, pas de localisation.
///
/// Persistance locale pour le prototype ; la même forme sera écrite dans
/// Firestore sous `player_progress/{uid}`.
class PlayerProgress extends ChangeNotifier {
  PlayerProgress._(this._prefs, Map<String, dynamic> data)
      : _xp = _entier(data['xp']),
        _lumiere = _entier(data['lumiere']),
        _sceneId = data['scene_id'] is String ? data['scene_id'] as String : null,
        _beatIndex = _entier(data['beat_index']),
        _actionsFaites = _ensemble(data['actions_faites']),
        _notionsVues = _ensemble(data['notions_vues']),
        _compagnons = _ensemble(data['compagnons']);

  /// Lecture defensive : une sauvegarde corrompue ou ecrite par une version
  /// anterieure ne doit jamais empecher de jouer. On repart des valeurs par
  /// defaut plutot que de planter.
  static int _entier(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static Set<String> _ensemble(Object? v) {
    if (v is! List) return <String>{};
    return v.whereType<String>().toSet();
  }

  static const _key = 'nour_player_progress_v1';

  /// Appelé après chaque sauvegarde locale. Branché sur Firebase au
  /// démarrage ; laissé nul, le jeu fonctionne intégralement hors ligne.
  void Function(PlayerProgress)? auSauvegarde;

  final SharedPreferences _prefs;

  int _xp;
  int _lumiere;
  String? _sceneId;
  int _beatIndex;
  final Set<String> _actionsFaites;
  final Set<String> _notionsVues;
  final Set<String> _compagnons;

  int get xp => _xp;
  int get lumiere => _lumiere;
  String? get sceneId => _sceneId;
  int get beatIndex => _beatIndex;
  Set<String> get notionsVues => Set.unmodifiable(_notionsVues);
  Set<String> get compagnons => Set.unmodifiable(_compagnons);
  bool actionFaite(String id) => _actionsFaites.contains(id);

  /// Paliers de niveau. Purement ludique — un « niveau » ne dit rien de la
  /// personne, seulement de son avancée dans l'histoire.
  static const _paliers = [0, 100, 250, 450, 700, 1000, 1400];

  int get niveau {
    var n = 1;
    for (var i = 0; i < _paliers.length; i++) {
      if (_xp >= _paliers[i]) n = i + 1;
    }
    return n;
  }

  int get xpPalierActuel => _paliers[(niveau - 1).clamp(0, _paliers.length - 1)];

  int get xpProchainPalier =>
      niveau < _paliers.length ? _paliers[niveau] : _paliers.last;

  /// Progression 0..1 à l'intérieur du niveau courant.
  double get progressionNiveau {
    final span = xpProchainPalier - xpPalierActuel;
    if (span <= 0) return 1;
    return ((_xp - xpPalierActuel) / span).clamp(0.0, 1.0);
  }

  bool get aUneSauvegarde => _sceneId != null;

  static Future<PlayerProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    var data = <String, dynamic>{};
    try {
      final raw = prefs.getString(_key);
      if (raw != null) {
        final decode = json.decode(raw);
        if (decode is Map<String, dynamic>) data = decode;
      }
    } catch (_) {
      // Sauvegarde illisible : on recommence proprement plutot que de
      // bloquer le joueur sur un ecran d'erreur.
    }
    return PlayerProgress._(prefs, data);
  }

  Map<String, dynamic> toJson() => {
        'xp': _xp,
        'lumiere': _lumiere,
        'scene_id': _sceneId,
        'beat_index': _beatIndex,
        'actions_faites': _actionsFaites.toList(),
        'notions_vues': _notionsVues.toList(),
        'compagnons': _compagnons.toList(),
      };

  Future<void> _save() async {
    await _prefs.setString(_key, json.encode(toJson()));
    // La synchro distante est un bonus : elle ne doit jamais retarder ni
    // interrompre le jeu.
    auSauvegarde?.call(this);
  }

  /// Applique une progression venue du serveur, si elle est plus avancée que
  /// la locale. On ne fait jamais reculer un joueur (CDC : la Lumiere et l'XP
  /// ne redescendent pas).
  void fusionner(Map<String, dynamic> distant) {
    final xpDistant = _entier(distant['xp']);
    if (xpDistant <= _xp) return;
    _xp = xpDistant;
    _lumiere = _entier(distant['lumiere']).clamp(0, 100);
    final sid = distant['scene_id'];
    if (sid is String) {
      _sceneId = sid;
      _beatIndex = _entier(distant['beat_index']);
    }
    _actionsFaites.addAll(_ensemble(distant['actions_faites']));
    _notionsVues.addAll(_ensemble(distant['notions_vues']));
    _compagnons.addAll(_ensemble(distant['compagnons']));
    notifyListeners();
  }

  void gagnerXp(int montant) {
    if (montant <= 0) return;
    _xp += montant;
    notifyListeners();
    _save();
  }

  /// La Lumière ne redescend jamais : le joueur ne perd pas ce qu'il a compris.
  void reglerLumiere(int valeur) {
    if (valeur <= _lumiere) return;
    _lumiere = valeur.clamp(0, 100);
    notifyListeners();
    _save();
  }

  void marquerPosition(String sceneId, int beatIndex) {
    _sceneId = sceneId;
    _beatIndex = beatIndex;
    _save();
  }

  void marquerAction(String id) {
    _actionsFaites.add(id);
    notifyListeners();
    _save();
  }

  void marquerNotion(String id) {
    if (_notionsVues.add(id)) {
      notifyListeners();
      _save();
    }
  }

  void ajouterCompagnon(String nom) {
    if (_compagnons.add(nom)) {
      notifyListeners();
      _save();
    }
  }

  Future<void> reinitialiser() async {
    _xp = 0;
    _lumiere = 0;
    _sceneId = null;
    _beatIndex = 0;
    _actionsFaites.clear();
    _notionsVues.clear();
    _compagnons.clear();
    notifyListeners();
    await _prefs.remove(_key);
  }
}
