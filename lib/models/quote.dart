import 'room.dart';

class Quote {
  final int id;
  final String userId;
  final DateTime createdAt;
  final int totalCartons;
  final List<Room> rooms;

  Quote({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.totalCartons,
    required this.rooms,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      totalCartons: json['total_cartons'] as int,
      rooms: json['rooms'] != null 
          ? (json['rooms'] as List)
              .map((roomJson) => Room.fromJson(roomJson as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'total_cartons': totalCartons,
      'rooms': rooms.map((room) => room.toJson()).toList(),
    };
  }
}