use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use lazy_static::lazy_static;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum MilestoneType {
    CountBased,
    TypeBased,
    SpecificPokemon,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MilestoneDefinition {
    pub id: String,
    pub milestone_type: MilestoneType,
    pub requirement: String,
    pub display_text: String,
    pub color: String,
    pub icon: String,
    pub order: u32,
}

lazy_static! {
    pub static ref MILESTONE_DEFINITIONS: HashMap<String, MilestoneDefinition> = {
        let mut map = HashMap::new();
        
        // Count-based milestones
        let count_milestones = vec![
            (10, "Din första 10!", "#2196F3"),
            (20, "20 Pokémon fångade!", "#4CAF50"),
            (30, "30 Pokémon - bra jobbat!", "#009688"),
            (40, "40 Pokémon i samlingen!", "#3F51B5"),
            (50, "Halvvägs till 100!", "#FF9800"),
            (60, "60 Pokémon!", "#FF5722"),
            (70, "70 Pokémon - fortsätt så!", "#F44336"),
            (80, "80 Pokémon!", "#E91E63"),
            (90, "90 Pokémon - snart 100!", "#9C27B0"),
            (100, "100 Pokémon - fantastiskt!", "#FFC107"),
            (110, "110 Pokémon!", "#FF8F00"),
            (120, "120 Pokémon!", "#FF6F00"),
            (130, "130 Pokémon!", "#E65100"),
            (140, "140 Pokémon - nästan alla!", "#FF6F00"),
            (150, "150 Pokémon - otroligt!", "#FF5722"),
            (151, "ALLA 151 - Helt fantastiskt! Vi trodde faktiskt inte att någon skulle göra det!", "#673AB7"),
        ];
        
        for (i, (count, text, color)) in count_milestones.iter().enumerate() {
            map.insert(
                format!("count_{}", count),
                MilestoneDefinition {
                    id: format!("count_{}", count),
                    milestone_type: MilestoneType::CountBased,
                    requirement: count.to_string(),
                    display_text: text.to_string(),
                    color: color.to_string(),
                    icon: count.to_string(),
                    order: i as u32,
                }
            );
        }
        
        // Type-based milestones (first Pokemon of each type)
        let type_milestones = vec![
            ("Normal", "Första Normal-typ!", "#A8A878", "Normal"),
            ("Eld", "Första Eld-typ!", "#F08030", "🔥"),
            ("Vatten", "Första Vatten-typ!", "#6890F0", "💧"),
            ("Gräs", "Första Gräs-typ!", "#78C850", "🍃"),
            ("Elektro", "Första Elektro-typ!", "#F8D030", "⚡️"),
            ("Is", "Första Is-typ!", "#98D8D8", "🧊"),
            ("Kamp", "Första Kamp-typ!", "#C03028", "🤜🤛"),
            ("Gift", "Första Gift-typ!", "#A040A0", "☠️"),
            ("Mark", "Första Mark-typ!", "#E0C068", "Mark"),
            ("Flyg", "Första Flyg-typ!", "#A890F0", "🪽"),
            ("Psykisk", "Första Psykisk-typ!", "#F85888", "Psy"),
            ("Insekt", "Första Insekt-typ!", "#A8B820", "🐜"),
            ("Sten", "Första Sten-typ!", "#B8A038", "🪨"),
            ("Spöke", "Första Spöke-typ!", "#705898", "👻"),
            ("Drake", "Första Drake-typ!", "#7038F8", "🐉"),
            ("Mörk", "Första Mörk-typ!", "#705848", "Mörk"),
            ("Stål", "Första Stål-typ!", "#B8B8D0", "Stål"),
            ("Fé", "Första Fé-typ!", "#EE99AC", "Fé"),
        ];
        
        for (i, (type_name, text, color, icon)) in type_milestones.iter().enumerate() {
            map.insert(
                format!("type_{}", type_name.to_lowercase()),
                MilestoneDefinition {
                    id: format!("type_{}", type_name.to_lowercase()),
                    milestone_type: MilestoneType::TypeBased,
                    requirement: type_name.to_string(),
                    display_text: text.to_string(),
                    color: color.to_string(),
                    icon: icon.to_string(),
                    order: 100 + i as u32,
                }
            );
        }
        
        // Special Pokemon milestones
        map.insert(
            "pokemon_144".to_string(),
            MilestoneDefinition {
                id: "pokemon_144".to_string(),
                milestone_type: MilestoneType::SpecificPokemon,
                requirement: "144".to_string(),
                display_text: "Articuno fångad!".to_string(),
                color: "#00BCD4".to_string(),
                icon: "❄️\nArticuno".to_string(),
                order: 200,
            }
        );
        
        map.insert(
            "pokemon_145".to_string(),
            MilestoneDefinition {
                id: "pokemon_145".to_string(),
                milestone_type: MilestoneType::SpecificPokemon,
                requirement: "145".to_string(),
                display_text: "Zapdos fångad!".to_string(),
                color: "#FFD700".to_string(),
                icon: "⚡️\nZapdos".to_string(),
                order: 201,
            }
        );
        
        map.insert(
            "pokemon_146".to_string(),
            MilestoneDefinition {
                id: "pokemon_146".to_string(),
                milestone_type: MilestoneType::SpecificPokemon,
                requirement: "146".to_string(),
                display_text: "Moltres fångad!".to_string(),
                color: "#FF6B35".to_string(),
                icon: "🔥\nMoltres".to_string(),
                order: 202,
            }
        );
        
        map.insert(
            "pokemon_150".to_string(),
            MilestoneDefinition {
                id: "pokemon_150".to_string(),
                milestone_type: MilestoneType::SpecificPokemon,
                requirement: "150".to_string(),
                display_text: "Mewtwo fångad!".to_string(),
                color: "#9C27B0".to_string(),
                icon: "✨✨\nMewtwo".to_string(),
                order: 203,
            }
        );
        
        map.insert(
            "pokemon_151".to_string(),
            MilestoneDefinition {
                id: "pokemon_151".to_string(),
                milestone_type: MilestoneType::SpecificPokemon,
                requirement: "151".to_string(),
                display_text: "Mew fångad!".to_string(),
                color: "#FF69B4".to_string(),
                icon: "✨\nMew".to_string(),
                order: 204,
            }
        );
        
        map.insert(
            "pokemon_312798312".to_string(),
            MilestoneDefinition {
                id: "pokemon_312798312".to_string(),
                milestone_type: MilestoneType::SpecificPokemon,
                requirement: "312798312".to_string(),
                display_text: "Hittat bug-pokémon MissingNo!".to_string(),
                color: "#757575".to_string(),
                icon: "👾\nMissingNo".to_string(),
                order: 205,
            }
        );
        
        // Legendary trio milestone
        map.insert(
            "legendary_birds".to_string(),
            MilestoneDefinition {
                id: "legendary_birds".to_string(),
                milestone_type: MilestoneType::SpecificPokemon,
                requirement: "144,145,146".to_string(),
                display_text: "Alla tre legendariska fåglar hittade!".to_string(),
                color: "#FFD700".to_string(),
                icon: "❄️⚡️🔥".to_string(),
                order: 206,
            }
        );
        
        map
    };
}

pub fn get_milestone_definition(milestone_id: &str) -> Option<MilestoneDefinition> {
    MILESTONE_DEFINITIONS.get(milestone_id).cloned()
}

pub fn get_count_milestone_for_count(count: u32) -> Option<MilestoneDefinition> {
    MILESTONE_DEFINITIONS.get(&format!("count_{}", count)).cloned()
}

pub fn get_type_milestone_for_type(type_name: &str) -> Option<MilestoneDefinition> {
    MILESTONE_DEFINITIONS.get(&format!("type_{}", type_name.to_lowercase())).cloned()
}

pub fn get_pokemon_milestone(pokemon_id: u32) -> Option<MilestoneDefinition> {
    MILESTONE_DEFINITIONS.get(&format!("pokemon_{}", pokemon_id)).cloned()
}