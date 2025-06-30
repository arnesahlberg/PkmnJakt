import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/pokedex_container.dart';
import '../models/milestone.dart';

class ComprehensiveMilestoneScreen extends StatelessWidget {
  final List<MilestoneDefinition> milestones;
  final int currentPokemonCount;
  final String userName;

  const ComprehensiveMilestoneScreen({
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
                      "${userName}s Prestationer",
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
                ComprehensiveMilestoneDisplay(
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

class ComprehensiveMilestoneDisplay extends StatelessWidget {
  final List<MilestoneDefinition> milestones;
  final int currentPokemonCount;

  const ComprehensiveMilestoneDisplay({
    super.key,
    required this.milestones,
    this.currentPokemonCount = 0,
  });

  Map<String, List<MilestoneDefinition>> getMilestonesByType() {
    final Map<String, List<MilestoneDefinition>> categories = {
      'Framsteg': [],
      'Första av varje typ': [],
      'Speciella Pokémon': [],
    };

    for (MilestoneDefinition milestone in milestones) {
      switch (milestone.milestoneType) {
        case MilestoneType.countBased:
          categories['Framsteg']!.add(milestone);
          break;
        case MilestoneType.typeBased:
          categories['Första av varje typ']!.add(milestone);
          break;
        case MilestoneType.specificPokemon:
          categories['Speciella Pokémon']!.add(milestone);
          break;
      }
    }

    // Remove empty categories and sort milestones within each category
    categories.removeWhere((key, value) => value.isEmpty);
    for (var category in categories.values) {
      category.sort((a, b) => a.order.compareTo(b.order));
    }

    return categories;
  }

  Color _parseColor(String colorString) {
    try {
      // Remove the # if present
      String hexColor = colorString.replaceAll('#', '');
      // Add alpha if not present
      if (hexColor.length == 6) {
        hexColor = 'FF' + hexColor;
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      // Fallback to a nice color if parsing fails
      return Colors.amber;
    }
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case 'Framsteg':
        return Colors.blue.shade100;
      case 'Första av varje typ':
        return Colors.green.shade100;
      case 'Speciella Pokémon':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color getCategoryTextColor(String category) {
    switch (category) {
      case 'Framsteg':
        return Colors.blue.shade800;
      case 'Första av varje typ':
        return Colors.green.shade800;
      case 'Speciella Pokémon':
        return Colors.purple.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final badgeSize = screenWidth < 600 ? 64.0 : 80.0;
    final categories = getMilestonesByType();

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF992109), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alla Prestationer',
              style: TextStyle(
                fontFamily: 'PixelFontTitle',
                fontSize: 18,
                color: Color(0xFFE3350D),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categories.entries.map(
              (entry) => _buildCategorySection(
                entry.key,
                entry.value,
                badgeSize,
                screenWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    String categoryName,
    List<MilestoneDefinition> milestones,
    double badgeSize,
    double screenWidth,
  ) {
    if (milestones.isEmpty) return const SizedBox.shrink();

    final crossAxisCount = categoryName == 'Framsteg'
        ? (screenWidth < 400 ? 4 : screenWidth < 600 ? 6 : 8)
        : (screenWidth < 400 ? 3 : screenWidth < 600 ? 4 : 6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: getCategoryColor(categoryName),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              categoryName,
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: getCategoryTextColor(categoryName),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              return _buildMilestoneBadge(milestones[index], badgeSize);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneBadge(MilestoneDefinition milestone, double size) {
    final color = _parseColor(milestone.color);
    
    // Handle different icon formats
    String displayText;
    double fontSize;
    
    if (milestone.isCountBased) {
      // For count-based milestones, just show the number
      displayText = milestone.requirement;
      fontSize = size * 0.4;
    } else {
      // For other milestones, show the icon (which might contain newlines and text)
      displayText = milestone.icon;
      // Adjust font size based on content
      if (milestone.icon.contains('\n')) {
        fontSize = size * 0.18; // Smaller for multi-line text
      } else if (milestone.icon.length > 3) {
        fontSize = size * 0.25; // Medium for longer text
      } else {
        fontSize = size * 0.4; // Larger for short icons
      }
    }
    
    return GestureDetector(
      onTap: () {
        // Could show milestone details here
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            displayText,
            style: TextStyle(
              fontFamily: 'PixelFontTitle',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}