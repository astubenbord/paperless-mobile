enum SortField {
  archiveSerialNumber("archive_serial_number"),
  correspondentName("correspondent__name"),
  title("title"),
  documentType("document_type__name"),
  created("created"),
  added("added"),
  modified("modified");

  final String queryString;

  const SortField(this.queryString);

  @override
  String toString() {
    return name.toLowerCase();
  }
}
