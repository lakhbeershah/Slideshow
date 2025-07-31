import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:opennow/models/user_model.dart';
import 'package:opennow/services/firestore_service.dart';

/// Authentication service that handles Firebase Auth operations
/// Supports phone number OTP authentication for both shop owners and customers
class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Current user and authentication state
  User? _firebaseUser;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _verificationId;
  String? _errorMessage;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null && _currentUser != null;

  /// Initialize auth service and listen to auth state changes
  AuthService() {
    _initializeAuthListener();
  }

  /// Set up Firebase Auth state listener
  void _initializeAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      
      if (user != null) {
        // User is signed in, fetch user data from Firestore
        await _loadUserData(user.uid);
      } else {
        // User is signed out
        _currentUser = null;
      }
      
      notifyListeners();
    });
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      _currentUser = await _firestoreService.getUser(uid);
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _currentUser = null;
    }
  }

  /// Send OTP to the provided phone number
  /// Phone number should be in international format (+1234567890)
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      _setLoading(true);
      _clearError();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _setError('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          debugPrint('OTP sent to $phoneNumber');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );

      return true;
    } catch (e) {
      _setError('Failed to send OTP: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify OTP and complete authentication
  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) {
      _setError('No verification ID found. Please request OTP again.');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _signInWithCredential(credential);
      return true;
    } catch (e) {
      _setError('Invalid OTP: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with phone auth credential
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;
      
      if (user != null) {
        // Check if user exists in Firestore
        UserModel? existingUser = await _firestoreService.getUser(user.uid);
        
        if (existingUser == null) {
          // New user - will need to complete profile setup
          debugPrint('New user signed in: ${user.phoneNumber}');
        } else {
          // Existing user
          debugPrint('Existing user signed in: ${existingUser.name}');
        }
      }
    } catch (e) {
      _setError('Authentication failed: $e');
      rethrow;
    }
  }

  /// Create user profile after successful authentication
  Future<bool> createUserProfile({
    required String name,
    required UserRole role,
  }) async {
    if (_firebaseUser == null) {
      _setError('No authenticated user found');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      UserModel newUser = UserModel(
        id: _firebaseUser!.uid,
        phoneNumber: _firebaseUser!.phoneNumber ?? '',
        name: name,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createUser(newUser);
      _currentUser = newUser;
      
      debugPrint('User profile created successfully');
      return true;
    } catch (e) {
      _setError('Failed to create user profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile({
    String? name,
    UserRole? role,
  }) async {
    if (_currentUser == null) {
      _setError('No user logged in');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      UserModel updatedUser = _currentUser!.copyWith(
        name: name,
        role: role,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateUser(updatedUser);
      _currentUser = updatedUser;
      
      debugPrint('User profile updated successfully');
      return true;
    } catch (e) {
      _setError('Failed to update user profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _auth.signOut();
      _currentUser = null;
      _verificationId = null;
      _clearError();
      debugPrint('User signed out successfully');
    } catch (e) {
      _setError('Failed to sign out: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user needs to complete profile setup
  bool get needsProfileSetup {
    return _firebaseUser != null && _currentUser == null;
  }

  /// Resend OTP with the same phone number
  Future<bool> resendOTP() async {
    if (_firebaseUser?.phoneNumber == null) {
      _setError('No phone number found');
      return false;
    }

    return await sendOTP(_firebaseUser!.phoneNumber!);
  }

  /// Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    debugPrint('Auth Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear any existing error messages
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    super.dispose();
  }
}