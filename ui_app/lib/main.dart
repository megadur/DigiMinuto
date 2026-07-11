import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';
import 'services/app_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppServices.instance.init();
  runApp(const DigiMinutoApp());
}

class DigiMinutoApp extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  const DigiMinutoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'DigiMinuto',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
            colorScheme: const ColorScheme.light(
              surface: Colors.white,
              onSurface: Colors.black87,
              primary: Color(0xFF6366F1), // Indigo
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
              bodyColor: Colors.black87,
              displayColor: Colors.black87,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
            colorScheme: const ColorScheme.dark(
              surface: Color(0xFF1E293B), // Slate 800
              onSurface: Colors.white,
              primary: Color(0xFF6366F1), // Indigo
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            useMaterial3: true,
          ),
          home: const DashboardScreen(),
        );
      },
    );
  }
}
