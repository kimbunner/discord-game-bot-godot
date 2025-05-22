extends Node

var db
var config = {}

func _ready():
    db = get_node("/root/DatabaseManager")
    load_config()
    setup_default_data()

func load_config():
    var config_file = File.new()
    if config_file.file_exists("res://config.json"):
        config_file.open("res://config.json", File.READ)
        var json = JSON.parse(config_file.get_as_text())
        if json.error == OK:
            config = json.result
        config_file.close()

func setup_default_data():
    # Add default items
    if config.has("default_items"):
        db.open_db()
        for item in config["default_items"]:
            db.query("""
                INSERT OR IGNORE INTO items (id, name, type, value, description)
                VALUES (?, ?, ?, ?, ?)
            """, [item.id, item.name, item.type, item.value, item.description])
        db.close_db()
    
    # Add redeem codes
    if config.has("redeem_codes"):
        db.open_db()
        for code in config["redeem_codes"]:
            db.query("""
                INSERT OR IGNORE INTO redeem_codes 
                (code, reward_type, reward_value, reward_item_id, uses_left, expiry_date)
                VALUES (?, ?, ?, ?, ?, ?)
            """, [
                code.code,
                code.reward_type,
                code.get("reward_value", 0),
                code.get("reward_item_id", ""),
                code.get("uses_left", -1),
                code.get("expiry_date", null)
            ])
        db.close_db()

func give_starter_items(player_id: String):
    if config.has("starter_items"):
        for item_id in config["starter_items"]:
            db.add_item_to_inventory(player_id, item_id)
