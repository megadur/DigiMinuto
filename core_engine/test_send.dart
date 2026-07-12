import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/core/key_pairs.dart';

void main() async {
  Nostr.instance.disableLogs();
  await Nostr.instance.relays.init(relaysUrl: ['wss://relay.damus.io']);
  
  final keys = Nostr.instance.keys.generateKeyPair();
  
  final request = NostrRequest(
    filters: [
      NostrFilter(
        kinds: [29999],
        p: [keys.public],
      )
    ],
  );
  
  final stream = Nostr.instance.relays.startEventsSubscription(request: request);
  stream.stream.listen((event) {
    print("Received: ${event.content}");
  });
  
  final event = NostrEvent.fromPartialData(
    kind: 29999,
    content: "test payload",
    keyPairs: keys,
    tags: [
      ["p", keys.public]
    ],
  );
  
  Nostr.instance.relays.sendEventToRelays(event);
  
  await Future.delayed(Duration(seconds: 5));
  print("Done");
}
