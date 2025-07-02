import 'package:flutter/material.dart';
import 'package:pkmn_gui/widgets/common_app_bar.dart';
import 'package:pkmn_gui/widgets/pokedex_container.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../constants.dart';
import '../widgets/milestone_badge.dart';
import '../widgets/type_badge.dart';
import '../main.dart'; // for UserSession
import '../models/milestone.dart';

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
  late Future<List<dynamic>> _comprehensiveMilestonesFuture;
  late Future<Map<String, dynamic>> _typeStatsFuture;
  late Future<Map<String, dynamic>> _currentUserPokedexFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = ApiService.getUser(widget.userId);
    _pokedexFuture = ApiService.getUserPokedex(widget.userId);
    _comprehensiveMilestonesFuture = ApiService.getUserMilestoneDefinitions(widget.userId);
    _typeStatsFuture = ApiService.getUserPokemonByType(widget.userId);
    
    // Get current user's pokedex
    final session = Provider.of<UserSession>(context, listen: false);
    if (session.token != null) {
      _currentUserPokedexFuture = ApiService.getMyPokedex(session.token!);
    } else {
      _currentUserPokedexFuture = Future.value({'pokedex': []});
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: widget.userName),
      body: Container(
        decoration: AppBoxDecorations.gradientBackground,
        child: FutureBuilder<List<Object>>(
          future: Future.wait([
            _userDataFuture,
            _pokedexFuture,
            _comprehensiveMilestonesFuture,
            _typeStatsFuture,
            _currentUserPokedexFuture,
          ]),
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
            final comprehensiveMilestonesData = snapshot.data![2] as List<dynamic>;
            final typeStats = snapshot.data![3] as Map<String, dynamic>;
            final currentUserPokedexData = snapshot.data![4] as Map<String, dynamic>;
            final caughtCount = caughtPokemon.length;
            
            // Parse comprehensive milestones
            final comprehensiveMilestones = comprehensiveMilestonesData
                .map((data) => MilestoneDefinition.fromJson(data as Map<String, dynamic>))
                .toList();
            
            // Create a Set of current user's caught Pokemon numbers for fast lookup
            final currentUserPokedex = currentUserPokedexData['pokedex'] as List<dynamic>? ?? [];
            final currentUserCaughtNumbers = currentUserPokedex
                .map((pokemon) => pokemon['number'] as int)
                .toSet();

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
                if (comprehensiveMilestones.isNotEmpty)
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
                              children:
                                  comprehensiveMilestones.map((milestone) {
                                    return ComprehensiveMilestoneBadge(
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
                if (typeStats.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: PokedexContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pokémon per Typ",
                              style: TextStyle(
                                fontFamily: 'PixelFontTitle',
                                fontSize: 18,
                                color: AppColors.primaryRed,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...typeStats.entries
                                .where((entry) => entry.value > 0)
                                .map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      children: [
                                        TypeBadge(typeName: entry.key),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${entry.value} st',
                                          style: const TextStyle(
                                            fontFamily: 'PixelFont',
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                    child: Text(
                      "${widget.userName}${widget.userName.endsWith('s') ? '' : 's'} Fångade Pokémon",
                      style: const TextStyle(
                        fontFamily: 'PixelFontTitle',
                        fontSize: 20,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
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
                        final pokemonNumber = pokemon['number'] as int;
                        final isCaughtByViewer = currentUserCaughtNumbers.contains(pokemonNumber);
                        
                        return Container(
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
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.secondaryRed,
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Container(
                                      color: Colors.white,
                                      child: isCaughtByViewer
                                          ? Image.asset(
                                              'assets/images/pkmn/${pokemon['number']}.jpg',
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) =>
                                                      Container(
                                                        color: Colors.white,
                                                        child: const Icon(
                                                          Icons.image_outlined,
                                                          size: 48,
                                                        ),
                                                      ),
                                            )
                                          : Container(
                                              color: Colors.grey.shade100,
                                              child: Center(
                                                child: Text(
                                                  '?',
                                                  style: TextStyle(
                                                    fontSize: 48,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey.shade400,
                                                  ),
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
                                      isCaughtByViewer 
                                          ? pokemon['name'] 
                                          : "#${pokemon['number']}",
                                      style: const TextStyle(
                                        fontFamily: 'PixelFont',
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    if (isCaughtByViewer)
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
