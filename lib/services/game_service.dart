import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game.dart';
import '../models/invitation.dart'; // your Invitation class
import 'auth_service.dart';

class GameService {
  GameService(
      {this.baseUrl = const String.fromEnvironment('API_URL',
          defaultValue: 'http://10.0.2.2:8000')});
  final String baseUrl;

  Map<String, String> get _headers {
    final token = AuthService.instance.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token'
    };
  }

  Future<Game> create(String opponentId, int minutes, String color) async {
    final r = await http.post(Uri.parse('$baseUrl/games'),
        headers: _headers,
        body: jsonEncode(
            {'opponent_id': opponentId, 'minutes': minutes, 'color': color}));
    if (r.statusCode >= 400) throw Exception(jsonDecode(r.body)['detail']);
    return Game.fromJson(jsonDecode(r.body));
  }

  Future<Game> move(String id, String move) async {
    final r = await http.post(Uri.parse('$baseUrl/games/$id/moves'),
        headers: _headers, body: jsonEncode({'move': move}));
    if (r.statusCode >= 400) throw Exception(jsonDecode(r.body)['detail']);
    return Game.fromJson(jsonDecode(r.body));
  }

  Future<Game> getGame(String id) async {
    final r =
        await http.get(Uri.parse('$baseUrl/games/$id'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(jsonDecode(r.body)['detail']);
    return Game.fromJson(jsonDecode(r.body));
  }

  Future<Game> requestRestart(String id) async {
    final r = await http.post(Uri.parse('$baseUrl/games/$id/restart'),
        headers: _headers);
    if (r.statusCode >= 400) throw Exception(jsonDecode(r.body)['detail']);
    return Game.fromJson(jsonDecode(r.body));
  }

  Future<Game> quitGame(String id) async {
    final r = await http.post(Uri.parse('$baseUrl/games/$id/quit'),
        headers: _headers);
    if (r.statusCode >= 400) throw Exception(jsonDecode(r.body)['detail']);
    return Game.fromJson(jsonDecode(r.body));
  }

  // ——— Invitations ———
  Future<void> createInvitation(
      String opponentId, int minutes, String color) async {
    final r = await http.post(Uri.parse('$baseUrl/invitations'),
        headers: _headers,
        body: jsonEncode(
            {'to_user_id': opponentId, 'minutes': minutes, 'color': color}));
    if (r.statusCode >= 400) throw Exception(jsonDecode(r.body)['detail']);
  }

  Future<List<Invitation>> getInvitations() async {
    final r =
        await http.get(Uri.parse('$baseUrl/invitations'), headers: _headers);
    if (r.statusCode >= 400) throw Exception('Failed to load invites');
    final list = jsonDecode(r.body) as List;
    return list.map((e) => Invitation.fromJson(e)).toList();
  }

  Future<Game> acceptInvite(String id) async {
    final r = await http.post(
      Uri.parse('$baseUrl/invitations/$id/accept'),
      headers: _headers,
    );
    if (r.statusCode >= 400) {
      throw Exception(jsonDecode(r.body)['detail'] ?? 'Failed to accept');
    }
    return Game.fromJson(jsonDecode(r.body));
  }

  Future<List<Game>> getGames() async {
    final r = await http.get(Uri.parse('$baseUrl/games'), headers: _headers);
    if (r.statusCode >= 400) throw Exception('Failed to load games');
    return (jsonDecode(r.body) as List)
        .map((item) => Game.fromJson(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final uri = Uri.parse('$baseUrl/users/search').replace(
      queryParameters: query.isEmpty ? null : {'q': query},
    );
    final r = await http.get(uri, headers: _headers);
    if (r.statusCode >= 400) {
      throw Exception(jsonDecode(r.body)['detail'] ?? 'Failed to load users');
    }
    final list = jsonDecode(r.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> declineInvite(String id) async {
    final r = await http.post(
      Uri.parse('$baseUrl/invitations/$id/decline'),
      headers: _headers,
    );
    if (r.statusCode >= 400) {
      throw Exception(jsonDecode(r.body)['detail'] ?? 'Failed to decline');
    }
  }
}
