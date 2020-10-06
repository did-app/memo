ALTER TABLE message_notifications ADD COLUMN success BOOLEAN;
UPDATE message_notifications SET success = TRUE;
ALTER TABLE message_notifications ALTER COLUMN success SET NOT NULL;
