# NOUR — Le Jeu · PLAN.md

> Référence fonctionnelle : `NOUR_Le_Jeu_Cahier_des_Charges_V1.docx` (V1)
> Cible de cette itération : **Vertical slice jouable — Chapitre 1 « La Lumière perdue »**

---

## Étape 1 — Inspection du projet existant

État au démarrage :

| Élément | Présent | Note |
|---|---|---|
| Cahier des charges V1 (.docx) | ✅ | Lu intégralement, 20 sections |
| Planches de référence pixel art (5 PNG) | ✅ | Écrans mobiles, chambre, carte, HUD, dialogues |
| Code source | ❌ | Aucun |
| Choix technique arrêté | ❌ | Le CDC dit « Flutter **ou** React Native » |
| Projet Firebase | ❌ | À créer |

Aucun code existant → **aucune fonctionnalité à ne pas casser**. Départ propre.

Outils vérifiés sur la machine : Flutter 3.44.6 (stable), Node 24.18.0.

---

## Étape 4 — Architecture technique proposée

### Décision : **Flutter + Flame**, et non React Native

| Critère | Flutter + Flame | React Native |
|---|---|---|
| Rendu 2D / boucle de jeu | Flame : moteur 2D natif, sprite sheets, `SpriteAnimation` | Nécessite `react-native-game-engine` + Skia, moins mature |
| Pixel art net | `FilterQuality.none` de bout en bout, trivial | Lissage difficile à désactiver de façon fiable |
| Perf mobile 60 fps | Compilation AOT, un seul thread de rendu | Pont JS ⇄ natif = à-coups sur animation continue |
| Firebase | SDK officiel de première classe | Bon aussi |
| Cohérence UI + jeu | Le HUD Flutter se superpose au canvas Flame, un seul langage | Deux mondes de rendu à réconcilier |

Le CDC exige « pixel art lisible sur petit écran » et des micro-animations fluides
(§5, §12) avec priorité **FLUIDITÉ > COMPLEXITÉ**. Flame répond directement à ça.

### Découpage en couches

```
lib/
  main.dart
  app/            thème (palette ocre), routage, bootstrap
  core/           modèles, services, état (Riverpod)
  data/           dépôts : local (JSON) puis Firebase
  game/           monde Flame : acteurs, scènes, animations
  ui/             écrans Flutter : HUD, dialogue, quiz, action réelle, XP,
                  carte, bibliothèque des connaissances
assets/
  data/           CONTENU SÉPARÉ DU CODE (§6 CDC)
    scenes.json         scénario du Chapitre 1
    quiz.json           banque de questions + statut de validation
    knowledge.json      fiches de notions islamiques
    real_actions.json   actions réelles + variantes de contexte
  sprites/  bg/  ui/
```

**Règle d'or (§6 CDC)** : les quiz et dialogues se modifient dans les JSON,
jamais dans la logique du jeu. Le moteur de scène ne connaît que des `id`.

### Firebase — portée volontairement minimale

| Service | Utilisé | Pourquoi |
|---|---|---|
| Authentication | Oui (anonyme d'abord) | Sauvegarde sans formulaire, données minimales (§16) |
| Cloud Firestore | Oui | `users`, `player_progress`, `quest_attempts` |
| Cloud Functions | Non pour le MVP | Rien ne le justifie encore |
| Storage | Non pour le MVP | Les sprites sont livrés dans le bundle |
| Analytics | Non | §16 : collecter le minimum |
| FCM | Non pour le MVP | Nécessite consentement explicite |

Le contenu (`scenes`, `quiz`, `knowledge`) reste **local en JSON** pour le
prototype, avec la même forme que les futures collections Firestore : la
migration ne changera que la couche `data/`, pas le jeu.

---

## Étape 7 — Modèle de données (§15 CDC)

`users` · `player_progress` · `scenes` · `quests` · `quest_attempts` ·
`quiz_questions` · `knowledge` · `characters` · `dialogues` · `items` · `rewards`

Extensibilité : chaque scène porte `chapterId`, `order`, `unlockCondition`.
Le Chapitre 2 s'ajoutera en déposant un JSON, sans toucher au moteur.

---

## Étape 6 — Système de scène

Machine à états, une scène = une séquence de **beats** typés :

```
dialogue → choice → quiz → real_action → validation → xp_reward → transition
```

Le moteur lit la liste de beats et rend l'écran correspondant. Ajouter un
type de beat = ajouter un widget ; ajouter du contenu = éditer un JSON.

### Boucle centrale (§4 CDC)

```
ʿILM → ACTION RÉELLE → XP → PROGRESSION → HISTOIRE
```

**Garde-fous encodés dans le moteur, pas seulement dans les textes :**
- l'XP est un compteur ludique — jamais étiqueté comme mesure de foi ;
- la « Lumière » est un pourcentage narratif, sans jugement moral ;
- aucune validation d'action réelle ne demande de preuve (§9, §11, §16) ;
- l'échec d'un quiz n'inflige aucune perte — il ré-explique.

---

## Chapitre 1 — les 9 scènes

| # | Scène | Notion | Action réelle | XP |
|---|---|---|---|---|
| 1 | La chambre | — | Ranger un espace | 20 |
| 2 | Le carrefour | — | Choix d'objectif | — |
| 3 | Le premier Waswas | Istiʿādhah | Duʿā du matin | 60 |
| 4 | Je ne veux plus être seul | Taʿāruf | Saluer quelqu'un | 100 |
| 5 | Le village | Adab / Salām | Écouter quelqu'un | 80 |
| 6 | Le refus | Sabr | Réessayer sans forcer | 100 |
| 7 | Le geste | Niyyah | Rendre un service | 150 |
| 8 | Le feu | Shukr | Exprimer sa gratitude | 150 |
| 9 | Climax — Le Grand Waswas | ʿIlm | Dernière action | 250 |

---

## Contenu islamique — protocole (§3, §8 CDC)

Chaque entrée religieuse porte obligatoirement :
`texte · source · référence · statut · explication · niveau`

`statut` ∈ `{ A_VALIDER, VALIDE }`.

**Aucune entrée n'est `VALIDE` tant qu'un humain compétent ne l'a pas vérifiée.**
Les questions issues du §10 du CDC sont reprises **telles quelles**, avec leur
statut d'origine : Q4, Q5, Q7, Q9 sont explicitement « à vérifier » dans le CDC
et le restent ici. L'interface affiche un marqueur « à valider » sur ces fiches.

Interdits absolus, vérifiés à la relecture :
- aucun hadith ni verset inventé ;
- aucune parole attribuée au Prophète ﷺ sans référence ;
- aucune invocation présentée comme une attaque ou un pouvoir ;
- aucune représentation de prophète.

---

## Étapes 8–10 — Test, correction, itération

1. Vertical slice jouable de bout en bout (scènes 1 → 9)
2. Passe QA : boucle complète sans blocage, sauvegarde/reprise
3. Branchement Firebase
4. Sprites pixel art définitifs en remplacement des placeholders
5. Chapitre 2

---

## Ce qui est livré maintenant

Un prototype **jouable dans le navigateur** (canvas HTML autonome) couvrant la
boucle complète du Chapitre 1 — c'est la maquette jouable qui valide le game
design avant d'engager le code Flutter. La structure des données JSON qu'il
utilise est exactement celle que reprendra le client Flutter.
