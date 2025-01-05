import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sound/models/song.dart';
import 'package:sound/services/user_preferences_service.dart';
import 'package:sound/services/audio_player_service.dart';

class HistoryList extends StatefulWidget {
  final UserPreferencesService preferencesService;

  const HistoryList({
    super.key,
    required this.preferencesService,
  });

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _history = widget.preferencesService.getListeningHistory();
    });
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return "À l'instant";
        }
        return "Il y a ${difference.inMinutes} minutes";
      }
      return "Il y a ${difference.inHours} heures";
    } else if (difference.inDays == 1) {
      return "Hier";
    } else if (difference.inDays < 7) {
      return "Il y a ${difference.inDays} jours";
    } else {
      return DateFormat.yMMMd('fr_FR').format(date);
    }
  }

  Widget _buildGroupHeader(String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Text(
        date,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_history.isEmpty) {
      return const Center(
        child: Text(
          'Aucun historique d\'écoute',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    String? currentDate;
    
    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final song = Song.fromJson(item);
        final lastPlayed = DateTime.parse(item['lastPlayed']);
        final date = DateFormat.yMMMd('fr_FR').format(lastPlayed);

        Widget? header;
        if (currentDate != date) {
          currentDate = date;
          header = _buildGroupHeader(date);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null) header,
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.music_note,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              title: Text(song.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.artist),
                  Text(
                    _formatDate(item['lastPlayed']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              onTap: () async {
                final playerService = AudioPlayerService();
                await playerService.playSong(song);
              },
            ),
          ],
        );
      },
    );
  }
}