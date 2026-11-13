import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/fishing_screen.dart';
import 'services/angler_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Full-screen portrait orientation lock
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // True full-screen immersive mode (hides status bar & nav bar)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // System bar overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize offline storage & default tackle inventory
  await AnglerStorage.init();

  runApp(const DaReelBaitApp());
}

class DaReelBaitApp extends StatelessWidget {
  const DaReelBaitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Da Reel Bait',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A10),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFFB300),
          surface: Color(0xFF14141E),
        ),
      ),
      home: const FishingScreen(),
    );
  }
}
