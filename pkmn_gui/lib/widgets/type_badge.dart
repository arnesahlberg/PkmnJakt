import 'package:flutter/material.dart';

class TypeBadge extends StatelessWidget {
  final String typeName;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const TypeBadge({
    super.key,
    required this.typeName,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  static const Map<String, Color> typeColors = {
    'Gräs': Color(0xFF78C850),
    'Gift': Color(0xFFA040A0),
    'Eld': Color(0xFFF08030),
    'Vatten': Color(0xFF6890F0),
    'Elektro': Color(0xFFF8D030),
    'Is': Color(0xFF98D8D8),
    'Kamp': Color(0xFFC03028),
    'Mark': Color(0xFFE0C068),
    'Flyg': Color(0xFFA890F0),
    'Flygande': Color(0xFFA890F0), // Keep for backwards compatibility
    'Psykisk': Color(0xFFF85888),
    'Insekt': Color(0xFFA8B820),
    'Sten': Color(0xFFB8A038),
    'Spöke': Color(0xFF705898),
    'Drake': Color(0xFF7038F8),
    'Stål': Color(0xFFB8B8D0),
    'Normal': Color(0xFFA8A878),
    'Mörk': Color(0xFF705848),
    'Fé': Color(0xFFEE99AC),
  };

  @override
  Widget build(BuildContext context) {
    final color = typeColors[typeName] ?? Colors.grey;
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        typeName.toUpperCase(),
        style: TextStyle(
          fontFamily: 'PixelFont',
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class TypeBadgeList extends StatelessWidget {
  final List<String>? types;
  final double fontSize;
  final double spacing;

  const TypeBadgeList({
    super.key,
    required this.types,
    this.fontSize = 12,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (types == null || types!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: types!.map((type) => TypeBadge(
        typeName: type,
        fontSize: fontSize,
      )).toList(),
    );
  }
}