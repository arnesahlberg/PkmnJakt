// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MilestoneDefinition _$MilestoneDefinitionFromJson(Map<String, dynamic> json) =>
    MilestoneDefinition(
      id: json['id'] as String,
      milestoneType: $enumDecode(
        _$MilestoneTypeEnumMap,
        json['milestone_type'],
      ),
      requirement: json['requirement'] as String,
      displayText: json['display_text'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      order: (json['order'] as num).toInt(),
    );

Map<String, dynamic> _$MilestoneDefinitionToJson(
  MilestoneDefinition instance,
) => <String, dynamic>{
  'id': instance.id,
  'milestone_type': _$MilestoneTypeEnumMap[instance.milestoneType]!,
  'requirement': instance.requirement,
  'display_text': instance.displayText,
  'color': instance.color,
  'icon': instance.icon,
  'order': instance.order,
};

const _$MilestoneTypeEnumMap = {
  MilestoneType.countBased: 'CountBased',
  MilestoneType.typeBased: 'TypeBased',
  MilestoneType.specificPokemon: 'SpecificPokemon',
};
