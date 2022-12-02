import 'package:paperless_api/src/models/labels/correspondent_model.dart';
import 'package:paperless_api/src/models/labels/document_type_model.dart';
import 'package:paperless_api/src/models/labels/storage_path_model.dart';
import 'package:paperless_api/src/models/labels/tag_model.dart';

///
/// Provides basic CRUD operations for labels, including:
/// <ul>
///    <li>Correspondents</li>
///    <li>Document Types</li>
///    <li>Tags</li>
///    <li>Storage Paths</li>
/// </ul>
///
abstract class PaperlessLabelsApi {
  Future<Correspondent?> getCorrespondent(int id);
  Future<List<Correspondent>> getCorrespondents();
  Future<Correspondent> saveCorrespondent(Correspondent correspondent);
  Future<Correspondent> updateCorrespondent(Correspondent correspondent);
  Future<int> deleteCorrespondent(Correspondent correspondent);

  Future<Tag?> getTag(int id);
  Future<List<Tag>> getTags({List<int>? ids});
  Future<Tag> saveTag(Tag tag);
  Future<Tag> updateTag(Tag tag);
  Future<int> deleteTag(Tag tag);

  Future<DocumentType?> getDocumentType(int id);
  Future<List<DocumentType>> getDocumentTypes();
  Future<DocumentType> saveDocumentType(DocumentType type);
  Future<DocumentType> updateDocumentType(DocumentType documentType);
  Future<int> deleteDocumentType(DocumentType documentType);

  Future<StoragePath?> getStoragePath(int id);
  Future<List<StoragePath>> getStoragePaths();
  Future<StoragePath> saveStoragePath(StoragePath path);
  Future<StoragePath> updateStoragePath(StoragePath path);
  Future<int> deleteStoragePath(StoragePath path);
}
