import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/player_progress.dart';

/// Synchronisation Firebase de la progression.
///
/// Portée volontairement minimale (CDC §16 — collecter le minimum) :
///  - Authentification **anonyme** : sauvegarde sans e-mail ni formulaire ;
///  - Firestore : `player_progress/{uid}` uniquement ;
///  - AUCUNE collecte de preuve d'acte religieux, de localisation, de photo,
///    d'audio ou de contenu de messages.
///
/// Règle de conception : le réseau ne doit **jamais** bloquer une partie.
/// Toute erreur (hors ligne, quota, règles) est avalée ; la sauvegarde locale
/// reste la source de vérité pour jouer.
abstract class SyncService {
  Future<void> init();
  Future<void> push(PlayerProgress progress);
  Future<Map<String, dynamic>?> pull();
}

/// Repli hors-ligne : tout reste en local.
/// Utilisé si Firebase n'est pas initialisable (config absente, réseau coupé).
class LocalOnlySync implements SyncService {
  const LocalOnlySync();

  @override
  Future<void> init() async {}

  @override
  Future<void> push(PlayerProgress progress) async {}

  @override
  Future<Map<String, dynamic>?> pull() async => null;
}

class FirebaseSync implements SyncService {
  User? _user;

  bool get pret => _user != null;
  String? get uid => _user?.uid;

  @override
  Future<void> init() async {
    try {
      // Auth anonyme : aucune donnée personnelle demandée au joueur (CDC §16).
      _user = FirebaseAuth.instance.currentUser ??
          (await FirebaseAuth.instance.signInAnonymously()).user;
    } catch (_) {
      _user = null;
    }
  }

  DocumentReference<Map<String, dynamic>>? get _doc {
    final id = _user?.uid;
    if (id == null) return null;
    return FirebaseFirestore.instance.collection('player_progress').doc(id);
  }

  @override
  Future<void> push(PlayerProgress progress) async {
    try {
      await _doc?.set({
        ...progress.toJson(),
        'maj': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Hors ligne : la sauvegarde locale suffit, on ne signale rien au joueur.
    }
  }

  @override
  Future<Map<String, dynamic>?> pull() async {
    try {
      final snap = await _doc?.get();
      final data = snap?.data();
      if (data == null) return null;
      // `maj` est un Timestamp serveur : il ne fait pas partie du modèle.
      return Map<String, dynamic>.from(data)..remove('maj');
    } catch (_) {
      return null;
    }
  }
}
