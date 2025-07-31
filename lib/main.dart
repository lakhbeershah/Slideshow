import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:opennow/app.dart';
import 'package:opennow/services/auth_service.dart';
import 'package:opennow/services/firestore_service.dart';
import 'package:opennow/services/location_service.dart';
import 'package:opennow/services/geofence_service.dart';

/// Main entry point of the OpenNow application
/// Initializes Firebase and sets up service providers
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // TODO: Add your Firebase configuration files (google-services.json for Android, GoogleService-Info.plist for iOS)
  await Firebase.initializeApp(
    // TODO: Uncomment and configure with your Firebase project settings
    // options: const FirebaseOptions(
    //   apiKey: "your-api-key",
    //   authDomain: "your-project.firebaseapp.com",
    //   projectId: "your-project-id",
    //   storageBucket: "your-project.appspot.com",
    //   messagingSenderId: "123456789",
    //   appId: "1:123456789:android:abc123def456",
    // ),
  );
  
  runApp(
    /// Multi-provider setup for dependency injection
    /// All services are available throughout the app via Provider
    MultiProvider(
      providers: [
        /// Authentication service - handles Firebase Auth and OTP
        ChangeNotifierProvider(create: (context) => AuthService()),
        
        /// Firestore service - handles all database operations
        Provider(create: (context) => FirestoreService()),
        
        /// Location service - handles device location tracking
        Provider(create: (context) => LocationService()),
        
        /// Geofence service - handles shop open/close logic based on location
        ChangeNotifierProvider(create: (context) => GeofenceService()),
      ],
      child: const OpenNowApp(),
    ),
  );
}