import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound/screens/home_screen.dart';
import 'package:sound/services/theme_service.dart';
import 'package:sound/services/user_preferences_service.dart';
import 'package:sound/theme/app_theme.dart';
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.yourdomain.sound.channel.audio',
    androidNotificationChannelName: 'Sound Audio Playback',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
    preloadArtwork: true,
    androidNotificationClickStartsActivity: true,
    androidStopForegroundOnPause: true,
    fastForwardInterval: const Duration(seconds: 10),
    rewindInterval: const Duration(seconds: 10),
  );

  final prefs = await SharedPreferences.getInstance();
  final themeService = ThemeService(prefs);
  final userPreferencesService = UserPreferencesService(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeService),
        Provider(create: (_) => userPreferencesService),
      ],
      child: const SoundApp(),
    ),
  );
}

class SoundApp extends StatelessWidget {
  const SoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Sound',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        );
      },
    );
  }
}