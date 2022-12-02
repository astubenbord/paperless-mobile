class PaperlessServerStatisticsModel {
  final int documentsTotal;
  final int documentsInInbox;

  PaperlessServerStatisticsModel({
    required this.documentsTotal,
    required this.documentsInInbox,
  });

  PaperlessServerStatisticsModel.fromJson(Map<String, dynamic> json)
      : documentsTotal = json['documents_total'],
        documentsInInbox = json['documents_inbox'];
}
