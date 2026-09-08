import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  WebSocketChannel? _presenceChannel;
  Stream<dynamic> connect(String baseUrl, String gameId, String token) {
    final uri = Uri.parse(
        '${baseUrl.replaceFirst('http', 'ws')}/ws/games/$gameId?token=$token');
    _channel = WebSocketChannel.connect(uri);
    return _channel!.stream.map((e) => jsonDecode(e as String));
  }

  Stream<dynamic> connectPresence(String baseUrl, String token) {
    final uri = Uri.parse(
        '${baseUrl.replaceFirst('http', 'ws')}/ws/presence?token=$token');
    _presenceChannel = WebSocketChannel.connect(uri);
    return _presenceChannel!.stream.map((e) => jsonDecode(e as String));
  }

  void send(Map<String, dynamic> event) =>
      _channel?.sink.add(jsonEncode(event));
  void dispose() {
    _channel?.sink.close();
    _presenceChannel?.sink.close();
  }
}
