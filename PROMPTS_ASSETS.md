# NOUR — Prompts pour les assets manquants

Prompts prêts à copier dans ton générateur d'images.
Classés **par priorité réelle** : le n°1 est celui qui change le plus le jeu.

---

## Règles communes à tous les prompts

À rappeler dans chaque génération, ce sont les erreurs les plus fréquentes :

- **PNG à fond transparent** — pas de damier peint dans l'image, pas de JPEG.
  C'est le point qui coûte le plus cher à rattraper.
- **Toutes les frames à la même taille**, même échelle, même point d'ancrage,
  pieds alignés en bas. Sinon l'animation « saute ».
- **Visage non détaillé** — silhouette et couleurs suffisent à reconnaître
  le personnage (cahier des charges §6, §12).
- **Pas de texte, pas d'interface, pas de cadre** dans l'image.
- Palette chaude : ocre, sable, beige, terre cuite.

---

# PRIORITÉ 1 — Les deux animations idle

C'est ce qui se voit **en permanence** à l'écran. Aujourd'hui les personnages
sont figés : une seule pose que le moteur fait osciller d'1 pixel.

## 1A. Protagoniste — IDLE

> Créer une SPRITESHEET PIXEL ART du protagoniste de NOUR.
>
> Le personnage doit être **exactement le même** que le sprite existant :
> jeune garçon vu de dos / trois quarts dos, cheveux bruns en bataille,
> écharpe rouge foncé, tunique bleu-gris, brassards blancs, pantalon brun,
> bottes de cuir marron, sac à dos en cuir.
>
> Animation IDLE : le personnage est debout, immobile, il respire.
>
> **4 frames horizontales**, dans cet ordre :
> 1. position neutre
> 2. le corps monte très légèrement (inspiration), les épaules se soulèvent
> 3. retour à la position neutre
> 4. le corps descend très légèrement (expiration)
>
> L'écharpe et le bas de la tunique bougent très doucement, comme sous une
> brise légère. Le sac à dos reste stable.
>
> Mouvement **minimal et naturel**. Aucune animation exagérée. Le personnage
> reste pratiquement immobile — c'est une respiration, pas un balancement.
>
> Contraintes techniques :
> - fond **transparent** (PNG, pas de damier peint, pas de JPEG)
> - les 4 frames ont exactement la même taille et la même échelle
> - même point d'ancrage : les pieds sont alignés sur la même ligne
> - pas de texte, pas d'interface, pas de cadre
>
> Style pixel art RPG 16-bit, palette chaude ocre et terre.
> Spritesheet prête pour un moteur de jeu 2D.

**Fichier à déposer :** `sources/sprites/protagonist-idle-planche.png`

---

## 1B. Noura — IDLE

> Créer une SPRITESHEET PIXEL ART de NOURA, personnage féminin de NOUR.
>
> Le personnage doit être **exactement le même** que le sprite existant :
> femme vue de dos / trois quarts dos, hijab beige clair drapé sur les
> épaules, longue robe verte à liseré doré au bas et aux manches, ceinture
> de cuir brun, sacoche en bandoulière, chaussures de cuir marron.
>
> **Aucun détail de visage.**
>
> Animation IDLE : elle est debout, calme, elle respire.
>
> **4 frames horizontales**, dans cet ordre :
> 1. position neutre
> 2. le corps monte très légèrement (inspiration)
> 3. retour à la position neutre
> 4. le corps descend très légèrement (expiration)
>
> Le voile et le bas de la robe ondulent très doucement. La sacoche reste
> stable. Posture calme et bienveillante.
>
> Mouvement **minimal**. Aucune animation exagérée.
>
> Contraintes techniques :
> - fond **transparent** (PNG, pas de damier peint, pas de JPEG)
> - les 4 frames ont exactement la même taille et la même échelle
> - même point d'ancrage : les pieds alignés sur la même ligne
> - pas de texte, pas d'interface, pas de cadre
>
> Style pixel art RPG 16-bit, palette chaude.
> Spritesheet prête pour un moteur de jeu 2D.

**Fichier à déposer :** `sources/sprites/noura-idle-planche.png`

---

# PRIORITÉ 2 — Noura vue de face

Noura parle **17 fois** dans le chapitre. Toutes ses planches actuelles sont
de dos : quand elle s'adresse au joueur, c'est étrange.

## 2. Noura — pose de dialogue, trois quarts face

> Créer un SPRITE PIXEL ART de NOURA, personnage féminin de NOUR.
>
> Même personnage exactement : hijab beige clair, longue robe verte à liseré
> doré, ceinture de cuir brun, sacoche en bandoulière.
>
> Cette fois vue de **trois quarts face**, tournée vers le spectateur, dans
> une posture de dialogue : elle parle, une main légèrement ouverte devant
> elle dans un geste d'explication calme.
>
> **Visage volontairement non détaillé** : pas de traits réalistes, pas de
> bouche ni d'yeux détaillés. On la reconnaît à sa silhouette, ses couleurs
> et son voile — pas à son visage.
>
> Posture bienveillante, ni autoritaire ni figée.
>
> **1 seule pose** (pas d'animation).
>
> Contraintes techniques :
> - fond **transparent** (PNG, pas de damier peint, pas de JPEG)
> - personnage centré, pieds en bas de l'image
> - pas de texte, pas d'interface, pas de cadre
>
> Style pixel art RPG 16-bit, palette chaude, cohérent avec le sprite de dos
> existant.

**Fichier à déposer :** `sources/sprites/noura-face-planche.png`

---

# PRIORITÉ 3 — Les trois PNJ du village

Le scénario nomme précisément trois personnages qui n'existent pas encore.
Les PNJ actuels (enfant pêcheur, fille au panier, marchand) ne correspondent
à aucun d'eux.

> **Alternative gratuite :** je peux adapter les dialogues aux PNJ existants
> plutôt que d'en générer trois. Dis-le-moi si tu préfères.

## 3. Les trois villageois

> Créer une planche de SPRITES PIXEL ART : **3 personnages villageois** pour
> un RPG 2D, alignés horizontalement, bien séparés.
>
> Tous les trois vus **de dos ou de trois quarts dos**, visages non
> détaillés. Style pixel art RPG 16-bit, palette chaude ocre, sable, terre
> cuite, cohérent avec un village méditerranéen ancien.
>
> **Personnage 1 — un homme au puits**
> Homme adulte, la quarantaine, tenue de travail simple en lin beige,
> manches retroussées, ceinture de corde. Il porte un seau ou une corde.
> Posture accueillante, tournée vers le spectateur en trois quarts.
>
> **Personnage 2 — une femme sous l'auvent**
> Femme adulte, robe longue terre cuite, foulard sur les cheveux, tablier.
> Elle est debout, détendue, à l'ombre. Posture paisible et hospitalière.
>
> **Personnage 3 — un jeune du village**
> Adolescent ou jeune adulte, tunique simple bleu-gris ou verte, allure
> pressée. Il est **en train de partir**, tourné vers l'extérieur, comme
> s'il rejoignait un groupe. Posture qui exprime « pas maintenant » sans
> être hostile ni méchante.
>
> Contraintes techniques :
> - fond **transparent** (PNG, pas de damier peint, pas de JPEG)
> - les 3 personnages à la **même échelle**, pieds alignés sur la même ligne
> - bien espacés horizontalement, sans se chevaucher
> - pas de texte, pas d'interface, pas de décor derrière eux
>
> Planche destinée à être découpée en sprites individuels.

**Fichier à déposer :** `sources/sprites/npcs-village-2-planche.png`

---

# Après la génération

Dépose les fichiers dans `sources/sprites/` avec **exactement** les noms
indiqués, puis :

```bash
python tools/decoupe_sprites.py
cd app && flutter test
```

Le script détecte automatiquement les planches et remplace les versions
dérivées. Il annonce ce qu'il utilise :

```
[planche dessinee] noura-idle-planche.png (4 frames)   ← ta planche
[derive] pas de noura-idle-planche.png -- repli sur ... ← version actuelle
```

**Nombre de frames différent de ce qui est demandé ?** Ça arrive souvent avec
les générateurs. Encode-le dans le nom : `noura-idle-planche-6f.png` → 6
frames. Le manifeste `sprites.json` se met à jour tout seul, aucune dimension
n'est codée en dur dans le jeu.

---

# Ce dont je n'ai PAS besoin

Pour éviter de générer inutilement :

| | Pourquoi |
|---|---|
| Décors supplémentaires | Les 9 scènes sont couvertes |
| Animations `disappear` | Le fondu programmé fait le travail |
| `walk`, `attack`, `move` | Déjà produits, mais le jeu n'a pas encore de déplacement — c'est du code, pas du dessin |
| Les 12 backgrounds restants | Gardés dans `sources/backgrounds/` pour le chapitre 2 |

---

# Références des sprites existants

Pour que le générateur reste cohérent, voici ce qui est déjà en jeu :

| Sprite | Frames | Taille par frame |
|---|---|---|
| `protagonist/idle` | 4 | 37 × 97 |
| `protagonist/walk` | 4 | 46 × 96 |
| `noura/idle` | 4 | 43 × 97 |
| `noura/walk` | 6 | 47 × 96 |

Les planches sources sont dans `sources/sprites/` — tu peux les joindre au
générateur comme référence visuelle pour garantir que le personnage reste
identique.
