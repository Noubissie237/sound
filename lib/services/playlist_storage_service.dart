import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:sound/models/playlist.dart';

class PlaylistStorageService {
  static const String _key = 'playlists';
  final _uuid = const Uuid();
  final SharedPreferences _prefs;

  PlaylistStorageService(this._prefs);

  Future<List<Playlist>> getPlaylists() async {
    final String? playlistsJson = _prefs.getString(_key);
    if (playlistsJson == null) return [];

    final List<dynamic> decoded = json.decode(playlistsJson);
    return decoded.map((item) => Playlist.fromJson(item)).toList();
  }

  Future<void> savePlaylists(List<Playlist> playlists) async {
    final String encoded = json.encode(playlists.map((p) => p.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }

  Future<Playlist> createPlaylist(String name, {String? description}) async {
    final playlists = await getPlaylists();
    final newPlaylist = Playlist(
      id: _uuid.v4(),
      name: name,
      description: description,
    );
    playlists.add(newPlaylist);
    await savePlaylists(playlists);
    return newPlaylist;
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    final playlists = await getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      playlist.updatedAt = DateTime.now();
      playlists[index] = playlist;
      await savePlaylists(playlists);
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final playlists = await getPlaylists();
    playlists.removeWhere((p) => p.id == playlistId);
    await savePlaylists(playlists);
  }
}