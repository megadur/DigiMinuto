class Identity {
  final String publicKey;
  final String? privateKey; // Null if it's a contact, not the local user
  final String? name;
  final int reputationScore; // For the "Ramsch-Filter"

  Identity({
    required this.publicKey,
    this.privateKey,
    this.name,
    this.reputationScore = 0,
  });

  bool get isLocalUser => privateKey != null;

  Map<String, dynamic> toJson() {
    return {
      'publicKey': publicKey,
      'privateKey': privateKey,
      'name': name,
      'reputationScore': reputationScore,
    };
  }

  factory Identity.fromJson(Map<String, dynamic> json) {
    return Identity(
      publicKey: json['publicKey'],
      privateKey: json['privateKey'],
      name: json['name'],
      reputationScore: json['reputationScore'] ?? 0,
    );
  }
}
