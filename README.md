# Discord Game Bot

A Discord game bot built with Godot that implements game features like inventory, trading, enhanced combat system, weapons with rarities, upgrade materials, lootboxes, and casino games.

## Features

- Player inventory system
- Currency system
- Item trading between players
- Enhanced Combat System with Emojis
- Weapon System with Rarities and Upgrades
- Material and Enhancement System
- Lootbox System with Message Progress
- Casino Games with Emoji Support
- Anti-bot and Anti-cheat Measures
- SQLite database for data persistence

## Setup Instructions

1. Install Required Addons:
   - Install [Godiscord](https://github.com/Shuflduf/Godiscord) addon
   - Install [godot-sqlite](https://github.com/2shady4u/godot-sqlite) addon
   
2. Place the addons in your project:
   ```
   project/
   ├── addons/
   │   ├── godiscord/
   │   └── godot-sqlite/
   ```

3. Configure the Bot:
   - Copy your Discord bot token
   - Open `config.json` and replace "YOUR_BOT_TOKEN_HERE" with your actual bot token

4. Enable the Plugins:
   - Open Project Settings
   - Go to Plugins tab
   - Enable both Godiscord and godot-sqlite plugins

## Available Commands

All commands use the prefix `gunn ` (e.g., `gunn help`)

### Game Commands
- `help` - Show all available commands
- `inventory` - Show your inventory
- `balance` - Check your currency
- `stats` - Show your combat stats
- `trade @user <item_id>` - Trade an item with another user
- `fight @user` - Challenge another user to a fight
- `heal` - Heal yourself (costs 50 coins)
- `redeem <code>` - Redeem a code for rewards

### Weapon System
- `weapons` - Show your weapons
- `materials` - Show your upgrade materials
- `enhance <weapon_id> <material1> [material2...]` - Enhance a weapon
- `equip <weapon_id>` - Equip a weapon

#### Weapon Rarities
- ⚪ Common (50% chance)
- 🟢 Uncommon (25% chance)
- 🔵 Rare (15% chance)
- 🟣 Epic (8% chance)
- 🟡 Legendary (2% chance)

#### Weapon Types
- ⚔️ Sword
- 🏹 Bow
- 🔮 Staff
- 🪓 Axe

#### Enhancement Materials
- 💎 Common Crystal
- 🔷 Rare Crystal
- 🟣 Epic Crystal
- ⭐ Legendary Crystal
- 🔨 Enhancement Stone

### Lootbox System
- `lootbox` - Open a lootbox
- `status` - Check lootbox and message progress

Lootboxes:
- Earned every 10 messages
- Maximum 5 lootboxes stored
- Contains random weapons, materials, and currency
- 5-minute cooldown between openings
- Anti-spam protection

### Casino Commands
- `slots <wager>` - Play slots with emoji symbols
  - Symbols: 🍎 🍊 🍇 🍒 💎 7️⃣ 🎰
  - Payouts:
    - 3 Diamonds (💎💎💎) - x10 wager
    - 3 Sevens (7️⃣7️⃣7️⃣) - x7 wager
    - 3 matching symbols - x5 wager
    - 2 matching symbols - x2 wager

- `dice <wager> <number>` - Bet on a dice roll
  - Dice faces: ⚀ ⚁ ⚂ ⚃ ⚄ ⚅
  - Bet on a number (1-6)
  - Correct guess pays x6 wager

- `blackjack <wager>` - Play blackjack with card emojis
  - Card suits: ♠️ ♥️ ♣️ ♦️
  - Payouts:
    - Blackjack - x2.5 wager
    - Regular win - x2 wager

- `roulette <wager> <bet_type> [value]` - Play roulette
  - Bet types:
    - number <0-36> - x35 payout
    - red/black - x2 payout
    - even/odd - x2 payout

## Anti-Bot and Anti-Cheat Measures

- Rate limiting on commands
- Message spam detection
- Cooldown periods between actions
- Secure database transactions
- Input validation and sanitization

## Database Structure

The bot uses SQLite with the following tables:
- players: Stores player data (currency, stats, lootboxes)
- weapons: Stores player weapons and their stats
- materials: Stores upgrade materials
- inventory: Manages regular items
- redeem_codes: Stores available redeem codes

## Contributing

Feel free to contribute to this project by:
1. Forking the repository
2. Creating a feature branch
3. Committing your changes
4. Opening a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
