import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum(valueField: 'value')
enum RuleTypeEnum {
  titleContains(0),
  contentContains(1),
  asnIs(2),
  correspondentIs(3),
  documentTypeIs(4),
  isInInbox(5),
  hasTag(6),
  hasAnyTag(7),
  createdBefore(8),
  createdAfter(9),
  createdYearIs(10),
  createdMonthIs(11),
  createdDayIs(12),
  addedBefore(13),
  addedAfter(14),
  modifiedBefore(15),
  modifiedAfter(16),
  doesNotHaveTag(17),
  doesNotHaveAsn(18),
  titleOrContentContains(19),
  fulltextQuery(20),
  moreLikeThis(21),
  hasTagsIn(22),
  asnGreaterThan(23),
  asnLessThan(24),
  storagePathIs(25),
  hasCorrespondentIn(26),
  doesNotHaveCorrespondentIn(27),
  hasDocumentTypeIn(28),
  doesNotHaveDocumentTypeIn(29),
  hasStoragePathIn(30),
  doesNotHaveStoragePathIn(31),
  ownerIs(32),
  hasOwnerIn(33),
  doesNotHaveOwner(34),
  doesNotHaveOwnerIn(35),
  hasCustomFieldValue(36),
  isSharedByMe(37),
  hasCustomFields(38),
  hasCustomFieldIn(39),
  doesNotHaveCustomFieldIn(40),
  doesNotHaveCustomField(41),
  customFieldsQuery(42),
  createdTo(43),
  createdFrom(44),
  addedTo(45),
  addedFrom(46),
  mimeTypeIs(47),
  simpleTitleSearch(48),
  simpleTextSearch(49),
  hasDuplicates(50);

  const RuleTypeEnum(this.value);

  final int value;

  @override
  String toString() => name;
}
