// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filter_rule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FilterRule _$FilterRuleFromJson(Map<String, dynamic> json) => FilterRule(
      json['rule_type'] as int,
      json['value'] as String?,
    );

Map<String, dynamic> _$FilterRuleToJson(FilterRule instance) =>
    <String, dynamic>{
      'rule_type': instance.ruleType,
      'value': instance.value,
    };
