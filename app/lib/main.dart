import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/sync_service.dart';
import 'firebase_options.dart';
import 'app/theme.dart';
import 'core/player_progress.dart';
import 'core/sprite_catalog.dart';
import 'data/content_repository.dart';
import 'ui/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const NourApp());
}

class NourApp extends StatelessWidget {
  const NourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOUR — Le Jeu',
      debugShowCheckedModeBanner: false,
      theme: NourTheme.build(),
      home: const _Bootstrap(),
    );
  }
}

/// Chargement du contenu et de la progression, puis écran-titre.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  ContentRepository? _content;
  PlayerProgress? _progress;
  SpriteCatalog? _sprites;
  Object? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final content = await ContentRepository.load();
      final progress = await PlayerProgress.load();

      // Firebase : sauvegarde dans le cloud, sans jamais bloquer le jeu.
      // Si l'initialisation echoue (hors ligne, config absente), on reste
      // en local et le joueur ne voit aucune difference.
      SyncService sync = const LocalOnlySync();
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        final fb = FirebaseSync();
        await fb.init();
        if (fb.pret) {
          sync = fb;
          final distant = await fb.pull();
          if (distant != null) progress.fusionner(distant);
          progress.auSauvegarde = (p) => sync.push(p);
        }
      } catch (_) {
        // Firebase indisponible (hors ligne, auth non activee, quota) :
        // le jeu continue en local, le joueur ne voit aucune difference.
      }
      // Le catalogue de sprites ne bloque jamais le demarrage : s'il est
      // vide, le jeu tourne en rendu procedural.
      final sprites = await SpriteCatalog.load();
      if (!mounted) return;
      setState(() {
        _content = content;
        _progress = progress;
        _sprites = sprites;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_erreur != null) {
      return Scaffold(
        backgroundColor: NourColors.sable,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Contenu illisible :\n$_erreur',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
          ),
        ),
      );
    }

    if (_content == null || _progress == null) {
      return const Scaffold(
        backgroundColor: NourColors.sable,
        body: Center(
          child: CircularProgressIndicator(color: NourColors.ocre),
        ),
      );
    }

    return TitleScreen(
      content: _content!,
      progress: _progress!,
      sprites: _sprites,
    );
  }
}

/// Écran-titre (CDC §13 — splash / identité NOUR).
class TitleScreen extends StatelessWidget {
  const TitleScreen({
    super.key,
    required this.content,
    required this.progress,
    this.sprites,
  });

  final ContentRepository content;
  final PlayerProgress progress;
  final SpriteCatalog? sprites;

  void _jouer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          content: content,
          progress: progress,
          sprites: sprites,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NourColors.sable,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo pixel art du jeu (CDC 13 - splash / identite NOUR).
                Image.asset(
                  'assets/bg/logo-nour.png',
                  width: 260,
                  filterQuality: FilterQuality.none,
                  isAntiAlias: false,
                ),
                const SizedBox(height: 18),
                NourPanel(
                  color: NourColors.parchemin,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        content.chapitreTitre.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: NourColors.ocreFonce,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Retrouve ta lumière.\nAvance dans la vraie vie.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: NourColors.encreDouce),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                NourButton(
                  label: progress.aUneSauvegarde
                      ? 'Reprendre'
                      : 'Commencer',
                  onPressed: () => _jouer(context),
                ),
                if (progress.aUneSauvegarde) ...[
                  const SizedBox(height: 10),
                  NourButton(
                    label: 'Nouvelle partie',
                    filled: false,
                    onPressed: () async {
                      await progress.reinitialiser();
                      if (context.mounted) _jouer(context);
                    },
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Les contenus religieux de ce prototype sont en cours de '
                  'vérification et ne sont pas définitifs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10, height: 1.5, color: NourColors.verrou),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
