import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final instance = SettingsService._();
  bool _moveSounds = true;
  bool get moveSounds => _moveSounds;
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _moveSounds = prefs.getBool('move_sounds') ?? true;
    notifyListeners();
  }

  Future<void> setMoveSounds(bool value) async {
    _moveSounds = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('move_sounds', value);
  }
}
