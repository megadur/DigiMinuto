class Contact {
  final String publicKey;
  final String name;

  Contact({
    required this.publicKey,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'publicKey': publicKey,
      'name': name,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      publicKey: json['publicKey'],
      name: json['name'],
    );
  }
}
