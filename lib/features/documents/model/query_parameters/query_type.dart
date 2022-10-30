enum QueryType {
  title('title__icontains'),
  titleAndContent('title_content'),
  extended('query'),
  asn('asn');

  final String queryParam;
  const QueryType(this.queryParam);
}
