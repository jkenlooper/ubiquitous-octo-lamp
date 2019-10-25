-- The Color table stores color values that should be in web format.  These will
-- be used for the background color of bit icons and will be unique for each bit
-- icon.  This will allow multiple players to have the same bit icon, but it
-- will be on a different background color.
create table Color (
  id integer primary key,
  value text unique
);
