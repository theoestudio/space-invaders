-- One row per tap on a "More from TwinSpear" link: which game, and whether it was the
-- menu's list or the suggestion under a result. Unlinkable like `runs`: a random id
-- and the UTC date the row arrived, nothing about who tapped.
CREATE TABLE promo (
  id     TEXT NOT NULL PRIMARY KEY,                 -- random UUID
  day    TEXT NOT NULL,                             -- YYYY-MM-DD, UTC, server clock
  target TEXT NOT NULL,                             -- the tapped game's id
  place  TEXT NOT NULL CHECK (place IN ('menu', 'end'))
);

CREATE INDEX promo_day ON promo (day);
