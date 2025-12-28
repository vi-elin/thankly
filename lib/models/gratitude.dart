import '../data/entities/gratitude_entity.dart';

class Gratitude {
  final int? id;
  final int timestamp; // Unix timestamp in milliseconds
  final List<String> items;

  Gratitude({
    this.id,
    required this.timestamp,
    required this.items,
  });

  // Create from entity
  factory Gratitude.fromEntity(GratitudeEntity entity) {
    return Gratitude(
      id: entity.id,
      timestamp: entity.timestamp,
      items: entity.items,
    );
  }

  // Convert to entity
  GratitudeEntity toEntity() {
    return GratitudeEntity.fromItems(
      id: id,
      timestamp: timestamp,
      items: items,
    );
  }

  // Create a copy with modified fields
  Gratitude copyWith({
    int? id,
    int? timestamp,
    List<String>? items,
  }) {
    return Gratitude(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      items: items ?? this.items,
    );
  }

  // Get DateTime from timestamp
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);

  // Get date without time for grouping
  DateTime get dateOnly {
    final d = date;
    return DateTime(d.year, d.month, d.day);
  }

  // Create new gratitude with current timestamp
  factory Gratitude.now({List<String>? items}) {
    return Gratitude(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      items: items ?? [],
    );
  }
}
