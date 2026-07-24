/// Un membre de la famille lié au dossier du patient (README section 3.1 :
/// "plusieurs membres peuvent être liés au dossier d'un même patient pour
/// consulter en temps réel son évolution").
class MembreFamille {
  final String id;
  final String nom;
  final String prenom;
  final String lien; // ex: "Fils", "Fille", "Épouse"
  final String email;
  final bool estCompteActuel;

  const MembreFamille({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.lien,
    required this.email,
    this.estCompteActuel = false,
  });

  String get nomComplet => '$prenom $nom';
}
