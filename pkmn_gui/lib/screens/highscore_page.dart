import 'dart:async';
import 'package:flutter/material.dart';
import '../api_calls.dart';
import '../constants.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/pokedex_container.dart';
import '../widgets/pokedex_button.dart';
import '../widgets/milestone_badge.dart';
import '../widgets/highscore_list.dart';
import 'user_statistics_screen.dart';

class HighscorePage extends StatefulWidget {
  const HighscorePage({super.key});

  @override
  State<HighscorePage> createState() => _HighscorePageState();
}

class _HighscorePageState extends State<HighscorePage> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _scores = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  bool _isLoading = false;
  String? _error;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadHighscores();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _currentPage = 1;
      });
      _loadHighscores();
    });
  }

  Future<void> _loadHighscores() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> response;
      if (_searchController.text.isEmpty) {
        response = await ApiService.getHighscores(page: _currentPage);
      } else {
        response = await ApiService.searchHighscores(
          search: _searchController.text,
          page: _currentPage,
        );
      }

      if (mounted) {
        setState(() {
          _scores = response['scores'] ?? [];
          _totalPages = response['total_pages'] ?? 1;
          _totalCount = response['total_count'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
      _loadHighscores();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "Highscore"),
      body: Container(
        decoration: AppBoxDecorations.gradientBackground,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PokedexContainer(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Sök användarnamn eller ID...",
                    hintStyle: TextStyle(
                      fontFamily: 'PixelFont',
                      color: Colors.grey.shade600,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primaryRed,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'PixelFont', fontSize: 16),
                ),
              ),
            ),

            // Results count
            if (!_isLoading && _scores.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Visar ${_scores.length} av $_totalCount användare",
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

            // Highscore list
            Expanded(child: _buildContent()),

            // Pagination
            if (_totalPages > 1)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: PokedexContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed:
                            _currentPage > 1
                                ? () => _goToPage(_currentPage - 1)
                                : null,
                        color: AppColors.primaryRed,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Sida $_currentPage av $_totalPages",
                        style: const TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed:
                            _currentPage < _totalPages
                                ? () => _goToPage(_currentPage + 1)
                                : null,
                        color: AppColors.primaryRed,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _scores.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
        ),
      );
    }

    if (_error != null) {
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
              "Kunde inte ladda highscore",
              style: const TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 16,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: 8),
            PokedexButton(
              onPressed: _loadHighscores,
              child: const Text("Försök igen"),
            ),
          ],
        ),
      );
    }

    if (_scores.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? "Ingen highscore data än"
              : "Inga resultat hittades",
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: HighscoreList(
        highscores: _scores,
        title: "", // Empty title since we have the title in the app bar
        showContainer:
            true, // Don't show container since we're already in a styled page
        clickable: true,
        showFirstPlacesIcons:
            _currentPage == 1, // Only show medals on first page
      ),
    );
  }
}
