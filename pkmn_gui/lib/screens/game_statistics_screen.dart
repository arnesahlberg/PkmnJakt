import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  bool _isGameOver = false;
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
      final results = await Future.wait([
        AdminApiService.getGameSummaryStatistics(),
        AdminApiService.isGameOver(),
      ]);

      final stats = results[0] as Map<String, dynamic>;
      final gameStatusResponse = results[1] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _statistics = stats;
          _isGameOver = gameStatusResponse['is_game_over'] ?? false;
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
          // Game Over Banner - only show if game is actually over
          if (_isGameOver) ...[
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
          ],

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
                  'Totalt antal Pokémon-fångster',
                  '${_statistics!['total_pokemon_caught'] ?? 0}',
                ),
                const Divider(),
                _buildStatRow(
                  'Antal deltagare som fångat 10+ pokémon',
                  '${_statistics!['users_with_10_plus_catches'] ?? 0}',
                ),
                const Divider(),
                _buildStatRow(
                  'Antal delgatare som fångat 100+ pokémon',
                  '${_statistics!['users_with_100_plus_catches'] ?? 0}',
                ),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  ".. och vi har haft MASSOR av icke-digitala Pokémon-letare också!",
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // First and Last Catches
          if (_statistics!['first_catch'] != null ||
              _statistics!['last_catch'] != null ||
              _statistics!['longest_survivor'] != null) ...[
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
                    if (_statistics!['last_catch'] != null ||
                        _statistics!['longest_survivor'] != null)
                      const Divider(),
                  ],
                  if (_statistics!['last_catch'] != null) ...[
                    _buildCatchInfo(
                      'Sista fångsten',
                      _statistics!['last_catch'],
                    ),
                    if (_statistics!['longest_survivor'] != null)
                      const Divider(),
                  ],
                  if (_statistics!['longest_survivor'] != null)
                    _buildCatchInfo(
                      'Pokémon som klarade sig längst utan att bli fångad',
                      _statistics!['longest_survivor'],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // // Daytime Catch Frequency
          // if (_statistics!['daytime_catch_frequency'] != null) ...[
          //   PokedexContainer(
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         const Padding(
          //           padding: EdgeInsets.only(bottom: 16),
          //           child: Text(
          //             'Fångstfrekvens dagtid',
          //             style: AppTextStyles.titleMedium,
          //           ),
          //         ),
          //         _buildStatRow(
          //           'Pokémon per timme (06:30-22:30)',
          //           _statistics!['daytime_catch_frequency'].toStringAsFixed(1),
          //         ),
          //       ],
          //     ),
          //   ),
          //   const SizedBox(height: 16),
          // ],

          // Daily Activity Chart
          if (_statistics!['catches_per_day'] != null &&
              (_statistics!['catches_per_day'] as List).isNotEmpty) ...[
            PokedexContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Aktivitet per dag',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  const Text(
                    'Antal fångster per dag under lägret',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  _buildDailyChart(_statistics!['catches_per_day']),
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
    // Parse the datetime string
    String dateTimeStr = '';
    if (catchData['caught_at'] != null) {
      try {
        final DateTime dateTime = DateTime.parse(catchData['caught_at']);
        // Format: "05/07 12:20"
        dateTimeStr = DateFormat('dd/MM HH:mm').format(dateTime);
      } catch (e) {
        // Fallback formatting if parsing fails
        dateTimeStr = catchData['caught_at'].toString();
      }
    }

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
            '${catchData['user_name']} fångade ${catchData['pokemon_name']} (#${catchData['pokemon_number']})${dateTimeStr.isNotEmpty ? " - $dateTimeStr" : ""}',
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

  Widget _buildDailyChart(List<dynamic> dailyData) {
    // Find max value for scaling
    int maxCatches = 0;
    for (var data in dailyData) {
      if (data['catches'] > maxCatches) {
        maxCatches = data['catches'] as int;
      }
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final numberOfDays = dailyData.length;

          // Calculate bar width based on available space
          // If few days, expand to fill space; if many days, use minimum width with scrolling
          final minBarWidth = 80.0;
          final maxBarWidth = 120.0;
          final spacing = 8.0; // Total horizontal margin per bar

          // Calculate ideal bar width to fill available space
          final idealBarWidth =
              (availableWidth - (spacing * numberOfDays)) / numberOfDays;

          // Determine if we need scrolling
          final needsScrolling = idealBarWidth < minBarWidth;
          final barWidth =
              needsScrolling
                  ? minBarWidth
                  : idealBarWidth.clamp(minBarWidth, maxBarWidth);

          Widget chartContent = Row(
            mainAxisAlignment:
                needsScrolling
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children:
                dailyData.map<Widget>((data) {
                  final weekday = data['weekday'] as String;
                  final dayNumber = data['day_number'] as int;
                  final catches = data['catches'] as int;
                  final heightFactor =
                      maxCatches > 0 ? catches / maxCatches : 0.0;

                  // Swedish ordinal suffix
                  String ordinalSuffix = 'e';
                  if (dayNumber == 1 || dayNumber == 2) {
                    ordinalSuffix = 'a';
                  }

                  return Container(
                    width: barWidth,
                    margin: EdgeInsets.symmetric(horizontal: spacing / 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$catches',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          height: 120 * heightFactor,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          weekday,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$dayNumber:$ordinalSuffix',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          );

          return Column(
            children: [
              Expanded(
                child:
                    needsScrolling
                        ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: chartContent,
                        )
                        : Center(child: chartContent),
              ),
            ],
          );
        },
      ),
    );
  }
}
