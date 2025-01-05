class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final Duration duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.duration,
  });

  // Conversion en JSON pour le stockage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'path': path,
      'duration': duration.inSeconds,
    };
  }

  // Construction depuis JSON
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      path: json['path'],
      duration: Duration(seconds: json['duration']),
    );
  }

  // Égalité basée sur le path qui est unique
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;
}