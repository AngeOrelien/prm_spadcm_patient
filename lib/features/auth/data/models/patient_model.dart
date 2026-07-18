import '../../domain/entities/patient.dart';

/// Reflète exactement l'objet `utilisateur` renvoyé par le backend
/// (routes /verify-login-otp et /me). Garder ce mapping ici évite que le
/// reste de l'app dépende du format JSON du backend.
class PatientModel extends Patient {
  const PatientModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.role,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as String? ?? json['_id'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      email: json['email'] as String,
      role: roleFromString(json['role'] as String),
    );
  }
}
