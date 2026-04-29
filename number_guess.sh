#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

SECRET=$(( RANDOM % 1000 + 1 ))

echo "Enter your username:"
read -r USERNAME
USERNAME="${USERNAME:0:22}"
USERNAME_ESC="${USERNAME//\'/\'\'}"

USER_DATA="$($PSQL "SELECT username, games_played, COALESCE(best_game::text, '0') FROM users WHERE LOWER(username) = LOWER('$USERNAME_ESC');" 2>/dev/null)"
USER_DATA_TRIM=$(echo "$USER_DATA" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

if [[ -z "$USER_DATA_TRIM" ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME_ESC', 0, NULL);" >/dev/null 2>&1
else
  IFS='|' read -r DB_USERNAME GAMES_PLAYED BEST_GAME <<< "$USER_DATA_TRIM"
  DB_USERNAME=$(echo "$DB_USERNAME" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  GAMES_PLAYED=$(echo "$GAMES_PLAYED" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  BEST_GAME=$(echo "$BEST_GAME" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  echo "Welcome back, $DB_USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

TRIES=0
while true; do
  echo "Guess the secret number between 1 and 1000:"
  read -r GUESS

  if ! [[ "$GUESS" =~ ^-?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  ((TRIES++))

  if (( GUESS > SECRET )); then
    echo "It's lower than that, guess again:"
  elif (( GUESS < SECRET )); then
    echo "It's higher than that, guess again:"
  else
    echo "You guessed it in $TRIES tries. The secret number was $SECRET. Nice job!"
    $PSQL "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR $TRIES < best_game THEN $TRIES ELSE best_game END WHERE LOWER(username) = LOWER('$USERNAME_ESC');" >/dev/null 2>&1
    break
  fi
done
