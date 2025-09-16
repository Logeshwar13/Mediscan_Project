import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;

  // Initialize and check if user is already logged in
  Future<void> init() async {
    debugPrint('=== UserProvider init() started ===');
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      debugPrint('SharedPreferences keys: ${prefs.getKeys()}');
      
      // Check for both possible key names (your login page uses different keys)
      final userJson = prefs.getString('user') ?? prefs.getString('user_data');
      final token = prefs.getString('token') ?? prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      
      debugPrint('Found userJson: ${userJson != null}');
      debugPrint('Found token: ${token != null}');
      debugPrint('Found userId: $userId');

      if (userJson != null && token != null) {
        try {
          final userData = jsonDecode(userJson);
          _user = UserModel.fromJson(userData);
          _isLoggedIn = true;
          
          // Set the token in ApiService
          ApiService.setCurrentUser(_user!.id, token);
          
          debugPrint('User initialized successfully: ${_user!.name}, ID: ${_user!.id}');
        } catch (e) {
          debugPrint('Error parsing user data: $e');
          // Clear corrupted data
          await _clearStoredData();
        }
      } else {
        debugPrint('No complete user data found in storage');
      }
    } catch (e) {
      debugPrint('Error initializing user: $e');
      await _clearStoredData();
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('=== UserProvider init() completed ===');
    }
  }

  // Clear stored data helper
  Future<void> _clearStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove('user_data');
      await prefs.remove('token');
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      
      _user = null;
      _isLoggedIn = false;
      ApiService.clearUserData();
    } catch (e) {
      debugPrint('Error clearing stored data: $e');
    }
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    debugPrint('=== UserProvider login() started ===');
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.login(email, password);
      debugPrint('API login result: $result');
      
      if (result['success']) {
        _user = result['user'];
        _isLoggedIn = true;
        
        // Save to SharedPreferences using consistent keys
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user!.toJson()));
        await prefs.setString('token', result['token']);
        await prefs.setString('user_id', _user!.id);
        
        debugPrint('Login successful, user saved: ${_user!.name}');
        notifyListeners();
        return {'success': true, 'message': result['message']};
      } else {
        debugPrint('Login failed: ${result['error']}');
        return {'success': false, 'error': result['error']};
      }
    } catch (e) {
      debugPrint('Login exception: $e');
      return {'success': false, 'error': 'Login failed: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('=== UserProvider login() completed ===');
    }
  }

  // Signup user
  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    debugPrint('=== UserProvider signup() started ===');
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.signup(name, email, password, phone);
      debugPrint('API signup result: $result');
      
      if (result['success']) {
        _user = result['user'];
        _isLoggedIn = true;
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user!.toJson()));
        await prefs.setString('token', result['token']);
        await prefs.setString('user_id', _user!.id);
        
        debugPrint('Signup successful, user saved: ${_user!.name}');
        notifyListeners();
        return {'success': true, 'message': result['message']};
      } else {
        debugPrint('Signup failed: ${result['error']}');
        return {'success': false, 'error': result['error']};
      }
    } catch (e) {
      debugPrint('Signup exception: $e');
      return {'success': false, 'error': 'Signup failed: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('=== UserProvider signup() completed ===');
    }
  }

  // Logout user
  Future<void> logout() async {
    debugPrint('=== UserProvider logout() started ===');
    try {
      await _clearStoredData();
      debugPrint('User logged out successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
    debugPrint('=== UserProvider logout() completed ===');
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    if (_user == null) {
      return {'success': false, 'error': 'User not logged in'};
    }

    debugPrint('=== UserProvider updateProfile() started ===');
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.updateProfile(
        name: name ?? _user!.name,
        phone: phone ?? _user!.phone,
        address: address ?? _user!.address,
      );

      if (result['success']) {
        _user = result['user'];
        
        // Save updated user to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user!.toJson()));
        
        debugPrint('Profile updated successfully: ${_user!.name}');
        notifyListeners();
        return {'success': true, 'message': result['message']};
      } else {
        debugPrint('Profile update failed: ${result['error']}');
        return {'success': false, 'error': result['error']};
      }
    } catch (e) {
      debugPrint('Profile update exception: $e');
      return {'success': false, 'error': 'Failed to update profile: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('=== UserProvider updateProfile() completed ===');
    }
  }

  // Refresh user data from server
  Future<void> refreshUser() async {
    debugPrint('=== UserProvider refreshUser() started ===');
    
    if (!_isLoggedIn) {
      debugPrint('Cannot refresh user: not logged in');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.getProfile();
      debugPrint('API getProfile result: $result');
      
      if (result['success']) {
        _user = result['user'];
        
        // Save updated user to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user!.toJson()));
        
        debugPrint('User data refreshed from server: ${_user!.name}');
      } else {
        debugPrint('Failed to refresh user data: ${result['error']}');
        // Keep existing data if API fails
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
      // Keep existing data if there's an exception
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('=== UserProvider refreshUser() completed ===');
    }
  }

  // Check authentication status
  bool get isAuthenticated => _isLoggedIn && _user != null;
  
  // Get user name for display
  String get userName => _user?.name ?? 'User';
  
  // Get user email
  String get userEmail => _user?.email ?? '';
  
  // Debug method to print current state
  void debugCurrentState() {
    debugPrint('=== UserProvider Debug State ===');
    debugPrint('User: $_user');
    debugPrint('Is logged in: $_isLoggedIn');
    debugPrint('Is loading: $_isLoading');
    debugPrint('Is authenticated: $isAuthenticated');
    debugPrint('================================');
  }
}