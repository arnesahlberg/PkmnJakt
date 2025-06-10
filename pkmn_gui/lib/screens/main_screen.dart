import 'package:flutter/material.dart';
import 'package:pkmn_gui/constants.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/pokedex_container.dart';
import '../widgets/pokedex_button.dart';
import '../widgets/highscore_list.dart';
import 'package:intl/intl.dart';
import '../api_calls.dart';
import '../utils/auth_utils.dart';
import 'found_pokemon_scanner_screen.dart';

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Fel vid hämtning: $e",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Fel vid hämtning av extra data: $e",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _isExtraLoading = true;
    });
    await _loadData();
    await _loadExtraData();
  }

  String _formatTime(String isoTime) {
    final dateTime = DateTime.parse(isoTime);
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(dateTime);
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.borderRadius16),
            side: AppBorderStyles.primaryBorder,
          ),
          title: null,
          actions: null,
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      "Hur man fångar Pokémon",
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInfoStep(
                        "1",
                        "Hitta en Pokémon QR-kod ute i den verkliga världen.",
                      ),
                      const SizedBox(height: UIConstants.spacing12),
                      _buildInfoStep(
                        "2",
                        "Tryck på 'Fånga Pokémon' knappen i appen.",
                      ),
                      const SizedBox(height: UIConstants.spacing12),
                      _buildInfoStep(
                        "3",
                        "Använd kameran för att skanna QR-koden.",
                      ),
                      const SizedBox(height: UIConstants.spacing12),
                      _buildInfoStep(
                        "4",
                        "Grattis! Pokémon läggs till i ditt Pokédex.",
                      ),
                      const SizedBox(height: UIConstants.spacing24),
                      Container(
                        padding: const EdgeInsets.all(UIConstants.padding12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(
                            UIConstants.borderRadius8,
                          ),
                          border: Border.all(
                            color: const Color(0xFFFFB74D),
                            width: UIConstants.borderWidth1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Tips för att hitta olika Pokémon:",
                              style: TextStyle(
                                fontFamily: 'PixelFontTitle',
                                fontSize: 16,
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: UIConstants.spacing8),
                            _buildTipItem(
                              "Kolla anslagstavlan för ledtrådar om var olika Pokémon kan hittas!",
                            ),
                            const SizedBox(height: UIConstants.spacing8),
                            _buildTipItem(
                              "Olika Pokémon trivs i olika miljöer t.ex.",
                            ),
                            const SizedBox(height: UIConstants.spacing4),
                            Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHabitatItem(
                                    "Vatten-Pokémon",
                                    "gillar sjöar och vattendrag",
                                  ),
                                  _buildHabitatItem(
                                    "Gräs-Pokémon",
                                    "föredrar skog och grönområden",
                                  ),
                                  _buildHabitatItem(
                                    "Sten-Pokémon",
                                    "gillar klippiga områden och höjder",
                                  ),
                                  _buildHabitatItem(
                                    "Spök-Pokémon",
                                    "hittas ofta vid gamla byggnader",
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: UIConstants.spacing12),
                      const Text(
                        "Ju fler Pokémon du fångar, desto högre rankas du på topplistan!",
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: AppButtonStyles.secondaryButtonStyle,
                          child: const Text(
                            "OK",
                            style: TextStyle(
                              fontFamily: 'PixelFontTitle',
                              color: AppColors.primaryRed,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primaryRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: UIConstants.spacing10),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
      ],
    );
  }

  Widget _buildTipItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.tips_and_updates,
          size: UIConstants.iconSizeSmall,
          color: Color(0xFFE65100),
        ),
        const SizedBox(width: UIConstants.spacing8),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    );
  }

  Widget _buildHabitatItem(String pokemonType, String location) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spacing4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: "$pokemonType ", style: AppTextStyles.labelSmall),
            TextSpan(text: location, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  // helper to check if score has duplicates
  bool _hasDuplicateScore(dynamic currentScore) {
    return _highScores
            .where((s) => s['score'] == currentScore['score'])
            .length >
        1;
  }

  @override
  void initState() {
    super.initState();
    AuthUtils.validateTokenAndRedirect(context).then((isValid) {
      if (isValid) {
        _loadData();
        _loadExtraData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    return Scaffold(
      appBar: const CommonAppBar(title: "Pokémonjakt", showBackButton: false),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryRed,
                  ),
                ),
              )
              : Container(
                decoration: AppBoxDecorations.gradientBackground,
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppColors.primaryRed,
                  backgroundColor: AppColors.white,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PokedexContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Välkommen ${session.userName}!",
                                style: AppTextStyles.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _ranking == 1
                                    ? "Du är rankad: #$_ranking 🏆🥇🎉"
                                    : _ranking == 2
                                    ? "Du är rankad: #$_ranking 🥈"
                                    : _ranking == 3
                                    ? "Du är rankad: #$_ranking 🥉"
                                    : "Du är rankad: #$_ranking",
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.secondaryRed,
                                ),
                              ),
                              const SizedBox(height: UIConstants.spacing24),
                              Row(
                                children: [
                                  Expanded(
                                    child: PokedexButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/pokedex',
                                        );
                                      },
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.menu_book,
                                            color: AppColors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text("Mitt Pokédex"),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: PokedexButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const FoundPokemonScannerScreen(),
                                          ),
                                        ).then((_) {
                                          // refresh data when returning from catching pokemon
                                          _refreshData();
                                        });
                                      },
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.catching_pokemon,
                                            color: AppColors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text("Fånga Pokémon"),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: UIConstants.spacing16),
                              GestureDetector(
                                onTap: _showInfoDialog,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: AppColors.secondaryRed,
                                    ),
                                    const SizedBox(width: UIConstants.spacing8),
                                    Text(
                                      "Hur fångar jag Pokémon?",
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.secondaryRed,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        PokedexContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Dina senast fångade Pokémon",
                                style: TextStyle(
                                  fontFamily: 'PixelFontTitle',
                                  fontSize: 20,
                                  color: Color(0xFFE3350D),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_pokemonList.isEmpty)
                                const Text(
                                  "Du har inte fångat några Pokémon än!",
                                  style: TextStyle(
                                    fontFamily: 'PixelFont',
                                    fontSize: 16,
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _pokemonList.length,
                                  itemBuilder: (context, index) {
                                    final pokemon = _pokemonList[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF992109),
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFF992109),
                                                width: 1,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                              child: Image.asset(
                                                'assets/images/pkmn/${pokemon['number']}.jpg',
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.image_outlined,
                                                      size: 32,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${pokemon['name']}",
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        'PixelFontTitle',
                                                    fontSize: 16,
                                                    color: Color(0xFFE3350D),
                                                  ),
                                                ),
                                                Text(
                                                  "Nr. ${pokemon['number']}",
                                                  style: TextStyle(
                                                    fontFamily: 'PixelFont',
                                                    fontSize: 14,
                                                    color: Colors.grey.shade700,
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
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        if (!_isExtraLoading) ...[
                          const SizedBox(height: 24),
                          HighscoreList(highscores: _highScores),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/highscore'),
                              child: const Text('Se mer >'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          PokedexContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Senast fångade Pokémon av alla",
                                  style: TextStyle(
                                    fontFamily: 'PixelFontTitle',
                                    fontSize: 20,
                                    color: Color(0xFFE3350D),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_allPokemonList.isEmpty)
                                  const Text("Inga globala fångster än.")
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _allPokemonList.length,
                                    itemBuilder: (context, index) {
                                      final pokemon = _allPokemonList[index];
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF992109),
                                            width: 2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF992109,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                                child: Image.asset(
                                                  'assets/images/pkmn/${pokemon['number']}.jpg',
                                                  fit: BoxFit.contain,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Icon(
                                                        Icons.image_outlined,
                                                        size: 32,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${pokemon['name']}",
                                                    style: const TextStyle(
                                                      fontFamily:
                                                          'PixelFontTitle',
                                                      fontSize: 16,
                                                      color: Color(0xFFE3350D),
                                                    ),
                                                  ),
                                                  Text(
                                                    "Nr. ${pokemon['number']}",
                                                    style: TextStyle(
                                                      fontFamily: 'PixelFont',
                                                      fontSize: 14,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.person,
                                                        size: 12,
                                                        color: Color(
                                                          0xFF992109,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "${pokemon['found_by_user']['name']}",
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color(
                                                            0xFF992109,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
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
                    ),
                  ),
                ),
              ),
    );
  }
}
