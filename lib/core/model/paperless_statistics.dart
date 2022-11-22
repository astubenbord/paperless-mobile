import 'package:paperless_mobile/core/type/types.dart';

class PaperlessStatistics {
  final int documentsTotal;
  final int documentsInInbox;

  PaperlessStatistics({
    required this.documentsTotal,
    required this.documentsInInbox,
  });

  PaperlessStatistics.fromJson(JSON json)
      : documentsTotal = json['documents_total'],
        documentsInInbox = json['documents_inbox'];
}
