import 'package:flutter/material.dart';
import 'package:pkmn_gui/widgets/common_app_bar.dart';
import 'package:pkmn_gui/widgets/pokedex_container.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart';
import '../utils/auth_utils.dart';
import '../constants.dart';
import '../widgets/pokedex_button.dart';
import '../widgets/type_badge.dart';

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});
  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  late Future<List<dynamic>> _pokedexFuture;
  bool _isLoading = true;
  final int _maxStandardPokemon = 1000;
  bool _showOnlyCaught = true;
  List<int> _enabledIds = [];

  Future<List<dynamic>> _fetchPokedex() async {
    final session = Provider.of<UserSession>(context, listen: false);
    try {
      final results = await Future.wait([
        ApiService.getMyPokedex(session.token!),
        ApiService.getEnabledPokemonIds(),
      ]);
      final pokedexResult = results[0] as Map<String, dynamic>;
      final enabledIds = results[1] as List<int>;
      setState(() {
        _enabledIds = enabledIds;
        _isLoading = false;
      });
      return pokedexResult['pokedex'] as List<dynamic>;
    } catch (e) {
      if (mounted && isBackendUnavailableError(e)) {
        Navigator.pushReplacementNamed(context, '/backend_unavailable');
      }
      rethrow;
    }
  }

  Future<void> _refreshPokedex() async {
    setState(() {
      _isLoading = true;
    });
    _pokedexFuture = _fetchPokedex();
    // Don't return anything - this is a void method
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

    if (_showOnlyCaught) {
      fullList.addAll(caughtPokemon.map((p) => p as Map<String, dynamic>));
      fullList.sort(
        (a, b) => (a['number'] as int).compareTo(b['number'] as int),
      );
    } else {
      final standardIds =
          _enabledIds.isNotEmpty
              ? _enabledIds.where((id) => id <= _maxStandardPokemon).toList()
              : List.generate(_maxStandardPokemon, (i) => i + 1);

      for (final id in standardIds) {
        if (caughtMap.containsKey(id)) {
          fullList.add(caughtMap[id]!);
        } else {
          fullList.add({'number': id, 'caught': false, 'name': '???'});
        }
      }

      final specialEnabled =
          _enabledIds.where((id) => id > _maxStandardPokemon).toSet();
      for (var pokemon in caughtPokemon) {
        final num = pokemon['number'] as int;
        if (num > _maxStandardPokemon) {
          if (_enabledIds.isEmpty || specialEnabled.contains(num)) {
            if (!fullList.any((p) => p['number'] == num)) {
              fullList.add(pokemon);
            }
          }
        }
      }

      fullList.sort(
        (a, b) => (a['number'] as int).compareTo(b['number'] as int),
      );
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
              child: SingleChildScrollView(
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
                      const SizedBox(height: 16),
                      if (pokemon['types'] != null)
                        TypeBadgeList(
                          types: List<String>.from(pokemon['types']),
                          fontSize: 14,
                        ),
                      const SizedBox(height: 24),
                      // button to close (pokedex-button type)
                      /* ElevatedButton( // replaced
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
                      ), */
                      PokedexButton(
                        onPressed: () => Navigator.pop(context),
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
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "Pokédex"),
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
                  onRefresh: _refreshPokedex,
                  color: AppColors.primaryRed,
                  backgroundColor: AppColors.white,
                  child: FutureBuilder<List<dynamic>>(
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
                      final fullPokedex = _generateFullPokedexList(
                        caughtPokedex,
                      );
                      final caughtCount = caughtPokedex.length;

                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: PokedexContainer(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                        const SizedBox(
                                          width: UIConstants.spacing12,
                                        ),
                                        Text(
                                          "Fångade Pokémon: $caughtCount",
                                          style: AppTextStyles.titleMedium,
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Visa endast fångade",
                                            style: TextStyle(
                                              fontFamily: 'PixelFont',
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          Transform.scale(
                                            scale: 0.8,
                                            child: Switch(
                                              value: _showOnlyCaught,
                                              onChanged: (value) {
                                                setState(() {
                                                  _showOnlyCaught = value;
                                                });
                                              },
                                              activeColor: AppColors.primaryRed,
                                              inactiveThumbColor:
                                                  Colors.grey.shade400,
                                              inactiveTrackColor:
                                                  Colors.grey.shade300,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 12.0,
                            ),
                            sliver: SliverGrid.builder(
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
                                    _showOnlyCaught ||
                                    (!pokemon.containsKey('caught') ||
                                        pokemon['caught'] != false);

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
                                              color: Colors.white,
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
                                              child: Container(
                                                color: Colors.white,
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
                                                              ) => Container(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                child: const Icon(
                                                                  Icons
                                                                      .image_outlined,
                                                                  size: 48,
                                                                ),
                                                              ),
                                                        )
                                                        : Container(
                                                          color: Colors.white,
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .question_mark,
                                                              size: 48,
                                                              color:
                                                                  AppColors
                                                                      .secondaryRed,
                                                            ),
                                                          ),
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
                        ],
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
