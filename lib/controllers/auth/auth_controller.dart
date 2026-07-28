import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _loading = false;
  String? _errorMessage;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  User? get currentUser => _authService.currentUser;
  bool get isEmailVerified => _authService.isEmailVerified;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Returns true on success, false on failure (errorMessage will be set)
  Future<bool> login({required String email, required String password}) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await _authService.signIn(email: email, password: password);
      await _authService.reloadUser();
      await NotificationService.loginUser(_authService.currentUser!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Login failed';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await _authService.signUp(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      await NotificationService.loginUser(_authService.currentUser!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Sign up failed';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    _errorMessage = null;
    if (email.trim().isEmpty) {
      _errorMessage = 'Enter your email first';
      notifyListeners();
      return false;
    }
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Failed to send reset email';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    _setLoading(true);
    try {
      await _authService.sendEmailVerification();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send email: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refreshes the Firebase user and reports whether they're verified now
  Future<bool> checkVerificationStatus() async {
    try {
      await _authService.reloadUser();
      return isEmailVerified;
    } catch (_) {
      // Ignore transient errors, caller keeps polling
      return false;
    }
  }

  Future<void> logout() async {
    await NotificationService.logoutUser();
    await _authService.signOut();
    notifyListeners();
  }
}
