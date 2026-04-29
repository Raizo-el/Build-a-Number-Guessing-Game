#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

SECRET=$(( RANDOM % 1000 + 1 ))

echo "Enter your username:"
read -r INPUT_NAME
INPUT_NAME=$(printf '%s' "$INPUT_NAME" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
INPUT_NAME="${INPUT_NAME:0:22}"
INPUT_ESC=$(printf '%s' "$INPUT_NAME" | sed "s/'/''/g")

USER_DATA="$($PSQL "SELECT username, games_played, COALESCE(best_game::text, '0') FROM users WHERE username = '$INPUT_ESC';" 2>/dev/null)"
USER_DATA_TRIM=$(printf '%s' "$USER_DATA" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

if [[ -z "$USER_DATA_TRIM" ]]; then
  echo "Welcome, $INPUT_NAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$INPUT_ESC', 0, NULL);" >/dev/null 2>&1
  USERNAME_ESC=$INPUT_ESC
else
  IFS='|' read -r USERNAME GAMES_PLAYED BEST_GAME <<< "$USER_DATA_TRIM"
  USERNAME=$(printf '%s' "$USERNAME" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  GAMES_PLAYED=$(printf '%s' "$GAMES_PLAYED" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  BEST_GAME=$(printf '%s' "$BEST_GAME" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  USERNAME_ESC=$(printf '%s' "$USERNAME" | sed "s/'/''/g")
fi

TRIES=0
while true; do
  echo "Guess the secret number between 1 and 1000:"
  read -r GUESS
  GUESS=$(printf '%s' "$GUESS" | tr -d '\r')

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
    $PSQL "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR $TRIES < best_game THEN $TRIES ELSE best_game END WHERE username = '$USERNAME_ESC';" >/dev/null 2>&1
    break
  fi
done
