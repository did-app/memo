ALTER TABLE participants ADD COLUMN done Int;
UPDATE participants SET done = 0;
ALTER TABLE participants ALTER COLUMN done SET NOT NULL;
