class Transaction {
  final String id;
  final String tokenId;
  final String senderPubKey;
  final String receiverPubKey;
  final DateTime timestamp;
  final String signature;

  Transaction({
    required this.id,
    required this.tokenId,
    required this.senderPubKey,
    required this.receiverPubKey,
    required this.timestamp,
    required this.signature,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tokenId': tokenId,
      'senderPubKey': senderPubKey,
      'receiverPubKey': receiverPubKey,
      'timestamp': timestamp.toIso8601String(),
      'signature': signature,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      tokenId: json['tokenId'],
      senderPubKey: json['senderPubKey'],
      receiverPubKey: json['receiverPubKey'],
      timestamp: DateTime.parse(json['timestamp']),
      signature: json['signature'],
    );
  }
}
