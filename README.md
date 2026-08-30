# NOUR — Le Jeu

RPG mobile pixel art. **Chapitre 1 — Le chemin commence**, vertical slice jouable.

> **Principe non négociable :** Allah est Celui qui donne les bienfaits et
> permet les causes. Le jeu ne transforme jamais une invocation en pouvoir.
> Les quiz servent à apprendre ; l'XP récompense la progression dans le jeu,
> jamais la foi.

Référence fonctionnelle : `NOUR_Le_Jeu_Cahier_des_Charges_V1.docx`
Plan technique : [PLAN.md](PLAN.md)

---

## Lancer le jeu

```bash
cd app
flutter pub get
flutter run                 # appareil Android/iOS branché
flutter run -d chrome       # test rapide au navigateur
```

## Tests

```bash
cd app
flutter test        # 30 tests : contenu, règles CDC, assets, sprites, partie complète
flutter analyze     # 0 issue
```

Les tests ne vérifient pas seulement le code : ils **verrouillent les règles non
négociables du cahier des charges**. Ils échouent si quelqu'un marque un contenu
religieux comme validé sans vérification, ajoute une demande de preuve intrusive,
ou fait reculer la progression du joueur.

---

## Structure

```
data/                   contenu source (édité par l'équipe contenu)
  scenes.json             les 9 scènes du chapitre 1
  quiz.json               banque de questions + statut de validation
  knowledge.json          fiches de notions islamiques
  real_actions.json       actions réelles + variantes de contexte

app/
  lib/app/              thème (palette ocre/sable/terre cuite)
  lib/core/             modèles, moteur de scène, progression
  lib/data/             chargement du contenu, ancrage Firebase
  lib/ui/               HUD, dialogue, quiz, action réelle, carte, bibliothèque
  assets/data/          copie du contenu embarquée dans l'app
  assets/bg/            décors peints
  assets/pixel/         sprites + sprites.json (manifeste)
  test/                 QA

firestore.rules         règles de sécurité Firestore
sources/                images sources archivées (jamais lues par l'app)
tools/                  scripts de fabrication des assets
```

### Modifier le contenu sans toucher au code

Éditer un JSON dans `data/`, puis :

```bash
cp data/*.json app/assets/data/
cd app && flutter test    # vérifie que rien n'est cassé
```

Le moteur ne connaît que des `id` : ajouter une scène, un quiz ou une action ne
demande aucune modification de la logique du jeu (CDC §6).

---

## Boucle de gameplay

```
ʿILM → ACTION RÉELLE → XP → PROGRESSION → HISTOIRE
```

Une scène est une liste de **beats** typés, lus par `SceneEngine` :

| Beat | Rôle |
|---|---|
| `narration` / `monologue` / `noura` / `pnj` / `waswas` | dialogue — **une réplique à la fois**, historique via l'icône horloge du HUD |
| `choix` | choix narratif, panneau de direction |
| `quiz` | apprentissage — jamais une attaque |
| `real_action` | action dans la vraie vie, validation déclarative |
| `xp` | récompense ludique — célébration plein écran après une action réelle |
| `etape` | étapes du climax |
| `transition` / `fin` | enchaînement |

Ajouter un type de beat = ajouter un widget. Ajouter du contenu = éditer un JSON.

---

## Garde-fous appliqués

**Contenu religieux (CDC §3, §8)**
Chaque entrée porte `source`, `reference`, `statut`. Aucun hadith ni verset
inventé. Les références ont été précisées par l'équipe (Bukhari 1, 6018, 6237 ;
Muslim 2664 ; Coran 2:153, 14:7, 16:98, 49:13) mais **7 des 8 quiz et les 9
fiches restent `A_VALIDER`** tant qu'une personne compétente ne les a pas
vérifiées — l'interface l'affiche au joueur.
Seul `q10_ilm` est `VALIDE` : c'est une phrase de philosophie du jeu, pas un
texte religieux.

**Protection du joueur (CDC §9, §11, §16)**
Validation déclarative uniquement. Jamais de photo, d'audio, de localisation ni
d'accès aux messages. « Plus tard » est toujours proposé, sans reproche. Une
mauvaise réponse ne retire jamais d'XP.

**Séparation jeu / religion (CDC §3, §5)**
L'XP est une mécanique de jeu et ne mesure jamais la foi. La « Lumière » est une
métaphore narrative. Le Waswas est une masse abstraite, jamais une figure
littérale. Aucune invocation n'est présentée comme une attaque ou un pouvoir.

---

## État actuel

| | |
|---|---|
| Chapitre 1 jouable de bout en bout | ✅ 9 scènes, 173 beats, 8 quiz, 8 actions, 910 XP |
| Écrans | ✅ titre, jeu, dialogue, quiz, action, carte, bibliothèque |
| Sauvegarde / reprise | ✅ locale (`shared_preferences`) |
| Décors des 9 scènes | ✅ illustrations pixel art définitives |
| Sprites en jeu | ✅ branchés au moteur (protagoniste, Noura, Karim, Waswas) |
| Firebase | ⚠️ configuré et déployé — reste à activer l'auth anonyme |
| Build Android / Web | ✅ vérifiés |
| Sprites personnages | ✅ protagoniste, Noura, 4 PNJ, Waswas, Grand Waswas |
| Animations dérivées | 🎨 idle / interact / disappear (voir SPRITES.md) |

### Firebase

Projet : **`nour-le-jeux`**. Configuré pour Android, iOS et Web
(`lib/firebase_options.dart`), packages installés, règles de sécurité
**déployées et compilées**.

Portée volontairement minimale (CDC §16 — collecter le minimum) :
auth **anonyme** (aucun e-mail demandé) + la seule collection
`player_progress`. Pas d'Analytics, pas de Storage, pas de Cloud Functions.

**Il reste une action manuelle** (impossible en ligne de commande) :

> Console Firebase → **Authentication** → *Get started* →
> activer le fournisseur **Anonyme**.
> <https://console.firebase.google.com/project/nour-le-jeux/authentication/providers>

Tant que ce n'est pas fait, `accounts:signUp` renvoie
`CONFIGURATION_NOT_FOUND`. **Ce n'est pas bloquant** : l'échec est absorbé,
le jeu tourne et sauvegarde en local exactement comme avant — comportement
vérifié en conditions réelles.

Règle de conception : *le réseau ne doit jamais bloquer une partie.* Toute
erreur Firebase est avalée, la sauvegarde locale reste la source de vérité.

---

## Prochaines étapes

1. **Validation religieuse** — dossier prêt :
   [VALIDATION_RELIGIEUSE.docx](VALIDATION_RELIGIEUSE.docx) (annotable dans
   Word) et [.md](VALIDATION_RELIGIEUSE.md). À faire relire par une personne
   compétente. **Bloquant pour toute publication.**
   Régénérer après modification du contenu :
   `python tools/dossier_validation.py && python tools/dossier_validation_docx.py`
2. Planches dessinées pour les animations aujourd'hui dérivées
   (`idle`, `interact`, `emotion`) — détail dans [SPRITES.md](SPRITES.md).
3. Activer l'auth anonyme dans la console Firebase (voir ci-dessus).
4. Playtests (CDC §19 : le joueur comprend-il la boucle, l'action réelle est-elle
   faisable, le ton reste-t-il non culpabilisant ?).
5. Chapitre 2.

---

## Illustrations

Les décors peints vivent dans `app/assets/bg/`. Le système est mixte : une
illustration quand elle existe, un rendu procédural sinon — le jeu ne casse
jamais parce qu'un visuel manque.

| Décor | Source | Écran |
|---|---|---|
| `chambre` | `assets/bg/chambre.png` | Scène 1 |
| `carrefour` | `assets/bg/carrefour.png` | Scène 2 |
| `waswas` | `assets/bg/waswas.png` | Scène 3 |
| `vallee` | `assets/bg/vallee.png` | Scène 4 |
| `village` | `assets/bg/village.png` | Scènes 5 à 7 |
| `riviere` | `assets/bg/riviere.png` | Scène 8 — « Le jardin abandonné » |
| `climax` | `assets/bg/climax.png` | Scène 9 |

**Ajouter une illustration** : déposer le PNG dans `app/assets/bg/`, puis
ajouter une ligne dans `_fonds` de
[decor_painter.dart](app/lib/ui/decor_painter.dart). Rien d'autre à modifier.

Deux règles appliquées automatiquement :
- `filterQuality: none` — le pixel art n'est jamais lissé à l'agrandissement ;
- quand un fond peint contient déjà le personnage et ses sources de lumière,
  le moteur n'y superpose ni protagoniste ni lanterne (`_fondsAvecProtagoniste`).

Les images sont redimensionnées à 768 px de large (NEAREST, pour préserver le
grain pixel) : 5,5 Mo d'originaux ramenés à 1,7 Mo embarqués.

---

## Sprites

17 fichiers dans `app/assets/pixel/`, organisés par personnage et par ennemi.
Le détail — conventions, correspondance avec les scènes, et surtout **ce qui
vient d'une vraie planche dessinée par rapport à ce qui est dérivé
automatiquement** — est dans [SPRITES.md](SPRITES.md).

Régénérer après avoir remplacé une source :

```bash
python tools/decoupe_sprites.py
cd app && flutter test
```

Le jeu lit le nombre de frames et leur taille dans
`app/assets/pixel/sprites.json`, généré par le script : **aucune dimension
n'est codée en dur**. Remplacer une planche et relancer suffit.

---

## Construire un APK

```bash
cd app
flutter build apk --release                    # 51,6 Mo, toutes architectures
flutter build apk --release --split-per-abi    # ~22 Mo par architecture
```

| Fichier | Taille | Pour |
|---|---|---|
| `app-arm64-v8a-release.apk` | 22,7 Mo | tous les téléphones récents |
| `app-armeabi-v7a-release.apk` | 20,1 Mo | appareils 32 bits anciens |
| `app-release.apk` | 51,6 Mo | universel (contient les 3 architectures) |

**Attention — signature.** Ces APK sont signés avec la clé *debug* d'Android
(`CN=Android Debug`). Ils s'installent et se testent, mais **le Play Store les
refuse**. Pour publier il faudra créer un keystore et le déclarer dans
`android/key.properties`.

**Attention — contenu.** Tant que la validation religieuse n'est pas faite,
ces APK sont destinés à un **test restreint**, pas à une diffusion large.
