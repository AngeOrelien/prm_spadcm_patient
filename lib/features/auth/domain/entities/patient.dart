/// Rôle du compte connecté côté app Patients/Familles.
///
/// `patient` : le patient lui-même détient et utilise le compte.
/// `famille` : un proche/aidant suit le patient avec un accès délégué
/// (même app, même parcours — seul le rôle backend diffère pour l'audit).
enum RoleCompteMenager { patient, famille }

RoleCompteMenager roleFromString(String value) {
  switch (value) {
    case 'patient':
      return RoleCompteMenager.patient;
    case 'famille':
      return RoleCompteMenager.famille;
    default:
      throw ArgumentError('Rôle patient/famille inconnu: $value');
  }
}

/// Représente le compte connecté (le patient ou un membre de sa famille).
/// Reste volontairement minimal pour l'instant : le dossier médical complet
/// (`ficheNumero`, antécédents, allergies...) sera exposé par une future
/// feature `dossier-medical` plutôt que d'alourdir cette entité de session.
class Patient {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final RoleCompteMenager role;

  const Patient({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
  });

  String get nomComplet => '$prenom $nom';
}
