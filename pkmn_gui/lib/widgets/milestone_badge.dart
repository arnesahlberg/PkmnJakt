import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/milestone.dart';

class MilestoneBadge extends StatelessWidget {
  final int milestone;
  final double size;

  const MilestoneBadge({super.key, required this.milestone, this.size = 24});

  Color get badgeColor {
    switch (milestone) {
      case 10:
        return Colors.blue.shade400;
      case 20:
        return Colors.green.shade600;
      case 30:
        return Colors.teal.shade600;
      case 40:
        return Colors.indigo.shade600;
      case 50:
        return Colors.orange.shade600;
      case 60:
        return Colors.deepOrange.shade600;
      case 70:
        return Colors.red.shade600;
      case 80:
        return Colors.pink.shade600;
      case 90:
        return Colors.purple.shade600;
      case 100:
        return Colors.amber.shade600;
      case 110:
        return Colors.amber.shade700;
      case 120:
        return Colors.amber.shade800;
      case 130:
        return Colors.amber.shade900;
      case 140:
        return const Color(0xFFFF8F00); // Deep amber
      case 150:
        return const Color(0xFFFF6F00); // Darker amber
      case 151:
        return Colors.deepPurple.shade600; // Special purple for completing all
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border: Border.all(color: badgeColor.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          milestone.toString(),
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: size * 0.55,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class ComprehensiveMilestoneBadge extends StatelessWidget {
  final MilestoneDefinition milestone;
  final double size;

  const ComprehensiveMilestoneBadge({
    super.key,
    required this.milestone,
    this.size = 32,
  });

  Color _parseColor(String colorString) {
    try {
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(milestone.color);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          milestone.icon.length > 3
              ? milestone.icon.substring(0, 2)
              : milestone.icon,
          style: TextStyle(fontSize: size * 0.5, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class MilestoneBadgeRow extends StatelessWidget {
  final List<int> milestones;
  final double badgeSize;

  const MilestoneBadgeRow({
    super.key,
    required this.milestones,
    this.badgeSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();

    // Only show the highest milestone
    final highestMilestone = milestones.last;

    return MilestoneBadge(milestone: highestMilestone, size: badgeSize);
  }
}

class AllMilestoneBadges extends StatelessWidget {
  final List<int> milestones;
  final double badgeSize;

  const AllMilestoneBadges({
    super.key,
    required this.milestones,
    this.badgeSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children:
          milestones
              .map(
                (milestone) =>
                    MilestoneBadge(milestone: milestone, size: badgeSize),
              )
              .toList(),
    );
  }
}

class ResponsiveMilestoneDisplay extends StatelessWidget {
  final List<int> milestones;
  final int currentPokemonCount;

  const ResponsiveMilestoneDisplay({
    super.key,
    required this.milestones,
    this.currentPokemonCount = 0,
  });

  Map<String, List<int>> getMilestoneTiers() {
    final Map<String, List<int>> tiers = {
      'Nybörjare': [],
      'Erfaren': [],
      'Expert': [],
      'Mästare': [],
    };

    for (int milestone in milestones) {
      if (milestone <= 30) {
        tiers['Nybörjare']!.add(milestone);
      } else if (milestone <= 60) {
        tiers['Erfaren']!.add(milestone);
      } else if (milestone <= 100) {
        tiers['Expert']!.add(milestone);
      } else {
        tiers['Mästare']!.add(milestone);
      }
    }

    // Remove empty tiers
    tiers.removeWhere((key, value) => value.isEmpty);
    return tiers;
  }

  int? getNextMilestone() {
    const allMilestones = [
      10,
      20,
      30,
      40,
      50,
      60,
      70,
      80,
      90,
      100,
      110,
      120,
      130,
      140,
      150,
      151,
    ];
    for (int milestone in allMilestones) {
      if (!milestones.contains(milestone)) {
        return milestone;
      }
    }
    return null;
  }

  Color getTierColor(String tier) {
    switch (tier) {
      case 'Nybörjare':
        return Colors.green.shade100;
      case 'Erfaren':
        return Colors.blue.shade100;
      case 'Expert':
        return Colors.orange.shade100;
      case 'Mästare':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color getTierTextColor(String tier) {
    switch (tier) {
      case 'Nybörjare':
        return Colors.green.shade800;
      case 'Erfaren':
        return Colors.blue.shade800;
      case 'Expert':
        return Colors.orange.shade800;
      case 'Mästare':
        return Colors.purple.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final badgeSize = screenWidth < 600 ? 22.0 : 28.0;
    final tiers = getMilestoneTiers();
    final nextMilestone = getNextMilestone();

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
              'Framsteg',
              style: TextStyle(
                fontFamily: 'PixelFontTitle',
                fontSize: 18,
                color: Color(0xFFE3350D),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (nextMilestone != null) ...[
              const SizedBox(height: 8),
              _buildNextMilestoneIndicator(nextMilestone),
            ],
            const SizedBox(height: 16),
            ...tiers.entries.map(
              (entry) => _buildTierSection(
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

  Widget _buildNextMilestoneIndicator(int nextMilestone) {
    final progress = currentPokemonCount / nextMilestone;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Light orange background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF8F00),
          width: 2,
        ), // Vibrant orange border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_outlined,
                color: Color(0xFFE65100), // Dark orange
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Nästa mål: $nextMilestone Pokémon',
                style: const TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(
                    0xFFE65100,
                  ), // Dark orange for better readability
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFFFE0B2), // Light orange background
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFFFF8F00),
            ), // Vibrant orange
          ),
          const SizedBox(height: 4),
          Text(
            '$currentPokemonCount / $nextMilestone',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFBF360C), // Darker orange for contrast
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierSection(
    String tierName,
    List<int> milestones,
    double badgeSize,
    double screenWidth,
  ) {
    if (milestones.isEmpty) return const SizedBox.shrink();

    final crossAxisCount =
        screenWidth < 400
            ? 4
            : screenWidth < 600
            ? 6
            : 8;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: getTierColor(tierName),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tierName,
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: getTierTextColor(tierName),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              return MilestoneBadge(
                milestone: milestones[index],
                size: badgeSize,
              );
            },
          ),
        ],
      ),
    );
  }
}

class MilestoneSummary extends StatelessWidget {
  final List<int> milestones;
  final List<MilestoneDefinition>? comprehensiveMilestones;
  final int currentPokemonCount;
  final VoidCallback onViewAll;

  const MilestoneSummary({
    super.key,
    required this.milestones,
    this.comprehensiveMilestones,
    required this.onViewAll,
    this.currentPokemonCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate total achievements
    final totalAchievements =
        comprehensiveMilestones?.length ?? milestones.length;

    if (totalAchievements == 0) return const SizedBox.shrink();

    // Get a mix of different milestone types to display
    List<Widget> displayBadges = [];

    if (comprehensiveMilestones != null &&
        comprehensiveMilestones!.isNotEmpty) {
      // Sort by order to get most recent
      final sortedMilestones = List<MilestoneDefinition>.from(
        comprehensiveMilestones!,
      )..sort((a, b) => b.order.compareTo(a.order));

      // Get a mix: highest count milestone, a type milestone, and a special milestone
      MilestoneDefinition? highestCount;
      MilestoneDefinition? typeExample;
      MilestoneDefinition? specialExample;

      for (var m in sortedMilestones) {
        if (m.milestoneType == MilestoneType.countBased &&
            highestCount == null) {
          highestCount = m;
        } else if (m.milestoneType == MilestoneType.typeBased &&
            typeExample == null) {
          typeExample = m;
        } else if (m.milestoneType == MilestoneType.specificPokemon &&
            specialExample == null) {
          specialExample = m;
        }
      }

      // Add them to display in priority order
      if (highestCount != null) {
        displayBadges.add(
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ComprehensiveMilestoneBadge(
              milestone: highestCount,
              size: 32,
            ),
          ),
        );
      }
      if (specialExample != null && displayBadges.length < 3) {
        displayBadges.add(
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ComprehensiveMilestoneBadge(
              milestone: specialExample,
              size: 32,
            ),
          ),
        );
      }
      if (typeExample != null && displayBadges.length < 3) {
        displayBadges.add(
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ComprehensiveMilestoneBadge(
              milestone: typeExample,
              size: 32,
            ),
          ),
        );
      }

      // Fill remaining slots with other recent milestones
      int added = displayBadges.length;
      for (var m in sortedMilestones) {
        if (displayBadges.length >= 3) break;
        if (m != highestCount && m != typeExample && m != specialExample) {
          displayBadges.add(
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ComprehensiveMilestoneBadge(milestone: m, size: 32),
            ),
          );
        }
      }
    } else {
      // Fallback to old milestones display
      final displayMilestones =
          milestones.length > 3
              ? milestones.sublist(milestones.length - 3)
              : milestones;

      displayBadges =
          displayMilestones
              .map(
                (milestone) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: MilestoneBadge(milestone: milestone, size: 32),
                ),
              )
              .toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                totalAchievements == 1
                    ? 'Du har uppnått 1 prestation!'
                    : 'Du har uppnått $totalAchievements prestationer!',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.secondaryRed,
                ),
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Visa alla',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.secondaryRed,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    color: AppColors.secondaryRed,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...displayBadges,
            if (totalAchievements > 3)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '+${totalAchievements - 3}',
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
