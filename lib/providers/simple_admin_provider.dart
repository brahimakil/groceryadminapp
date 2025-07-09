import 'package:flutter/foundation.dart';
import '../services/simple_auth_service.dart';

class SimpleAdminProvider extends ChangeNotifier {
  final SimpleAuthService _authService = SimpleAuthService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _authService.isLoggedIn;
  Map<String, dynamic>? get adminData => _authService.currentAdminData;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    bool success = await _authService.loginAdmin(email, password);
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    
    bool success = await _authService.registerAdmin(email, password, name);
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  void logout() {
    _authService.logout();
    notifyListeners();
  }
} 