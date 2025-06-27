import 'package:flutter/material.dart';
import 'package:pkmn_gui/widgets/common_app_bar.dart';
import 'package:pkmn_gui/widgets/pokedex_container.dart';
import '../api_calls.dart';
import '../constants.dart';
import '../widgets/milestone_badge.dart';

class UserStatisticsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserStatisticsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserStatisticsScreen> createState() => _UserStatisticsScreenState();
}

class _UserStatisticsScreenState extends State<UserStatisticsScreen> {
  late Future<Map<String, dynamic>> _userDataFuture;
  late Future<List<dynamic>> _pokedexFuture;
  late Future<List<int>> _milestonesFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = ApiService.getUser(widget.userId);
    _pokedexFuture = ApiService.getUserPokedex(widget.userId);
    _milestonesFuture = ApiService.getUserMilestones(widget.userId);
  }

  void _showPokemonDetails(Map<String, dynamic> pokemon) {
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
      appBar: CommonAppBar(title: widget.userName),
      body: Container(
        decoration: AppBoxDecorations.gradientBackground,
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([_userDataFuture, _pokedexFuture, _milestonesFuture]),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.primaryRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Kunde inte hämta användardata",
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontFamily: 'PixelFont',
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Error: ${snapshot.error}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontFamily: 'PixelFont',
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final caughtPokemon = snapshot.data![1] as List<dynamic>;
            final milestones = snapshot.data![2] as List<int>;
            final caughtCount = caughtPokemon.length;

            // Sort Pokemon by number
            caughtPokemon.sort(
              (a, b) => (a['number'] as int).compareTo(b['number'] as int),
            );

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: PokedexContainer(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                                  Icons.person,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: UIConstants.spacing12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.userName,
                                    style: AppTextStyles.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "ID: ${widget.userId}",
                                    style: TextStyle(
                                      fontFamily: 'PixelFont',
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Fångade Pokémon: $caughtCount",
                            style: TextStyle(
                              fontFamily: 'PixelFont',
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (milestones.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: PokedexContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Milstolpar",
                              style: TextStyle(
                                fontFamily: 'PixelFontTitle',
                                fontSize: 18,
                                color: AppColors.primaryRed,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: milestones.map((milestone) {
                                return MilestoneBadge(
                                  milestone: milestone,
                                  size: 40,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
                if (caughtPokemon.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.catching_pokemon_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Inga Pokémon fångade än",
                              style: TextStyle(
                                fontFamily: 'PixelFont',
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
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
                      itemCount: caughtPokemon.length,
                      itemBuilder: (context, index) {
                        final pokemon = caughtPokemon[index];
                        return GestureDetector(
                          onTap: () => _showPokemonDetails(pokemon),
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
                                  color: AppColors.shadowColor.withOpacity(
                                    0.15,
                                  ),
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
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.secondaryRed,
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Image.asset(
                                        'assets/images/pkmn/${pokemon['number']}.jpg',
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.image_outlined,
                                                  size: 48,
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
                                        pokemon['name'],
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
    );
  }
}
