import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/audio/sound_manager.dart';
import 'core/services/save_manager.dart';
import 'ui/screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved data and preload audio assets into RAM
  await SaveManager.instance.init();
  await SoundManager.instance.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0F14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const LeftRightApp());
}

class LeftRightApp extends StatelessWidget {
  const LeftRightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Left-Right: Tune Your Brain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
      ),
      home: const GameScreen(),
    );
  }
}