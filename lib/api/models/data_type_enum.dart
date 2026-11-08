enum DataTypeEnum {
  string,
  url,
  date,
  boolean,
  integer,
  float,
  monetary,
  documentlink,
  select;

  @override
  String toString() => name;
}

DataTypeEnum dataTypeEnumFromJson(Object? value) {
  if (value == 'longtext') return DataTypeEnum.string;
  return DataTypeEnum.values.firstWhere(
    (type) => type.name == value,
    orElse: () => DataTypeEnum.string,
  );
}

String dataTypeEnumToJson(DataTypeEnum value) => value.name;
