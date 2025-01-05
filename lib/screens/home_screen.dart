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
import 'package:sound/services/user_preferences_service.dart';
import 'package:sound/widgets/song_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _hasPermission = false;
  late final AudioPlayerService _playerService;
  late final TabController _tabController;
  late final UserPreferencesService preferencesService;

  @override
  void initState() {
    super.initState();
    _playerService = AudioPlayerService();
    _tabController = TabController(length: 4, vsync: this);
    _initializeServices();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    preferencesService = UserPreferencesService(prefs);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    return DefaultTabController(
      length: 4,
      child: Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.8),
                    Theme.of(context).primaryColor.withOpacity(0.2),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    "assets/img/music.png",
                    width: 35,
                    height: 35,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sound',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.music_note), text: 'Musique'),
                Tab(icon: Icon(Icons.favorite), text: 'Favoris'),
                Tab(icon: Icon(Icons.history), text: 'Historique'),
                Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
              ],
            ),
            actions: [
              // Bouton Shuffle avec animation
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.shuffle),
                  tooltip: 'Mélanger',
                  onPressed: () {
                    _playerService.playlistManager.shuffle();
                    setState(() {});
                  },
                ),
              ),
              // Bouton Playlist
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.playlist_play),
                  tooltip: 'Playlists',
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
              ),
              // Bouton Theme avec animation
              Container(
                margin: const EdgeInsets.only(right: 8, left: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return RotationTransition(
                      turns: animation,
                      child: child,
                    );
                  },
                  child: IconButton(
                    key: ValueKey<bool>(
                      Provider.of<ThemeService>(context).isDarkMode,
                    ),
                    icon: Icon(
                      Provider.of<ThemeService>(context).isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    tooltip: Provider.of<ThemeService>(context).isDarkMode
                        ? 'Mode clair'
                        : 'Mode sombre',
                    onPressed: () {
                      Provider.of<ThemeService>(context, listen: false)
                          .toggleTheme();
                    },
                  ),
                ),
              ),
            ],
          ),
          body: _hasPermission
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    const SongList(filter: SongListFilter.all),
                    const SongList(filter: SongListFilter.favorites),
                    const SongList(filter: SongListFilter.history),
                    const SongList(filter: SongListFilter.stats),
                  ],
                )
              : Center(
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.folder_open,
                            size: 48,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Permission d\'accès aux fichiers requise',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pour pouvoir acceder à vos fichier et charger la musique, l\'application a besoin d\'accéder à vos fichiers.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _checkPermissions,
                            icon: const Icon(Icons.security),
                            label: const Text('Autoriser l\'accès'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
    );
  }
}
