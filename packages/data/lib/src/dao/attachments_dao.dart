import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/tables.dart';

part 'attachments_dao.g.dart';

@DriftAccessor(tables: [Attachments])
class AttachmentsDao extends DatabaseAccessor<LifeButlerDatabase> with _$AttachmentsDaoMixin {
  AttachmentsDao(LifeButlerDatabase db) : super(db);

  Future<List<Attachment>> getAllAttachments() async {
    final query = select(attachments)
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]);
    
    return await query.get();
  }

  Future<List<Attachment>> getAttachmentsByType(String objectType) async {
    final query = select(attachments)
      ..where((a) => a.objectType.equals(objectType))
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]);
    
    return await query.get();
  }

  Future<List<Attachment>> getAttachmentsByObjectId(String objectId) async {
    final query = select(attachments)
      ..where((a) => a.objectId.equals(objectId))
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]);
    
    return await query.get();
  }

  Future<Attachment?> getAttachmentById(String id) async {
    final query = select(attachments)..where((a) => a.id.equals(id));
    return await query.getSingleOrNull();
  }

  Future<int> insertAttachment(AttachmentsCompanion attachmentData) async {
    return await into(attachments).insert(attachmentData);
  }

  Future<bool> updateAttachment(String id, AttachmentsCompanion attachmentData) async {
    return await (update(attachments)..where((a) => a.id.equals(id))).write(attachmentData) > 0;
  }

  Future<bool> deleteAttachment(String id) async {
    return await (delete(attachments)..where((a) => a.id.equals(id))).go() > 0;
  }

  Future<List<Attachment>> searchAttachments(String searchTerm) async {
    final query = select(attachments)
      ..where((a) => 
        a.fileName.contains(searchTerm) |
        a.objectType.contains(searchTerm)
      )
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]);
    
    return await query.get();
  }
}
