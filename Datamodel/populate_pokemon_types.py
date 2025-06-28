#!/usr/bin/env python3
"""
Populate Pokemon types in the database with Swedish type names
"""

import sqlite3
import os

# Pokemon type data for Gen 1 (including MissingNo) with Swedish type names
pokemon_types = {
    1: ["Gräs", "Gift"],         # Bulbasaur
    2: ["Gräs", "Gift"],         # Ivysaur
    3: ["Gräs", "Gift"],         # Venusaur
    4: ["Eld"],                  # Charmander
    5: ["Eld"],                  # Charmeleon
    6: ["Eld", "Flyg"],          # Charizard
    7: ["Vatten"],               # Squirtle
    8: ["Vatten"],               # Wartortle
    9: ["Vatten"],               # Blastoise
    10: ["Insekt"],              # Caterpie
    11: ["Insekt"],              # Metapod
    12: ["Insekt", "Flyg"],      # Butterfree
    13: ["Insekt", "Gift"],      # Weedle
    14: ["Insekt", "Gift"],      # Kakuna
    15: ["Insekt", "Gift"],      # Beedrill
    16: ["Normal", "Flyg"],      # Pidgey
    17: ["Normal", "Flyg"],      # Pidgeotto
    18: ["Normal", "Flyg"],      # Pidgeot
    19: ["Normal"],              # Rattata
    20: ["Normal"],              # Raticate
    21: ["Normal", "Flyg"],      # Spearow
    22: ["Normal", "Flyg"],      # Fearow
    23: ["Gift"],                # Ekans
    24: ["Gift"],                # Arbok
    25: ["Elektro"],             # Pikachu
    26: ["Elektro"],             # Raichu
    27: ["Mark"],                # Sandshrew
    28: ["Mark"],                # Sandslash
    29: ["Gift"],                # Nidoran♀
    30: ["Gift"],                # Nidorina
    31: ["Gift", "Mark"],        # Nidoqueen
    32: ["Gift"],                # Nidoran♂
    33: ["Gift"],                # Nidorino
    34: ["Gift", "Mark"],        # Nidoking
    35: ["Normal"],              # Clefairy
    36: ["Normal"],              # Clefable
    37: ["Eld"],                 # Vulpix
    38: ["Eld"],                 # Ninetales
    39: ["Normal"],              # Jigglypuff
    40: ["Normal"],              # Wigglytuff
    41: ["Gift", "Flyg"],        # Zubat
    42: ["Gift", "Flyg"],        # Golbat
    43: ["Gräs", "Gift"],        # Oddish
    44: ["Gräs", "Gift"],        # Gloom
    45: ["Gräs", "Gift"],        # Vileplume
    46: ["Insekt", "Gräs"],      # Paras
    47: ["Insekt", "Gräs"],      # Parasect
    48: ["Insekt", "Gift"],      # Venonat
    49: ["Insekt", "Gift"],      # Venomoth
    50: ["Mark"],                # Diglett
    51: ["Mark"],                # Dugtrio
    52: ["Normal"],              # Meowth
    53: ["Normal"],              # Persian
    54: ["Vatten"],              # Psyduck
    55: ["Vatten"],              # Golduck
    56: ["Kamp"],                # Mankey
    57: ["Kamp"],                # Primeape
    58: ["Eld"],                 # Growlithe
    59: ["Eld"],                 # Arcanine
    60: ["Vatten"],              # Poliwag
    61: ["Vatten"],              # Poliwhirl
    62: ["Vatten", "Kamp"],      # Poliwrath
    63: ["Psyko"],               # Abra
    64: ["Psyko"],               # Kadabra
    65: ["Psyko"],               # Alakazam
    66: ["Kamp"],                # Machop
    67: ["Kamp"],                # Machoke
    68: ["Kamp"],                # Machamp
    69: ["Gräs", "Gift"],        # Bellsprout
    70: ["Gräs", "Gift"],        # Weepinbell
    71: ["Gräs", "Gift"],        # Victreebel
    72: ["Vatten", "Gift"],      # Tentacool
    73: ["Vatten", "Gift"],      # Tentacruel
    74: ["Sten", "Mark"],        # Geodude
    75: ["Sten", "Mark"],        # Graveler
    76: ["Sten", "Mark"],        # Golem
    77: ["Eld"],                 # Ponyta
    78: ["Eld"],                 # Rapidash
    79: ["Vatten", "Psyko"],     # Slowpoke
    80: ["Vatten", "Psyko"],     # Slowbro
    81: ["Elektro"],             # Magnemite
    82: ["Elektro"],             # Magneton
    83: ["Normal", "Flyg"],      # Farfetch'd
    84: ["Normal", "Flyg"],      # Doduo
    85: ["Normal", "Flyg"],      # Dodrio
    86: ["Vatten"],              # Seel
    87: ["Vatten", "Is"],        # Dewgong
    88: ["Gift"],                # Grimer
    89: ["Gift"],                # Muk
    90: ["Vatten"],              # Shellder
    91: ["Vatten", "Is"],        # Cloyster
    92: ["Spöke", "Gift"],       # Gastly
    93: ["Spöke", "Gift"],       # Haunter
    94: ["Spöke", "Gift"],       # Gengar
    95: ["Sten", "Mark"],        # Onix
    96: ["Psyko"],               # Drowzee
    97: ["Psyko"],               # Hypno
    98: ["Vatten"],              # Krabby
    99: ["Vatten"],              # Kingler
    100: ["Elektro"],            # Voltorb
    101: ["Elektro"],            # Electrode
    102: ["Gräs", "Psyko"],      # Exeggcute
    103: ["Gräs", "Psyko"],      # Exeggutor
    104: ["Mark"],               # Cubone
    105: ["Mark"],               # Marowak
    106: ["Kamp"],               # Hitmonlee
    107: ["Kamp"],               # Hitmonchan
    108: ["Normal"],             # Lickitung
    109: ["Gift"],               # Koffing
    110: ["Gift"],               # Weezing
    111: ["Mark", "Sten"],       # Rhyhorn
    112: ["Mark", "Sten"],       # Rhydon
    113: ["Normal"],             # Chansey
    114: ["Gräs"],               # Tangela
    115: ["Normal"],             # Kangaskhan
    116: ["Vatten"],             # Horsea
    117: ["Vatten"],             # Seadra
    118: ["Vatten"],             # Goldeen
    119: ["Vatten"],             # Seaking
    120: ["Vatten"],             # Staryu
    121: ["Vatten", "Psyko"],    # Starmie
    122: ["Psyko"],              # Mr. Mime
    123: ["Insekt", "Flyg"],     # Scyther
    124: ["Is", "Psyko"],        # Jynx
    125: ["Elektro"],            # Electabuzz
    126: ["Eld"],                # Magmar
    127: ["Insekt"],             # Pinsir
    128: ["Normal"],             # Tauros
    129: ["Vatten"],             # Magikarp
    130: ["Vatten", "Flyg"],     # Gyarados
    131: ["Vatten", "Is"],       # Lapras
    132: ["Normal"],             # Ditto
    133: ["Normal"],             # Eevee
    134: ["Vatten"],             # Vaporeon
    135: ["Elektro"],            # Jolteon
    136: ["Eld"],                # Flareon
    137: ["Normal"],             # Porygon
    138: ["Sten", "Vatten"],     # Omanyte
    139: ["Sten", "Vatten"],     # Omastar
    140: ["Sten", "Vatten"],     # Kabuto
    141: ["Sten", "Vatten"],     # Kabutops
    142: ["Sten", "Flyg"],       # Aerodactyl
    143: ["Normal"],             # Snorlax
    144: ["Is", "Flyg"],         # Articuno
    145: ["Elektro", "Flyg"],    # Zapdos
    146: ["Eld", "Flyg"],        # Moltres
    147: ["Drake"],              # Dratini
    148: ["Drake"],              # Dragonair
    149: ["Drake", "Flyg"],      # Dragonite
    150: ["Psyko"],              # Mewtwo
    151: ["Psyko"],              # Mew
    312798312: ["Flyg", "Normal"] # MissingNo (Fixed: Flying instead of Bird)
}

def populate_types(db_path):
    """Populate Pokemon types in the database"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Get type IDs
        cursor.execute("SELECT type_id, type_name FROM PokemonTypes")
        type_map = {name: id for id, name in cursor.fetchall()}
        
        # Clear existing type links first
        cursor.execute("DELETE FROM PokemonTypeLinks")
        
        # Insert Pokemon type links with proper ordering
        for pokemon_id, types in pokemon_types.items():
            # Sort types by name to ensure consistent ordering since GROUP_CONCAT doesn't support ORDER BY in older SQLite
            # Primary type first, then secondary
            for i, type_name in enumerate(types, 1):
                if type_name in type_map:
                    cursor.execute("""
                        INSERT INTO PokemonTypeLinks (pokemon_id, type_id, type_order)
                        VALUES (?, ?, ?)
                    """, (pokemon_id, type_map[type_name], i))
                else:
                    print(f"Warning: Type '{type_name}' not found in database for Pokemon {pokemon_id}")
        
        conn.commit()
        print(f"Successfully populated types for {len(pokemon_types)} Pokemon with Swedish type names")
        
    except Exception as e:
        conn.rollback()
        print(f"Error populating types: {e}")
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    db_path = os.path.join(os.path.dirname(__file__), "..", "Database", "base.db")
    populate_types(db_path)