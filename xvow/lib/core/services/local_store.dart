import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class LocalStore {
  const LocalStore();

  // Kept for hot-reload compatibility with previous class shape.
  static const String _fileName = 'xvow_state.json';
  static const String _storageKey = 'xvow_state_json';

  Future<AppSnapshot?> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final content = prefs.getString(_storageKey);
    if (content == null) {
      return null;
    }
    if (content.trim().isEmpty) {
      return null;
    }
    return AppSnapshot.fromJson(
      Map<String, dynamic>.from(jsonDecode(content) as Map),
    );
  }

  Future<void> saveSnapshot(AppSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, snapshot.encode());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
