extends Node

const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")
var db: SQLite
var db_path: String = "user://game_bot.db"

func _ready() -> void:
    db = SQLite.new()
    db.path = db_path
    _create_tables()

func _create_tables() -> void:
    db.open_db()
    
    # Players table
    db.query("""
        CREATE TABLE IF NOT EXISTS players (
            id TEXT PRIMARY KEY,
            currency INTEGER DEFAULT 0,
            level INTEGER DEFAULT 1,
            exp INTEGER DEFAULT 0,
            hp INTEGER DEFAULT 100,
            attack INTEGER DEFAULT 10,
            defense INTEGER DEFAULT 5,
            lootboxes INTEGER DEFAULT 0
        );
    """)
    
    # Weapons table
    db.query("""
        CREATE TABLE IF NOT EXISTS weapons (
            id TEXT PRIMARY KEY,
            owner_id TEXT,
            type TEXT,
            rarity TEXT,
            damage REAL,
            crit_chance REAL,
            level INTEGER,
            enhancement INTEGER,
            equipped INTEGER DEFAULT 0,
            FOREIGN KEY (owner_id) REFERENCES players(id)
        );
    """)
    
    # Materials table
    db.query("""
        CREATE TABLE IF NOT EXISTS materials (
            id TEXT PRIMARY KEY,
            owner_id TEXT,
            type TEXT,
            quantity INTEGER DEFAULT 1,
            FOREIGN KEY (owner_id) REFERENCES players(id)
        );
    """)
    
    # Items table (for non-weapon items)
    db.query("""
        CREATE TABLE IF NOT EXISTS items (
            id TEXT PRIMARY KEY,
            name TEXT,
            type TEXT,
            value INTEGER,
            description TEXT
        );
    """)
    
    # Inventory table (for non-weapon items)
    db.query("""
        CREATE TABLE IF NOT EXISTS inventory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player_id TEXT,
            item_id TEXT,
            quantity INTEGER DEFAULT 1,
            FOREIGN KEY (player_id) REFERENCES players(id)
        );
    """)
    
    # Redeem codes table
    db.query("""
        CREATE TABLE IF NOT EXISTS redeem_codes (
            code TEXT PRIMARY KEY,
            reward_type TEXT,
            reward_value INTEGER,
            reward_item_id TEXT,
            uses_left INTEGER DEFAULT -1,
            expiry_date TEXT
        );
    """)
    
    db.close_db()

# Player operations
func get_player(player_id: String) -> Dictionary:
    db.open_db()
    var result: Array = db.fetch_array("SELECT * FROM players WHERE id = ?", [player_id])
    db.close_db()
    return result[0] if result and result.size() > 0 else {}

func create_player(player_id: String) -> void:
    db.open_db()
    db.query("INSERT INTO players (id) VALUES (?)", [player_id])
    db.close_db()

func update_player_currency(player_id: String, amount: int) -> void:
    db.open_db()
    db.query("UPDATE players SET currency = currency + ? WHERE id = ?", [amount, player_id])
    db.close_db()

func update_player_stats(player_id: String, stats: Dictionary) -> void:
    db.open_db()
    var query: String = "UPDATE players SET "
    var updates: Array[String] = []
    var values: Array = []
    
    for key in stats:
        updates.append("%s = ?" % key)
        values.append(stats[key])
    
    query += ", ".join(PackedStringArray(updates))
    query += " WHERE id = ?"
    values.append(player_id)
    db.query(query, values)
    db.close_db()

# Weapon operations
func add_weapon(player_id: String, weapon: Dictionary) -> void:
    db.open_db()
    db.query("""
        INSERT INTO weapons (id, owner_id, type, rarity, damage, crit_chance, level, enhancement)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, [
        weapon.id, player_id, weapon.type, weapon.rarity,
        weapon.damage, weapon.crit_chance, weapon.level, weapon.enhancement
    ])
    db.close_db()

func get_player_weapons(player_id: String) -> Array:
    db.open_db()
    var result: Array = db.fetch_array("SELECT * FROM weapons WHERE owner_id = ?", [player_id])
    db.close_db()
    return result if result else []

func update_weapon(weapon: Dictionary) -> void:
    db.open_db()
    db.query("""
        UPDATE weapons 
        SET damage = ?, crit_chance = ?, level = ?, enhancement = ?, equipped = ?
        WHERE id = ?
    """, [
        weapon.damage, weapon.crit_chance, weapon.level,
        weapon.enhancement, weapon.get("equipped", 0), weapon.id
    ])
    db.close_db()

func delete_weapon(weapon_id: String) -> void:
    db.open_db()
    db.query("DELETE FROM weapons WHERE id = ?", [weapon_id])
    db.close_db()

# Material operations
func add_material(player_id: String, material: Dictionary) -> void:
    db.open_db()
    var existing: Array = db.fetch_array("""
        SELECT quantity FROM materials 
        WHERE owner_id = ? AND type = ?
    """, [player_id, material.type])
    
    if existing and existing.size() > 0:
        db.query("""
            UPDATE materials 
            SET quantity = quantity + 1 
            WHERE owner_id = ? AND type = ?
        """, [player_id, material.type])
    else:
        db.query("""
            INSERT INTO materials (id, owner_id, type, quantity)
            VALUES (?, ?, ?, 1)
        """, [material.id, player_id, material.type])
    db.close_db()

func get_player_materials(player_id: String) -> Array:
    db.open_db()
    var result: Array = db.fetch_array("SELECT * FROM materials WHERE owner_id = ?", [player_id])
    db.close_db()
    return result if result else []

func use_materials(player_id: String, material_types: Array) -> bool:
    db.open_db()
    var success: bool = true
    
    for material_type in material_types:
        var result: Array = db.fetch_array("""
            SELECT quantity FROM materials 
            WHERE owner_id = ? AND type = ?
        """, [player_id, material_type])
        
        if not result or result[0].quantity < 1:
            success = false
            break
        
        db.query("""
            UPDATE materials 
            SET quantity = quantity - 1 
            WHERE owner_id = ? AND type = ?
        """, [player_id, material_type])
    
    db.close_db()
    return success

# Lootbox operations
func get_lootbox_count(player_id: String) -> int:
    db.open_db()
    var result: Array = db.fetch_array("SELECT lootboxes FROM players WHERE id = ?", [player_id])
    db.close_db()
    return result[0].lootboxes if result else 0

func add_lootbox(player_id: String) -> void:
    db.open_db()
    db.query("UPDATE players SET lootboxes = lootboxes + 1 WHERE id = ?", [player_id])
    db.close_db()

func remove_lootbox(player_id: String) -> void:
    db.open_db()
    db.query("UPDATE players SET lootboxes = lootboxes - 1 WHERE id = ? AND lootboxes > 0", [player_id])
    db.close_db()
