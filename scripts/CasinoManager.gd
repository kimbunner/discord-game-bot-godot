extends Node

const EMOJI_SLOTS = ["🍎", "🍊", "🍇", "🍒", "💎", "7️⃣", "🎰"]
const EMOJI_DICE = ["⚀", "⚁", "⚂", "⚃", "⚄", "⚅"]
const EMOJI_CARDS = ["♠️", "♥️", "♣️", "♦️"]
const CARD_NUMBERS = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

var db
var rng = RandomNumberGenerator.new()

func _init():
    rng.randomize()
    db = get_node("/root/DatabaseManager")

# Slots game
func play_slots(player_id: String, wager: int) -> Dictionary:
    var player = db.get_player(player_id)
    if player.currency < wager:
        return {"success": false, "message": "Not enough currency!"}
    
    # Generate 3 random emojis
    var slots = []
    for i in range(3):
        slots.append(EMOJI_SLOTS[rng.randi() % EMOJI_SLOTS.size()])
    
    var win_amount = 0
    var result_message = "🎰 | " + slots[0] + " | " + slots[1] + " | " + slots[2] + " | 🎰\n"
    
    # Check win conditions
    if slots[0] == slots[1] and slots[1] == slots[2]:
        # Jackpot for 3 matching symbols
        if slots[0] == "💎":
            win_amount = wager * 10  # Diamond jackpot
        elif slots[0] == "7️⃣":
            win_amount = wager * 7   # Seven jackpot
        else:
            win_amount = wager * 5   # Regular match
    elif slots[0] == slots[1] or slots[1] == slots[2]:
        win_amount = wager * 2       # Two matching symbols
    
    # Update player currency
    db.update_player_currency(player_id, win_amount - wager)
    
    if win_amount > 0:
        result_message += "🎉 You won " + str(win_amount) + " coins!"
    else:
        result_message += "😢 You lost " + str(wager) + " coins!"
    
    return {"success": true, "message": result_message}

# Dice game
func play_dice(player_id: String, wager: int, bet_number: int) -> Dictionary:
    if bet_number < 1 or bet_number > 6:
        return {"success": false, "message": "Please bet on a number between 1 and 6!"}
    
    var player = db.get_player(player_id)
    if player.currency < wager:
        return {"success": false, "message": "Not enough currency!"}
    
    var roll = rng.randi_range(1, 6)
    var result_message = "🎲 You rolled: " + EMOJI_DICE[roll-1] + "\n"
    
    var win_amount = 0
    if roll == bet_number:
        win_amount = wager * 6
        result_message += "🎉 You won " + str(win_amount) + " coins!"
    else:
        result_message += "😢 You lost " + str(wager) + " coins!"
    
    db.update_player_currency(player_id, win_amount - wager)
    return {"success": true, "message": result_message}

# Blackjack game
func get_card_value(card: Dictionary) -> int:
    if card.number in ["J", "Q", "K"]:
        return 10
    elif card.number == "A":
        return 11
    else:
        return int(card.number)

func play_blackjack(player_id: String, wager: int) -> Dictionary:
    var player = db.get_player(player_id)
    if player.currency < wager:
        return {"success": false, "message": "Not enough currency!"}
    
    # Deal initial cards
    var player_hand = []
    var dealer_hand = []
    
    for i in range(2):
        player_hand.append({
            "suit": EMOJI_CARDS[rng.randi() % EMOJI_CARDS.size()],
            "number": CARD_NUMBERS[rng.randi() % CARD_NUMBERS.size()]
        })
        dealer_hand.append({
            "suit": EMOJI_CARDS[rng.randi() % EMOJI_CARDS.size()],
            "number": CARD_NUMBERS[rng.randi() % CARD_NUMBERS.size()]
        })
    
    var player_total = 0
    var dealer_total = 0
    
    for card in player_hand:
        player_total += get_card_value(card)
    for card in dealer_hand:
        dealer_total += get_card_value(card)
    
    var result_message = "Your hand: "
    for card in player_hand:
        result_message += card.suit + card.number + " "
    result_message += "(" + str(player_total) + ")\n"
    
    result_message += "Dealer shows: " + dealer_hand[0].suit + dealer_hand[0].number + " ??\n"
    
    var win_amount = 0
    if player_total == 21:
        win_amount = wager * 2.5
        result_message += "🎉 Blackjack! You won " + str(win_amount) + " coins!"
    elif player_total > 21:
        result_message += "😢 Bust! You lost " + str(wager) + " coins!"
    elif dealer_total == 21:
        result_message += "😢 Dealer Blackjack! You lost " + str(wager) + " coins!"
    elif dealer_total > 21:
        win_amount = wager * 2
        result_message += "🎉 Dealer bust! You won " + str(win_amount) + " coins!"
    elif player_total > dealer_total:
        win_amount = wager * 2
        result_message += "🎉 You won " + str(win_amount) + " coins!"
    else:
        result_message += "😢 Dealer wins! You lost " + str(wager) + " coins!"
    
    db.update_player_currency(player_id, win_amount - wager)
    return {"success": true, "message": result_message}

# Roulette game
func play_roulette(player_id: String, wager: int, bet_type: String, bet_value = null) -> Dictionary:
    var player = db.get_player(player_id)
    if player.currency < wager:
        return {"success": false, "message": "Not enough currency!"}
    
    var result = rng.randi_range(0, 36)
    var win_amount = 0
    var result_message = "🎲 Ball landed on: " + str(result) + "\n"
    
    match bet_type:
        "number":
            if bet_value == result:
                win_amount = wager * 35
        "red":
            if result in [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36]:
                win_amount = wager * 2
        "black":
            if result in [2,4,6,8,10,11,13,15,17,20,22,24,26,28,29,31,33,35]:
                win_amount = wager * 2
        "even":
            if result != 0 and result % 2 == 0:
                win_amount = wager * 2
        "odd":
            if result % 2 == 1:
                win_amount = wager * 2
    
    if win_amount > 0:
        result_message += "🎉 You won " + str(win_amount) + " coins!"
    else:
        result_message += "😢 You lost " + str(wager) + " coins!"
    
    db.update_player_currency(player_id, win_amount - wager)
    return {"success": true, "message": result_message}
