class RequestPost {
  final String id;
  final String pubKey;
  final String text;
  final DateTime timestamp;

  RequestPost({
    required this.id,
    required this.pubKey,
    required this.text,
    required this.timestamp,
  });

  factory RequestPost.fromJson(Map<String, dynamic> json) {
    return RequestPost(
      id: json['id'],
      pubKey: json['pubKey'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pubKey': pubKey,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
