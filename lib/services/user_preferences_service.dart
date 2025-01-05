import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound/models/song.dart';

class UserPreferencesService {
  static const String _historyKey = 'listening_history';
  static const String _favoritesKey = 'favorite_songs';
  static const String _statsKey = 'listening_stats';

  final SharedPreferences _prefs;

  UserPreferencesService(this._prefs);

  Future<void> addToHistory(Song song) async {
    final history = getListeningHistory();
    final songWithTimestamp = {
      ...song.toJson(),
      'lastPlayed': DateTime.now().toIso8601String(),
    };

    history.removeWhere((item) {
      final lastPlayed = DateTime.parse(item['lastPlayed']);
      return item['path'] == song.path &&
          DateTime.now().difference(lastPlayed).inHours < 1;
    });

    history.insert(0, songWithTimestamp);

    if (history.length > 100) {
      history.removeLast();
    }

    await _prefs.setString(_historyKey, jsonEncode(history));
    await _updateStats(song);
  }

  List<Map<String, dynamic>> getListeningHistory() {
    final String? historyJson = _prefs.getString(_historyKey);
    if (historyJson == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(historyJson));
  }

  Future<void> toggleFavorite(Song song) async {
    final favorites = getFavorites();
    final songIndex = favorites.indexWhere((s) => s['path'] == song.path);

    if (songIndex >= 0) {
      favorites.removeAt(songIndex);
    } else {
      favorites.add(song.toJson());
    }

    await _prefs.setString(_favoritesKey, jsonEncode(favorites));
  }

  List<Map<String, dynamic>> getFavorites() {
    final String? favoritesJson = _prefs.getString(_favoritesKey);
    if (favoritesJson == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(favoritesJson));
  }

  bool isFavorite(Song song) {
    final favorites = getFavorites();
    return favorites.any((s) => s['path'] == song.path);
  }

  Future<void> _updateStats(Song song) async {
    final statsJson = _prefs.getString(_statsKey);
    Map<String, dynamic> stats;

    if (statsJson == null) {
      stats = {};
    } else {
      stats = Map<String, dynamic>.from(jsonDecode(statsJson));
    }

    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month}';

    if (!stats.containsKey(dateKey)) {
      stats[dateKey] = {
        'totalPlays': 0,
        'songPlays': <String, int>{}, 
      };
    }

    final monthData = stats[dateKey] as Map<String, dynamic>;
    monthData['totalPlays'] = (monthData['totalPlays'] as int? ?? 0) + 1;

    if (!monthData.containsKey('songPlays')) {
      monthData['songPlays'] = <String, int>{};
    }

    final songPlays =
        (monthData['songPlays'] as Map<dynamic, dynamic>).cast<String, int>();
    songPlays[song.path] = (songPlays[song.path] ?? 0) + 1;
    monthData['songPlays'] = songPlays;

    await _prefs.setString(_statsKey, jsonEncode(stats));
  }

  Map<String, dynamic> getListeningStats() {
    final String? statsJson = _prefs.getString(_statsKey);
    if (statsJson == null) return {};

    return Map<String, dynamic>.from(jsonDecode(statsJson));
  }
}
