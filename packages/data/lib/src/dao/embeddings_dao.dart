import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/tables.dart';
import '../models/embedding_model.dart';

part 'embeddings_dao.g.dart';

@DriftAccessor(tables: [Embeddings])
class EmbeddingsDao extends DatabaseAccessor<LifeButlerDatabase> with _$EmbeddingsDaoMixin {
  EmbeddingsDao(LifeButlerDatabase db) : super(db);

  Future<List<EmbeddingModel>> getAllEmbeddings() async {
    final query = select(embeddings)
      ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]);
    
    final rows = await query.get();
    return rows.map((row) => EmbeddingModel.fromDrift(row)).toList();
  }

  Future<List<EmbeddingModel>> getEmbeddingsByObject(String objectType, String objectId) async {
    final query = select(embeddings)
      ..where((e) => e.objectType.equals(objectType) & e.objectId.equals(objectId))
      ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]);
    
    final rows = await query.get();
    return rows.map((row) => EmbeddingModel.fromDrift(row)).toList();
  }

  Future<EmbeddingModel?> getEmbeddingById(String id) async {
    final query = select(embeddings)..where((e) => e.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? EmbeddingModel.fromDrift(row) : null;
  }

  Future<String> insertEmbedding(EmbeddingModel embedding) async {
    final companion = EmbeddingsCompanion(
      id: Value(embedding.id),
      objectType: Value(embedding.objectType),
      objectId: Value(embedding.objectId),
      chunkText: Value(embedding.chunkText),
      vectorBlob: Value(embedding.vectorBlob),
      createdAt: Value(embedding.createdAt),
    );
    
    await into(embeddings).insert(companion);
    return embedding.id;
  }

  Future<bool> updateEmbedding(EmbeddingModel embedding) async {
    final companion = EmbeddingsCompanion(
      objectType: Value(embedding.objectType),
      objectId: Value(embedding.objectId),
      chunkText: Value(embedding.chunkText),
      vectorBlob: Value(embedding.vectorBlob),
    );
    
    return await (update(embeddings)..where((e) => e.id.equals(embedding.id))).write(companion) > 0;
  }

  Future<bool> deleteEmbedding(String id) async {
    return await (delete(embeddings)..where((e) => e.id.equals(id))).go() > 0;
  }

  Future<bool> deleteEmbeddingsByObject(String objectType, String objectId) async {
    return await (delete(embeddings)
      ..where((e) => e.objectType.equals(objectType) & e.objectId.equals(objectId))
    ).go() > 0;
  }

  Future<List<EmbeddingModel>> searchEmbeddingsByText(String searchTerm) async {
    final query = select(embeddings)
      ..where((e) => e.chunkText.contains(searchTerm))
      ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]);
    
    final rows = await query.get();
    return rows.map((row) => EmbeddingModel.fromDrift(row)).toList();
  }
}
