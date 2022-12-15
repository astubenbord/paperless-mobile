import 'package:equatable/equatable.dart';
import 'package:paperless_api/src/constants.dart';

abstract class DateRangeQuery extends Equatable {
  const DateRangeQuery();
  Map<String, String> toQueryParameter();
}

class UnsetDateRangeQuery extends DateRangeQuery {
  const UnsetDateRangeQuery();
  @override
  List<Object?> get props => [];

  @override
  Map<String, String> toQueryParameter() => const {};
}

class FixedDateRangeQuery extends DateRangeQuery {
  final String _querySuffix;

  final DateTime? after;
  final DateTime? before;

  const FixedDateRangeQuery._(this._querySuffix, {this.after, this.before})
      : assert(after != null || before != null);

  const FixedDateRangeQuery.created({DateTime? after, DateTime? before})
      : this._('created', after: after, before: before);

  const FixedDateRangeQuery.added({DateTime? after, DateTime? before})
      : this._('added', after: after, before: before);

  const FixedDateRangeQuery.modified({DateTime? after, DateTime? before})
      : this._('modified', after: after, before: before);

  @override
  List<Object?> get props => [_querySuffix, after, before];

  @override
  Map<String, String> toQueryParameter() {
    final Map<String, String> params = {};

    // Add/subtract one day in the following because paperless uses gt/lt not gte/lte
    if (after != null) {
      params.putIfAbsent('${_querySuffix}__date__gt',
          () => apiDateFormat.format(after!.subtract(const Duration(days: 1))));
    }

    if (before != null) {
      params.putIfAbsent('${_querySuffix}__date__lt',
          () => apiDateFormat.format(before!.add(const Duration(days: 1))));
    }
    return params;
  }

  FixedDateRangeQuery copyWith({
    DateTime? before,
    DateTime? after,
  }) {
    return FixedDateRangeQuery._(
      _querySuffix,
      before: before ?? this.before,
      after: after ?? this.after,
    );
  }
}

class LastNDateRangeQuery extends DateRangeQuery {
  final DateRangeUnit unit;
  final int n;
  final String _field;

  const LastNDateRangeQuery._(
    this._field, {
    required this.n,
    required this.unit,
  });

  const LastNDateRangeQuery.created(int n, DateRangeUnit unit)
      : this._('created', unit: unit, n: n);
  const LastNDateRangeQuery.added(int n, DateRangeUnit unit)
      : this._('added', unit: unit, n: n);
  const LastNDateRangeQuery.modified(int n, DateRangeUnit unit)
      : this._('modified', unit: unit, n: n);

  @override
  // TODO: implement props
  List<Object?> get props => [_field, n, unit];

  @override
  Map<String, String> toQueryParameter() {
    return {
      'query': '[$_field:$n ${unit.name} to now]',
    };
  }
}

enum DateRangeUnit {
  day,
  week,
  month,
  year;
}
