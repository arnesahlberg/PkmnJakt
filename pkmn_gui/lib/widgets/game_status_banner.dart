import 'package:flutter/material.dart';
import '../constants.dart';
import '../api_calls.dart';
import 'pokedex_button.dart';

class GameStatusBanner extends StatefulWidget {
  final VoidCallback? onStatisticsPressed;
  final bool showButton;
  
  const GameStatusBanner({
    super.key,
    this.onStatisticsPressed,
    this.showButton = true,
  });

  @override
  State<GameStatusBanner> createState() => _GameStatusBannerState();
}

class _GameStatusBannerState extends State<GameStatusBanner> {
  bool? _isGameOver;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkGameStatus();
  }

  Future<void> _checkGameStatus() async {
    try {
      final response = await ApiService.isGameOver();
      if (mounted) {
        setState(() {
          _isGameOver = response['is_game_over'] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      // In case of error, don't show the banner
      if (mounted) {
        setState(() {
          _isGameOver = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isGameOver != true) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spelet är slut!',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tack för att du deltog i Pokémon-jakten!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.showButton) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PokedexButton(
                onPressed: widget.onStatisticsPressed ??
                    () {
                      Navigator.pushNamed(context, '/game_statistics');
                    },
                child: const Text('Se spelstatistik'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}