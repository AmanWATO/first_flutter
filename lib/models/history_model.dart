class HistoryEntry {
  final int id;
  final String url;
  final String favicon;
  final String timestamp;

  HistoryEntry({
    required this.id,
    required this.url,
    required this.favicon,
    required this.timestamp,
  });

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['_id'] ?? 0,
      url: map['url'] ?? '',
      favicon: map['favicon'] ?? '',
      timestamp: map['timestamp'] ?? '',
    );
  }
}
