import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/common_app_bar.dart';
import "qr_scanner_screen.dart";
import '../main.dart'; // for UserSession
import '../api_calls.dart'; // for fetching statistics

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Future<Map<String, dynamic>>? _statsFuture;

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child:
              session.isLoggedIn
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Välkommen tillbaka, ${session.userName}! Du är redan inloggad.',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        child: const Text('Fortsätt'),
                      ),
                    ],
                  )
                  : SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Välkommen till Stensund Pokemon-Jakt 2025!',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Klicka på knappen nedan och scanna ditt deltagar-band för rikslägret.',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontFamily: 'PixelFont',
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QRScannerScreen(),
                              ),
                            );
                          },
                          child: const Text('Logga in med bandet'),
                        ),
                        const SizedBox(height: 32),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _statsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Senast fångade Pokémon:",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'PixelFont',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 140,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: recent.length,
                                    itemBuilder: (context, index) {
                                      final pokemon = recent[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
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
                                                    Icons.image_outlined,
                                                    size: 80,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${pokemon['name']}",
                                              style: const TextStyle(
                                                fontFamily: 'PixelFont',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "Nr. ${pokemon['number']}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              "Fångad av: ${pokemon['found_by_user']['name']}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              "Tid: ${_formatTime(pokemon['time_found'])}",
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
                                const SizedBox(height: 32),
                                highs.isEmpty
                                    ? const SizedBox()
                                    : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Global Highscore:",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'PixelFont',
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
                                            return ListTile(
                                              title: Text(
                                                "${score['name']} (ID: ${score['id']})",
                                                style: const TextStyle(
                                                  fontFamily: 'PixelFont',
                                                  fontSize: 18,
                                                ),
                                              ),
                                              trailing: Text(
                                                "Fångade: ${score['score']}",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
