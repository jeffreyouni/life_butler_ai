import 'package:meta/meta.dart';

/// Knowledge Graph interfaces for lightweight KG functionality
abstract class KnowledgeGraph {
  /// Add a node to the knowledge graph
  Future<void> addNode(KgNode node);

  /// Add an edge between two nodes
  Future<void> addEdge(KgEdge edge);

  /// Find nodes by type
  Future<List<KgNode>> findNodesByType(String nodeType);

  /// Find connected nodes
  Future<List<KgNode>> findConnectedNodes(
    String nodeId, {
    String? edgeType,
    int maxDepth = 1,
  });

  /// Find paths between two nodes
  Future<List<KgPath>> findPaths(
    String fromNodeId,
    String toNodeId, {
    int maxDepth = 3,
  });

  /// Get node by ID
  Future<KgNode?> getNode(String nodeId);

  /// Get all edges for a node
  Future<List<KgEdge>> getNodeEdges(String nodeId);

  /// Remove node and all its edges
  Future<void> removeNode(String nodeId);

  /// Clear all KG data
  Future<void> clear();
}

/// Lightweight KG node representation
@immutable
class KgNode {
  const KgNode({
    required this.id,
    required this.type,
    required this.label,
    this.properties = const {},
    this.objectId,
    this.objectType,
  });

  final String id;
  final String type;
  final String label;
  final Map<String, dynamic> properties;
  final String? objectId;  // Reference to domain object
  final String? objectType;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'label': label,
      'properties': properties,
      'object_id': objectId,
      'object_type': objectType,
    };
  }

  factory KgNode.fromMap(Map<String, dynamic> map) {
    return KgNode(
      id: map['id'],
      type: map['type'],
      label: map['label'],
      properties: Map<String, dynamic>.from(map['properties'] ?? {}),
      objectId: map['object_id'],
      objectType: map['object_type'],
    );
  }

  KgNode copyWith({
    String? type,
    String? label,
    Map<String, dynamic>? properties,
    String? objectId,
    String? objectType,
  }) {
    return KgNode(
      id: id,
      type: type ?? this.type,
      label: label ?? this.label,
      properties: properties ?? this.properties,
      objectId: objectId ?? this.objectId,
      objectType: objectType ?? this.objectType,
    );
  }
}

/// KG edge representation
@immutable
class KgEdge {
  const KgEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.type,
    this.properties = const {},
    this.weight = 1.0,
  });

  final String id;
  final String fromNodeId;
  final String toNodeId;
  final String type;
  final Map<String, dynamic> properties;
  final double weight;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_node_id': fromNodeId,
      'to_node_id': toNodeId,
      'type': type,
      'properties': properties,
      'weight': weight,
    };
  }

  factory KgEdge.fromMap(Map<String, dynamic> map) {
    return KgEdge(
      id: map['id'],
      fromNodeId: map['from_node_id'],
      toNodeId: map['to_node_id'],
      type: map['type'],
      properties: Map<String, dynamic>.from(map['properties'] ?? {}),
      weight: (map['weight'] ?? 1.0).toDouble(),
    );
  }
}

/// Path between nodes in the KG
@immutable
class KgPath {
  const KgPath({
    required this.nodes,
    required this.edges,
    required this.totalWeight,
  });

  final List<KgNode> nodes;
  final List<KgEdge> edges;
  final double totalWeight;

  int get length => edges.length;

  /// Get a human-readable description of the path
  String get description {
    if (nodes.length < 2) return '';
    
    final buffer = StringBuffer();
    for (int i = 0; i < edges.length; i++) {
      if (i > 0) buffer.write(' → ');
      buffer.write('${nodes[i].label} -[${edges[i].type}]-> ${nodes[i + 1].label}');
    }
    
    return buffer.toString();
  }
}

/// Common KG node types
class KgNodeTypes {
  static const String person = 'person';
  static const String place = 'place';
  static const String event = 'event';
  static const String organization = 'organization';
  static const String concept = 'concept';
  static const String activity = 'activity';
  static const String item = 'item';
  static const String metric = 'metric';
  static const String goal = 'goal';
  static const String habit = 'habit';
  static const String skill = 'skill';
  static const String emotion = 'emotion';
  static const String category = 'category';
}

/// Common KG edge types
class KgEdgeTypes {
  static const String relatesTo = 'RELATES_TO';
  static const String happenedAt = 'HAPPENED_AT';
  static const String involvesPerson = 'INVOLVES_PERSON';
  static const String locatedAt = 'LOCATED_AT';
  static const String memberOf = 'MEMBER_OF';
  static const String causedBy = 'CAUSED_BY';
  static const String leadTo = 'LEAD_TO';
  static const String affects = 'AFFECTS';
  static const String improves = 'IMPROVES';
  static const String worsens = 'WORSENS';
  static const String requires = 'REQUIRES';
  static const String enables = 'ENABLES';
  static const String associatedWith = 'ASSOCIATED_WITH';
  static const String conflictsWith = 'CONFLICTS_WITH';
  static const String dependsOn = 'DEPENDS_ON';
  static const String influencedBy = 'INFLUENCED_BY';
}
