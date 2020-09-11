CREATE TABLE identifiers (
  id SERIAL PRIMARY KEY,
  email_address VARCHAR NOT NULL UNIQUE,
  nickname VARCHAR,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('identifiers');

CREATE TABLE link_tokens (
  selector VARCHAR PRIMARY KEY,
  validator VARCHAR NOT NULL,
  identifier_id INT REFERENCES identifiers(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
  -- updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE refresh_tokens (
  selector VARCHAR PRIMARY KEY,
  validator VARCHAR NOT NULL,
  link_token_selector VARCHAR REFERENCES link_tokens(selector) ON DELETE CASCADE NOT NULL,
  user_agent VARCHAR NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
  -- updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE session_tokens (
  selector VARCHAR PRIMARY KEY,
  validator VARCHAR NOT NULL,
  refresh_token_selector VARCHAR REFERENCES refresh_tokens(selector) ON DELETE CASCADE NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
  -- updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE conversations (
  id SERIAL PRIMARY KEY,
  topic VARCHAR,
  resolved BOOLEAN NOT NULL DEFAULT False,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('conversations');

CREATE TABLE messages (
  conversation_id INT REFERENCES conversations(id) NOT NULL,
  counter INT NOT NULL,
  PRIMARY KEY (conversation_id, counter),
  content TEXT NOT NULL,
  author_id INT REFERENCES identifiers(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('messages');

CREATE TABLE pins (
  id SERIAL PRIMARY KEY,
  conversation_id INT REFERENCES conversations(id) NOT NULL,
  content TEXT NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('pins');

-- Single incrementing message would allow the cursor to be unique
-- UUID for message would make it hard to fake the cursor position, but only messing up your own cursor
CREATE TABLE participants (
  identifier_id INT REFERENCES identifiers(id) NOT NULL,
  conversation_id INT REFERENCES conversations(id) NOT NULL,
  PRIMARY KEY (identifier_id, conversation_id),
  cursor INT NOT NULL,
  -- requires cursor being nullable for conversation with no messages or making a create conversation "Event"
  -- FOREIGN KEY (conversation_id, cursor) REFERENCES messages(conversation_id, counter),
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
  conversation_id INT NOT NULL,
  counter INT NOT NULL,
  FOREIGN KEY (conversation_id, counter) REFERENCES messages(conversation_id, counter),
  identifier_id INT REFERENCES identifiers(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
)
