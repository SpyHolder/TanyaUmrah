import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/message.dart';
import '../models/student.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static String? _accountId;
  static String? get accountId => _accountId;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _accountId = null;
    // Legacy data has no verified owner; never attach it to a Firebase account.
    for (final key in [
      AppConstants.keyStudentProfile,
      AppConstants.keyChatHistory,
      AppConstants.keyBookmarks,
      'tanya_umrah_api_url',
    ]) {
      await _prefs!.remove(key);
    }
  }

  static void useAccount(String? uid) => _accountId = uid;
  static String? _key(String name) =>
      _accountId == null ? null : '$_accountId:$name';

  static Student? getStudent() {
    final key = _key(AppConstants.keyStudentProfile);
    final text = key == null ? null : _prefs?.getString(key);
    if (text == null) return null;
    try {
      return Student.fromJson(jsonDecode(text));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveStudent(Student student) async {
    final key = _key(AppConstants.keyStudentProfile);
    if (key != null) await _prefs!.setString(key, jsonEncode(student.toJson()));
  }

  static List<ChatMessage> _messages(String name) {
    final key = _key(name);
    final text = key == null ? null : _prefs?.getString(key);
    if (text == null) return [];
    try {
      return (jsonDecode(text) as List)
          .map((item) => ChatMessage.fromJson(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<ChatMessage> getChatHistory() {
    final bookmarks = getBookmarks().map((m) => m.id).toSet();
    return _messages(AppConstants.keyChatHistory)..forEach(
      (message) => message.isBookmarked = bookmarks.contains(message.id),
    );
  }

  static Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final key = _key(AppConstants.keyChatHistory);
    if (key == null) return;
    await _prefs!.setString(
      key,
      jsonEncode(messages.map((m) => m.toJson()).toList()),
    );
  }

  static String? getConversationId() {
    final key = _key('conversation_id');
    return key == null ? null : _prefs?.getString(key);
  }

  static Future<void> saveConversationId(String? id) async {
    final key = _key('conversation_id');
    if (key == null) return;
    if (id == null) {
      await _prefs!.remove(key);
    } else {
      await _prefs!.setString(key, id);
    }
  }

  static Future<void> clearChatHistory() async {
    final key = _key(AppConstants.keyChatHistory);
    if (key != null) await _prefs!.remove(key);
    await saveConversationId(null);
  }

  static List<ChatMessage> getBookmarks() =>
      _messages(AppConstants.keyBookmarks);

  static Future<void> toggleBookmark(ChatMessage message) async {
    final key = _key(AppConstants.keyBookmarks);
    if (key == null) return;
    final bookmarks = getBookmarks();
    final exists = bookmarks.any((m) => m.id == message.id);
    bookmarks.removeWhere((m) => m.id == message.id);
    message.isBookmarked = !exists;
    if (!exists) bookmarks.insert(0, message);
    await _prefs!.setString(
      key,
      jsonEncode(bookmarks.map((m) => m.toJson()).toList()),
    );
  }
}
