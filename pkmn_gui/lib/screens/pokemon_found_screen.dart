import 'package:flutter/material.dart';
import 'package:pkmn_gui/api_calls.dart';
import 'package:pkmn_gui/constants.dart';
import 'package:pkmn_gui/widgets/common_app_bar.dart';
import 'package:pkmn_gui/widgets/pokedex_container.dart';

class PokemonFoundScreen extends StatefulWidget {
  const PokemonFoundScreen({super.key});

  @override
  State<PokemonFoundScreen> createState() => _PokemonFoundScreenState();
}

class _PokemonFoundScreenState extends State<PokemonFoundScreen> {
  List<dynamic> _pokemonCounts = [];
  List<dynamic> _filteredPokemonCounts = [];
  bool _isLoading = true;
  String _sortBy = 'count'; // 'count', 'number', 'name'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final result = await ApiService.getPokemonFoundCounts();
      setState(() {
        _pokemonCounts = result['pokemon_counts'] ?? [];
        _applyFiltersAndSort();
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

  void _applyFiltersAndSort() {
    // Filter by search query
    _filteredPokemonCounts = _pokemonCounts.where((pokemon) {
      final name = pokemon['pokemon_name'].toString().toLowerCase();
      final number = pokemon['pokemon_number'].toString();
      return name.contains(_searchQuery.toLowerCase()) || 
             number.contains(_searchQuery);
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'count':
        _filteredPokemonCounts.sort((a, b) {
          int countCompare = b['count'].compareTo(a['count']);
          if (countCompare != 0) return countCompare;
          return a['pokemon_name'].compareTo(b['pokemon_name']);
        });
        break;
      case 'number':
        _filteredPokemonCounts.sort((a, b) => 
          a['pokemon_number'].compareTo(b['pokemon_number']));
        break;
      case 'name':
        _filteredPokemonCounts.sort((a, b) => 
          a['pokemon_name'].compareTo(b['pokemon_name']));
        break;
    }
  }

  Color _getDifficultyColor(int count, int maxCount) {
    if (count == 0) return Colors.red.shade900;
    if (maxCount == 0) return Colors.grey;
    
    double ratio = count / maxCount;
    if (ratio >= 0.7) return Colors.green.shade700;
    if (ratio >= 0.4) return Colors.yellow.shade700;
    if (ratio >= 0.2) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  String _getDifficultyText(int count, int maxCount) {
    if (count == 0) return 'Ej hittad';
    if (maxCount == 0) return 'Okänd';
    
    double ratio = count / maxCount;
    if (ratio >= 0.7) return 'Lätt';
    if (ratio >= 0.4) return 'Medium';
    if (ratio >= 0.2) return 'Svår';
    return 'Mycket svår';
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = _pokemonCounts.isEmpty ? 0 : 
      _pokemonCounts.map((p) => p['count'] as int).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: const CommonAppBar(
        title: "Hittade Pokémon",
        showBackButton: true,
      ),
      body: Container(
        decoration: AppBoxDecorations.gradientBackground,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryRed,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primaryRed,
                backgroundColor: AppColors.white,
                child: Column(
                  children: [
                    // Search and Sort Controls
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: PokedexContainer(
                        child: Column(
                          children: [
                            // Search field
                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                  _applyFiltersAndSort();
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Sök Pokémon',
                                labelStyle: AppTextStyles.labelMedium,
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    UIConstants.borderRadius8,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    UIConstants.borderRadius8,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.secondaryRed,
                                    width: UIConstants.borderWidth2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    UIConstants.borderRadius8,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryRed,
                                    width: UIConstants.borderWidth2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: UIConstants.spacing12),
                            // Sort options
                            Row(
                              children: [
                                const Text(
                                  'Sortera efter:',
                                  style: AppTextStyles.labelMedium,
                                ),
                                const SizedBox(width: UIConstants.spacing12),
                                Expanded(
                                  child: SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(
                                        value: 'count',
                                        label: Text('Antal'),
                                      ),
                                      ButtonSegment(
                                        value: 'number',
                                        label: Text('Nummer'),
                                      ),
                                      ButtonSegment(
                                        value: 'name',
                                        label: Text('Namn'),
                                      ),
                                    ],
                                    selected: {_sortBy},
                                    onSelectionChanged: (Set<String> newSelection) {
                                      setState(() {
                                        _sortBy = newSelection.first;
                                        _applyFiltersAndSort();
                                      });
                                    },
                                    style: ButtonStyle(
                                      textStyle: MaterialStateProperty.all(
                                        const TextStyle(
                                          fontFamily: 'PixelFont',
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Pokemon list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _filteredPokemonCounts.length,
                        itemBuilder: (context, index) {
                          final pokemon = _filteredPokemonCounts[index];
                          final count = pokemon['count'] as int;
                          final difficultyColor = _getDifficultyColor(count, maxCount);
                          final difficultyText = _getDifficultyText(count, maxCount);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: PokedexContainer(
                              child: Row(
                                children: [
                                  // Pokemon image
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        UIConstants.borderRadius8,
                                      ),
                                      border: Border.all(
                                        color: AppColors.secondaryRed,
                                        width: UIConstants.borderWidth2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.asset(
                                        'assets/images/pkmn/${pokemon['pokemon_number']}.jpg',
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.image_not_supported,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: UIConstants.spacing12),
                                  // Pokemon info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pokemon['pokemon_name'],
                                          style: AppTextStyles.titleSmall,
                                        ),
                                        Text(
                                          'Nr. ${pokemon['pokemon_number']}',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Count and difficulty
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        count.toString(),
                                        style: AppTextStyles.titleMedium.copyWith(
                                          color: difficultyColor,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: difficultyColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            UIConstants.borderRadius8,
                                          ),
                                          border: Border.all(
                                            color: difficultyColor,
                                            width: UIConstants.borderWidth1,
                                          ),
                                        ),
                                        child: Text(
                                          difficultyText,
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: difficultyColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}