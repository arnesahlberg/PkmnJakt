import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/pokedex_container.dart';
import '../widgets/milestone_badge.dart';

class MilestoneScreen extends StatelessWidget {
  final List<int> milestones;
  final int currentPokemonCount;
  final String userName;

  const MilestoneScreen({
    super.key,
    required this.milestones,
    required this.currentPokemonCount,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: "Mina Prestationer",
        showBackButton: true,
      ),
      body: Container(
        decoration: AppBoxDecorations.gradientBackground,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PokedexContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$userName:s Prestationer",
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: UIConstants.spacing8),
                    Text(
                      milestones.isEmpty
                          ? "Inga prestationer uppnådda än!"
                          : milestones.length == 1
                              ? "Du har uppnått 1 prestation!"
                              : "Du har uppnått ${milestones.length} prestationer!",
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.secondaryRed,
                      ),
                    ),
                    if (currentPokemonCount > 0) ...[
                      const SizedBox(height: UIConstants.spacing8),
                      Text(
                        "Du har fångat $currentPokemonCount Pokémon",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.secondaryRed,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (milestones.isNotEmpty) ...[
                const SizedBox(height: UIConstants.spacing24),
                ResponsiveMilestoneDisplay(
                  milestones: milestones,
                  currentPokemonCount: currentPokemonCount,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}