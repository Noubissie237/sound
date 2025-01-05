class Playlist {
  String id;
  String name;
  String? description;
  List<String> songIds; 
  DateTime createdAt;
  DateTime updatedAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : songIds = songIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'songIds': songIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        songIds: List<String>.from(json['songIds']),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}
