import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';

class LocalStorageService {
  static const String _storageKey = 'studySmartData';

  Future<UserData?> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return UserData.fromJson(jsonMap);
    } catch (e) {
      // ignore: avoid_print
      print('Error loading user data: $e');
      return null;
    }
  }

  Future<bool> saveUserData(UserData userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(userData.toJson());
      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      // ignore: avoid_print
      print('Error saving user data: $e');
      return false;
    }
  }

  Future<bool> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      // ignore: avoid_print
      print('Error clearing user data: $e');
      return false;
    }
  }
}
