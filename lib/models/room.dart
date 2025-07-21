class Room {
  final int? id;
  final int? quoteId;
  final String nom;
  final double superficie;
  final int designationId;
  final double? surfaceParCarton;
  final int? cartons;
  final DateTime? createdAt;

  Room({
    this.id,
    this.quoteId,
    required this.nom,
    required this.superficie,
    required this.designationId,
    this.surfaceParCarton,
    this.cartons,
    this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int?,
      quoteId: json['quote_id'] as int?,
      nom: json['nom'] as String,
      superficie: (json['superficie'] as num).toDouble(),
      designationId: json['designation_id'] as int,
      surfaceParCarton: json['surface_par_carton'] != null 
          ? (json['surface_par_carton'] as num).toDouble() 
          : null,
      cartons: json['cartons'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (quoteId != null) 'quote_id': quoteId,
      'nom': nom,
      'superficie': superficie,
      'designation_id': designationId,
      if (surfaceParCarton != null) 'surface_par_carton': surfaceParCarton,
      if (cartons != null) 'cartons': cartons,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toEdgeFunctionJson() {
    return {
      'nom': nom,
      'superficie': superficie,
      'designationId': designationId,
    };
  }
}