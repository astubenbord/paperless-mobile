import 'package:paperless_api/paperless_api.dart';

class LabelState<T extends Label> {
  LabelState.initial() : this(isLoaded: false, labels: {});
  final bool isLoaded;
  final Map<int, T> labels;

  LabelState({
    this.isLoaded = false,
    this.labels = const {},
  });

  T? getLabel(int? key) {
    if (isLoaded) {
      return labels[key];
    }
    return null;
  }
}
