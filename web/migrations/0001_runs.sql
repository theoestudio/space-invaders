-- One row per finished run, sent by the production web build.
-- Unlinkable by design: no player id, no client timestamp, no seed, and a random
-- row id, so two rows can never be tied to the same person. `day` is the UTC
-- date the row ARRIVED, which for a daily run is also the run's date.
CREATE TABLE runs (
  id        TEXT    PRIMARY KEY,                  -- random UUID
  day       TEXT    NOT NULL,                     -- YYYY-MM-DD, UTC, server clock
  mode      TEXT    NOT NULL CHECK (mode IN ('daily', 'arcade')),
  outcome   TEXT    NOT NULL CHECK (outcome IN ('cashed', 'invaded', 'empty')),
  waves     INTEGER NOT NULL,                     -- waves cleared, 0..30
  payout    INTEGER NOT NULL,                     -- balls cashed out; 0 when bust
  peak      INTEGER NOT NULL,                     -- most balls held at once
  shots     INTEGER NOT NULL,                     -- shots fired (fever shots included)
  kills     INTEGER NOT NULL,                     -- invaders broken
  hits      INTEGER NOT NULL,                     -- House shots that hit the launcher
  spins     INTEGER NOT NULL,                     -- reel spins
  fevers    INTEGER NOT NULL,                     -- 7-7-7 fevers
  pocketed  INTEGER NOT NULL,                     -- balls that landed in a pocket
  caught    INTEGER NOT NULL,                     -- balls caught in the launcher's cup
  official  INTEGER NOT NULL                      -- 0 for a daily replay (practice), else 1
);

CREATE INDEX runs_day ON runs (day);
