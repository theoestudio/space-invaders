-- The leaderboard (src/board.ts) reads counted cash-outs per mode, per day for the daily
-- run, highest payout first. A daily run's `day` is now the date of the daily it played
-- (the same as the arrival date except across UTC midnight).
CREATE INDEX runs_board ON runs (mode, official, outcome, day, payout);
