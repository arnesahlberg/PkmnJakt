import 'package:json_annotation/json_annotation.dart';

part 'milestone.g.dart';

enum MilestoneType {
  @JsonValue('CountBased')
  countBased,
  @JsonValue('TypeBased')
  typeBased,
  @JsonValue('SpecificPokemon')
  specificPokemon,
}

@JsonSerializable()
class MilestoneDefinition {
  final String id;
  @JsonKey(name: 'milestone_type')
  final MilestoneType milestoneType;
  final String requirement;
  @JsonKey(name: 'display_text')
  final String displayText;
  final String color;
  final String icon;
  final int order;

  MilestoneDefinition({
    required this.id,
    required this.milestoneType,
    required this.requirement,
    required this.displayText,
    required this.color,
    required this.icon,
    required this.order,
  });

  factory MilestoneDefinition.fromJson(Map<String, dynamic> json) =>
      _$MilestoneDefinitionFromJson(json);

  Map<String, dynamic> toJson() => _$MilestoneDefinitionToJson(this);

  /// Returns whether this is a count-based milestone
  bool get isCountBased => milestoneType == MilestoneType.countBased;

  /// Returns whether this is a type-based milestone
  bool get isTypeBased => milestoneType == MilestoneType.typeBased;

  /// Returns whether this is a specific Pokemon milestone
  bool get isSpecificPokemon => milestoneType == MilestoneType.specificPokemon;

  /// Get the count value for count-based milestones
  int? get countValue {
    if (isCountBased) {
      return int.tryParse(requirement);
    }
    return null;
  }

  /// Get the type name for type-based milestones
  String? get typeName {
    if (isTypeBased) {
      return requirement;
    }
    return null;
  }

  /// Get the Pokemon ID for specific Pokemon milestones
  int? get pokemonId {
    if (isSpecificPokemon && requirement.contains(',')) {
      // This is a special case like legendary birds
      return null;
    }
    if (isSpecificPokemon) {
      return int.tryParse(requirement);
    }
    return null;
  }

  /// Get the Pokemon IDs for multi-Pokemon milestones (like legendary birds)
  List<int>? get pokemonIds {
    if (isSpecificPokemon && requirement.contains(',')) {
      return requirement.split(',').map((id) => int.parse(id.trim())).toList();
    }
    return null;
  }
}