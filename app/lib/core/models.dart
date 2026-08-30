library;

/// Modèles de contenu NOUR.
///
/// Ils reflètent exactement la forme des JSON d'`assets/data/` et celle des
/// futures collections Firestore (CDC §15). Passer du JSON local à Firestore
/// ne changera que la couche `data/`, jamais ces modèles ni le moteur.

/// Statut de validation d'un contenu religieux (CDC §3, §8).
/// Rien n'est présenté comme définitivement validé tant que ce n'est pas
/// `valide` — et seul un humain compétent peut le faire passer à `valide`.
enum StatutValidation {
  aValider,
  valide;

  static StatutValidation parse(String? raw) =>
      raw == 'VALIDE' ? StatutValidation.valide : StatutValidation.aValider;

  bool get estValide => this == StatutValidation.valide;
}

class Notion {
  const Notion({
    required this.id,
    required this.termeAr,
    required this.translitteration,
    required this.titreFr,
    required this.definition,
    required this.explication,
    required this.source,
    required this.reference,
    required this.niveau,
    required this.statut,
    this.citation,
  });

  final String id;
  final String termeAr;
  final String translitteration;
  final String titreFr;
  final String definition;
  final String explication;
  final String source;
  final String reference;
  final String niveau;
  final StatutValidation statut;

  /// Texte traduit, quand la fiche en porte un.
  final String? citation;

  factory Notion.fromJson(Map<String, dynamic> j) => Notion(
        id: j['id'] as String,
        termeAr: j['terme_ar'] as String? ?? '',
        translitteration: j['translitteration'] as String? ?? '',
        titreFr: j['titre_fr'] as String? ?? '',
        definition: j['definition'] as String? ?? '',
        explication: j['explication'] as String? ?? '',
        source: j['source'] as String? ?? '',
        reference: j['reference'] as String? ?? '',
        niveau: j['niveau'] as String? ?? 'debutant',
        statut: StatutValidation.parse(j['statut'] as String?),
        citation: j['citation'] as String?,
      );
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.notion,
    required this.question,
    required this.choix,
    required this.reponse,
    required this.explication,
    required this.source,
    required this.reference,
    required this.statut,
    this.citation,
    this.citationAr,
  });

  final String id;
  final String notion;
  final String question;
  final List<String> choix;
  final int reponse;
  final String explication;
  final String source;
  final String reference;
  final StatutValidation statut;

  /// Texte traduit du verset ou du hadith. Afficher un TEXTE engage plus
  /// qu'afficher une reference : ces entrees sont prioritaires a la
  /// relecture (CDC §3, §8).
  final String? citation;

  /// Le texte arabe, quand il est disponible.
  final String? citationAr;

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id'] as String,
        notion: j['notion'] as String? ?? '',
        question: j['question'] as String,
        choix: (j['choix'] as List).cast<String>(),
        reponse: j['reponse'] as int,
        explication: j['explication'] as String? ?? '',
        source: j['source'] as String? ?? '',
        reference: j['reference'] as String? ?? '',
        statut: StatutValidation.parse(j['statut'] as String?),
        citation: j['citation'] as String?,
        citationAr: j['citation_ar'] as String?,
      );
}

/// Action à accomplir dans la vraie vie.
/// Validation déclarative uniquement — aucune preuve n'est jamais demandée
/// (CDC §11, §16). Le joueur peut toujours reporter sans reproche.
class RealAction {
  const RealAction({
    required this.id,
    required this.titre,
    required this.duree,
    required this.variantes,
    required this.xp,
  });

  final String id;
  final String titre;
  final String duree;
  final List<String> variantes;
  final int xp;

  factory RealAction.fromJson(Map<String, dynamic> j) => RealAction(
        id: j['id'] as String,
        titre: j['titre'] as String,
        duree: j['duree'] as String? ?? '',
        variantes: (j['variantes'] as List).cast<String>(),
        xp: j['xp'] as int? ?? 0,
      );
}

/// Un beat = une unité narrative typée. Le moteur ne sait rien du contenu :
/// il lit `type` et rend l'écran correspondant.
class Beat {
  const Beat(this.data);
  final Map<String, dynamic> data;

  String get type => data['type'] as String;
  String get texte => data['texte'] as String? ?? '';
  String? get titre => data['titre'] as String?;
  String? get qui => data['qui'] as String?;
  String? get nom => data['nom'] as String?;
  String? get etat => data['etat'] as String?;
  String? get intro => data['intro'] as String?;
  String? get sousTexte => data['sous_texte'] as String?;
  String? get description => data['description'] as String?;
  String? get questionId => data['question'] as String?;
  String? get actionId => data['action'] as String?;
  String? get vers => data['vers'] as String?;
  int get montant => data['montant'] as int? ?? 0;
  String get questionChoix => data['question'] as String? ?? '';

  List<ChoixOption> get options => ((data['options'] as List?) ?? [])
      .map((o) => ChoixOption.fromJson(o as Map<String, dynamic>))
      .toList();
}

class ChoixOption {
  const ChoixOption({
    required this.id,
    required this.texte,
    required this.verrouille,
    this.note,
    this.reponse,
  });

  final String id;
  final String texte;
  final bool verrouille;
  final String? note;
  final String? reponse;

  factory ChoixOption.fromJson(Map<String, dynamic> j) => ChoixOption(
        id: j['id'] as String,
        texte: j['texte'] as String,
        verrouille: j['verrouille'] as bool? ?? false,
        note: j['note'] as String?,
        reponse: j['reponse'] as String?,
      );
}

class Scene {
  const Scene({
    required this.id,
    required this.ordre,
    required this.titre,
    required this.decor,
    required this.lumiere,
    required this.beats,
  });

  final String id;
  final int ordre;
  final String titre;
  final String decor;

  /// Progression narrative de la Lumière, en pourcentage.
  /// Métaphore de récit — ne mesure ni la foi ni la valeur du joueur (CDC §3).
  final int lumiere;
  final List<Beat> beats;

  factory Scene.fromJson(Map<String, dynamic> j) => Scene(
        id: j['id'] as String,
        ordre: j['ordre'] as int,
        titre: j['titre'] as String,
        decor: j['decor'] as String? ?? 'vallee',
        lumiere: j['lumiere'] as int? ?? 0,
        beats: (j['beats'] as List)
            .map((b) => Beat(b as Map<String, dynamic>))
            .toList(),
      );
}
