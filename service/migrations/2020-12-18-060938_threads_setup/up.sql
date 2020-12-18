-- TODO this might need a topic/subject but only applies to linked thread
-- I suspect linked joins to threads in the same way pair or group does
CREATE TABLE threads (
  id SERIAL PRIMARY KEY,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('threads');

CREATE TABLE pairs (
  lower_identifier_id INT REFERENCES identifiers(id) NOT NULL,
  upper_identifier_id INT REFERENCES identifiers(id) NOT NULL,
  PRIMARY KEY (lower_identifier_id, upper_identifier_id),
  thread_id INT REFERENCES threads(id) NOT NULL
  -- timestamps on thread
);

ALTER TABLE pairs ADD CONSTRAINT pair_identifier_order
    CHECK (lower_identifier_id < upper_identifier_id);
-- STRICTLY lover so can't be pair with oneself

CREATE TABLE notes (
  thread_id INT REFERENCES threads(id) NOT NULL,
  counter INT NOT NULL,
  PRIMARY KEY (thread_id, counter),
  -- TODO rename content
  blocks JSONB NOT NULL,
  authored_by INT REFERENCES identifiers(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('notes');

-- We aren't tracking invited by because go on first message

CREATE TABLE note_notifications (
  id SERIAL PRIMARY KEY,
  thread_id INT NOT NULL,
  counter INT NOT NULL,
  -- TODO check does foreign key mean the combination is valid?
  FOREIGN KEY (thread_id, counter) REFERENCES notes(thread_id, counter),
  identifier_id INT REFERENCES identifiers(id) NOT NULL,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
)
