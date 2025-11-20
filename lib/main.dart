// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/exercise_selection_screen.dart';
import 'screens/exercise_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AiFitnessApp());
}

class AiFitnessApp extends StatefulWidget {
  const AiFitnessApp({super.key});

  @override
  State<AiFitnessApp> createState() => _AiFitnessAppState();
}

class _AiFitnessAppState extends State<AiFitnessApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Fitness Coach',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      routes: {
        '/': (c) => const LoginScreen(),
        '/signup': (c) => const SignUpScreen(),
        '/dashboard': (c) => DashboardScreen(onToggleTheme: _toggleTheme),
        '/reset': (c) => const ResetPasswordScreen(),
        '/profile': (c) => const ProfileScreen(),
        '/exercise_select': (c) => const ExerciseSelectionScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/exercise') {
          final args = settings.arguments as Map<String, dynamic>?;
          final exercise = args?['exercise'] ?? 'pushup';
          return MaterialPageRoute(builder: (_) => ExerciseScreen(exercise: exercise));
        }
        return null;
      },
    );
  }
}
