// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentFilter _$DocumentFilterFromJson(Map<String, dynamic> json) =>
    DocumentFilter(
      documentType: json['documentType'] == null
          ? const IdQueryParameter.unset()
          : IdQueryParameter.fromJson(
              json['documentType'] as Map<String, dynamic>),
      correspondent: json['correspondent'] == null
          ? const IdQueryParameter.unset()
          : IdQueryParameter.fromJson(
              json['correspondent'] as Map<String, dynamic>),
      storagePath: json['storagePath'] == null
          ? const IdQueryParameter.unset()
          : IdQueryParameter.fromJson(
              json['storagePath'] as Map<String, dynamic>),
      asnQuery: json['asnQuery'] == null
          ? const IdQueryParameter.unset()
          : IdQueryParameter.fromJson(json['asnQuery'] as Map<String, dynamic>),
      tags: json['tags'] == null
          ? const IdsTagsQuery()
          : const TagsQueryJsonConverter()
              .fromJson(json['tags'] as Map<String, dynamic>),
      sortField: $enumDecodeNullable(_$SortFieldEnumMap, json['sortField']) ??
          SortField.created,
      sortOrder: $enumDecodeNullable(_$SortOrderEnumMap, json['sortOrder']) ??
          SortOrder.descending,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 25,
      query: json['query'] == null
          ? const TextQuery()
          : TextQuery.fromJson(json['query'] as Map<String, dynamic>),
      added: json['added'] == null
          ? const UnsetDateRangeQuery()
          : const DateRangeQueryJsonConverter()
              .fromJson(json['added'] as Map<String, dynamic>),
      created: json['created'] == null
          ? const UnsetDateRangeQuery()
          : const DateRangeQueryJsonConverter()
              .fromJson(json['created'] as Map<String, dynamic>),
      modified: json['modified'] == null
          ? const UnsetDateRangeQuery()
          : const DateRangeQueryJsonConverter()
              .fromJson(json['modified'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DocumentFilterToJson(DocumentFilter instance) =>
    <String, dynamic>{
      'pageSize': instance.pageSize,
      'page': instance.page,
      'documentType': instance.documentType.toJson(),
      'correspondent': instance.correspondent.toJson(),
      'storagePath': instance.storagePath.toJson(),
      'asnQuery': instance.asnQuery.toJson(),
      'tags': const TagsQueryJsonConverter().toJson(instance.tags),
      'sortField': _$SortFieldEnumMap[instance.sortField]!,
      'sortOrder': _$SortOrderEnumMap[instance.sortOrder]!,
      'created': const DateRangeQueryJsonConverter().toJson(instance.created),
      'added': const DateRangeQueryJsonConverter().toJson(instance.added),
      'modified': const DateRangeQueryJsonConverter().toJson(instance.modified),
      'query': instance.query.toJson(),
    };

const _$SortFieldEnumMap = {
  SortField.archiveSerialNumber: 'archiveSerialNumber',
  SortField.correspondentName: 'correspondentName',
  SortField.title: 'title',
  SortField.documentType: 'documentType',
  SortField.created: 'created',
  SortField.added: 'added',
  SortField.modified: 'modified',
};

const _$SortOrderEnumMap = {
  SortOrder.ascending: 'ascending',
  SortOrder.descending: 'descending',
};
