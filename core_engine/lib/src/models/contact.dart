class Contact {
  final String publicKey;
  final String name;
  final String? portfolio;

  Contact({
    required this.publicKey,
    required this.name,
    this.portfolio,
  });

  Map<String, dynamic> toJson() {
    return {
      'publicKey': publicKey,
      'name': name,
      'portfolio': portfolio,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      publicKey: json['publicKey'],
      name: json['name'],
      portfolio: json['portfolio'],
    );
  }
}
