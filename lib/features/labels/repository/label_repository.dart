import 'package:paperless_mobile/features/labels/correspondent/model/correspondent.model.dart';
import 'package:paperless_mobile/features/labels/document_type/model/document_type.model.dart';
import 'package:paperless_mobile/features/labels/storage_path/model/storage_path.model.dart';
import 'package:paperless_mobile/features/labels/tags/model/tag.model.dart';

abstract class LabelRepository {
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
