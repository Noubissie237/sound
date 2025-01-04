import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound/screens/playlist_screen.dart';
import 'package:sound/services/audio_player_service.dart';
import 'package:sound/services/playlist_storage_service.dart';
import 'package:sound/services/theme_service.dart';
import 'package:sound/widgets/song_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPermission = false;
  late final AudioPlayerService _playerService;

  @override
  void initState() {
    super.initState();
    _playerService = AudioPlayerService(); // Initialisez le service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  Future _checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        if (deviceInfo.version.sdkInt >= 33) {
          // Android 13 et supérieur
          final audioStatus = await Permission.audio.request();
          setState(() {
            _hasPermission = audioStatus.isGranted;
          });
        } else {
          // Android 12 et inférieur
          final storageStatus = await Permission.storage.request();
          setState(() {
            _hasPermission = storageStatus.isGranted;
          });
        }
      } else {
        setState(() {
          _hasPermission = true;
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification des permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de permission: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: () {
              _playerService.playlistManager.shuffle();
              setState(() {}); // Rafraîchir la liste
            },
          ),
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistsScreen(
                      storageService: PlaylistStorageService(prefs),
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              Provider.of<ThemeService>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              Provider.of<ThemeService>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: _hasPermission
          ? const SongList()
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Permission d\'accès aux fichiers requise'),
                  ElevatedButton(
                    onPressed: _checkPermissions,
                    child: const Text('Autoriser l\'accès'),
                  ),
                ],
              ),
            ),
    );
  }
}
