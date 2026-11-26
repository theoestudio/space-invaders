-- Rules versions. The descent (floors and the cashier, rules 2) pays far more than
-- the launch game (rules 1), so the leaderboard ranks runs only against runs played
-- under the same rules. Rows from before this migration are rules 1.
ALTER TABLE runs ADD COLUMN rules INTEGER NOT NULL DEFAULT 1;
-- The floor the run ended on (1..5, 6 for After Hours) and how many fixtures it
-- bought at the cashier. NULL on rules 1 rows, which had neither.
ALTER TABLE runs ADD COLUMN floor INTEGER;
ALTER TABLE runs ADD COLUMN bought INTEGER;

-- The boards read top cash-outs and count the ones above a payout. These partial
-- indexes hold only counted cash-outs, ordered so both are index range reads; the
-- WHERE clauses must match boardScope() in src/board.ts word for word.
DROP INDEX runs_board;
CREATE INDEX runs_daily_board ON runs (rules, day, payout, waves)
  WHERE mode = 'daily' AND official = 1 AND outcome = 'cashed';
CREATE INDEX runs_arcade_board ON runs (rules, payout, waves)
  WHERE mode = 'arcade' AND official = 1 AND outcome = 'cashed';

-- Counted cash-outs per board, so a board's total is one row read instead of a scan
-- of the whole board. `day` is '' for arcade, which is all time.
CREATE TABLE boards (
  rules INTEGER NOT NULL,
  mode  TEXT    NOT NULL CHECK (mode IN ('daily', 'arcade')),
  day   TEXT    NOT NULL,
  total INTEGER NOT NULL,
  PRIMARY KEY (rules, mode, day)
);
INSERT INTO boards (rules, mode, day, total)
  SELECT 1, mode, CASE mode WHEN 'daily' THEN day ELSE '' END, COUNT(*)
  FROM runs WHERE official = 1 AND outcome = 'cashed'
  GROUP BY mode, CASE mode WHEN 'daily' THEN day ELSE '' END;
