import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/game_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  // ✅ STEP 1: Flutter bindings ensure karna
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ STEP 2: Firebase initialize karna
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Agar koi Firebase error aaye toh console mein print ho jaye
    debugPrint("Firebase Init Error: $e");
  }

  runApp(const SmartDiceApp());
}

class SmartDiceApp extends StatelessWidget {
  const SmartDiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Dice Arena',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        // ✅ Splash Screen se start hogi app
        home: const SplashScreen(),
      ),
    );
  }
}