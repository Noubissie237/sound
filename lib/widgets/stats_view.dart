import 'package:flutter/material.dart';
import 'package:sound/services/user_preferences_service.dart';

class StatsView extends StatefulWidget {
  final UserPreferencesService preferencesService;

  const StatsView({
    Key? key,
    required this.preferencesService,
  }) : super(key: key);

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  late Map<String, dynamic> _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _stats = widget.preferencesService.getListeningStats();
      _isLoading = false;
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentMonthStats() {
    final now = DateTime.now();
    final currentMonthKey = '${now.year}-${now.month}';
    final monthStats = _stats[currentMonthKey];
    if (monthStats == null) return '0';
    return monthStats['totalPlays'].toString();
  }

  String _getTopArtistThisMonth() {
    final now = DateTime.now();
    final currentMonthKey = '${now.year}-${now.month}';
    final monthStats = _stats[currentMonthKey];
    if (monthStats == null) return 'Aucun';

    // Logique pour trouver l'artiste le plus écouté
    final Map<String, int> artistPlays = {};
    final songPlays = monthStats['songPlays'] as Map<String, dynamic>;
    
    // Compte le nombre de lectures par artiste
    songPlays.forEach((songPath, plays) {
      // Vous devrez adapter cette partie selon votre structure de données
      final artist = songPath.split('/').last.split('-')[0];
      artistPlays[artist] = (artistPlays[artist] ?? 0) + (plays as int);
    });

    if (artistPlays.isEmpty) return 'Aucun';

    // Trouve l'artiste avec le plus de lectures
    final topArtist = artistPlays.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return topArtist;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentMonthPlays = _getCurrentMonthStats();
    final topArtist = _getTopArtistThisMonth();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques du mois',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Écoutes ce mois',
                currentMonthPlays,
                Icons.play_circle,
              ),
              _buildStatCard(
                'Artiste favori',
                topArtist,
                Icons.person,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Ici, on pourrait ajouter d'autres sections de statistiques,
          // comme un graphique d'évolution des écoutes sur les derniers mois
        ],
      ),
    );
  }
}