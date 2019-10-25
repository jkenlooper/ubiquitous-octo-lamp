CREATE TABLE BitIcon (
  id INTEGER PRIMARY KEY,
  user INTEGER REFERENCES User (id), -- TODO: migrate and remove. Switch to BitIcon_User table.
  author INTEGER REFERENCES BitAuthor (id),
  name TEXT UNIQUE, -- should match the filename without extension (character-fish)
  last_viewed TEXT, -- timestamp
  expiration TEXT -- timestamp -- TODO: migrate and remove. The expiration will be set on BitIcon_User
);
