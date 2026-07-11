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
  const DigiMinutoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigiMinuto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
