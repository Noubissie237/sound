import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sound/models/song.dart';

class AudioScanner {
  // Singleton instance
  static AudioScanner? _instance;
  // Cache des songs
  List<Song>? _cachedSongs;
  // Flag pour suivre si un scan est en cours
  bool _isScanning = false;

  // Constructeur privé
  AudioScanner._();

  // Méthode factory pour obtenir l'instance
  factory AudioScanner() {
    _instance ??= AudioScanner._();
    return _instance!;
  }

  Future<List<Song>> scanDevice() async {
    // Si nous avons déjà des songs en cache, les retourner
    if (_cachedSongs != null) {
      print("Returning cached songs: ${_cachedSongs!.length} songs");
      return _cachedSongs!;
    }

    // Si un scan est déjà en cours, attendre qu'il se termine
    if (_isScanning) {
      print("Scan already in progress, waiting...");
      while (_isScanning) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedSongs ?? [];
    }

    _isScanning = true;
    List<Song> songs = [];

    try {
      print("Starting new scan...");
      bool hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        print("Permissions non accordées");
        _isScanning = false;
        return [];
      }

      List<String> commonPaths = [
        '/storage/emulated/0',
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Android/media',
        '/storage/emulated/0/VidMate',
        '/storage/emulated/0/Xender',
      ];

      try {
        Directory('/storage').listSync().forEach((entity) {
          if (entity.path != '/storage/emulated' &&
              entity.path != '/storage/self' &&
              !entity.path.contains('emulated/0')) {
            commonPaths.add(entity.path);
          }
        });
      } catch (e) {
        print("Erreur lors de la recherche du stockage externe: $e");
      }

      print("Dossiers à scanner: ${commonPaths.join(', ')}");

      for (String directoryPath in commonPaths) {
        Directory directory = Directory(directoryPath);
        if (await directory.exists()) {
          print("Scan du dossier: $directoryPath");
          List<FileSystemEntity> files = await _getAllFiles(directory);
          print("Fichiers trouvés dans $directoryPath: ${files.length}");

          for (var file in files) {
            if (file is File) {
              String extension = path.extension(file.path).toLowerCase();
              if (['.mp3', '.m4a', '.wav', '.aac', '.ogg', '.flac']
                  .contains(extension)) {
                String fileId = path.basename(file.path).hashCode.toString();
                if (!songs.any((song) => song.path == file.path)) {
                  songs.add(Song(
                    id: fileId,
                    title: path.basenameWithoutExtension(file.path),
                    artist: 'Unknown Artist',
                    album: 'Unknown Album',
                    path: file.path,
                    duration: const Duration(seconds: 0),
                  ));
                }
              }
            }
          }
        }
      }

      print("Nombre total de chansons trouvées: ${songs.length}");
      _cachedSongs = songs;
    } catch (e) {
      print("Erreur lors du scan: $e");
    } finally {
      _isScanning = false;
    }

    return _cachedSongs ?? [];
  }

  // Méthode pour forcer un nouveau scan
  Future<List<Song>> rescan() async {
    print("Forcing rescan...");
    _cachedSongs = null;
    return scanDevice();
  }

  // Méthode pour vider le cache
  void clearCache() {
    print("Clearing song cache");
    _cachedSongs = null;
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      print("Version Android SDK: ${deviceInfo.version.sdkInt}");

      if (deviceInfo.version.sdkInt >= 33) {
        final audio = await Permission.audio.request();
        print("Statut permission audio: ${audio.isGranted}");
        return audio.isGranted;
      } else {
        final storage = await Permission.storage.request();
        print("Statut permission storage: ${storage.isGranted}");
        return storage.isGranted;
      }
    }
    return true;
  }

  Future<List<FileSystemEntity>> _getAllFiles(Directory dir) async {
    List<FileSystemEntity> files = [];
    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (!path.basename(entity.path).startsWith('.')) {
          files.add(entity);
        }
      }
    } catch (e) {
      print("Erreur lors de la lecture du répertoire ${dir.path}: $e");
    }
    return files;
  }
}
