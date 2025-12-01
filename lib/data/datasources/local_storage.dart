import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cheat_day_model.dart';
import '../models/cheat_memo_model.dart';

class LocalStorage {
  static const String _cheatDaysKey = 'cheat_days';
  static const String _cheatMemosKey = 'cheat_memos';

  Future<List<CheatDayModel>> getCheatDays() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_cheatDaysKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => CheatDayModel.fromJson(json)).toList();
  }

  Future<void> saveCheatDays(List<CheatDayModel> cheatDays) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = cheatDays.map((day) => day.toJson()).toList();
    await prefs.setString(_cheatDaysKey, json.encode(jsonList));
  }

  Future<List<CheatMemoModel>> getCheatMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_cheatMemosKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => CheatMemoModel.fromJson(json)).toList();
  }

  Future<void> saveCheatMemos(List<CheatMemoModel> memos) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = memos.map((memo) => memo.toJson()).toList();
    await prefs.setString(_cheatMemosKey, json.encode(jsonList));
  }

  Future<String> saveImage(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String fileName = 'cheat_day_$timestamp.jpg';
    final String filePath = '${directory.path}/$fileName';

    await imageFile.copy(filePath);
    return filePath;
  }

  Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
