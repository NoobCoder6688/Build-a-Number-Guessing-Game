#!/bin/bash

# Define the PSQL variable for querying the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Prompt the user for their username
echo "Enter your username:"
read USERNAME

# Check if the username already exists in the database
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]; then
  # If the username doesn't exist, insert it into the database
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  # Get the user_id of the newly inserted user
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # If the username exists, retrieve the user information
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< $USER_INFO
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate a random secret number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
GUESSES=0

# Prompt the user to guess the secret number
echo "Guess the secret number between 1 and 1000:"
while true; do
  read GUESS
  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  else
    ((GUESSES++))
    if (( GUESS == SECRET_NUMBER )); then
      echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
      break
    elif (( GUESS > SECRET_NUMBER )); then
      echo "It's lower than that, guess again:"
    else
      echo "It's higher than that, guess again:"
    fi
  fi
done

# Update the user's games played count
GAMES_PLAYED=$(( GAMES_PLAYED + 1 ))
UPDATE_GAMES_PLAYED_RESULT=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE user_id=$USER_ID")

# Insert the game result into the games table
INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $GUESSES)")

# Update the user's best game if this game had fewer guesses
if [[ -z $BEST_GAME || $GUESSES -lt $BEST_GAME ]]; then
  UPDATE_BEST_GAME_RESULT=$($PSQL "UPDATE users SET best_game=$GUESSES WHERE user_id=$USER_ID")
fi
