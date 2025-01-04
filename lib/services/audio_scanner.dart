import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sound/models/song.dart';

class AudioScanner {
  Future<List<Song>> scanDevice() async {
    List<Song> songs = [];

    try {
      bool hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        print("Permissions non accordées");
        return [];
      }

      // Liste des chemins communs pour les fichiers audio sur Android
      List<String> commonPaths = [
        '/storage/emulated/0', // Stockage interne principal
        '/storage/emulated/0/Music', // Dossier Musique standard
        '/storage/emulated/0/Download', // Dossier Téléchargements
        '/storage/emulated/0/Android/media', // Média des applications
        '/storage/emulated/0/DCIM', // Dossier DCIM
        '/storage/emulated/0/Documents', // Documents
        '/storage/emulated/0/VidMate', // VidMate
        '/storage/emulated/0/Xender', // Xender
      ];

      // Ajouter le stockage externe s'il existe
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

      // Scanner chaque chemin
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
                print("Fichier audio trouvé: ${file.path}");
                String fileId = path.basename(file.path).hashCode.toString();

                // Vérifier si la chanson n'est pas déjà dans la liste
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
    } catch (e) {
      print("Erreur lors du scan: $e");
    }

    return songs;
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
        // Ignorer les dossiers cachés
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
