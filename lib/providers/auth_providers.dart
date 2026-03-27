import 'dart:async';

import 'package:booking_app/providers/booking_providers.dart';
import 'package:booking_app/providers/chat_providers.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:booking_app/providers/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../services/auth_services.dart';
import '../services/firebase_services.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _authSubscription;

  // Flag: lần đầu mở app (đang check auth state)
  bool _isInit = true;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _initAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _initAuthListener() {
    _authSubscription =
        _firebaseService.authStateChanges.listen((User? authUser) async {
          // lần đầu mở app: hiển thị loading
          if (_isInit) {
            _isLoading = true;
            notifyListeners();
          }

          if (authUser == null) {
            _currentUser = null;
          } else {
            // nếu khác uid mới load lại dữ liệu
            if (_currentUser?.uid != authUser.uid) {
              _currentUser = await _authService.getCurrentUserData();
            }
          }

          _isInit = false;
          _isLoading = false;
          notifyListeners();
        });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentUser =
      await _authService.signIn(email: email, password: password);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ FIX: Đăng xuất không bị quay mãi
  /// - set loading đúng chuẩn try/finally
  /// - điều hướng về '/auth' để thoát khỏi HomeScreen
  Future<void> signOut(BuildContext context) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Clear listeners của các provider khác trước khi sign out
      context.read<HotelProvider>().disposeListeners();
      context.read<BookingProvider>().disposeListeners();
      context.read<ChatProvider>().disposeListeners();
      context.read<ReportProvider>().disposeListeners();

      await _authService.signOut();
      // authStateChanges sẽ set _currentUser = null (ở listener)
      // nhưng ta có thể set trước để UI update nhanh
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // ✅ QUAN TRỌNG: rời HomeScreen -> AuthWrapper
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (r) => false);
      // Nếu bạn muốn về HomeBeforeLogin thì đổi thành '/intro'
    }
  }

  Future<bool> resetPassword(String email) async {
    bool success = false;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);
      success = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
  }) async {
    try {
      if (_currentUser == null) {
        throw 'User not logged in';
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.updateUserProfile(
        uid: _currentUser!.uid,
        name: name,
        phone: phone,
      );

      // Update local user object
      _currentUser = _currentUser!.copyWith(name: name, phone: phone);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
