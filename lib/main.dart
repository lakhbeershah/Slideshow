import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      // TODO: Replace with your Firebase configuration
      apiKey: "YOUR_FIREBASE_API_KEY",
      appId: "YOUR_FIREBASE_APP_ID", 
      messagingSenderId: "YOUR_SENDER_ID",
      projectId: "YOUR_PROJECT_ID",
      // For Android, add: storageBucket: "YOUR_STORAGE_BUCKET"
    ),
  );
  
  runApp(const OpenNowApp());
}

class OpenNowApp extends StatelessWidget {
  const OpenNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const App(),
    );
  }
}