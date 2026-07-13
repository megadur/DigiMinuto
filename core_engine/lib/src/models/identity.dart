class Identity {
  final String publicKey;
  final String? privateKey; // Null if it's a contact, not the local user
  final String? name;
  final String? portfolio; // User's offerings/keywords
  final int reputationScore; // For the "Ramsch-Filter"

  Identity({
    required this.publicKey,
    this.privateKey,
    this.name,
    this.portfolio,
    this.reputationScore = 0,
  });

  bool get isLocalUser => privateKey != null;

  Map<String, dynamic> toJson() {
    return {
      'publicKey': publicKey,
      'privateKey': privateKey,
      'name': name,
      'portfolio': portfolio,
      'reputationScore': reputationScore,
    };
  }

  factory Identity.fromJson(Map<String, dynamic> json) {
    return Identity(
      publicKey: json['publicKey'],
      privateKey: json['privateKey'],
      name: json['name'],
      portfolio: json['portfolio'],
      reputationScore: json['reputationScore'] ?? 0,
    );
  }
}
