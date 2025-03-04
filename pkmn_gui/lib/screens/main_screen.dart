import 'package:flutter/material.dart';
import 'package:pkmn_gui/constants.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // for user session
import '../widgets/common_app_bar.dart';
import 'package:intl/intl.dart';
import '../api_calls.dart';
import 'pokedex_screen.dart';
import 'found_pokemon_scanner_screen.dart'; // new import

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});
  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  List<dynamic> _pokemonList = [];
  List<dynamic> _allPokemonList = [];
  List<dynamic> _highScores = [];
  bool _isLoading = true;
  bool _isExtraLoading = true;
  int _ranking = 0;

  Future<void> _loadData() async {
    final session = Provider.of<UserSession>(context, listen: false);
    try {
      final result = await ApiService.viewFoundPokemon(10, session.token!);
      final ranking = await ApiService.checkUserRanking(session.userId!);
      setState(() {
        _pokemonList = result['pokemon_found'] as List<dynamic>;
        _ranking = ranking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Fel vid hämtning: $e")));
    }
  }

  Future<void> _loadExtraData() async {
    try {
      final highscoreResult = await ApiService.getStatisticsHighscore();
      final latestResult = await ApiService.getStatisticsLatestPokemonFound();
      setState(() {
        _highScores = highscoreResult['user_scores'] as List<dynamic>;
        _allPokemonList = latestResult['found_pokemon'] as List<dynamic>;
        _isExtraLoading = false;
      });
    } catch (e) {
      setState(() => _isExtraLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fel vid hämtning av extra data: $e")),
      );
    }
  }

  String _formatTime(String isoTime) {
    final dateTime = DateTime.parse(isoTime);
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadExtraData();
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    return Scaffold(
      appBar: const CommonAppBar(
        title: "Stensund Pokemon-Jakt 2025",
        showBackButton: false,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        style: ButtonStyles.buttonStyleWide,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PokedexScreen(),
                            ),
                          );
                        },
                        child: const Text("Mitt pokedex"),
                      ),
                      const SizedBox(height: 16),
                      // New button "Hitta Pokémon"
                      ElevatedButton(
                        style: ButtonStyles.buttonStyleWide,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FoundPokemonScannerScreen(),
                            ),
                          );
                        },
                        child: const Text("Hitta Pokémon"),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Välkommen ${session.userName}",
                        style: TextStyles.welcomeTextStyle,
                      ),
                      const SizedBox(height: 16),

                      Text(
                        _ranking == 1
                            ? "Ranking: #$_ranking 🏆🥇🎉"
                            : _ranking == 2
                            ? "Ranking: #$_ranking 🥈"
                            : _ranking == 3
                            ? "Ranking: #$_ranking 🥉"
                            : "Ranking: #$_ranking",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Dina senast fångade Pokémon",
                        style: TextStyles.headerTextStyle,
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pokemonList.length,
                        itemBuilder: (context, index) {
                          final pokemon = _pokemonList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: Image.asset(
                                'assets/images/pkmn/${pokemon['number']}.jpg',
                                width: 48,
                                height: 48,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.image_outlined,
                                      size: 48,
                                    ),
                              ),
                              title: Text(
                                "${pokemon['name']} (Nr. ${pokemon['number']})",
                              ),
                              subtitle: Text(
                                "Tid: ${_formatTime(pokemon['time_found'])}",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                      const Text(
                        "Global Highscore",
                        style: TextStyles.headerTextStyle,
                      ),
                      _isExtraLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _highScores.length,
                            itemBuilder: (context, index) {
                              final score = _highScores[index];
                              return ListTile(
                                leading:
                                    index == 0
                                        ? const Icon(
                                          Icons.emoji_events,
                                          color: Colors.amber,
                                        )
                                        : index == 1
                                        ? const Icon(
                                          Icons.emoji_events,
                                          color: Colors.grey,
                                        )
                                        : index == 2
                                        ? const Icon(
                                          Icons.emoji_events,
                                          color: Colors.brown,
                                        )
                                        : Text(
                                          "",
                                        ), // no icon but still indented
                                title: Text(
                                  "${score['name']} (ID: ${score['id']})",
                                ),
                                trailing: Text(
                                  "Fångade: ${score['score']}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            },
                          ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                      const Text(
                        "Senast fångade Pokémon av alla",
                        style: TextStyles.headerTextStyle,
                      ),
                      _isExtraLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _allPokemonList.length,
                            itemBuilder: (context, index) {
                              final pokemon = _allPokemonList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  leading: Image.asset(
                                    'assets/images/pkmn/${pokemon['number']}.jpg',
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.image_outlined,
                                              size: 48,
                                            ),
                                  ),
                                  title: Text(
                                    "${pokemon['name']} (Nr. ${pokemon['number']})",
                                  ),
                                  subtitle: Text(
                                    "Fångad av: ${pokemon['found_by_user']['name']} - Tid: ${_formatTime(pokemon['time_found'])}",
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
    );
  }
}
