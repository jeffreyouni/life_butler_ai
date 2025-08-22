import 'package:meta/meta.dart';

@immutable
class SearchResult {
  const SearchResult({
    required this.id,
    required this.objectType,
    required this.objectId,
    required this.text,
    required this.similarity,
  });

  final String id;
  final String objectType;
  final String objectId;
  final String text;
  final double similarity;

  /// Get reference information for citations
  String get citation {
    return '$objectType ($objectId)';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'object_type': objectType,
      'object_id': objectId,
      'text': text,
      'similarity': similarity,
    };
  }
}
