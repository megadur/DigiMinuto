import 'dart:async';
import 'dart:convert';
import 'package:dart_nostr/dart_nostr.dart';
import '../models/request_post.dart';
import '../models/group_membership.dart';

class NostrService {
  final List<String> _relays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://nostr.mom',
  ];

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  StreamSubscription<NostrEvent>? _subscription;
  StreamSubscription<NostrEvent>? _requestsSubscription;

  Future<void> connect() async {
    try {
      Nostr.instance.disableLogs();
      await Nostr.instance.relays.init(
        relaysUrl: _relays,
        onRelayConnectionError: (relay, error, stackTrace) {
          // Fehler bei einzelnem Relay, ignorieren wir hier
        },
        onRelayConnectionDone: (relay, channel) {
          _updateConnectionStatus();
        },
      );
      _updateConnectionStatus();
    } catch (e) {
      print("Nostr connect error: $e");
      _isConnected = false;
      _connectionStatusController.add(false);
    }
  }

  void _updateConnectionStatus() {
    // Wenn wir mit mindestens einem Relay verbunden sind, gelten wir als online
    // Die API von dart_nostr bietet Nostr.instance.relaysService.relaysWebSocketsRegistry
    // Wir vereinfachen das und setzen es einfach auf true, wenn init() erfolgreich war.
    _isConnected = true;
    _connectionStatusController.add(true);
  }

  void startListening(String myPubKey, Function(String) onPayload) {
    if (_subscription != null) return;
    
    final request = NostrRequest(
      filters: [
        NostrFilter(
          kinds: [29999],
          p: [myPubKey],
        )
      ],
    );
    
    final stream = Nostr.instance.relays.startEventsSubscription(request: request);
    _subscription = stream.stream.listen((event) {
      if (event.content != null && event.content!.isNotEmpty) {
        onPayload(event.content!);
      }
    });
  }

  Future<void> sendPayload(String receiverPubKey, String payload, String myPrivateKey) async {
    final event = NostrEvent.fromPartialData(
      kind: 29999,
      content: payload,
      keyPairs: NostrKeyPairs(private: myPrivateKey),
      tags: [
        ["p", receiverPubKey]
      ],
    );
    
    Nostr.instance.relays.sendEventToRelays(event);
  }

  void publishRequest(String text, String myPrivateKey, {GroupMembership? group}) {
    final tags = <List<String>>[];
    
    if (group != null) {
      tags.add(["t", "digiminuto_group_${group.groupId}"]);
      // Unsichtbar das Einladungs-Ticket mitsenden
      tags.add(["group_ticket", jsonEncode(group.toMap())]);
    } else {
      tags.add(["t", "digiminuto_request"]);
    }

    final event = NostrEvent.fromPartialData(
      kind: 1,
      content: text,
      keyPairs: NostrKeyPairs(private: myPrivateKey),
      tags: tags,
    );
    Nostr.instance.relays.sendEventToRelays(event);
  }

  void subscribeToRequests(Function(RequestPost, GroupMembership?) onPost, {List<String>? groupIds}) {
    if (_requestsSubscription != null) {
      _requestsSubscription?.cancel();
      _requestsSubscription = null;
    }
    
    final tags = groupIds != null && groupIds.isNotEmpty 
        ? groupIds.map((id) => "digiminuto_group_$id").toList()
        : ["digiminuto_request"];

    final request = NostrRequest(
      filters: [
        NostrFilter(
          kinds: [1],
          t: tags,
          since: DateTime.now().subtract(const Duration(days: 7)),
        )
      ],
    );
    
    final stream = Nostr.instance.relays.startEventsSubscription(request: request);
    _requestsSubscription = stream.stream.listen((event) {
      if (event.content != null && event.content!.isNotEmpty) {
        final post = RequestPost(
          id: event.id ?? '',
          pubKey: event.pubkey,
          text: event.content!,
          timestamp: event.createdAt ?? DateTime.now(),
        );
        
        GroupMembership? ticket;
        try {
          final ticketTag = event.tags?.firstWhere((t) => t.isNotEmpty && t[0] == 'group_ticket', orElse: () => <String>[]);
          if (ticketTag != null && ticketTag.length > 1) {
            ticket = GroupMembership.fromMap(jsonDecode(ticketTag[1]));
          }
        } catch (_) {}

        onPost(post, ticket);
      }
    });
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _requestsSubscription?.cancel();
    _requestsSubscription = null;
    await Nostr.instance.relays.freeAllResources();
    _isConnected = false;
    _connectionStatusController.add(false);
  }
}
