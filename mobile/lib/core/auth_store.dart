import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

/// Holds the signed-in session and persists it with shared_preferences.
///
/// Good enough for a prototype: the JWT lives in app-private storage rather
/// than in memory only, so a restart keeps you logged in.
class AuthStore extends ChangeNotifier {
  AuthStore._();

  static final AuthStore instance = AuthStore._();

  static const String _tokenKey = 'fleetx.jwt';
  static const String _userKey = 'fleetx.user';

  String? _token;
  AppUser? _user;
  bool _ready = false;

  String? get token => _token;
  AppUser? get user => _user;

  /// False until [restore] finishes, so the splash screen knows to wait.
  bool get isReady => _ready;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  /// Reads any previously saved session off disk.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final rawUser = prefs.getString(_userKey);
    if (rawUser != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
      }
    }
    // A token without a user (or the reverse) is not a usable session.
    if (_token == null || _user == null) {
      _token = null;
      _user = null;
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> save(String token, AppUser user) async {
    _token = token;
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    notifyListeners();
  }

  /// Keeps the stored profile in sync after an edit or a `/auth/me` refresh.
  Future<void> updateUser(AppUser user) async {
    if (_token == null) return;
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }
}
