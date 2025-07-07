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

  Color _getCountColor(int count) {
    if (count == 0) return Colors.red.shade900;
    if (count >= 20) return Colors.green.shade700;
    if (count >= 10) return Colors.yellow.shade700;
    if (count >= 5) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
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
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontFamily: 'PixelFont',
                              ),
                              cursorColor: AppColors.primaryRed,
                              decoration: InputDecoration(
                                labelText: 'Sök Pokémon',
                                labelStyle: AppTextStyles.labelMedium,
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.textPrimary,
                                ),
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
                                        label: Text('Antal', style: TextStyle(color: AppColors.textPrimary)),
                                      ),
                                      ButtonSegment(
                                        value: 'number',
                                        label: Text('Nummer', style: TextStyle(color: AppColors.textPrimary)),
                                      ),
                                      ButtonSegment(
                                        value: 'name',
                                        label: Text('Namn', style: TextStyle(color: AppColors.textPrimary)),
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
                                      backgroundColor: MaterialStateProperty.resolveWith((states) {
                                        if (states.contains(MaterialState.selected)) {
                                          return AppColors.primaryRed;
                                        }
                                        return Colors.white;
                                      }),
                                      foregroundColor: MaterialStateProperty.resolveWith((states) {
                                        if (states.contains(MaterialState.selected)) {
                                          return Colors.white;
                                        }
                                        return AppColors.textPrimary;
                                      }),
                                      side: MaterialStateProperty.all(
                                        BorderSide(color: AppColors.primaryRed, width: 2),
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
                          final countColor = _getCountColor(count);

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
                                  // Count
                                  Text(
                                    count.toString(),
                                    style: AppTextStyles.titleLarge.copyWith(
                                      color: countColor,
                                      fontWeight: FontWeight.bold,
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
                ),
              ),
      ),
    );
  }
}