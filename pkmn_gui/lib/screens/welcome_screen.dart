import 'package:flutter/material.dart';
import 'package:pkmn_gui/constants.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/pokedex_container.dart';
import '../widgets/pokedex_button.dart';
import '../widgets/highscore_list.dart';
import '../widgets/game_status_banner.dart';
import "login_scanner_screen.dart";
import 'backend_unavailable_screen.dart';
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
  bool _datamatrixEnabled = true;
  bool _settingsLoaded = false;
  bool _backendUnavailable = false;
  int _activePokemonCount = 151; // default to 151

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _statsFuture = _fetchStats();
    _loadSettingsAndPokemonCount();
  }

  Future<void> _loadSettingsAndPokemonCount() async {
    try {
      final datamatrixEnabled = await ApiService.getDatamatrixLoginEnabled(
        fallbackOnError: false,
      );
      final enabledIds = await ApiService.getEnabledPokemonIds(
        fallbackOnError: false,
      );
      if (!mounted) return;
      setState(() {
        _datamatrixEnabled = datamatrixEnabled;
        _settingsLoaded = true;
        _activePokemonCount = enabledIds.length;
      });
    } catch (e) {
      _handleBackendError(e);
    }
  }

  void _handleBackendError(Object error) {
    if (!isBackendUnavailableError(error) || !mounted) return;
    setState(() {
      _backendUnavailable = true;
      _settingsLoaded = true;
      _isLoading = false;
    });
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    try {
      final recentResult = await ApiService.getStatisticsLatestPokemonFound();
      final highscoreResult = await ApiService.getStatisticsHighscore();
      return {
        'recent': recentResult['found_pokemon'] as List<dynamic>,
        'highscores': highscoreResult['user_scores'] as List<dynamic>,
      };
    } catch (e) {
      _handleBackendError(e);
      rethrow;
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _backendUnavailable = false;
    });
    _loadInitialData();
    setState(() {
      _isLoading = false;
    });
  }

  String _formatTime(String isoTime) {
    final dateTime = DateTime.parse(isoTime);
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    if (_backendUnavailable) return const BackendUnavailableScreen();

    final session = Provider.of<UserSession>(context);
    return Scaffold(
      appBar: const CommonAppBar(title: 'Pokémonjakt', showBackButton: false),
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
                : RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppColors.primaryRed,
                  backgroundColor: AppColors.white,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (!session.isLoggedIn) ...[
                            const GameStatusBanner(),
                            const SizedBox(height: 16),
                          ],
                          PokedexContainer(
                            child:
                                session.isLoggedIn
                                    ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Välkommen till',
                                          style: AppTextStyles.titleMedium,
                                        ),
                                        const Text(
                                          'Lerdala Pokemon-Jakt 2025!',
                                          style: AppTextStyles.titleLarge,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(
                                          height: UIConstants.spacing24,
                                        ),
                                        Text(
                                          'Detta är en pokémonjakt du kan delta i när du besöker Lerdala! '
                                          'Lite överallt på området finns pokémon gömda. Kan du hitta alla $_activePokemonCount?\n\n'
                                          '${_datamatrixEnabled ? 'Du kan fånga pokémon via telefonen. Först loggar du in genom att klicka på knappen nedan och klicka på "scanna bandet" (ditt deltagarband du fick vid mottagningen).' : 'Du kan fånga pokémon via telefonen. Logga in eller registrera dig med ett användarnamn genom att klicka på knappen nedan.'}\n\n'
                                          'Det finns också en analog pokémonjakt som du kan delta i med lappar du hämtar vid förrådet.',
                                          style: AppTextStyles.bodyLarge,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(
                                          height: UIConstants.spacing24,
                                        ),
                                        if (!_settingsLoaded)
                                          const SizedBox(
                                            height: 48,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.primaryRed),
                                              ),
                                            ),
                                          )
                                        else if (_datamatrixEnabled)
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
                                          )
                                        else
                                          PokedexButton(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/manual_login',
                                              );
                                            },
                                            child: const Text('Logga in'),
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
                                    snapshot.data!['highscores']
                                        as List<dynamic>;
                                if (recent.isEmpty) return const SizedBox();
                                return Column(
                                  children: [
                                    PokedexContainer(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Senast fångade Pokémon",
                                            style: AppTextStyles.titleMedium,
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            height: 160,
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
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
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
                                                          fontFamily:
                                                              'PixelFont',
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        "Nr. ${pokemon['number']}",
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              'PixelFont',
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
                                      HighscoreList(
                                        highscores: highs,
                                        clickable: false,
                                        showFirstPlacesIcons: true,
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
      ),
    );
  }
}
