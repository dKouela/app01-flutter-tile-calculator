class Designation {
  final int id;
  final String nom;
  final double surfaceParCarton;
  final DateTime createdAt;

  Designation({
    required this.id,
    required this.nom,
    required this.surfaceParCarton,
    required this.createdAt,
  });

  factory Designation.fromJson(Map<String, dynamic> json) {
    return Designation(
      id: json['id'] as int,
      nom: json['nom'] as String,
      surfaceParCarton: (json['surface_par_carton'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'surface_par_carton': surfaceParCarton,
      'created_at': createdAt.toIso8601String(),
    };
  }
}