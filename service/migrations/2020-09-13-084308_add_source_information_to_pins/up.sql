DROP TABLE pins;
CREATE TABLE pins (
  id SERIAL PRIMARY KEY,
  conversation_id INT NOT NULL,
  counter INT NOT NULL,
  FOREIGN KEY (conversation_id, counter) REFERENCES messages(conversation_id, counter),
  identifier_id INT REFERENCES identifiers(id) NOT NULL,
  content TEXT NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
