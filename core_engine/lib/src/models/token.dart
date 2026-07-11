enum TokenStatus {
  pending, // Waits for 2 guarantors
  active,  // Ready to use
  burned,  // Spent or invalid
}

class Token {
  final String id;
  final String creatorPubKey;
  final int amount;
  final int creationYear;
  String? guarantor1Signature;
  String? guarantor2Signature;
  TokenStatus status;

  Token({
    required this.id,
    required this.creatorPubKey,
    required this.amount,
    required this.creationYear,
    this.guarantor1Signature,
    this.guarantor2Signature,
    this.status = TokenStatus.pending,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorPubKey': creatorPubKey,
      'amount': amount,
      'creationYear': creationYear,
      'guarantor1Signature': guarantor1Signature,
      'guarantor2Signature': guarantor2Signature,
      'status': status.name,
    };
  }

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      id: json['id'],
      creatorPubKey: json['creatorPubKey'],
      amount: json['amount'],
      creationYear: json['creationYear'],
      guarantor1Signature: json['guarantor1Signature'],
      guarantor2Signature: json['guarantor2Signature'],
      status: TokenStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TokenStatus.pending,
      ),
    );
  }
}
