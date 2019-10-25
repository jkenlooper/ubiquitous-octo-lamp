-- This is a linking table to assign bit icons, background color, and players.
-- The expiration column is a carry-over from the BitIcon table and should have
-- a longer expiration then before (or no expiration?).
create table BitIcon_User (
  id integer primary key,
  bit_icon integer references BitIcon (id),
  user integer references User (id),
  color integer references Color (id),
  expiration text -- timestamp
);

