import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  static const _tokenKey = 'auth_token';

  User? _user;
  String? _token;
  bool _isLoading = true;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    if (_token != null) {
      try {
        _user = await _authService.getMe(_token!);
      } catch (_) {
        _token = null;
        await prefs.remove(_tokenKey);
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final result = await _authService.login(email: email, password: password);
    _token = result.token;
    _user = await _authService.getMe(_token!);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    await _authService.register(
      email: email,
      firstName: firstName,
      lastName: lastName,
      password: password,
    );
    // Auto-login after registration
    await login(email: email, password: password);
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
  }
}
