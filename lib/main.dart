import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  await loadSavedSettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Opticell',

          themeMode: currentMode,

          // LIGHT THEME
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.white,

            cardColor: Colors.white,

            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF101828),
              elevation: 0,
            ),

            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF101828)),
              bodyMedium: TextStyle(color: Color(0xFF6A7282)),
              titleLarge: TextStyle(
                color: Color(0xFF101828),
                fontWeight: FontWeight.bold,
              ),
            ),

            dividerColor: const Color(0xFFE5E7EB),
          ),

          // DARK THEME
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,

            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),

            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor: Colors.white,
              elevation: 0,
            ),

            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              titleLarge: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            dividerColor: Colors.white12,
          ),

          routes: {'/login': (_) => const LoginScreen()},
          home: const SplashScreen(),
        );
      },
    );
  }
}