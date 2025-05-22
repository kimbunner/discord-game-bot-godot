extends Node

const MESSAGES_FOR_LOOTBOX = 10
const MAX_LOOTBOXES = 5
const LOOTBOX_EMOJI = "📦"
const COOLDOWN_MINUTES = 5

var db
var weapon_manager
var rng = RandomNumberGenerator.new()

# Store message counts and timestamps for anti-spam
var message_counts = {}
var last_message_times = {}
var last_command_times = {}

func _init():
    rng.randomize()
    db = get_node("/root/DatabaseManager")
    weapon_manager = get_node("/root/WeaponManager")

func check_message(user_id: String, message_content: String) -> void:
    var current_time = OS.get_unix_time()
    
    # Anti-spam check
    if last_message_times.has(user_id):
        var time_diff = current_time - last_message_times[user_id]
        if time_diff < 1:  # 1 second cooldown between messages
            return
    
    # Update message count
    if not message_counts.has(user_id):
        message_counts[user_id] = 0
    message_counts[user_id] += 1
    
    # Update last message time
    last_message_times[user_id] = current_time
    
    # Check for lootbox
    if message_counts[user_id] >= MESSAGES_FOR_LOOTBOX:
        message_counts[user_id] = 0
        _add_lootbox(user_id)

func _add_lootbox(user_id: String) -> void:
    var current_boxes = db.get_lootbox_count(user_id)
    if current_boxes < MAX_LOOTBOXES:
        db.add_lootbox(user_id)

func can_open_lootbox(user_id: String) -> Dictionary:
    # Check if user has lootboxes
    var current_boxes = db.get_lootbox_count(user_id)
    if current_boxes <= 0:
        return {"can_open": false, "reason": "No lootboxes available!"}
    
    # Check cooldown
    var current_time = OS.get_unix_time()
    if last_command_times.has(user_id):
        var time_diff = current_time - last_command_times[user_id]
        if time_diff < COOLDOWN_MINUTES * 60:
            var minutes_left = ceil((COOLDOWN_MINUTES * 60 - time_diff) / 60.0)
            return {
                "can_open": false,
                "reason": "Please wait %d minutes before opening another lootbox!" % minutes_left
            }
    
    return {"can_open": true}

func open_lootbox(user_id: String) -> Dictionary:
    var check = can_open_lootbox(user_id)
    if not check.can_open:
        return {"success": false, "message": check.reason}
    
    # Update cooldown
    last_command_times[user_id] = OS.get_unix_time()
    
    # Remove lootbox
    db.remove_lootbox(user_id)
    
    # Generate rewards
    var rewards = _generate_lootbox_rewards()
    
    # Add rewards to user inventory
    for reward in rewards.items:
        if reward.type == "weapon":
            db.add_weapon(user_id, reward)
        else:
            db.add_material(user_id, reward)
    
    if rewards.currency > 0:
        db.update_player_currency(user_id, rewards.currency)
    
    # Format reward message
    var message = "%s **Lootbox Opened!**\n" % LOOTBOX_EMOJI
    
    if rewards.items.size() > 0:
        message += "\n**Items:**\n"
        for item in rewards.items:
            if item.type == "weapon":
                message += weapon_manager.format_weapon_info(item)
            else:
                message += "%s %s\n" % [item.emoji, item.type.replace("_", " ").capitalize()]
    
    if rewards.currency > 0:
        message += "\n💰 **%d coins**" % rewards.currency
    
    return {
        "success": true,
        "message": message,
        "rewards": rewards
    }

func _generate_lootbox_rewards() -> Dictionary:
    var rewards = {
        "items": [],
        "currency": rng.randi_range(100, 500)
    }
    
    # Generate 1-3 items
    var item_count = rng.randi_range(1, 3)
    
    for i in range(item_count):
        # 30% chance for weapon, 70% for material
        if rng.randf() < 0.3:
            rewards.items.append(weapon_manager.generate_weapon())
        else:
            rewards.items.append(weapon_manager.generate_material())
    
    return rewards

func check_rate_limit(user_id: String, command: String) -> Dictionary:
    var current_time = OS.get_unix_time()
    var command_key = "%s_%s" % [user_id, command]
    
    if last_command_times.has(command_key):
        var time_diff = current_time - last_command_times[command_key]
        if time_diff < COOLDOWN_MINUTES * 60:
            var minutes_left = ceil((COOLDOWN_MINUTES * 60 - time_diff) / 60.0)
            return {
                "allowed": false,
                "reason": "Please wait %d minutes before using this command again!" % minutes_left
            }
    
    last_command_times[command_key] = current_time
    return {"allowed": true}

func get_lootbox_status(user_id: String) -> String:
    var current_boxes = db.get_lootbox_count(user_id)
    var messages_left = MESSAGES_FOR_LOOTBOX - (message_counts.get(user_id, 0))
    
    return """
%s **Lootbox Status:**
Current Lootboxes: %d/%d
Messages until next: %d
    """ % [LOOTBOX_EMOJI, current_boxes, MAX_LOOTBOXES, messages_left]
