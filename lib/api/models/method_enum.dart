import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum MethodEnum {
  setCorrespondent,
  setDocumentType,
  setStoragePath,
  addTag,
  removeTag,
  modifyTags,
  modifyCustomFields,
  delete,
  reprocess,
  setPermissions,
  rotate,
  merge,
  editPdf,
  removePassword,
  split,
  deletePages;

  @override
  String toString() => name;
}
