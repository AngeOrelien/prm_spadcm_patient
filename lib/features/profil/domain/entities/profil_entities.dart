/// Onglet 5 — Profil (section 7.1 README) : infos du compte, membres de
/// famille liés au dossier (UC12 "Compte famille"), sécurité (biométrie).

class MembreFamille {
  final String id;
  final String nom;
  final String prenom;
  final String lien;
  final String email;
  final String? telephone;
  final bool estCompteConnecte;

  const MembreFamille({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.lien,
    required this.email,
    this.telephone,
    required this.estCompteConnecte,
  });

  String get nomComplet => '$prenom $nom';
}
