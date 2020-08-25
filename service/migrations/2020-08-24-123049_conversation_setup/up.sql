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
  -- TODO add these features
  -- slug VARCHAR UNIQUE,
  -- root_conversation_id INT REFERENCES conversations(id),
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('conversations');

CREATE TABLE participants (
  id SERIAL PRIMARY KEY,
  conversation_id INT REFERENCES conversations(id) NOT NULL,
  identifier_id INT REFERENCES identifiers(id) NOT NULL,
  -- TODO add these features
  -- Position
  -- mark as unrea
  -- active
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('participants');

CREATE TABLE messages (
  id SERIAL PRIMARY KEY,
  conversation_id INT REFERENCES conversations(id) NOT NULL,
  content TEXT NOT NULL,
  author_id INT REFERENCES identifiers(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('messages');
