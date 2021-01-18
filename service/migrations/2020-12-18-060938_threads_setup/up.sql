CREATE TABLE identifiers (
  id SERIAL PRIMARY KEY,
  email_address VARCHAR NOT NULL UNIQUE,
  greeting jsonb,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('identifiers');

CREATE TABLE link_tokens (
  selector VARCHAR PRIMARY KEY,
  validator VARCHAR NOT NULL,
  identifier_id INT REFERENCES identifiers(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE threads (
  id SERIAL PRIMARY KEY,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('threads');

CREATE TABLE pairs (
  lower_identifier_id INT REFERENCES identifiers(id) NOT NULL,
  lower_identifier_ack INT NOT NULL,
  CHECK (lower_identifier_ack >= 0),
  upper_identifier_id INT REFERENCES identifiers(id) NOT NULL,
  upper_identifier_ack INT NOT NULL,
  CHECK (upper_identifier_ack >= 0),
  PRIMARY KEY (lower_identifier_id, upper_identifier_id),
  thread_id INT REFERENCES threads(id) NOT NULL
  -- Doesn't need a timestamps as it is always references a thread and is an immutable record
);

ALTER TABLE pairs ADD CONSTRAINT pair_identifier_order
    CHECK (lower_identifier_id < upper_identifier_id);
-- This is strictly lower so identifier can't be pair with itself

CREATE TABLE memos (
  thread_id INT REFERENCES threads(id) NOT NULL,
  position INT NOT NULL,
  CHECK (position > 0),
  PRIMARY KEY (thread_id, position),
  content jsonb NOT NULL,
  authored_by INT REFERENCES identifiers(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('memos');

CREATE TABLE memo_notifications (
  id SERIAL PRIMARY KEY,
  thread_id INT NOT NULL,
  position INT NOT NULL,
  FOREIGN KEY (thread_id, position) REFERENCES memos(thread_id, position),
  recipient_id INT REFERENCES identifiers(id) NOT NULL,
  success BOOLEAN NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
);
