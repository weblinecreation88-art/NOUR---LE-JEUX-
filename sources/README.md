# sources/ — images brutes

**Ce dossier n'est pas versionné sur GitHub** (~61 Mo de JPEG/PNG originaux).

Il contient les planches telles que fournies par le générateur d'images,
avant traitement. Le jeu ne les lit jamais : il utilise `app/assets/`.

## Organisation

| Dossier | Contenu |
|---|---|
| `sprites/` | planches de personnages (protagoniste, Noura, PNJ, Waswas) |
| `backgrounds/` | décors bruts en 2752×1536 |
| `illustrations/` | scènes illustrées d'origine |
| `ui-references/` | maquettes d'interface, charte |
| `rejetes/` | planches écartées (incohérence de personnage, texte incrusté) |

## Régénérer les sprites

```bash
python tools/decoupe_sprites.py
```

Le script lit `sources/sprites/`, détoure, découpe et écrit dans
`app/assets/pixel/` + `sprites.json`.

**Sans ce dossier, le jeu fonctionne normalement** — les assets traités sont
versionnés. Le script n'est nécessaire que pour retraiter une source.

Détail complet : [../SPRITES.md](../SPRITES.md)
