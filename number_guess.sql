--
-- PostgreSQL database dump for number_guess (schema + table)
-- Rebuild: psql -U postgres < number_guess.sql
--

DROP DATABASE IF EXISTS number_guess;
CREATE DATABASE number_guess;

\connect number_guess

CREATE TABLE users(
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(22) UNIQUE NOT NULL,
  games_played INTEGER NOT NULL DEFAULT 0,
  best_game INTEGER
);
