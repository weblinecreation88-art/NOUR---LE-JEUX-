import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nour/core/player_progress.dart';

/// Une sauvegarde corrompue ne doit JAMAIS empecher de jouer.
/// (Bug reel rencontre : un champ de mauvais type plantait l application
/// entiere sur un ecran "Contenu illisible".)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('une sauvegarde illisible ne plante pas', () async {
    SharedPreferences.setMockInitialValues({
      'nour_player_progress_v1': 'ceci n est pas du json',
    });
    final p = await PlayerProgress.load();
    expect(p.xp, 0);
    expect(p.aUneSauvegarde, isFalse);
  });

  test('des champs de mauvais type sont ignores sans planter', () async {
    SharedPreferences.setMockInitialValues({
      'nour_player_progress_v1':
          '{"xp":"300","lumiere":null,"scene_id":42,'
          '"compagnons":[1,"Karim",null],"notions_vues":"pas une liste"}',
    });
    final p = await PlayerProgress.load();
    expect(p.xp, 300, reason: 'un entier en chaine est recupere');
    expect(p.lumiere, 0);
    expect(p.sceneId, isNull, reason: 'scene_id non-String est ignore');
    expect(p.compagnons, {'Karim'}, reason: 'seules les chaines sont gardees');
    expect(p.notionsVues, isEmpty);
  });

  test('une sauvegarde valide est relue correctement', () async {
    SharedPreferences.setMockInitialValues({
      'nour_player_progress_v1':
          '{"xp":400,"lumiere":45,"scene_id":"s5_village","beat_index":3,'
          '"actions_faites":["a1_ranger"],"notions_vues":["sabr"],'
          '"compagnons":["Karim"]}',
    });
    final p = await PlayerProgress.load();
    expect(p.xp, 400);
    expect(p.lumiere, 45);
    expect(p.sceneId, 's5_village');
    expect(p.beatIndex, 3);
    expect(p.actionFaite('a1_ranger'), isTrue);
    expect(p.compagnons, {'Karim'});
  });

  test('la Lumiere ne recule jamais', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await PlayerProgress.load();
    p.reglerLumiere(40);
    p.reglerLumiere(20);
    expect(p.lumiere, 40);
  });
}
