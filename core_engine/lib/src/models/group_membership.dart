import 'dart:convert';

class GroupMembership {
  final String groupId;
  final String groupName;
  final String memberPubKey;
  final String inviterPubKey; // The one who invited. If member == inviter, it's the founder.
  final DateTime timestamp;
  final String signature; // Signature over (groupId + groupName + memberPubKey + inviterPubKey + timestamp)

  GroupMembership({
    required this.groupId,
    required this.groupName,
    required this.memberPubKey,
    required this.inviterPubKey,
    required this.timestamp,
    required this.signature,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'memberPubKey': memberPubKey,
      'inviterPubKey': inviterPubKey,
      'timestamp': timestamp.toIso8601String(),
      'signature': signature,
    };
  }

  factory GroupMembership.fromMap(Map<String, dynamic> map) {
    return GroupMembership(
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
      memberPubKey: map['memberPubKey'] ?? '',
      inviterPubKey: map['inviterPubKey'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      signature: map['signature'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory GroupMembership.fromJson(String source) => GroupMembership.fromMap(json.decode(source));

  /// Returns the string that should be signed by the inviter
  String get messageToSign => '$groupId:$groupName:$memberPubKey:$inviterPubKey:${timestamp.millisecondsSinceEpoch}';
}
