class UserModel {
  final String uid;
  final String nom;
  final String prenom;
  final String entreprise;
  final String telephone;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.entreprise,
    required this.telephone,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      entreprise: json['entreprise'] as String,
      telephone: json['telephone'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nom': nom,
      'prenom': prenom,
      'entreprise': entreprise,
      'telephone': telephone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsert() {
    return {
      'nom': nom,
      'prenom': prenom,
      'entreprise': entreprise,
      'telephone': telephone,
    };
  }
}