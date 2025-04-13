import 'package:flutter/material.dart';
import 'package:pkmn_gui/widgets/common_app_bar.dart';
import 'package:pkmn_gui/widgets/pokedex_container.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart';
import '../utils/auth_utils.dart';
import '../constants.dart';

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});
  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  late Future<List<dynamic>> _pokedexFuture;
  bool _isLoading = true;
  // Maximum number of standard Pokémon
  final int _maxStandardPokemon = 151;

  Future<List<dynamic>> _fetchPokedex() async {
    final session = Provider.of<UserSession>(context, listen: false);
    final result = await ApiService.getMyPokedex(session.token!);
    setState(() {
      _isLoading = false;
    });
    return result['pokedex'] as List<dynamic>;
  }

  @override
  void initState() {
    super.initState();
    AuthUtils.validateTokenAndRedirect(context).then((isValid) {
      if (isValid) {
        _pokedexFuture = _fetchPokedex();
      }
    });
  }

  // Generate full pokedex list including placeholders for uncaught Pokémon
  List<Map<String, dynamic>> _generateFullPokedexList(
    List<dynamic> caughtPokemon,
  ) {
    // Create a map of caught Pokémon for quick lookup
    final Map<int, Map<String, dynamic>> caughtMap = {};
    for (var pokemon in caughtPokemon) {
      caughtMap[pokemon['number']] = pokemon;
    }

    // Generate the full list with placeholders
    final List<Map<String, dynamic>> fullList = [];

    // Add standard Pokémon (1-151) with placeholders if not caught
    for (int i = 1; i <= _maxStandardPokemon; i++) {
      if (caughtMap.containsKey(i)) {
        fullList.add(caughtMap[i]!);
      } else {
        fullList.add({'number': i, 'caught': false, 'name': '???'});
      }
    }

    // Add special Pokémon (>151) only if caught
    for (var pokemon in caughtPokemon) {
      if (pokemon['number'] > _maxStandardPokemon) {
        fullList.add(pokemon);
      }
    }

    return fullList;
  }

  void _showPokemonDetails(Map<String, dynamic> pokemon, bool isCaught) {
    if (!isCaught) return; // Don't show details for uncaught Pokémon

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UIConstants.borderRadius16),
            ),
            child: PokedexContainer(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pokemon['name'],
                      style: const TextStyle(
                        fontFamily: 'PixelFontTitle',
                        fontSize: 22,
                        color: AppColors.primaryRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "Nr. ${pokemon['number']}",
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 180,
                      height: 180,
                      padding: const EdgeInsets.all(UIConstants.padding16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(
                          UIConstants.borderRadius16,
                        ),
                        border: Border.all(
                          color: AppColors.secondaryRed,
                          width: UIConstants.borderWidth2,
                        ),
                      ),
                      child: Image.asset(
                        'assets/images/pkmn/${pokemon['number']}.jpg',
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.image_outlined, size: 80),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (pokemon['description'] != null)
                      Text(
                        pokemon['description'],
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),
                    if (pokemon['height'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withAlpha(
                            (0.1 * 255).toInt(),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Höjd: ${pokemon['height']} m",
                          style: const TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 14,
                            color: Color(0xFF992109),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            UIConstants.borderRadius8,
                          ),
                        ),
                      ),
                      child: const Text(
                        "Stäng",
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "Min Pokédex"),
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
                : FutureBuilder<List<dynamic>>(
                  future: _pokedexFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryRed,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                      );
                    }

                    final caughtPokedex = snapshot.data!;
                    final fullPokedex = _generateFullPokedexList(caughtPokedex);
                    final caughtCount = caughtPokedex.length;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: PokedexContainer(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: UIConstants.iconSizeNormal,
                                  height: UIConstants.iconSizeNormal,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryRed,
                                    border: Border.all(
                                      color: AppColors.secondaryRed,
                                      width: UIConstants.borderWidth2,
                                    ),
                                    boxShadow: AppShadows.lightShadow,
                                  ),
                                  child: const Icon(
                                    Icons.catching_pokemon,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: UIConstants.spacing12),
                                Text(
                                  "Fångade Pokémon: $caughtCount",
                                  style: AppTextStyles.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.75,
                                  ),
                              itemCount: fullPokedex.length,
                              itemBuilder: (context, index) {
                                final pokemon = fullPokedex[index];
                                final bool isCaught =
                                    !pokemon.containsKey('caught') ||
                                    pokemon['caught'] != false;

                                return GestureDetector(
                                  onTap:
                                      () => _showPokemonDetails(
                                        pokemon,
                                        isCaught,
                                      ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        UIConstants.borderRadius12,
                                      ),
                                      border: Border.all(
                                        color: AppColors.secondaryRed,
                                        width: UIConstants.borderWidth2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.shadowColor
                                              .withOpacity(0.15),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(1, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppColors.secondaryRed,
                                                width: 1,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                              child:
                                                  isCaught
                                                      ? Image.asset(
                                                        'assets/images/pkmn/${pokemon['number']}.jpg',
                                                        fit: BoxFit.contain,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => const Icon(
                                                              Icons
                                                                  .image_outlined,
                                                              size: 48,
                                                            ),
                                                      )
                                                      : const Center(
                                                        child: Icon(
                                                          Icons.question_mark,
                                                          size: 48,
                                                          color:
                                                              AppColors
                                                                  .secondaryRed,
                                                        ),
                                                      ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 4,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryRed,
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(10),
                                              bottomRight: Radius.circular(10),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                isCaught
                                                    ? pokemon['name']
                                                    : "???",
                                                style: const TextStyle(
                                                  fontFamily: 'PixelFont',
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                "#${pokemon['number']}",
                                                style: const TextStyle(
                                                  fontFamily: 'PixelFont',
                                                  fontSize: 10,
                                                  color: Colors.white70,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
      ),
    );
  }
}
