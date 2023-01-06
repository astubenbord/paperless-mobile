// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_query.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextQuery _$TextQueryFromJson(Map<String, dynamic> json) => TextQuery(
      queryType: $enumDecodeNullable(_$QueryTypeEnumMap, json['queryType']) ??
          QueryType.titleAndContent,
      queryText: json['queryText'] as String?,
    );

Map<String, dynamic> _$TextQueryToJson(TextQuery instance) => <String, dynamic>{
      'queryType': _$QueryTypeEnumMap[instance.queryType]!,
      'queryText': instance.queryText,
    };

const _$QueryTypeEnumMap = {
  QueryType.title: 'title',
  QueryType.titleAndContent: 'titleAndContent',
  QueryType.extended: 'extended',
  QueryType.asn: 'asn',
};
