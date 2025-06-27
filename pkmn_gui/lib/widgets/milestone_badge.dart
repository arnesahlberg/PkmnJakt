import 'package:flutter/material.dart';
import '../constants.dart';

class MilestoneBadge extends StatelessWidget {
  final int milestone;
  final double size;

  const MilestoneBadge({
    super.key,
    required this.milestone,
    this.size = 24,
  });

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
        border: Border.all(
          color: badgeColor.withOpacity(0.7),
          width: 1.5,
        ),
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
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
    
    return MilestoneBadge(
      milestone: highestMilestone,
      size: badgeSize,
    );
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
      children: milestones.map((milestone) => 
        MilestoneBadge(
          milestone: milestone,
          size: badgeSize,
        )
      ).toList(),
    );
  }
}