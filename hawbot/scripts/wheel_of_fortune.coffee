# Description:
#   Made so we can play Wheel of Fortune in Campfire
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   spin (me) - return a random consonant
#
# Author:
#   pyro2927

consonants = [
  "B",
  "C",
  "D",
  "F",
  "G",
  "H",
  "J",
  "K",
  "L",
  "M",
  "N",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "V",
  "W",
  "X",
  "Y",
  "Z"
]
vowels = [
  "A",
  "E",
  "I",
  "O",
  "U"
]
# available slots to land on the wheel when spinning
slots = [
  "BANKRUPT",
  "BANKRUPT",
  "LOSE A TURN",
  900,
  500,
  350,
  600,
  500,
  400,
  550,
  800,
  300,
  700,
  900,
  500,
  5000,
  300,
  500,
  450,
  500,
  800,
  700,
  650
]
# possible games from Before & After category, because is best
possible_games = [
  "ONCE IN A LIFETIME GUARANTEE",
  "DRAMA QUEEN OF HEARTS",
  "CEILING FAN CLUB",
  "MADE FROM SCRATCH MY BACK"
  "DONALD DUCK FOR COVER",
  "SIAMESE CAT BURLAR",
  "DISC JOCKEY SHORTS"
  "BEAUTY AND THE BEAST OF BURDEN",
  "BEER NUTS AND BOLTS"
]

max_players = 3
vowel_cost = 250

player_scores = {}
player_array = []
turn_index = 0

game_board = ""

guessed_letters = []

last_spun_amount = 0

add_player = (username) ->
  player_scores[username] ?= 0 
  player_array.push username

advance_player = (msg) ->
  turn_index++
  if turn_index > player_array.length - 1
    turn_index = 0
  msg.send player_array[turn_index] + ", you're up!"

handle_spin = (msg) ->
  spun_value = msg.random slots
  current_player = player_array[turn_index]
  if (spun_value == "BANKRUPT")
    player_scores[current_player] = 0
    msg.send "Whoops, you got a BANKRUPT. You now have $0, NEXT!"
    advance_player(msg)
  else if (!isNaN(spun_value))
    last_spun_amount = spun_value
    msg.send "You got $" + last_spun_amount + ".  What letter will you guess? (Use format 'I guess `X`')"
  else
    msg.send "Too bad, so sad, you've spun a LOSE YOUR TURN"
    advance_player(msg)

# end game, print winner, reset vars
end_game = (msg) ->
  # Figure out who the winner is
  winning_player = player_array[0]
  for player in player_array
    if player_scores[player] > player_scores[winning_player]
      winning_player = player

  msg.send "" + winning_player + " wins with a score of $" + player_scores[winning_player] + "! Congratulations!"

  # reset our values
  player_scores = {}
  player_array = []
  turn_index = 0
  guessed_letters = []
  last_spun_amount = 0
  msg.send "GAME OVER"

# print the current progress of the game board
print_progress = (msg) ->
  visible_board = game_board
  for ch, i in visible_board
    if ((ch not in guessed_letters) && (ch != ' '))
      visible_board = visible_board.replace(ch, '_')
  # Figure out if the game is OVER
  # check for '_' should work just fine
  if ('_' not in visible_board)
    end_game(msg)
  else
    msg.send visible_board.split('').join(' ')

# check to see if this letter guess is correct or not
check_guess = (msg, letter) ->
  current_player = player_array[turn_index]
  if (letter in guessed_letters)
    msg.send "That letter has already been guessed, turn lost."
    advance_player(msg)
  else if (letter in game_board.split(''))
    guessed_letters.push letter
    player_scores[current_player] += last_spun_amount
    last_spun_amount = 0
    msg.send "That is correct! You now have $" + player_scores[current_player] + " spin again!"
    print_progress(msg)
  else
    guessed_letters.push letter
    advance_player(msg)
    msg.send "BEEP! That letter does not appear. NEXT!"

buy_vowel = (msg, vowel) ->
  current_player = player_array[turn_index]
  if (vowel not in vowels)
    msg.send "That is not a vowel"
  else if (player_scores[current_player] < vowel_cost)
    msg.send "You only have $" + player_scores[current_player] + ", and vowels cost $#{vowel_cost}"
  else
    player_scores[current_player] -= vowel_cost
    check_guess(msg, vowel)

module.exports = (robot) ->
  robot.respond /spin( me)?/i, (msg) ->
    if (player_array.length == 0)
      msg.send "A game has not yet been started"
    else if (player_array.length < max_players)
      msg.send "Still waiting for more players to join"
    else if (player_array[turn_index] == msg.message.user.name)
      handle_spin(msg)
    else
      msg.send "It is not your turn"

  # guess a letter, only available after spinning
  robot.respond /i guess (.)/i, (msg) ->
    if (player_array[turn_index] == msg.message.user.name)
      if (letter in vowels)
        msg.send "I'm sorry, you must buy vowels for $#{vowel_cost} each. 'hubot buy vowel A'"
      else if (last_spun_amount == 0)
        msg.send "You must spin first"
      else
        letter = msg.match[1].toUpperCase()
        check_guess(msg, letter)
    else
      msg.send "It is not your turn"

  # start a game. user who says is automatically added as player one
  robot.respond /start wof game/i, (msg) ->
    if (player_array.length == 0)
      add_player(msg.message.user.name)
      game_board = msg.random(possible_games).toUpperCase()
      msg.send "Wheel of Fortune game started, waiting for " + (max_players - 1) + " more players"
      print_progress(msg)
    else
      msg.send "I'm sorry, a game is already in progress"

  robot.respond /end wof game/i, (msg) ->
    end_game(msg)
    msg.send "Game ended!"


  # allow people to check to see whose turn it is
  robot.respond /wof turn/i, (msg) ->
    if (player_array.length == 0)
      msg.send "No WoF game currently running"
    else
      msg.send "It is " + player_array[turn_index] + "'s turn'"
  
  # buy vowel
  # can only be done between spins
  robot.respond /buy vowel (.)/i, (msg) ->
    if (player_array.length < max_players)
      msg.send "Still waiting for more players"
    else if (player_array[turn_index] == msg.message.user.name)
      if (last_spun_amount != 0)
        msg.send "You've already spun, you must pick a consonant"
      else
        letter = msg.match[1].toUpperCase()
        buy_vowel(msg, letter)
    else
      msg.send "It is not your turn"

  robot.respond /what is the score/i, (msg) ->
    for player in player_array
      msg.send "" + player + ": $" + player_scores[player]

  robot.respond /i'?m in/i, (msg) ->
    if player_array.length >= max_players
      msg.send "Game already full, sorry " + msg.message.user.name
    else
      add_player(msg.message.user.name)
      players_needed = max_players - player_array.length 
      if players_needed == 0
        msg.send "Starting game! " + player_array[turn_index] + ", you're up first!"
      else
        msg.send "Wheel of Fortune game started, waiting for " + players_needed + " more players"
