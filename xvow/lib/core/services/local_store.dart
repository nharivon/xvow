import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_models.dart';

class LocalStore {
  const LocalStore();

  static const String _fileName = 'xvow_state.json';

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, _fileName));
  }

  Future<AppSnapshot?> loadSnapshot() async {
    final file = await _file();
    if (!await file.exists()) {
      return null;
    }
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return null;
    }
    return AppSnapshot.fromJson(
      Map<String, dynamic>.from(jsonDecode(content) as Map),
    );
  }

  Future<void> saveSnapshot(AppSnapshot snapshot) async {
    final file = await _file();
    await file.writeAsString(snapshot.encode(), flush: true);
  }

  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
