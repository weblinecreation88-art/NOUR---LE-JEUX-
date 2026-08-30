# -*- coding: utf-8 -*-
"""
Genere VALIDATION_RELIGIEUSE.md a partir des fichiers de contenu.

Le document est extrait des JSON, jamais retape a la main : ce qui est
soumis a la relecture est EXACTEMENT ce que le jeu affiche.

Usage : python tools/dossier_validation.py
"""
import io
import json
import os

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def lire(nom):
    with io.open(os.path.join(RACINE, 'data', nom + '.json'),
                 encoding='utf-8') as f:
        return json.load(f)


def main():
    quiz = lire('quiz')
    know = lire('knowledge')
    scenes = lire('scenes')

    # Ou chaque quiz apparait dans le chapitre
    emplacement = {}
    for sc in scenes['scenes']:
        for b in sc['beats']:
            if b.get('type') == 'quiz':
                emplacement[b['question']] = '%d. %s' % (sc['ordre'],
                                                         sc['titre'])

    L = []
    A = L.append

    A('# NOUR — Dossier de validation du contenu religieux')
    A('')
    A('> **À l’attention de la personne chargée de la '
      'relecture.**')
    A('')
    A('Ce document rassemble **tout** le contenu religieux du Chapitre 1 du '
      'jeu NOUR. Rien d’autre n’est présenté au joueur.')
    A('')
    A('Il est extrait automatiquement des fichiers du jeu : le texte '
      'ci-dessous est **exactement** celui qui s’affiche à '
      'l’écran.')
    A('')
    A('---')
    A('')
    A('## Ce qui est demandé')
    A('')
    A('Pour chaque entrée, merci d’indiquer :')
    A('')
    A('1. **La formulation est-elle correcte ?** (sinon : proposer la '
      'correction)')
    A('2. **La référence est-elle exacte ?** (sourate/verset, '
      'recueil/numéro)')
    A('3. **Le contenu peut-il être présenté ainsi à un '
      'jeune public ?**')
    A('4. **Statut** : VALIDÉ · À CORRIGER · À '
      'RETIRER')
    A('')
    A('Une case **Remarques** est prévue sous chaque entrée.')
    A('')
    A('---')
    A('')
    A('## Règles déjà appliquées dans le jeu')
    A('')
    A('Elles sont **vérifiées automatiquement** par les tests du '
      'projet :')
    A('')
    A('- Aucun hadith ni verset inventé.')
    A('- Aucune parole attribuée au Prophète ﷺ sans '
      'référence.')
    A('- Aucune invocation présentée comme une attaque, un sort ou '
      'un pouvoir.')
    A('- Aucune représentation de prophète.')
    A('- L’XP est une mécanique de jeu : elle ne mesure jamais la '
      'foi.')
    A('- Une mauvaise réponse ne retire rien et ne culpabilise pas.')
    A('- Aucune preuve d’acte religieux n’est demandée (ni '
      'photo, ni audio, ni localisation).')
    A('')
    A('**Tout contenu non validé est affiché au joueur avec la '
      'mention « Référence à valider ».** Rien '
      'n’est présenté comme définitif.')
    A('')
    A('---')
    A('')

    # ---------------------------------------------------------------- quiz
    A('# Partie 1 — Les questions de quiz')
    A('')
    A('%d questions. La bonne réponse est marquée **✔**.'
      % len(quiz['questions']))
    A('')

    for i, q in enumerate(quiz['questions'], 1):
        statut = ('À VALIDER' if q['statut'] == 'A_VALIDER' else 'VALIDE')
        A('---')
        A('')
        A('## Q%d — `%s`' % (i, q['id']))
        A('')
        A('| | |')
        A('|---|---|')
        A('| **Notion** | %s |' % q['notion'])
        A('| **Scène** | %s |' % emplacement.get(q['id'], '—'))
        A('| **Source indiquée** | %s |' % q['source'])
        A('| **Référence indiquée** | %s |' % q['reference'])
        A('| **Statut actuel** | **%s** |' % statut)
        A('')
        A('**Question posée au joueur :**')
        A('')
        A('> %s' % q['question'])
        A('')
        A('**Réponses proposées :**')
        A('')
        for j, c in enumerate(q['choix']):
            marque = ' **✔**' if j == q['reponse'] else ''
            A('- %s. %s%s' % (chr(65 + j), c, marque))
        A('')
        A('**Explication affichée après la réponse :**')
        A('')
        A('> %s' % q['explication'])
        A('')
        A('**Remarques du relecteur :**')
        A('')
        A('```')
        A('')
        A('')
        A('```')
        A('')
        A('Statut :  [ ] VALIDÉ   [ ] À CORRIGER   [ ] À '
          'RETIRER')
        A('')

    # ------------------------------------------------------------ notions
    A('---')
    A('')
    A('# Partie 2 — Les fiches de notions')
    A('')
    A('%d fiches, consultables par le joueur dans la bibliothèque du '
      'jeu.' % len(know['notions']))
    A('')

    for i, n in enumerate(know['notions'], 1):
        statut = ('À VALIDER' if n['statut'] == 'A_VALIDER' else 'VALIDE')
        A('---')
        A('')
        A('## N%d — %s (%s)' % (i, n['translitteration'], n['terme_ar']))
        A('')
        A('| | |')
        A('|---|---|')
        A('| **Identifiant** | `%s` |' % n['id'])
        A('| **Titre français** | %s |' % n['titre_fr'])
        A('| **Niveau** | %s |' % n['niveau'])
        A('| **Source indiquée** | %s |' % n['source'])
        A('| **Référence indiquée** | %s |' % n['reference'])
        A('| **Statut actuel** | **%s** |' % statut)
        A('')
        A('**Définition affichée :**')
        A('')
        A('> %s' % n['definition'])
        A('')
        A('**Explication affichée :**')
        A('')
        A('> %s' % n['explication'])
        A('')
        A('**Remarques du relecteur :**')
        A('')
        A('```')
        A('')
        A('')
        A('```')
        A('')
        A('Statut :  [ ] VALIDÉ   [ ] À CORRIGER   [ ] À '
          'RETIRER')
        A('')

    # ------------------------------------------------------------- points
    A('---')
    A('')
    A('# Partie 3 — Points signalés par l’équipe')
    A('')
    A('Ces entrées sont celles où nous avons le moins de '
      'certitude. Elles méritent une attention particulière.')
    A('')
    A('| Entrée | Pourquoi |')
    A('|---|---|')
    A('| `q4_sabr` / `sabr` | Aucune source précise. Le cahier des '
      'charges indique « à vérifier précisément '
      '». |')
    A('| `q_niyyah` / `niyyah` | « Référence à '
      'documenter » — le hadith habituellement cité n’a '
      'pas été rattaché formellement. |')
    A('| `q9_shukr` / `shukr` | « Référence à documenter '
      '». |')
    A('| `q7_salam` / `salam` | Muwatta Malik cité, mais numéro non '
      'vérifié. |')
    A('| `q6_adab` / `adab` | Bukhari 6136 cité, à confirmer. |')
    A('| `q1_taaruf`, `q3_istiadhah` | Références coraniques '
      '(49:13 ; 16:98) qui semblent solides, mais à confirmer '
      'formellement. |')
    A('')
    A('---')
    A('')
    A('# Partie 4 — Contenu volontairement NON religieux')
    A('')
    A('Une seule entrée est marquée `VALIDE` dans le jeu : '
      '**`q10_ilm`**.')
    A('')
    A('Ce n’est **pas** un texte religieux. C’est la phrase de '
      'philosophie du jeu, écrite par l’équipe :')
    A('')
    A('> « Le ʿilm, les efforts et le fait de passer à '
      'l’action. »')
    A('')
    A('Elle est présentée comme telle au joueur, jamais comme une '
      'citation. Merci de confirmer que cette distinction est claire.')
    A('')
    A('---')
    A('')
    A('# Après la relecture')
    A('')
    A('Renvoyer ce document annoté. Les corrections seront '
      'reportées dans `data/quiz.json` et `data/knowledge.json`, et le '
      'statut passera à `VALIDE` **uniquement** pour les entrées '
      'explicitement validées.')
    A('')
    A('Tant qu’une entrée reste `A_VALIDER`, le jeu continue '
      'd’afficher « Référence à valider » au '
      'joueur.')
    A('')

    dest = os.path.join(RACINE, 'VALIDATION_RELIGIEUSE.md')
    with io.open(dest, 'w', encoding='utf-8') as f:
        f.write('\n'.join(L))
    print('VALIDATION_RELIGIEUSE.md : %d lignes' % len(L))
    print('  %d questions de quiz' % len(quiz['questions']))
    print('  %d fiches de notions' % len(know['notions']))


if __name__ == '__main__':
    main()
