import 'package:flutter/material.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/highscore_list.dart';
import '../api_calls.dart';
import '../constants.dart';

class HighscoreScreen extends StatefulWidget {
  const HighscoreScreen({super.key});

  @override
  State<HighscoreScreen> createState() => _HighscoreScreenState();
}

class _HighscoreScreenState extends State<HighscoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoading = false;
  List<dynamic> _scores = [];

  @override
  void initState() {
    super.initState();
    _fetchScores();
  }

  Future<void> _fetchScores() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getGlobalHighscore(
        _pageSize,
        _currentPage * _pageSize,
        filter: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
      setState(() {
        _scores = result['user_scores'] as List<dynamic>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fel vid hämtning: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    _currentPage++;
    _fetchScores();
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _currentPage--;
      _fetchScores();
    }
  }

  void _onSearch() {
    _currentPage = 0;
    _fetchScores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Highscore'),
      body: Container(
        decoration: AppBoxDecorations.gradientBackground,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: AppInputDecorations.simpleInputDecoration(
                        'Sök på namn eller id',
                      ),
                      onSubmitted: (_) => _onSearch(),
                    ),
                    const SizedBox(height: 16),
                    HighscoreList(
                      highscores: _scores,
                      showContainer: false,
                      title: 'Highscore',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _currentPage > 0 ? _prevPage : null,
                          child: const Text('Föregående'),
                        ),
                        ElevatedButton(
                          onPressed: _scores.length == _pageSize ? _nextPage : null,
                          child: const Text('Nästa'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
