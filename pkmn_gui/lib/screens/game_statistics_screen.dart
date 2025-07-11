import 'package:flutter/material.dart';
import '../api_calls.dart';
import '../constants.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/pokedex_container.dart';
import '../widgets/highscore_list.dart';

class GameStatisticsScreen extends StatefulWidget {
  const GameStatisticsScreen({super.key});

  @override
  State<GameStatisticsScreen> createState() => _GameStatisticsScreenState();
}

class _GameStatisticsScreenState extends State<GameStatisticsScreen> {
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await AdminApiService.getGameSummaryStatistics();
      if (mounted) {
        setState(() {
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Spelstatistik'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundLight, AppColors.white],
          ),
        ),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Fel: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStatistics,
                        child: const Text('Försök igen'),
                      ),
                    ],
                  ),
                )
                : _buildStatisticsContent(),
      ),
    );
  }

  Widget _buildStatisticsContent() {
    if (_statistics == null) {
      return const Center(child: Text('Inga statistik tillgänglig'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Game Over Banner
          PokedexContainer(
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: AppColors.goldMedal,
                ),
                const SizedBox(height: 16),
                Text(
                  'Spelet är slut!',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tack till alla som deltog Friskportlägrets Pokémon-jakt!',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Overall Statistics
          PokedexContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Övergripande statistik',
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                _buildStatRow(
                  'Totalt antal deltagare',
                  '${_statistics!['total_users_registered'] ?? 0}',
                ),
                const Divider(),
                _buildStatRow(
                  'Spelare med 10+ fångster',
                  '${_statistics!['users_with_10_plus_catches'] ?? 0}',
                ),
                const Divider(),
                _buildStatRow(
                  'Spelare med 100+ fångster',
                  '${_statistics!['users_with_100_plus_catches'] ?? 0}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // First and Last Catches
          if (_statistics!['first_catch'] != null ||
              _statistics!['last_catch'] != null) ...[
            PokedexContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('Milstolpar', style: AppTextStyles.titleMedium),
                  ),
                  if (_statistics!['first_catch'] != null) ...[
                    _buildCatchInfo(
                      'Första fångsten',
                      _statistics!['first_catch'],
                    ),
                    if (_statistics!['last_catch'] != null) const Divider(),
                  ],
                  if (_statistics!['last_catch'] != null)
                    _buildCatchInfo(
                      'Sista fångsten',
                      _statistics!['last_catch'],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Hourly Activity Chart - MOVED UP
          if (_statistics!['catches_per_hour'] != null &&
              (_statistics!['catches_per_hour'] as List).isNotEmpty) ...[
            PokedexContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Aktivitet per timme',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  const Text(
                    'Totalt antal fångster per timme under hela eventet',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  _buildHourlyChart(_statistics!['catches_per_hour']),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Most Caught Pokemon
          if (_statistics!['most_caught_pokemon'] != null &&
              (_statistics!['most_caught_pokemon'] as List).isNotEmpty) ...[
            PokedexContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Mest fångade Pokémon',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  _buildPokemonStatsList(_statistics!['most_caught_pokemon']),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Least Caught Pokemon
          if (_statistics!['least_caught_pokemon'] != null &&
              (_statistics!['least_caught_pokemon'] as List).isNotEmpty) ...[
            PokedexContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Minst fångade Pokémon',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  _buildPokemonStatsList(_statistics!['least_caught_pokemon']),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Top 10 Players - MOVED TO BOTTOM
          if (_statistics!['top_10_players'] != null &&
              (_statistics!['top_10_players'] as List).isNotEmpty) ...[
            HighscoreList(
              highscores: _statistics!['top_10_players'],
              title: 'Topp 10 spelare',
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatchInfo(String title, Map<String, dynamic> catchData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${catchData['user_name']} fångade ${catchData['pokemon_name']} (#${catchData['pokemon_number']})',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonStatsList(List<dynamic> pokemonStats) {
    return Column(
      children:
          pokemonStats.take(10).map((stat) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${stat['pokemon_name']} (#${stat['pokemon_number']})',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  Text(
                    '${stat['times_caught']} gånger',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildHourlyChart(List<dynamic> hourlyData) {
    // Find max value for scaling
    int maxCatches = 0;
    for (var data in hourlyData) {
      if (data['catches'] > maxCatches) {
        maxCatches = data['catches'] as int;
      }
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  hourlyData.map<Widget>((data) {
                    final hour = data['hour'] as int;
                    final catches = data['catches'] as int;
                    final heightFactor =
                        maxCatches > 0 ? catches / maxCatches : 0.0;

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$catches',
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            height: 120 * heightFactor,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('$hour', style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Timme på dygnet',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}