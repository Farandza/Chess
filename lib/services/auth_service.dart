import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();
  static const _baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');

  String? _token;
  User? _currentUser;
  String? get token => _token;
  User? get currentUser => _currentUser;

  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('access_token');
    final savedUser = prefs.getString('current_user');
    if (savedToken == null || savedUser == null) return false;
    _token = savedToken;
    _currentUser = User.fromJson(jsonDecode(savedUser) as Map<String, dynamic>);
    try {
      await refreshVerification();
      return true;
    } catch (_) {
      await signOut();
      return false;
    }
  }

  Future<User> signIn({required String email, required String password}) =>
      _authenticate(
          '/auth/login', {'email': email.trim(), 'password': password});
  Future<User> register(
          {required String name,
          required String email,
          required String password}) =>
      _authenticate('/auth/register', {
        'username': name.trim(),
        'email': email.trim(),
        'password': password
      });

  Future<User> _authenticate(String path, Map<String, String> body) async {
    final response = await http.post(Uri.parse('$_baseUrl$path'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    final data = _decode(response);
    _token = data['access_token'] as String;
    _currentUser = User.fromJson(data['user'] as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', _token!);
    await prefs.setString('current_user', jsonEncode(data['user']));
    return _currentUser!;
  }

  Future<bool> refreshVerification() async {
    final response =
        await http.get(Uri.parse('$_baseUrl/users/me'), headers: _headers);
    _currentUser = User.fromJson(_decode(response));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'current_user',
        jsonEncode({
          'id': _currentUser!.id,
          'username': _currentUser!.username,
          'email': _currentUser!.email,
          'email_verified': _currentUser!.emailVerified,
          'rating': _currentUser!.rating,
        }));
    return _currentUser!.emailVerified;
  }

  Future<void> sendVerificationEmail() async {
    final response = await http.post(
        Uri.parse('$_baseUrl/auth/resend-verification'),
        headers: _headers);
    _decode(response);
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );
    _decode(response);
  }

  Future<void> signOut() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('current_user');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token'
      };

  Map<String, dynamic> _decode(http.Response response) {
    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Request failed.');
    }
    return data;
  }
}
