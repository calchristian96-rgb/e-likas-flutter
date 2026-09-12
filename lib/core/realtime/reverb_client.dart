import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// A minimal Pusher-protocol client for Laravel Reverb — public
/// channels only. The app never authenticates, so it never needs the
/// private/presence channel auth handshake, which is why this is a
/// small hand-rolled client on top of web_socket_channel rather than a
/// full third-party Pusher/Reverb wrapper package.
///
/// Phase 1 scaffolding: connection plumbing only, unused so far.
/// Module 6 wires this into the alerts feature — and only after
/// confirming with the backend that the "sent alert" broadcast
/// actually targets a public channel, not a private/staff one.
class ReverbClient {
  ReverbClient({
    required this.host,
    required this.port,
    required this.appKey,
    this.useTls = false,
  });

  final String host;
  final int port;
  final String appKey;
  final bool useTls;

  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  void connect() {
    final scheme = useTls ? 'wss' : 'ws';
    final uri = Uri.parse('$scheme://$host:$port/app/$appKey');
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    channel.stream.listen((raw) {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      _messageController.add(decoded);
    }, onError: _messageController.addError);
  }

  void subscribe(String channelName) {
    _send({
      'event': 'pusher:subscribe',
      'data': {'channel': channelName},
    });
  }

  void _send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  void dispose() {
    _channel?.sink.close();
    _messageController.close();
  }
}
