# NOUR — Sprites pixel art

Organisation, nommage et fabrication des sprites du jeu.

---

## Arborescence

```
app/assets/pixel/
├── sprites.json                    manifeste généré (frames, tailles, fps)
│
├── characters/
│   ├── protagonist/
│   │   ├── idle.png                4 frames · 37×97
│   │   ├── walk.png                4 frames · 46×96
│   │   ├── interact.png            1 frame  · 46×96
│   │   └── emotion.png             1 frame  · 46×96
│   │
│   ├── noura/
│   │   ├── idle.png                4 frames · 43×97
│   │   ├── walk.png                6 frames · 47×96
│   │   └── interact.png            1 frame  · 43×96
│   │
│   └── npcs/
│       ├── enfant_pecheur.png      1 frame  · 36×96
│       ├── fille_panier.png        1 frame  · 54×96
│       ├── marchand.png            1 frame  · 42×96
│       └── karim_ancien.png        1 frame  · 41×96
│
└── enemies/
    ├── waswas/
    │   ├── idle.png                4 frames · 211×146
    │   ├── move.png                4 frames · 211×150
    │   └── disappear.png           4 frames · 211×140
    │
    └── grand_waswas/
        ├── idle.png                4 frames · 285×196
        ├── attack.png              4 frames · 285×202
        └── disappear.png           4 frames · 285×190
```

Total : 17 fichiers, ~880 Ko.

---

## Correspondance avec le Chapitre 1

| Sprite | Où il sert |
|---|---|
| `protagonist/*` | toutes les scènes |
| `noura/*` | dès la scène 3, puis tout le chapitre |
| `npcs/karim_ancien` | scène 7 « Le geste » — devient le compagnon |
| `npcs/marchand`, `fille_panier`, `enfant_pecheur` | scène 5 « Le village » |
| `waswas/*` | scènes 3 et 6 |
| `grand_waswas/*` | scène 9 — climax |

---

## Conventions

Toutes garanties par le script de fabrication et vérifiées par
`app/test/sprites_test.dart` :

- **Frames de largeur égale** — une spritesheet de N frames a une largeur
  exactement divisible par N.
- **Point d'ancrage constant** — personnage centré horizontalement, pieds
  alignés sur le bas de la frame. Une animation ne « saute » jamais.
- **Vraie transparence** — PNG avec canal alpha.
- **Hauteur normalisée** — 96 px pour les personnages, plus pour les masses.
- **Aucun lissage** — redimensionnement `NEAREST`, affichage
  `filterQuality: none`.

### Respect du cahier des charges

- Personnages **de dos ou de trois quarts**, visages non détaillés (CDC §6, §12).
- Waswas = **masse abstraite**, sans visage ni figure littérale d'un être
  invisible (CDC §12).
- `disappear.png` est un **fondu avec retrait**, pas une mise à mort : le
  waswas est une pensée qui recule, pas un monstre vaincu (CDC §5).

---

## Fabriquer / régénérer

```bash
python tools/decoupe_sprites.py
```

Le script lit `sources/sprites/*.jpeg`, produit tous les PNG et réécrit
`sprites.json`. Il est **idempotent** : on peut le relancer autant de fois
que voulu.

### Ce que le script résout

Les sources sont des **JPEG avec le damier de transparence peint dans
l'image** — ce n'est pas un vrai canal alpha. Un simple filtre sur le gris ne
marche pas : le protagoniste porte du gris-bleu proche du gris du damier.

Le script fait un **remplissage par diffusion depuis les bords** : seuls les
pixels gris *connectés au bord* deviennent transparents. Un gris à l'intérieur
du vêtement est donc préservé. Les résidus JPEG isolés sont ensuite supprimés
par un filtre d'îlots.

> **Mieux vaut fournir de vrais PNG à fond transparent.** Le détourage depuis
> un JPEG reste une récupération : elle marche ici, mais un PNG propre donnera
> toujours un meilleur résultat.

---

## Remplacer un sprite — dépose et relance

Le script **détecte automatiquement** une planche dessinée si elle porte le
bon nom. Aucune modification de code n'est nécessaire.

| Dépose ce fichier dans `sources/sprites/` | Ce qu'il remplace |
|---|---|
| `protagonist-idle-planche.png` | l'idle dérivé du protagoniste |
| `protagonist-walk-planche.png` | la marche du protagoniste |
| `noura-idle-planche.png` | l'idle dérivé de Noura |
| `noura-walk-planche.png` | la marche de Noura |

Puis :

```bash
python tools/decoupe_sprites.py
cd app && flutter test
```

Le script annonce ce qu'il utilise :

```
[planche dessinee] noura-idle-planche.png (4 frames)   ← planche trouvée
[derive] pas de noura-idle-planche.png -- repli sur ...  ← repli
```

**Nombre de frames différent ?** Encode-le dans le nom :
`noura-walk-planche-6f.png` → 6 frames. Sans suffixe, la valeur par défaut
s'applique (4 pour les idle, 4/6 pour les marches).

`sprites.json` est régénéré à chaque passage : **aucune dimension n'est codée
en dur dans le jeu**. Une planche de taille ou de cadence différente est prise
en compte sans toucher au code.

> Fournis des **PNG à vraie transparence** si possible. Le détourage du damier
> peint fonctionne, mais c'est une récupération — un PNG propre donnera
> toujours un meilleur résultat.

---

## État réel — à lire avant de commander des planches

Ce qui vient de vraies planches dessinées :

| Sprite | Origine |
|---|---|
| `protagonist/walk` | planche 4 frames fournie ✅ |
| `noura/walk` | planche 6 frames fournie ✅ |
| `protagonist/idle` | planche 4 frames dessinée ✅ |
| `noura/idle` | planche 4 frames dessinée ✅ |
| `noura/interact` | pose de dialogue trois quarts face ✅ |
| `npcs/*` | planche 4 personnages fournie ✅ |
| `waswas`, `grand_waswas` (pose de base) | planches fournies ✅ |

Ce qui est **dérivé automatiquement**, et gagnerait à être redessiné :

| Sprite | Comment il est fabriqué | Ce qu'il faudrait |
|---|---|---|
| `protagonist/interact` | frame de marche réutilisée | geste dédié (tendre la main, ouvrir une porte) |
| `protagonist/emotion` | frame de marche réutilisée | pose d'émotion (doute, soulagement) |
| `waswas/move`, `grand_waswas/attack` | flottement de la pose de base | ondulation dessinée de la masse |
| `*/disappear` | fondu + retrait programmé | dissipation dessinée |

Ces dérivés sont **fonctionnels et cohérents** — le jeu tourne avec. Ils ne
sont simplement pas au niveau d'une animation dessinée à la main.

### Encore à produire

- Les trois villageois nommés dans le scénario (« un homme au puits »,
  « une femme sous l'auvent », « un jeune du village ») — prompt prêt dans
  [PROMPTS_ASSETS.md](PROMPTS_ASSETS.md). Alternative : adapter les dialogues
  aux PNJ existants.
- Animations de marche pour les PNJ, si le village doit être vivant

---

## Noura de face pendant les dialogues

Elle parle 17 fois dans le chapitre. Le moteur choisit automatiquement :

| Situation | Sprite affiché |
|---|---|
| Noura prononce la réplique courante | `interact.png` — trois quarts face |
| Elle est présente sans parler | `idle.png` — de dos, respiration |

Piloté par `nouraParle` dans [decor_painter.dart](app/lib/ui/decor_painter.dart),
alimenté par le type du beat courant.
