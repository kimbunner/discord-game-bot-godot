extends Node

const WEAPON_EMOJIS = {
    "sword": "⚔️",
    "bow": "🏹",
    "magic": "🔮",
    "shield": "🛡️"
}

const EFFECT_EMOJIS = {
    "hit": "💥",
    "miss": "💨",
    "critical": "⚡",
    "heal": "💚",
    "buff": "💪",
    "debuff": "🤕",
    "death": "💀",
    "victory": "🏆"
}

const STATUS_EMOJIS = {
    "poison": "☠️",
    "burn": "🔥",
    "freeze": "❄️",
    "stun": "💫"
}

var db
var rng = RandomNumberGenerator.new()

func _init():
    rng.randomize()
    db = get_node("/root/DatabaseManager")

func calculate_damage(attacker_stats: Dictionary, defender_stats: Dictionary) -> Dictionary:
    var base_damage = attacker_stats.attack - defender_stats.defense
    var is_critical = rng.randf() < 0.15  # 15% critical chance
    
    if base_damage < 0:
        base_damage = 0
    
    if is_critical:
        base_damage *= 2
    
    return {
        "damage": base_damage,
        "is_critical": is_critical
    }

func apply_status_effect() -> Dictionary:
    var effects = ["poison", "burn", "freeze", "stun"]
    var chance = rng.randf()
    
    if chance < 0.2:  # 20% chance for status effect
        var effect = effects[rng.randi() % effects.size()]
        return {
            "has_effect": true,
            "effect": effect,
            "emoji": STATUS_EMOJIS[effect]
        }
    
    return {
        "has_effect": false
    }

func generate_combat_log(attacker: String, defender: String, damage_info: Dictionary, status_info: Dictionary) -> String:
    var log = ""
    
    # Attack phase
    if damage_info.is_critical:
        log += EFFECT_EMOJIS.critical + " Critical hit! "
    
    log += "%s %s attacks %s" % [
        WEAPON_EMOJIS.sword,
        attacker,
        defender
    ]
    
    if damage_info.damage > 0:
        log += "\n%s Deals %d damage!" % [EFFECT_EMOJIS.hit, damage_info.damage]
    else:
        log += "\n%s Attack blocked!" % EFFECT_EMOJIS.miss
    
    # Status effect phase
    if status_info.has_effect:
        log += "\n%s %s was inflicted with %s!" % [
            status_info.emoji,
            defender,
            status_info.effect
        ]
    
    return log

func execute_combat_turn(attacker_id: String, defender_id: String) -> Dictionary:
    var attacker = db.get_player(attacker_id)
    var defender = db.get_player(defender_id)
    
    var damage_info = calculate_damage(attacker, defender)
    var status_info = apply_status_effect()
    
    # Update defender's HP
    defender.hp -= damage_info.damage
    
    # Check for victory
    var is_victory = defender.hp <= 0
    if is_victory:
        defender.hp = 0
    
    # Update stats in database
    db.update_player_stats(defender_id, {"hp": defender.hp})
    
    # Generate combat log
    var log = generate_combat_log(attacker.id, defender.id, damage_info, status_info)
    
    # Add victory/death message if applicable
    if is_victory:
        log += "\n%s %s has been defeated! %s %s is victorious!" % [
            EFFECT_EMOJIS.death,
            defender.id,
            EFFECT_EMOJIS.victory,
            attacker.id
        ]
        
        # Award victory rewards
        var reward = 100 + rng.randi_range(1, 50)  # Base 100 + random 1-50
        db.update_player_currency(attacker_id, reward)
        log += "\n💰 Victory reward: %d coins!" % reward
        
        # Reset defender's HP
        db.update_player_stats(defender_id, {"hp": 100})
    
    return {
        "log": log,
        "is_victory": is_victory,
        "damage_dealt": damage_info.damage,
        "was_critical": damage_info.is_critical,
        "status_effect": status_info
    }

func heal_player(player_id: String, amount: int) -> Dictionary:
    var player = db.get_player(player_id)
    var heal_amount = amount
    
    if player.hp + heal_amount > 100:
        heal_amount = 100 - player.hp
    
    player.hp += heal_amount
    db.update_player_stats(player_id, {"hp": player.hp})
    
    return {
        "healed": heal_amount,
        "new_hp": player.hp,
        "message": "%s Healed for %d HP! Current HP: %d/100" % [
            EFFECT_EMOJIS.heal,
            heal_amount,
            player.hp
        ]
    }

func get_player_status(player_id: String) -> String:
    var player = db.get_player(player_id)
    return """
%s **Combat Status:**
❤️ HP: %d/100
%s Attack: %d
%s Defense: %d
""" % [
        WEAPON_EMOJIS.sword,
        player.hp,
        EFFECT_EMOJIS.buff,
        player.attack,
        WEAPON_EMOJIS.shield,
        player.defense
    ]
