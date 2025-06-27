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
    if (milestone == 151) return Colors.purple;
    if (milestone >= 100) return Colors.amber;
    if (milestone >= 50) return Colors.orange;
    return Colors.blue;
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
    
    // Group milestones for display
    final displayMilestones = <int>[];
    
    // Show first few milestones
    if (milestones.isNotEmpty) {
      displayMilestones.addAll(milestones.take(3));
    }
    
    // Always show highest milestone if more than 3
    if (milestones.length > 3 && !displayMilestones.contains(milestones.last)) {
      displayMilestones.add(milestones.last);
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < displayMilestones.length; i++) ...[
          if (i == 3 && milestones.length > 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '...',
                style: TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: badgeSize * 0.6,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          MilestoneBadge(
            milestone: displayMilestones[i],
            size: badgeSize,
          ),
          if (i < displayMilestones.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}