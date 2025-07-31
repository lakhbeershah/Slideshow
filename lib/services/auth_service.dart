import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _user;
  bool _isLoading = true;
  String? _verificationId;
  int? _resendToken;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  UserRole? get userRole => _user?.role;
  String? get verificationId => _verificationId;

  AuthService() {
    _initAuth();
  }

  // Initialize authentication state
  Future<void> _initAuth() async {
    try {
      _auth.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser != null) {
          // User is signed in, fetch user data from Firestore
          await _fetchUserData(firebaseUser.uid);
        } else {
          // User is signed out
          _user = null;
        }
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _user = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Send OTP to phone number
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
          throw Exception(e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          notifyListeners();
        },
        timeout: const Duration(seconds: 60),
      );
      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  // Verify OTP and sign in
  Future<bool> verifyOTP(String otp) async {
    try {
      if (_verificationId == null) {
        throw Exception('No verification ID available');
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      return await _signInWithCredential(credential);
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // Sign in with credential
  Future<bool> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      UserCredential result = await _auth.signInWithCredential(credential);
      User? firebaseUser = result.user;
      
      if (firebaseUser != null) {
        // Check if user exists in Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          // User exists, fetch data
          _user = UserModel.fromFirestore(userDoc);
        } else {
          // New user, create in Firestore
          _user = UserModel(
            id: firebaseUser.uid,
            phone: firebaseUser.phoneNumber ?? '',
            role: UserRole.customer, // Default role
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          
          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set(_user!.toMap());
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    }
  }

  // Update user role
  Future<bool> updateUserRole(UserRole role) async {
    try {
      if (_user == null) return false;
      
      _user = _user!.copyWith(role: role);
      
      await _firestore
          .collection('users')
          .doc(_user!.id)
          .update({'role': role.name});
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  // Resend OTP
  Future<bool> resendOTP(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
          throw Exception(e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          notifyListeners();
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
      return true;
    } catch (e) {
      print('Error resending OTP: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _verificationId = null;
      _resendToken = null;
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Clear verification data
  void clearVerificationData() {
    _verificationId = null;
    _resendToken = null;
    notifyListeners();
  }
}