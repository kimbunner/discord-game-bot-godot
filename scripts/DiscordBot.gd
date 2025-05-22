extends Node

const COMMAND_PREFIX = "gunn "

onready var discord_bot = $DiscordBot
onready var db = get_node("/root/DatabaseManager")
onready var casino = get_node("/root/CasinoManager")
onready var combat = get_node("/root/CombatManager")
onready var weapon_manager = get_node("/root/WeaponManager")
onready var lootbox_manager = get_node("/root/LootboxManager")

var bot_token = "" # Add your Discord bot token here

func _ready() -> void:
    discord_bot.token = bot_token
    discord_bot.connect("message_received", self, "_on_message_received")

func _on_message_received(message: Dictionary) -> void:
    var content: String = message.content
    var author_id: String = message.author.id
    
    # Anti-bot check: Process message for lootbox progress
    lootbox_manager.check_message(author_id, content)
    
    # Check if player exists, if not create them
    if not db.get_player(author_id):
        db.create_player(author_id)
    
    # Parse commands
    if content.begins_with(COMMAND_PREFIX):
        var command_text: String = content.substr(COMMAND_PREFIX.length())
        var parts: PackedStringArray = command_text.split(" ")
        var command: String = parts[0].to_lower()
        var args: PackedStringArray = parts.slice(1, parts.size())
        
        # Rate limit check
        var rate_check: Dictionary = lootbox_manager.check_rate_limit(author_id, command)
        if not rate_check.allowed:
            message.reply(rate_check.reason)
            return
        
        match command:
            "help":
                show_help(message)
            "inventory":
                show_inventory(message, author_id)
            "balance":
                show_balance(message, author_id)
            "stats":
                show_stats(message, author_id)
            "trade":
                handle_trade(message, author_id, args)
            "fight":
                handle_fight(message, author_id, args)
            "heal":
                handle_heal(message, author_id, args)
            "redeem":
                handle_redeem(message, author_id, args)
            # Weapon Commands
            "weapons":
                show_weapons(message, author_id)
            "materials":
                show_materials(message, author_id)
            "enhance":
                handle_enhance(message, author_id, args)
            "equip":
                handle_equip(message, author_id, args)
            # Lootbox Commands
            "lootbox":
                handle_lootbox(message, author_id, args)
            "status":
                show_status(message, author_id)
            # Casino Commands
            "slots":
                handle_slots(message, author_id, args)
            "dice":
                handle_dice(message, author_id, args)
            "blackjack":
                handle_blackjack(message, author_id, args)
            "roulette":
                handle_roulette(message, author_id, args)
            _:
                message.reply("Unknown command. Use 'gunn help' to see available commands.")

func show_help(message: Dictionary) -> void:
    var help_text: String = """
**Available Commands:**
🎮 **Game Commands:**
`gunn help` - Show this help message
`gunn inventory` - Show your inventory
`gunn balance` - Check your currency
`gunn stats` - Show your combat stats
`gunn trade @user <item_id>` - Trade an item with another user
`gunn fight @user` - Challenge another user to a fight
`gunn heal` - Heal yourself (costs 50 coins)
`gunn redeem <code>` - Redeem a code for rewards

⚔️ **Weapon Commands:**
`gunn weapons` - Show your weapons
`gunn materials` - Show your upgrade materials
`gunn enhance <weapon_id> <material1> [material2...]` - Enhance a weapon
`gunn equip <weapon_id>` - Equip a weapon

📦 **Lootbox Commands:**
`gunn lootbox` - Open a lootbox
`gunn status` - Check lootbox and message progress

🎰 **Casino Commands:**
`gunn slots <wager>` - Play slots
`gunn dice <wager> <number>` - Bet on dice
`gunn blackjack <wager>` - Play blackjack
`gunn roulette <wager> <bet_type> [value]` - Play roulette
    """
    message.reply(help_text)

# Weapon Commands
func show_weapons(message: Dictionary, player_id: String) -> void:
    var weapons: Array = db.get_player_weapons(player_id)
    if weapons.empty():
        message.reply("You don't have any weapons yet! Get some from lootboxes!")
        return
    
    var response: String = "**Your Weapons:**\n"
    for weapon in weapons:
        response += weapon_manager.format_weapon_info(weapon)
    
    message.reply(response)

func show_materials(message: Dictionary, player_id: String) -> void:
    var materials: Array = db.get_player_materials(player_id)
    if materials.empty():
        message.reply("You don't have any materials yet! Get some from lootboxes!")
        return
    
    var response: String = "**Your Materials:**\n"
    for material in materials:
        var info: Dictionary = weapon_manager.MATERIAL_TYPES[material.type]
        response += "%s %s x%d\n" % [
            info.emoji,
            material.type.replace("_", " ").capitalize(),
            material.quantity
        ]
    
    message.reply(response)

func handle_enhance(message: Dictionary, player_id: String, args: Array) -> void:
    if args.size() < 2:
        message.reply("Usage: gunn enhance <weapon_id> <material1> [material2...]")
        return
    
    var weapon_id: String = args[0]
    var material_types: PackedStringArray = args.slice(1, args.size())
    
    # Check if player has the weapon
    var weapons: Array = db.get_player_weapons(player_id)
    var weapon: Dictionary = null
    for w in weapons:
        if w.id == weapon_id:
            weapon = w
            break
    
    if not weapon:
        message.reply("You don't own this weapon!")
        return
    
    # Check if player has the materials
    if not db.use_materials(player_id, material_types):
        message.reply("You don't have all the required materials!")
        return
    
    # Enhance weapon
    var result: Dictionary = weapon_manager.enhance_weapon(weapon, material_types)
    
    if result.destroyed:
        db.delete_weapon(weapon_id)
        message.reply("💥 Oh no! Your weapon was destroyed in the enhancement process!")
    elif result.success:
        db.update_weapon(result.weapon)
        message.reply("✨ Enhancement successful!\n" + weapon_manager.format_weapon_info(result.weapon))
    else:
        message.reply("❌ Enhancement failed! But your weapon is safe.")

func handle_equip(message: Dictionary, player_id: String, args: Array) -> void:
    if args.empty():
        message.reply("Usage: gunn equip <weapon_id>")
        return
    
    var weapon_id: String = args[0]
    var weapons: Array = db.get_player_weapons(player_id)
    var target_weapon: Dictionary = null
    
    for weapon in weapons:
        if weapon.id == weapon_id:
            target_weapon = weapon
            break
    
    if not target_weapon:
        message.reply("You don't own this weapon!")
        return
    
    # Unequip all weapons
    for weapon in weapons:
        weapon.equipped = 0
        db.update_weapon(weapon)
    
    # Equip the selected weapon
    target_weapon.equipped = 1
    db.update_weapon(target_weapon)
    
    message.reply("⚔️ Equipped: " + weapon_manager.format_weapon_info(target_weapon))

# Lootbox Commands
func handle_lootbox(message: Dictionary, player_id: String, args: Array) -> void:
    var result: Dictionary = lootbox_manager.open_lootbox(player_id)
    message.reply(result.message)

func show_status(message: Dictionary, player_id: String) -> void:
    var status: String = lootbox_manager.get_lootbox_status(player_id)
    message.reply(status)

# ... (keep existing casino command handlers) ...
