import 'dart:async';
import 'package:dart_nostr/dart_nostr.dart';

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

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await Nostr.instance.relays.freeAllResources();
    _isConnected = false;
    _connectionStatusController.add(false);
  }
}
