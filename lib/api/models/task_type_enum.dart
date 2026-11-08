import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum TaskTypeEnum {
  consumeFile('consume_file'),
  trainClassifier('train_classifier'),
  sanityCheck('sanity_check'),
  indexOptimize('index_optimize'),
  mailFetch('mail_fetch'),
  llmIndex('llm_index'),
  emptyTrash('empty_trash'),
  checkWorkflows('check_workflows'),
  bulkUpdate('bulk_update'),
  reprocessDocument('reprocess_document'),
  buildShareLink('build_share_link'),
  bulkDelete('bulk_delete'),
  applyAiSuggestions('apply_ai_suggestions');

  const TaskTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
