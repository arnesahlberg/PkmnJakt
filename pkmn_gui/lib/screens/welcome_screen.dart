import 'package:flutter/material.dart';
import 'package:pkmn_gui/constants.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/pokedex_container.dart';
import '../widgets/pokedex_button.dart';
import "login_scanner_screen.dart";
import '../main.dart'; // for UserSession
import '../api_calls.dart'; // for fetching statistics

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Future<Map<String, dynamic>>? _statsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final recentResult = await ApiService.getStatisticsLatestPokemonFound();
    final highscoreResult = await ApiService.getStatisticsHighscore();
    return {
      'recent': recentResult['found_pokemon'] as List<dynamic>,
      'highscores': highscoreResult['user_scores'] as List<dynamic>,
    };
  }

  String _formatTime(String isoTime) {
    final dateTime = DateTime.parse(isoTime);
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Stensund Pokemon-Jakt 2025!',
        showBackButton: false,
      ),
      body: Container(
        decoration: AppBoxDecorations.gradientBackground,
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryRed,
                    ),
                  ),
                )
                : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        PokedexContainer(
                          child:
                              session.isLoggedIn
                                  ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Välkommen tillbaka, ${session.userName}!',
                                        style: AppTextStyles.titleLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(
                                        height: UIConstants.spacing24,
                                      ),
                                      PokedexButton(
                                        onPressed: () {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/home',
                                          );
                                        },
                                        child: const Text('Fortsätt'),
                                      ),
                                    ],
                                  )
                                  : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Välkommen till',
                                        style: AppTextStyles.titleMedium,
                                      ),
                                      const Text(
                                        'Stensund Pokemon-Jakt 2025!',
                                        style: AppTextStyles.titleLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(
                                        height: UIConstants.spacing24,
                                      ),
                                      Text(
                                        'Scanna ditt deltagar-band för rikslägret',
                                        style: AppTextStyles.bodyLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(
                                        height: UIConstants.spacing24,
                                      ),
                                      PokedexButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const QRScannerScreen(),
                                            ),
                                          );
                                        },
                                        child: const Text('Scanna Bandet'),
                                      ),
                                    ],
                                  ),
                        ),
                        if (!session.isLoggedIn) ...[
                          const SizedBox(height: 24),
                          FutureBuilder<Map<String, dynamic>>(
                            future: _statsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFE3350D),
                                  ),
                                );
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return const SizedBox();
                              }
                              final recent =
                                  snapshot.data!['recent'] as List<dynamic>;
                              final highs =
                                  snapshot.data!['highscores'] as List<dynamic>;
                              if (recent.isEmpty) return const SizedBox();
                              return Column(
                                children: [
                                  PokedexContainer(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Senast fångade Pokémon:",
                                          style: AppTextStyles.titleMedium,
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          height: 200,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: recent.length,
                                            itemBuilder: (context, index) {
                                              final pokemon = recent[index];
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  right: 16,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF992109,
                                                    ),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Image.asset(
                                                      'assets/images/pkmn/${pokemon['number']}.jpg',
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.contain,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => const Icon(
                                                            Icons
                                                                .image_outlined,
                                                            size: 80,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "${pokemon['name']}",
                                                      style: const TextStyle(
                                                        fontFamily: 'PixelFont',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      "Nr. ${pokemon['number']}",
                                                      style: const TextStyle(
                                                        fontFamily: 'PixelFont',
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      "${pokemon['found_by_user']['name']}",
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      _formatTime(
                                                        pokemon['time_found'],
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (highs.isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    PokedexContainer(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Global Highscore:",
                                            style: TextStyle(
                                              fontFamily: 'PixelFontTitle',
                                              fontSize: 20,
                                              color: Color(0xFFE3350D),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: highs.length,
                                            itemBuilder: (context, index) {
                                              final score = highs[index];
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF992109,
                                                    ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    if (index < 3) ...[
                                                      Icon(
                                                        Icons.emoji_events,
                                                        color:
                                                            index == 0
                                                                ? Colors.amber
                                                                : index == 1
                                                                ? Colors
                                                                    .grey[400]
                                                                : Colors
                                                                    .brown[300],
                                                        size: 24,
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    Expanded(
                                                      child: Text(
                                                        "${score['name']} (ID: ${score['id']})",
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              'PixelFont',
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFFE3350D,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        "${score['score']}",
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
