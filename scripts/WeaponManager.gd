extends Node

const RARITY_EMOJIS = {
    "common": "⚪",
    "uncommon": "🟢",
    "rare": "🔵",
    "epic": "🟣",
    "legendary": "🟡"
}

const RARITY_CHANCES = {
    "common": 0.50,     # 50%
    "uncommon": 0.25,   # 25%
    "rare": 0.15,       # 15%
    "epic": 0.08,       # 8%
    "legendary": 0.02   # 2%
}

const RARITY_MULTIPLIERS = {
    "common": 1.0,
    "uncommon": 1.5,
    "rare": 2.0,
    "epic": 2.5,
    "legendary": 3.0
}

const WEAPON_TYPES = {
    "sword": {
        "emoji": "⚔️",
        "base_damage": [15, 25],
        "base_crit": 0.1
    },
    "bow": {
        "emoji": "🏹",
        "base_damage": [12, 30],
        "base_crit": 0.15
    },
    "staff": {
        "emoji": "🔮",
        "base_damage": [20, 35],
        "base_crit": 0.05
    },
    "axe": {
        "emoji": "🪓",
        "base_damage": [18, 28],
        "base_crit": 0.12
    }
}

const MATERIAL_TYPES = {
    "common_crystal": {"emoji": "💎", "rarity": "common"},
    "rare_crystal": {"emoji": "🔷", "rarity": "rare"},
    "epic_crystal": {"emoji": "🟣", "rarity": "epic"},
    "legendary_crystal": {"emoji": "⭐", "rarity": "legendary"},
    "enhancement_stone": {"emoji": "🔨", "rarity": "common"}
}

var rng = RandomNumberGenerator.new()
var db

func _init():
    rng.randomize()
    db = get_node("/root/DatabaseManager")

func generate_weapon(weapon_type: String = "") -> Dictionary:
    if weapon_type.empty():
        var types = WEAPON_TYPES.keys()
        weapon_type = types[rng.randi() % types.size()]
    
    var rarity = _generate_rarity()
    var weapon_base = WEAPON_TYPES[weapon_type]
    var damage_range = weapon_base.base_damage
    
    var base_damage = rng.randf_range(damage_range[0], damage_range[1])
    var final_damage = base_damage * RARITY_MULTIPLIERS[rarity]
    
    return {
        "id": str(randi()),
        "type": weapon_type,
        "rarity": rarity,
        "damage": final_damage,
        "crit_chance": weapon_base.base_crit,
        "level": 1,
        "enhancement": 0,
        "emoji": weapon_base.emoji,
        "rarity_emoji": RARITY_EMOJIS[rarity]
    }

func _generate_rarity() -> String:
    var roll = rng.randf()
    var cumulative = 0.0
    
    for rarity in RARITY_CHANCES:
        cumulative += RARITY_CHANCES[rarity]
        if roll <= cumulative:
            return rarity
    
    return "common"  # Fallback

func enhance_weapon(weapon: Dictionary, materials: Array) -> Dictionary:
    var success_chance = 0.0
    var enhancement_power = 0.0
    
    for material in materials:
        match material.type:
            "enhancement_stone":
                success_chance += 0.1
                enhancement_power += 1.0
            "common_crystal":
                success_chance += 0.05
                enhancement_power += 0.5
            "rare_crystal":
                success_chance += 0.1
                enhancement_power += 1.0
            "epic_crystal":
                success_chance += 0.15
                enhancement_power += 1.5
            "legendary_crystal":
                success_chance += 0.2
                enhancement_power += 2.0
    
    var roll = rng.randf()
    var result = {
        "success": roll <= success_chance,
        "weapon": weapon.duplicate(),
        "destroyed": false
    }
    
    if result.success:
        result.weapon.enhancement += 1
        result.weapon.damage *= (1.0 + (enhancement_power * 0.1))
        result.weapon.crit_chance += 0.01
    elif roll > 0.95:  # 5% chance to destroy on failure
        result.destroyed = true
    
    return result

func format_weapon_info(weapon: Dictionary) -> String:
    return """
%s %s **Level %d %s +%d**
💥 Damage: %.1f
⚡ Crit Chance: %.1f%%
    """ % [
        weapon.rarity_emoji,
        weapon.emoji,
        weapon.level,
        weapon.type.capitalize(),
        weapon.enhancement,
        weapon.damage,
        weapon.crit_chance * 100
    ]

func generate_material(material_type: String = "") -> Dictionary:
    if material_type.empty():
        var types = MATERIAL_TYPES.keys()
        material_type = types[rng.randi() % types.size()]
    
    var material_info = MATERIAL_TYPES[material_type]
    
    return {
        "id": str(randi()),
        "type": material_type,
        "emoji": material_info.emoji,
        "rarity": material_info.rarity
    }
