# -*- coding: utf-8 -*-
"""
Prepare les sprites NOUR a partir des sources JPEG.

Probleme resolu : les sources sont des JPEG ou le damier de transparence est
PEINT dans l'image (ce n'est pas un vrai canal alpha). Il faut donc :
  1. detecter le damier gris et le rendre transparent ;
  2. rogner au plus juste autour du personnage ;
  3. decouper les spritesheets en frames de largeur egale ;
  4. exporter en PNG avec vraie transparence.

Usage : python tools/decoupe_sprites.py
"""
import io
import os
from PIL import Image

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SORTIE = os.path.join(RACINE, 'app', 'assets', 'pixel')

# --- Detection du damier -------------------------------------------------
#
# Le damier est PEINT dans le JPEG. Deux ecueils :
#   - le protagoniste porte du gris-bleu, proche du gris du damier ;
#   - le JPEG laisse des artefacts qui survivent a un simple filtre couleur.
#
# Solution : remplissage par diffusion depuis les BORDS. Seuls les pixels
# gris CONNECTES au bord deviennent transparents. Un gris a l interieur du
# personnage est donc preserve, et les residus isoles disparaissent.

from collections import deque

def est_gris_damier(p):
    r, g, b = p[:3]
    if abs(r - g) > 24 or abs(g - b) > 24 or abs(r - b) > 24:
        return False
    return 100 <= r <= 255

def rendre_transparent(im):
    im = im.convert('RGBA')
    px = im.load()
    w, h = im.size

    fond = bytearray(w * h)
    file_ = deque()

    def pousser(x, y):
        if 0 <= x < w and 0 <= y < h and not fond[y * w + x]                 and est_gris_damier(px[x, y]):
            fond[y * w + x] = 1
            file_.append((x, y))

    for x in range(w):
        pousser(x, 0); pousser(x, h - 1)
    for y in range(h):
        pousser(0, y); pousser(w - 1, y)

    while file_:
        x, y = file_.popleft()
        pousser(x + 1, y); pousser(x - 1, y)
        pousser(x, y + 1); pousser(x, y - 1)

    for y in range(h):
        rang = y * w
        for x in range(w):
            if fond[rang + x]:
                px[x, y] = (0, 0, 0, 0)

    return nettoyer(im)

def nettoyer(im, seuil=90):
    """Supprime les ilots opaques minuscules (artefacts JPEG) qui
    fausseraient le rognage."""
    px = im.load()
    w, h = im.size
    vu = bytearray(w * h)
    for sy in range(h):
        for sx in range(w):
            if vu[sy * w + sx] or px[sx, sy][3] == 0:
                continue
            pile = [(sx, sy)]
            vu[sy * w + sx] = 1
            ilot = []
            while pile:
                x, y = pile.pop()
                ilot.append((x, y))
                for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h                             and not vu[ny * w + nx] and px[nx, ny][3] > 0:
                        vu[ny * w + nx] = 1
                        pile.append((nx, ny))
            if len(ilot) < seuil:
                for x, y in ilot:
                    px[x, y] = (0, 0, 0, 0)
    return im

def rogner(im, marge=2):
    bbox = im.getbbox()
    if not bbox:
        return im
    l, t, r, b = bbox
    w, h = im.size
    return im.crop((max(0, l - marge), max(0, t - marge),
                    min(w, r + marge), min(h, b + marge)))

SOURCES = os.path.join(RACINE, 'sources', 'sprites')

# Nombre de frames REELLEMENT produit pour chaque sortie. Renseigne pendant
# la fabrication, puis utilise par le manifeste : si une planche deposee a
# plus de frames que prevu, sprites.json le reflete automatiquement.
FRAMES_REELS = {}


def charger(nom):
    return rendre_transparent(Image.open(os.path.join(SOURCES, nom)))

def ecrire(im, *chemin):
    dest = os.path.join(SORTIE, *chemin)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    im.save(dest, 'PNG', optimize=True)
    print('  %-46s %sx%s  %d KB' % (
        os.path.join(*chemin), im.size[0], im.size[1],
        os.path.getsize(dest) // 1024))

def sprite_unique(source, *chemin, hauteur=None, seuil=None):
    """Une seule pose -> un PNG rogne."""
    im = charger(source)
    if seuil:
        im = nettoyer(im, seuil=seuil)
    im = rogner(im)
    if hauteur:
        im = redimensionner(im, hauteur)
    ecrire(im, *chemin)
    return im

def redimensionner(im, hauteur):
    """NEAREST : preserve le grain pixel art (CDC 12)."""
    if im.size[1] <= hauteur:
        return im
    w = round(im.size[0] * hauteur / im.size[1])
    return im.resize((w, hauteur), Image.NEAREST)

def detecter_colonnes(im, nb_attendu, largeur_min=20):
    """
    Localise chaque personnage par son profil d'opacite.

    Les generateurs ne repartissent pas les poses en colonnes egales : un
    decoupage arithmetique coupe alors les personnages en deux (bug reel
    rencontre sur la planche idle de Noura). On detecte donc les blocs de
    pixels opaques separes par du vide.

    Renvoie une liste de (x_debut, x_fin), ou None si la detection ne donne
    pas le compte attendu (on retombe alors sur les colonnes egales).
    """
    alpha = im.getchannel('A')
    w, h = im.size
    pleines = []
    for x in range(w):
        _, mx = alpha.crop((x, 0, x + 1, h)).getextrema()
        pleines.append(mx > 200)

    blocs, debut = [], None
    for x, plein in enumerate(pleines):
        if plein and debut is None:
            debut = x
        elif not plein and debut is not None:
            if x - debut >= largeur_min:
                blocs.append((debut, x))
            debut = None
    if debut is not None and w - debut >= largeur_min:
        blocs.append((debut, w))

    return blocs if len(blocs) == nb_attendu else None


def spritesheet(source, nb_frames, *chemin, hauteur=None):
    """
    Decoupe la planche, rogne chaque frame, puis reassemble sur une grille
    reguliere (toutes les frames a la meme taille, personnage centre
    horizontalement et pose au sol) -> spritesheet exploitable par Flame.

    La decoupe suit les personnages detectes ; a defaut, des colonnes egales.
    """
    im = charger(source)
    w, h = im.size

    colonnes = detecter_colonnes(im, nb_frames)
    if colonnes is not None:
        frames = []
        for x0, x1 in colonnes:
            f = im.crop((x0, 0, x1, h))
            bb = f.getbbox()
            if bb:
                f = f.crop(bb)
            frames.append(f)
        return _assembler(frames, nb_frames, chemin, hauteur)

    pas = w // nb_frames
    frames = []
    for i in range(nb_frames):
        f = im.crop((i * pas, 0, (i + 1) * pas, h))
        bbox = f.getbbox()
        if bbox:
            f = f.crop(bbox)
        frames.append(f)

    return _assembler(frames, nb_frames, chemin, hauteur)


def _assembler(frames, nb_frames, chemin, hauteur):
    """
    Pose les frames sur une grille reguliere : meme taille, personnage
    centre horizontalement, pieds alignes en bas. C'est ce qui garantit
    qu'une animation ne « saute » pas d'une frame a l'autre.
    """
    fw = max(f.size[0] for f in frames)
    fh = max(f.size[1] for f in frames)
    feuille = Image.new('RGBA', (fw * nb_frames, fh), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        x = i * fw + (fw - f.size[0]) // 2      # centre horizontalement
        y = fh - f.size[1]                       # pieds alignes en bas
        feuille.paste(f, (x, y))

    if hauteur:
        ech = hauteur / fh
        feuille = feuille.resize(
            (max(1, round(feuille.size[0] * ech)), hauteur), Image.NEAREST)
        fw, fh = round(fw * ech), hauteur

    ecrire(feuille, *chemin)
    FRAMES_REELS['/'.join(chemin)] = nb_frames
    print('       -> %d frames de %dx%d' % (nb_frames, fw, fh))
    return fw, fh, nb_frames

def idle_respiration(source, *chemin, hauteur=None, frames=4):
    """
    Fabrique un IDLE 4 frames a partir d'une pose unique.

    Respiration discrete : le corps monte de 1 px puis redescend
    (0, -1, 0, -1 en cycle doux). Toutes les frames ont la meme taille,
    la meme echelle et le meme point d'ancrage (pieds en bas), comme
    l'exige un moteur 2D.

    C'est un PLACEHOLDER honnete : une vraie spritesheet dessinee
    (vetements qui bougent, epaules) reste superieure et la remplacera
    sans changer une ligne de code.
    """
    pose = rogner(charger(source))
    if hauteur:
        pose = redimensionner(pose, hauteur)
    w, h = pose.size
    amplitude = 1
    decalages = [0, -amplitude, 0, amplitude][:frames]

    feuille = Image.new('RGBA', (w * frames, h + amplitude), (0, 0, 0, 0))
    for i, dy in enumerate(decalages):
        feuille.paste(pose, (i * w, amplitude + dy), pose)
    ecrire(feuille, *chemin)
    FRAMES_REELS['/'.join(chemin)] = frames
    print('       -> %d frames de %dx%d (respiration +/-%dpx)'
          % (frames, w, h + amplitude, amplitude))



def planche_ou_source(planche, source, nb_frames_defaut, *chemin,
                      hauteur=None):
    """
    Prefere une planche de remplacement si elle existe, sinon utilise la
    source d'origine.

    Le nombre de frames peut etre encode dans le nom du fichier
    (ex. `noura-walk-planche-6f.png`) ; sinon on garde la valeur par defaut.
    """
    import re
    nom, nb = source, nb_frames_defaut
    for candidat in os.listdir(SOURCES):
        base = planche.replace('.png', '')
        if candidat.startswith(base):
            nom = candidat
            m = re.search(r'-(\d+)f\.', candidat)
            if m:
                nb = int(m.group(1))
            print('  [planche dessinee] %s (%d frames)' % (nom, nb))
            break
    return spritesheet(nom, nb, *chemin, hauteur=hauteur)


def idle_ou_derive(planche, pose_unique, nb_frames, *chemin, hauteur=None):
    """
    Utilise une VRAIE planche d'animation si elle existe dans sources/sprites/,
    sinon retombe sur l'idle derive d'une pose unique.

    Deposer la planche dessinee (PNG a fond transparent de preference) et
    relancer le script suffit : aucune modification de code, aucune dimension
    a mettre a jour ailleurs -- sprites.json est regenere.
    """
    import re
    base = planche.replace('.png', '')
    for candidat in sorted(os.listdir(SOURCES)):
        if candidat.startswith(base):
            nb = nb_frames
            m = re.search(r'-(\d+)f\.', candidat)
            if m:
                nb = int(m.group(1))
            print('  [planche dessinee] %s (%d frames)' % (candidat, nb))
            return spritesheet(candidat, nb, *chemin, hauteur=hauteur)
    print('  [derive] pas de %s -- repli sur %s' % (planche, pose_unique))
    return idle_respiration(pose_unique, *chemin,
                            hauteur=hauteur, frames=nb_frames)


def decouper_pnj(source, noms, hauteur):
    """
    Une planche de N personnages -> un PNG par personnage.

    Le nombre de decoupes suit la longueur de `noms`, ce qui permet de
    traiter aussi bien une planche de 4 que de 3 villageois.
    """
    im = charger(source)
    w, h = im.size
    
    colonnes = detecter_colonnes(im, len(noms))
    if colonnes is not None:
        for i, nom in enumerate(noms):
            x0, x1 = colonnes[i]
            f = im.crop((x0, 0, x1, h))
            bbox = f.getbbox()
            if bbox:
                f = f.crop(bbox)
            ecrire(redimensionner(f, hauteur), 'characters', 'npcs', nom + '.png')
        return

    pas = w // len(noms)
    for i, nom in enumerate(noms):
        f = im.crop((i * pas, 0, (i + 1) * pas, h))
        bbox = f.getbbox()
        if bbox:
            f = f.crop(bbox)
        ecrire(redimensionner(f, hauteur), 'characters', 'npcs', nom + '.png')


def depuis_frame(source_png, index, largeur_frame):
    """Extrait une frame d une spritesheet deja produite."""
    im = Image.open(os.path.join(SORTIE, source_png)).convert('RGBA')
    return im.crop((index * largeur_frame, 0,
                    (index + 1) * largeur_frame, im.size[1]))


def disparition(source_png, *chemin, frames=4):
    """
    Animation de DISPARITION du Waswas : la masse s efface progressivement
    (alpha decroissant + leger retrecissement).

    Elle ne se fait pas 'tuer' : elle recule et se defait. C est une pensee,
    pas un monstre vaincu (CDC 5, 12).
    """
    im = Image.open(os.path.join(SORTIE, source_png)).convert('RGBA')
    w, h = im.size
    feuille = Image.new('RGBA', (w * frames, h), (0, 0, 0, 0))
    for i in range(frames):
        k = 1.0 - i / frames                       # 1.0 -> 0.25
        ech = 0.82 + 0.18 * k                      # retrecit un peu
        fw, fh = max(1, round(w * ech)), max(1, round(h * ech))
        f = im.resize((fw, fh), Image.NEAREST)
        a = f.getchannel('A').point(lambda v, k=k: int(v * k))
        f.putalpha(a)
        feuille.paste(f, (i * w + (w - fw) // 2, (h - fh) // 2), f)
    ecrire(feuille, *chemin)
    FRAMES_REELS['/'.join(chemin)] = frames
    print('       -> %d frames de %dx%d (fondu + retrait)' % (frames, w, h))


def flottement(source_png, *chemin, frames=4, amplitude=3):
    """IDLE d une masse abstraite : elle respire / ondule sur place."""
    im = Image.open(os.path.join(SORTIE, source_png)).convert('RGBA')
    w, h = im.size
    decalages = [0, -amplitude, 0, amplitude][:frames]
    feuille = Image.new('RGBA', (w * frames, h + 2 * amplitude), (0, 0, 0, 0))
    for i, dy in enumerate(decalages):
        feuille.paste(im, (i * w, amplitude + dy), im)
    ecrire(feuille, *chemin)
    FRAMES_REELS['/'.join(chemin)] = frames
    print('       -> %d frames de %dx%d' % (frames, w, h + 2 * amplitude))


def pose_derivee(source_png, *chemin, index=0, nb_frames=1, dx=0, dy=0):
    """Reutilise une frame existante comme pose distincte."""
    im = Image.open(os.path.join(SORTIE, source_png)).convert('RGBA')
    largeur = im.size[0] // nb_frames
    im = im.crop((index * largeur, 0, (index + 1) * largeur, im.size[1]))
    if dx or dy:
        d = Image.new('RGBA', im.size, (0, 0, 0, 0))
        d.paste(im, (dx, dy), im)
        im = d
    ecrire(im, *chemin)



# (chemin relatif, nb frames, fps, boucle)
CATALOGUE = [
    ('characters/protagonist/idle.png', 4, 6, True),
    ('characters/protagonist/walk.png', 4, 8, True),
    ('characters/protagonist/interact.png', 1, 1, False),
    ('characters/protagonist/emotion.png', 1, 1, False),
    ('characters/noura/idle.png', 4, 6, True),
    ('characters/noura/walk.png', 6, 10, True),
    ('characters/noura/interact.png', 1, 1, False),
    ('characters/npcs/enfant_pecheur.png', 1, 1, False),
    ('characters/npcs/fille_panier.png', 1, 1, False),
    ('characters/npcs/marchand.png', 1, 1, False),
    ('characters/npcs/karim_ancien.png', 1, 1, False),
    ('enemies/waswas/idle.png', 4, 5, True),
    ('enemies/waswas/move.png', 4, 7, True),
    ('enemies/waswas/disappear.png', 4, 6, False),
    ('enemies/grand_waswas/idle.png', 4, 4, True),
    ('enemies/grand_waswas/attack.png', 4, 7, True),
    ('enemies/grand_waswas/disappear.png', 4, 5, False),
]


def ecrire_manifeste():
    """
    Ecrit sprites.json : le jeu y lit le nombre de frames et leur taille,
    au lieu de les coder en dur. Remplacer une planche et relancer ce script
    suffit a mettre le jeu a jour.
    """
    import json
    entrees = {}
    for chemin, nb_defaut, fps, boucle in CATALOGUE:
        f = os.path.join(SORTIE, chemin)
        if not os.path.exists(f):
            print('  !! manquant, ignore : ' + chemin)
            continue
        # Le compte reellement produit prime sur la valeur du catalogue :
        # une planche deposee avec plus de frames est prise en compte.
        nb = FRAMES_REELS.get(chemin, nb_defaut)
        w, h = Image.open(f).size
        entrees[chemin] = {
            'chemin': 'assets/pixel/' + chemin,
            'frames': nb,
            'frame_largeur': w // nb,
            'frame_hauteur': h,
            'fps': fps,
            'boucle': boucle,
        }
    doc = {
        '_meta': {
            'description': 'Manifeste des sprites NOUR. Genere par '
                           'tools/decoupe_sprites.py.',
            'regle': 'Frames de largeur egale, personnage centre, '
                     'pieds alignes en bas.',
            'note': 'Ne pas editer a la main : relancer le script apres '
                    'avoir remplace une source.',
        },
        'sprites': entrees,
    }
    dest = os.path.join(SORTIE, 'sprites.json')
    with io.open(dest, 'w', encoding='utf-8') as fh:
        fh.write(json.dumps(doc, indent=2, ensure_ascii=False))
    print('\nsprites.json : %d entrees' % len(entrees))


if __name__ == '__main__':
    H = 96   # hauteur cible des personnages (lisible sur mobile)

    print('\nPROTAGONISTE')
    idle_ou_derive('protagonist-idle-planche.png',
                   'protagonist-idle-source.jpeg', 4,
                   'characters', 'protagonist', 'idle.png', hauteur=H)
    planche_ou_source('protagonist-walk-planche.png',
                      'protagonist-walk-source.jpeg', 4,
                      'characters', 'protagonist', 'walk.png', hauteur=H)
    # interact / emotion : poses derivees de la marche, en attendant des
    # planches dediees (voir SPRITES.md).
    pose_derivee('characters/protagonist/walk.png',
                 'characters', 'protagonist', 'interact.png',
                 index=1, nb_frames=4)
    pose_derivee('characters/protagonist/walk.png',
                 'characters', 'protagonist', 'emotion.png',
                 index=0, nb_frames=4)

    print('\nNOURA')
    idle_ou_derive('noura-idle-planche.png', 'noura-idle-source.jpeg', 4,
                   'characters', 'noura', 'idle.png', hauteur=H)
    planche_ou_source('noura-walk-planche.png',
                      'noura-walk-source.jpeg', 6,
                      'characters', 'noura', 'walk.png', hauteur=H)
    # Pose de dialogue. Si une planche de face est fournie, elle prime :
    # Noura parle 17 fois dans le chapitre, la voir de dos est etrange.
    if os.path.exists(os.path.join(SOURCES, 'noura-face-planche.png')):
        print('  [planche dessinee] noura-face-planche.png')
        sprite_unique('noura-face-planche.png',
                      'characters', 'noura', 'interact.png', hauteur=H)
    else:
        # Repli : la pose main ouverte, de dos.
        sprite_unique('noura-idle-source.jpeg',
                      'characters', 'noura', 'interact.png', hauteur=H)

    print('\nPNJ DU VILLAGE')
    decouper_pnj('npcs-village-source.jpeg',
                 ['enfant_pecheur', 'fille_panier', 'marchand',
                  'karim_ancien'], H)
    # Planche optionnelle : les 3 villageois nommes dans le scenario
    # (scenes 5 et 6). Absente, le jeu utilise les PNJ ci-dessus.
    if os.path.exists(os.path.join(SOURCES, 'npcs-village-2-planche.png')):
        print('  [planche dessinee] npcs-village-2-planche.png')
        decouper_pnj('npcs-village-2-planche.png',
                     ['homme_puits', 'femme_auvent', 'jeune_village'], H)

    print('\nWASWAS')
    # Seuil de nettoyage eleve : la masse du waswas laissait des ilots de
    # damier visibles a l'ecran (petits carres clairs).
    sprite_unique('waswas-source.jpeg',
                  'enemies', 'waswas', 'base.png', hauteur=140, seuil=600)
    flottement('enemies/waswas/base.png', 'enemies', 'waswas', 'idle.png')
    flottement('enemies/waswas/base.png', 'enemies', 'waswas', 'move.png',
               amplitude=5)
    disparition('enemies/waswas/base.png', 'enemies', 'waswas', 'disappear.png')

    print('\nGRAND WASWAS')
    sprite_unique('grand-waswas-source.jpeg',
                  'enemies', 'grand_waswas', 'base.png', hauteur=190,
                  seuil=600)
    flottement('enemies/grand_waswas/base.png',
               'enemies', 'grand_waswas', 'idle.png')
    flottement('enemies/grand_waswas/base.png',
               'enemies', 'grand_waswas', 'attack.png', amplitude=6)
    disparition('enemies/grand_waswas/base.png',
                'enemies', 'grand_waswas', 'disappear.png')

    # base.png ne sert que d'intermediaire de fabrication.
    for tmp in ('enemies/waswas/base.png', 'enemies/grand_waswas/base.png'):
        chemin = os.path.join(SORTIE, tmp)
        if os.path.exists(chemin):
            os.remove(chemin)

    ecrire_manifeste()

    print('\nTermine.')
