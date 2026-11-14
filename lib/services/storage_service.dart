import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/student.dart';
import '../models/message.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // API Base URL Setting
  static String getApiBaseUrl() {
    return _prefs?.getString(AppConstants.keyApiUrl) ?? AppConstants.defaultBaseUrl;
  }

  static Future<void> setApiBaseUrl(String url) async {
    await _prefs?.setString(AppConstants.keyApiUrl, url.trim());
  }

  // Student Profile
  static Student? getStudent() {
    final str = _prefs?.getString(AppConstants.keyStudentProfile);
    if (str == null) return null;
    try {
      return Student.fromJson(jsonDecode(str));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveStudent(Student student) async {
    await _prefs?.setString(AppConstants.keyStudentProfile, jsonEncode(student.toJson()));
  }

  static Future<void> clearStudent() async {
    await _prefs?.remove(AppConstants.keyStudentProfile);
  }

  // Chat History
  static List<ChatMessage> getChatHistory() {
    final str = _prefs?.getString(AppConstants.keyChatHistory);
    if (str == null) return [];
    try {
      final List list = jsonDecode(str);
      return list.map((item) => ChatMessage.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final list = messages.map((m) => m.toJson()).toList();
    await _prefs?.setString(AppConstants.keyChatHistory, jsonEncode(list));
  }

  static Future<void> clearChatHistory() async {
    await _prefs?.remove(AppConstants.keyChatHistory);
  }

  // Bookmarks
  static List<ChatMessage> getBookmarks() {
    final str = _prefs?.getString(AppConstants.keyBookmarks);
    if (str == null) return [];
    try {
      final List list = jsonDecode(str);
      return list.map((item) => ChatMessage.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> toggleBookmark(ChatMessage msg) async {
    final bookmarks = getBookmarks();
    final index = bookmarks.indexWhere((m) => m.id == msg.id);
    if (index >= 0) {
      bookmarks.removeAt(index);
      msg.isBookmarked = false;
    } else {
      msg.isBookmarked = true;
      bookmarks.insert(0, msg);
    }
    final list = bookmarks.map((m) => m.toJson()).toList();
    await _prefs?.setString(AppConstants.keyBookmarks, jsonEncode(list));
  }

  // Dark Mode
  static bool isDarkMode() {
    return _prefs?.getBool(AppConstants.keyDarkMode) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    await _prefs?.setBool(AppConstants.keyDarkMode, value);
  }
}
