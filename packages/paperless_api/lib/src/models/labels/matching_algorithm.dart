import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum MatchingAlgorithm {
  anyWord(1, "Any: Match one of the following words"),
  allWords(2, "All: Match all of the following words"),
  exactMatch(3, "Exact: Match the following string"),
  regex(4, "Regex: Match the regular expression"),
  similarWord(5, "Similar: Match a similar word"),
  auto(6, "Auto: Learn automatic assignment");

  final int value;
  final String name;

  const MatchingAlgorithm(this.value, this.name);

  static MatchingAlgorithm fromInt(int? value) {
    return MatchingAlgorithm.values
        .where((element) => element.value == value)
        .firstWhere(
          (element) => true,
          orElse: () => MatchingAlgorithm.anyWord,
        );
  }
}
