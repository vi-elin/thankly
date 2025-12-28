import 'package:floor/floor.dart';
import 'dart:convert';

@entity
class GratitudeEntity {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final int timestamp; // Unix timestamp in milliseconds
  final String itemsJson; // JSON-encoded list of items

  GratitudeEntity({
    this.id,
    required this.timestamp,
    required this.itemsJson,
  });

  // Helper to get items as list
  List<String> get items {
    try {
      final decoded = jsonDecode(itemsJson);
      return List<String>.from(decoded);
    } catch (e) {
      return [];
    }
  }

  // Helper to create entity from items
  static GratitudeEntity fromItems({
    int? id,
    required int timestamp,
    required List<String> items,
  }) {
    return GratitudeEntity(
      id: id,
      timestamp: timestamp,
      itemsJson: jsonEncode(items),
    );
  }

  // Get DateTime from timestamp
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);

  // Get date without time for grouping
  DateTime get dateOnly {
    final d = date;
    return DateTime(d.year, d.month, d.day);
  }
}
