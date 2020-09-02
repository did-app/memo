CREATE TABLE identifiers (
  id SERIAL PRIMARY KEY,
  email_address VARCHAR NOT NULL UNIQUE,
  nickname VARCHAR,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('identifiers');

CREATE TABLE conversations (
  id SERIAL PRIMARY KEY,
  topic VARCHAR,
  resolved BOOLEAN NOT NULL DEFAULT False,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('conversations');

CREATE TABLE messages (
  id SERIAL PRIMARY KEY,
  conversation_id INT REFERENCES conversations(id) NOT NULL,
  counter INT NOT NULL,
  content TEXT NOT NULL,
  author_id INT REFERENCES identifiers(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('messages');
CREATE UNIQUE INDEX unique_messages_conversation_id_counter ON messages(conversation_id, counter);

CREATE TABLE pins (
  id SERIAL PRIMARY KEY,
  conversation_id INT REFERENCES conversations(id) NOT NULL,
  content TEXT NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('pins');

CREATE TABLE participants (
  identifier_id INT REFERENCES identifiers(id) NOT NULL,
  conversation_id INT REFERENCES conversations(id) NOT NULL,
  PRIMARY KEY (identifier_id, conversation_id),
  cursor INT NOT NULL,
  notify VARCHAR CHECK (notify IN ('none', 'all', 'concluded')) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('participants');
CREATE UNIQUE INDEX unique_participant_identifier_id_conversation_id ON participants(identifier_id, conversation_id);

CREATE VIEW participant_lists AS (
  SELECT p.conversation_id, json_agg(json_build_object(
      'identifier_id', p.identifier_id,
      'email_address', i.email_address,
      'nickname', i.nickname
  )) as participants
  FROM participants AS p
  JOIN identifiers AS i ON i.id = p.identifier_id
  GROUP BY (p.conversation_id)
);

CREATE TABLE message_notifications (
  id SERIAL PRIMARY KEY,
  message_id INT REFERENCES messages(id) NOT NULL,
  identifier_id INT REFERENCES identifiers(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
)
